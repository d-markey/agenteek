import 'in_memory_file_system.dart';

class PersistentFileSystem extends MemoryFileSystem {
  PersistentFileSystem(this.root);

  @override
  final String root;
}
