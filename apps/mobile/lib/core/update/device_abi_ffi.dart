import 'dart:ffi' show Abi;

/// `arm32` untuk ponsel Android 32-bit lama, `x64` untuk emulator, dan `arm64` untuk sisanya.
/// Cocok dengan APK per arsitektur yang diterbitkan pada setiap rilis.
String deviceApkAbi() {
  final abi = Abi.current();
  if (abi == Abi.androidArm) return 'arm32';
  if (abi == Abi.androidX64) return 'x64';
  return 'arm64';
}
