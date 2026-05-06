# AGENTS.md — `agenteek_files`

## Package Purpose

Provides `FileToolSet`, a `ToolSet` that exposes **file-system operations as LLM tools**. Agents equipped with this toolset can navigate directory trees, read file contents, search by regex, and (optionally) create, edit, or delete files — all scoped to a configurable root directory to prevent path traversal attacks.

---

## Public API

### `FileToolSet`

```dart
FileToolSet({
  required String prefix,     // tool name namespace, e.g. "src"
  String? scope,              // human description injected into tool descriptions
  String root = '.',          // physical root directory (canonicalized)
  String displayRoot = '.',   // alias shown to the LLM (hides real path)
  bool allowCreate = false,
  bool allowReplace = false,
  bool allowDelete = false,
  bool showHiddenFiles = false,
})
```

Instantiation registers all permitted tools immediately. There is no lazy initialization.

### `FileReader`

Low-level helper (`lib/src/file_reader.dart`) with two static methods:
- `FileReader.readString(File)` — reads file bytes and auto-detects encoding (UTF-8, UTF-16 LE/BE, UTF-32 LE/BE).
- `FileReader.readLines(File)` — reads and splits into lines (used by `read_lines` and `replace_lines` tools).

---

## Registered Tools

Tools are always registered with the pattern `${prefix}_<action>`.

| Tool | Registered When | Description |
|------|----------------|-------------|
| `${prefix}_list_files` | Always | List files in a directory (optional: recursive, include hidden) |
| `${prefix}_locate_file` | Always | Find files anywhere under root by base-name substring |
| `${prefix}_list_directories` | Always | List sub-directories (optional: recursive, include hidden) |
| `${prefix}_search_contents` | Always | Regex search across all files (or glob-filtered subset); returns `{file → [{beginLine, endLine, text}]}` |
| `${prefix}_read_lines` | Always | Read a line range from a file (1-based, inclusive) |
| `${prefix}_line_count` | Always | Count lines in a file |
| `${prefix}_create_dir` | `allowCreate=true` | Create a directory (recursive) |
| `${prefix}_create_file` | `allowCreate=true` | Create an empty file |
| `${prefix}_replace_lines` | `allowReplace=true` | Replace a line range with new content |
| `${prefix}_delete` | `allowDelete=true` | Delete a file or empty directory |

---

## Security Model

- **Root confinement**: Every path argument is `p.canonicalize(p.join(root, path))` before resolving. If the result does not start with `root`, the call throws `'Access denied'`.
- **Hidden files**: Files/directories starting with `.` are blocked unless `showHiddenFiles: true`. Applies both to listing *and* to reading/writing.
- **Symlinks**: `check<T>(root)` resolves symlinks after canonicalization and re-checks the resolved path against `root`. Symlink escaping is prevented.
- **No shell execution**: All operations use `dart:io` file APIs directly — no `Process.run`. (Shell execution is the `agenteek_dart` toolset's responsibility.)
- **Search guard**: The `search_contents` tool refuses `.*` or `.+` patterns to prevent LLMs from accidentally dumping the entire codebase.

---

## Coding Conventions

- **Paths passed by LLMs are relative**: Strip a leading `/` from the LLM-provided path (the LLM may use POSIX-style paths). All paths are resolved relative to `root`.
- **`displayRoot` vs `root`**: Use `displayRoot` in tool descriptions and error messages shown to the LLM; keep `root` private to the toolset. This allows you to present a virtual root label like `"workspace"` without exposing the physical disk path.
- **Scope injection**: If `scope` is non-empty, it is appended to every tool description as `**scope: <scope>**`. Use this to help the LLM choose between multiple `FileToolSet` instances (e.g., one for source, one for tests).
- **Return types**: Read tools return `Json` (`Map<String, dynamic>`). Create/replace/delete tools return `String` success messages. Errors are thrown as `String` (tool framework converts them to `{'error': ...}`).
- **Line numbering is 1-based**: Consistent with most editors and the LLM's mental model.
- **`FileReader` encoding detection**: If a file starts with a BOM, the appropriate codec is used. Otherwise UTF-8 is assumed. Do not bypass `FileReader` with `File.readAsString()` to avoid encoding bugs on Windows.

---

## Dependencies

| Package | Role |
|---------|------|
| `agenteek` | `ToolSet` base class, `z.*` schema helpers |
| `dartantic_interface` | `Tool` declaration type |
| `collection` | `lowerBound` (binary search for line offsets in regex search) |
| `glob` | Glob pattern matching for `search_contents` path filter |
| `path` | `basename`, `canonicalize`, `join` |
| `dart_mcp` | Transitive (through `agenteek`) |

---

## Testing

```bash
dart test packages/toolsets/agenteek_files
```

When writing tests, create a temporary directory with `Directory.systemTemp.createTempSync()` and pass it as `root`. Tear it down in `tearDown`.
