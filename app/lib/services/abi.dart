/// Whether this is the Android app on a 32-bit phone (it needs the 32-bit APK).
library;

export 'abi_stub.dart' if (dart.library.ffi) 'abi_io.dart';
