import 'local_files_base.dart';
import 'local_files_web.dart' if (dart.library.io) 'local_files_io.dart'
    as impl;

export 'local_files_base.dart';

final LocalFiles localFiles = impl.platformLocalFiles;
