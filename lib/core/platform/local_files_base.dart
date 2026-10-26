/// Filesystem operations that the controllers need, without importing
/// `dart:io` into the shared (web-compiled) code path.
abstract interface class LocalFiles {
  Future<bool> exists(String path);

  Future<void> delete(String path);
}
