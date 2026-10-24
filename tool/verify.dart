// 用 Unicorn 模拟原始 libencodeV3.so 得到的基准向量，校验 Dart 移植。
// 运行：dart run tool/verify.dart
// ignore_for_file: avoid_print, library_private_types_in_public_api
import 'dart:typed_data';
import 'package:xlamp/protocol/v3_frame.dart';

class Vec {
  const Vec(this.input, this.rand, this.expected);
  final String input;
  final int rand;
  final String expected;
}

const List<Vec> vectors = <Vec>[
  Vec('1030000001000210341278569a0011000000112200330100', 0x23c4,
      '0201021b16f00830801cf4d3d037f57f8ac8d05ec3d655042d2d76c42374d7'),
  Vec('1030000002000010341278569a0045000000112200330100', 0x2b53,
      '0201021b16f0083080b876e136d0bcb823ff29a49f67e7941e388b532b57d5'),
  Vec('1030000003000210341278569a0021000000112200330100', 0x1234,
      '0201021b16f008308013854393fdb56a5491e2f80091c0e79d0a0534122c84'),
  Vec('1030000004000110341278569a0052000000112200330100', 0xabcd,
      '0201021b16f0083080c853cbcf793d5ebce5ea7a305efad9e29901cdabb4c2'),
  Vec('1030000005000310341278569a0022000000112200330100', 0x0000,
      '0201021b16f0083080a5e0f261ec236d525d01c3189614b8271080000047e8'),
];

int main() {
  int ok = 0;
  for (final Vec v in vectors) {
    final Uint8List input = _hex(v.input);
    final int tx = input[4];
    final Uint8List frame = V3Frame.build(
      type: input[6] | (input[7] << 8),
      var1: input[8] | (input[9] << 8) | (input[10] << 16) | (input[11] << 24),
      var2: input[12],
      command: input[14] | (input[15] << 8),
      p21: input[17],
      p22: input[18],
      p23: input[19],
      rand: v.rand,
      tx: tx,
    );
    final String got = _toHex(frame);
    if (got == v.expected) {
      ok++;
    } else {
      print('MISMATCH\n  got $got\n  exp ${v.expected}');
    }
  }
  print('matched $ok/${vectors.length}');
  return ok == vectors.length ? 0 : 1;
}

Uint8List _hex(String s) {
  final Uint8List out = Uint8List(s.length ~/ 2);
  for (int i = 0; i < out.length; i++) {
    out[i] = int.parse(s.substring(i * 2, i * 2 + 2), radix: 16);
  }
  return out;
}

String _toHex(List<int> b) =>
    b.map((int e) => e.toRadixString(16).padLeft(2, '0')).join();
