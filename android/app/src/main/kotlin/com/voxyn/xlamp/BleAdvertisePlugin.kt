package com.voxyn.xlamp

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.bluetooth.le.AdvertiseCallback
import android.bluetooth.le.AdvertiseData
import android.bluetooth.le.AdvertiseSettings
import android.bluetooth.le.BluetoothLeAdvertiser
import android.content.Context
import android.os.Handler
import android.os.Looper
import android.os.ParcelUuid
import android.util.Log
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.util.UUID
import java.util.concurrent.CountDownLatch
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicInteger

/**
 * 把 Dart 生成的 31 字节 v3 帧通过 BLE 广播发送出去。
 *
 * 与原 App 的 com.allinktec.ble_plugin.BlePlugin 行为对齐：
 *  - 取 payload[5..31) 共 26 字节，两字节一组转成 13 个 16-bit Service UUID；
 *  - 8 个 500ms 的广播窗口交替使用两个数据槽；
 *  - 最后广播 [0xbbaa, 0x3412] 结束标记后停止。
 */
class BleAdvertisePlugin(private val context: Context) : MethodChannel.MethodCallHandler {

    companion object {
        private const val TAG = "xLampBle"
        private const val CHANNEL = "xlamp/ble"
    }

    private val adapter: BluetoothAdapter? by lazy {
        (context.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager)?.adapter
    }
    private val advertiser: BluetoothLeAdvertiser?
        get() = adapter?.bluetoothLeAdvertiser

    private var executor: ExecutorService? = null
    private var activeCallback: AdvertiseCallback? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    fun attach(engine: io.flutter.embedding.engine.FlutterEngine) {
        MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isSupported" -> {
                val a = adapter
                result.success(a != null && a.isMultipleAdvertisementSupported)
            }
            "isEnabled" -> result.success(adapter?.isEnabled == true)
            "advertise" -> {
                val args = call.arguments as? Map<*, *> ?: run {
                    result.error("bad_args", "arguments required", null)
                    return
                }
                val payload = args["payload"] as? ByteArray
                if (payload == null || payload.size < 31) {
                    result.error("bad_payload", "payload must be 31 bytes", null)
                    return
                }
                val duration = (args["duration"] as? Number)?.toInt() ?: 4000
                val repeats = (args["repeats"] as? Number)?.toInt() ?: 8
                val interval = (args["interval"] as? Number)?.toInt() ?: 500
                startAdvertising(payload, duration, repeats, interval, result)
            }
            "stop" -> {
                stopInternal()
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }

    private fun startAdvertising(
        payload: ByteArray,
        duration: Int,
        repeats: Int,
        interval: Int,
        result: MethodChannel.Result,
    ) {
        val adv = advertiser
        if (adv == null) {
            result.error("bluetooth_unavailable", "the device does not have bluetooth", null)
            return
        }
        if (adapter?.isEnabled != true) {
            result.error("bluetooth_disabled", "bluetooth is disabled", null)
            return
        }
        val data = buildData(payload.copyOfRange(5, 31))
        if (data == null) {
            result.error("bad_payload", "cannot build advertise data", null)
            return
        }
        val settings = AdvertiseSettings.Builder()
            .setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_LOW_LATENCY)
            .setTimeout(duration)
            .setConnectable(true)
            .setTxPowerLevel(AdvertiseSettings.ADVERTISE_TX_POWER_HIGH)
            .build()
        val marker = buildMarker()

        stopInternal()
        val first = CountDownLatch(1)
        val errorCode = AtomicInteger(0)
        val callback = object : AdvertiseCallback() {
            override fun onStartSuccess(settingsInEffect: AdvertiseSettings?) {
                Log.d(TAG, "advertise started")
                first.countDown()
            }

            override fun onStartFailure(code: Int) {
                Log.w(TAG, "advertise failed: $code")
                errorCode.compareAndSet(0, code)
                first.countDown()
            }
        }
        activeCallback = callback

