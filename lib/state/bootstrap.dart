/// Selects the composition root at compile time: native builds get SQLite and
/// real file imports, the browser gets in-memory equivalents.
export 'bootstrap_web.dart' if (dart.library.io) 'bootstrap_io.dart';
