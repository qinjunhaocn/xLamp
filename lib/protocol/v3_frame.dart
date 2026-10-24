import 'dart:typed_data';

import 'package:pointycastle/export.dart';

/// 31 字节 v3 帧编码器。
///
/// 该实现是 libencodeV3.so 中 `ble_v3_encoder` 的逐指令移植，已用 Unicorn
/// 在原始 ARM64 代码上对多组随机输入做过逐字节比对（见 tool/verify.dart）。
///
/// 帧结构（编码完成后）：
///   0..3  02 01 02 1b
///   4..5  16 f0
///   6     08
///   7     30
///   8     80（v3 标志）
///   9     00
///   10    tx_count
///   11..12 type
///   13..16 var1
///   17    var2
///   18..21 command + 参数槽
///   22..23 参数槽
///   24..25 AES(PDU[8..23]) 前两字节
///   26    0
///   27..28 rand
///   29..30 CRC-16/CCITT
class V3Frame {
  V3Frame._();

  /// XBOXES 表，取自 libencodeV3.so 的 .rodata（4 行 x 32 字节）。
  static const List<int> xboxes = <int>[
    0xb7, 0xfd, 0x93, 0x26, 0x36, 0x3f, 0xf7, 0xcc, 0x34, 0xa5, 0xe5, 0xf1,
    0x71, 0xd8, 0x31, 0x15, 0x04, 0xc7, 0x23, 0xc3, 0x18, 0x96, 0x05, 0x9a,
    0x07, 0x12, 0x80, 0xe2, 0xeb, 0x27, 0xb2, 0x75, 0xd0, 0xef, 0xaa, 0xfb,
    0x43, 0x4d, 0x33, 0x85, 0x45, 0xf9, 0x02, 0x7f, 0x50, 0x3c, 0x9f, 0xa8,
    0x51, 0xa3, 0x40, 0x8f, 0x92, 0x9d, 0x38, 0xf5, 0xbc, 0xb6, 0xda, 0x21,
    0x10, 0xff, 0xf3, 0xd2, 0xe0, 0x32, 0x3a, 0x0a, 0x49, 0x06, 0x24, 0x5c,
    0xc2, 0xd3, 0xac, 0x62, 0x91, 0x95, 0xe4, 0x79, 0xe7, 0xc8, 0x37, 0x6d,
    0x8d, 0xd5, 0x4e, 0xa9, 0x6c, 0x56, 0xf4, 0xea, 0x65, 0x7a, 0xae, 0x08,
    0xe1, 0xf8, 0x98, 0x11, 0x69, 0xd9, 0x8e, 0x94, 0x9b, 0x1e, 0x87, 0xe9,
    0xce, 0x55, 0x28, 0xdf, 0x8c, 0xa1, 0x89, 0x0d, 0xbf, 0xe6, 0x42, 0x68,
    0x41, 0x99, 0x2d, 0x0f, 0xb0, 0x54, 0xbb, 0x16,
  ];

  /// 运行时 AES key 的固定后缀（前三字节由 rand 与 tx_count 生成）。
  static const List<int> keyTail = <int>[
    0x0d, 0xbf, 0xe6, 0x42, 0x68, 0x41, 0x99,
    0x2d, 0x0f, 0xb0, 0x54, 0xbb, 0x16,
  ];

  /// 原始 APK 中 srand(0x99 + 0x10) 后首次 rand() 的低 16 位。
  static const int defaultRand = 0x2b53;

  static int _txCount = 0x10;

  static int get txCount => _txCount;

  static set txCount(int value) => _txCount = value & 0xff;

  static int _nextTx() {
    final int v = _txCount & 0xff;
    _txCount = (_txCount + 1) & 0xff;
    return v;
  }

  static int crc16(List<int> data, int init) {
    int crc = init & 0xffff;
    for (final int b in data) {
      crc ^= (b & 0xff) << 8;
      for (int i = 0; i < 8; i++) {
        crc = ((crc & 0x8000) != 0)
            ? ((crc << 1) ^ 0x1021) & 0xffff
            : (crc << 1) & 0xffff;
      }
    }
    return crc;
  }

  /// 构造 31 字节 v3 帧。
  ///
  /// [command] 为 16 位操作码，[p21]/[p22]/[p23] 为部分命令使用的参数槽。
  static Uint8List build({
    required int type,
    required int var1,
    required int var2,
    required int command,
    int p21 = 0,
    int p22 = 0,
    int p23 = 0,
    int rand = defaultRand,
    int? tx,
  }) {
    final int txValue = tx != null ? (tx & 0xff) : _nextTx();
    final Uint8List p = Uint8List(31);
    p[0] = 0x02;
    p[1] = 0x01;
    p[2] = 0x02;
    p[3] = 0x1b;
    p[4] = 0x16;
    p[5] = 0xf0;
    p[6] = 0x08;
    p[7] = 0x30;
    p[8] = 0x80;
    p[9] = 0x00;
    p[10] = txValue;
    p[11] = type & 0xff;
    p[12] = (type >> 8) & 0xff;
    p[13] = var1 & 0xff;
    p[14] = (var1 >> 8) & 0xff;
    p[15] = (var1 >> 16) & 0xff;
    p[16] = (var1 >> 24) & 0xff;
    p[17] = var2 & 0xff;
    p[18] = command & 0xff;
    p[19] = (command >> 8) & 0xff;
    p[20] = 0;
    p[21] = p21 & 0xff;
    p[22] = p22 & 0xff;
    p[23] = p23 & 0xff;
    p[24] = 0;
    p[25] = 0;
    p[26] = 0;

    final int rand16 = rand & 0xffff;
    final Uint8List key = Uint8List.fromList(<int>[
      rand16 & 0xff,
      (rand16 >> 8) & 0xff,
      txValue,
      ...keyTail,
    ]);

    final Uint8List block = Uint8List.fromList(p.sublist(8, 24));
    final ECBBlockCipher cipher = ECBBlockCipher(AESEngine())
      ..init(true, KeyParameter(key));
    final Uint8List out = Uint8List(16);
    cipher.processBlock(block, 0, out, 0);

    int check = out[0] | (out[1] << 8);
    if (check == 0) check = 0xffff;
    p[24] = check & 0xff;
    p[25] = (check >> 8) & 0xff;

    final int r = rand16 & 0xff;
    final int row = 0; // wrapper 的 input[2] 恒为 0
    for (int i = 9; i <= 26; i++) {
      p[i] ^= r ^ xboxes[row * 32 + ((i + r) & 0x1f)];
    }

    p[27] = rand16 & 0xff;
    p[28] = (rand16 >> 8) & 0xff;

    final int crc = crc16(p.sublist(7, 29), (~rand16) & 0xffff);
    p[29] = crc & 0xff;
    p[30] = (crc >> 8) & 0xff;
    return p;
  }

  /// 把 31 字节帧转换为 13 个 16-bit Service UUID。
  static List<int> serviceUuid16(Uint8List frame) {
    final List<int> out = <int>[];
    for (int i = 0; i < 13; i++) {
      out.add((frame[5 + 2 * i] & 0xff) | ((frame[6 + 2 * i] & 0xff) << 8));
    }
    return out;
  }
}
