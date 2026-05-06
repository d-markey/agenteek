# AGENTS.md — `agenteek_dart`

## Package Purpose

Provides `DartToolSet`, a `ToolSet` that allows agents to **analyze, format, and interact with Dart codebases**. It wraps the standard `dart` CLI tools and provides secure access to the file system for code-related operations.

---

## Public API

### `DartToolSet`

```dart
DartToolSet({
  required String prefix, // tool name namespace, e.g. "dev"
  String root = '.',      // code root directory (canonicalized)
})
```

The toolset registers tools for common Dart developer workflows. All operations are restricted to the provided `root` directory using secure path checking.

---

## Registered Tools

Tools are prefixed with `${prefix}_`.

| Tool | Action | Description |
|------|--------|-------------|
| `${prefix}_get_pubspec` | Read `pubspec.yaml` | Retrieves the content of the `pubspec.yaml` file in the root. |
| `${prefix}_analyze` | `dart analyze` | Runs the Dart analyzer on a specific file or directory. |
| `${prefix}_format` | `dart format` | Formats a specific Dart file. |

---

## Implementation Details

- **Process Execution**: Uses `Process.start` to execute the `dart` executable. Outut (stdout/stderr) is captured and returned to the LLM.
- **Path Security**: Implements `FileSystemEntityEx.check(root)` to ensure all paths provided by the LLM are within the `root` directory and resolve safely (handling symlinks).
- **Concurrency**: Manages process output via streams and completes with the full output string and exit code.

---

## Coding Conventions

- **Relative Paths**: The LLM should provide paths relative to the `root`.
- **Error Handling**: Missing files or directories result in a descriptive error message returned to the agent.
- **Namespace**: Use a descriptive `prefix` (like `coder` or `dev`) to distinguish these tools from general file system tools.

---

## Dependencies

| Package | Role |
|---------|------|
| `agenteek` | `ToolSet` base class |
| `agenteek_files` | `FileReader` for reading files |
| `dartantic_interface` | `Tool` declaration type |
| `path` | Path manipulation |
