import 'dart:io';

import 'local_files_base.dart';

const LocalFiles platformLocalFiles = _IoLocalFiles();

class _IoLocalFiles implements LocalFiles {
  const _IoLocalFiles();

  @override
  Future<bool> exists(String path) => File(path).exists();

  @override
  Future<void> delete(String path) async {
    final file = File(path);
    if (await file.exists()) await file.delete();
  }
}