        val pool = Executors.newSingleThreadExecutor()
        executor = pool
        val slots = arrayOf(data, data)
        val gap = interval.toLong().coerceIn(100, 2000)
        repeat(repeats.coerceIn(1, 32)) { i ->
            pool.submit {
                if (pool.isShutdown) return@submit
                try {
                    adv.stopAdvertising(callback)
                    adv.startAdvertising(settings, slots[i % 2], callback)
                } catch (t: Throwable) {
                    Log.w(TAG, "startAdvertising", t)
                }
                sleep(gap)
            }
        }
        pool.submit {
            if (pool.isShutdown) return@submit
            try {
                adv.stopAdvertising(callback)
                adv.startAdvertising(settings, marker, callback)
            } catch (t: Throwable) {
                Log.w(TAG, "end marker", t)
            }
            sleep(gap)
        }
        pool.submit {
            try {
                adv.stopAdvertising(callback)
            } catch (t: Throwable) {
                Log.w(TAG, "stop", t)
            }
            pool.shutdown()
            synchronized(this) {
                if (executor === pool) {
                    executor = null
                    activeCallback = null
                }
            }
        }

        // 等第一次 startAdvertising 的结果，再回到主线程回复 Dart。
        Thread {
            first.await(800, TimeUnit.MILLISECONDS)
            val code = errorCode.get()
            mainHandler.post {
                if (code != 0) {
                    result.error("advertise_failed", describe(code), code)
                } else {
                    result.success(true)
                }
            }
        }.start()
    }

    private fun describe(code: Int): String = when (code) {
        AdvertiseCallback.ADVERTISE_FAILED_ALREADY_STARTED -> "广播已在进行中"
        AdvertiseCallback.ADVERTISE_FAILED_DATA_TOO_LARGE -> "广播数据超过 31 字节"
        AdvertiseCallback.ADVERTISE_FAILED_FEATURE_UNSUPPORTED -> "系统不支持 BLE 外设广播"
        AdvertiseCallback.ADVERTISE_FAILED_INTERNAL_ERROR -> "蓝牙广播内部错误"
        AdvertiseCallback.ADVERTISE_FAILED_TOO_MANY_ADVERTISERS -> "广播实例过多"
        else -> "广播启动失败（$code）"
    }

    private fun sleep(ms: Long) {
        try {
            Thread.sleep(ms)
        } catch (_: InterruptedException) {
        }
    }

    private fun stopInternal() {
        val old = executor
        executor = null
        val cb = activeCallback
        activeCallback = null
        if (old != null) {
            old.shutdownNow()
            try {
                old.awaitTermination(300, TimeUnit.MILLISECONDS)
            } catch (_: InterruptedException) {
            }
        }
        if (cb != null) {
            try {
                advertiser?.stopAdvertising(cb)
            } catch (_: Throwable) {
            }
        }
    }

    private fun uuid16(value: Int): ParcelUuid =
        ParcelUuid(UUID.fromString(String.format("0000%04x-0000-1000-8000-00805f9b34fb", value and 0xffff)))

    private fun buildData(frame: ByteArray): AdvertiseData? {
        if (frame.size != 26) return null
        val builder = AdvertiseData.Builder()
            .setIncludeDeviceName(false)
            .setIncludeTxPowerLevel(false)
        for (i in 0 until 13) {
            val lo = frame[2 * i].toInt() and 0xff
            val hi = frame[2 * i + 1].toInt() and 0xff
            builder.addServiceUuid(uuid16(lo or (hi shl 8)))
        }
        return builder.build()
    }

    private fun buildMarker(): AdvertiseData =
        AdvertiseData.Builder()
            .setIncludeDeviceName(false)
            .setIncludeTxPowerLevel(false)
            .addServiceUuid(uuid16(0xbbaa))
            .addServiceUuid(uuid16(0x3412))
            .build()
}
