import 'dart:ffi' show Abi;

/// True on phones running 32-bit Android (older or "Go" phones), which can't
/// install the 64-bit APK.
bool get isArm32Phone => Abi.current() == Abi.androidArm;
