import 'local_files_base.dart';

/// The browser preview cannot inspect paths from `dart:io`, so recordings are
/// always treated as reachable and deletion is a no-op.
const LocalFiles platformLocalFiles = _WebLocalFiles();

class _WebLocalFiles implements LocalFiles {
  const _WebLocalFiles();

  @override
  Future<bool> exists(String path) async => true;

  @override
  Future<void> delete(String path) async {}
}
