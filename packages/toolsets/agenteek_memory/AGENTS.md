# AGENTS.md — `agenteek_memory`

## Package Purpose

Provides `MemoryToolSet`, a `ToolSet` that gives agents **persistent key-value memory** organized by named topics. By default memory is in-process only; passing a `FileSystem` implementation makes it durable across sessions.

---

## Public API

### `MemoryToolSet`

```dart
MemoryToolSet({
  required String prefix,   // tool name namespace, e.g. "architect"
  required String owner,    // logical owner name; used in filename and log labels
  String? scope,            // optional human description for tool selection hints
  FileSystem? fileSystem,   // if null, uses MemoryFileSystem (in-process only)
})
```

If a `FileSystem` is provided (e.g., a filesystem-backed implementation from `agenteek`), memory is persisted to a file named `memory_<owner>.json` in that filesystem.

### `MemoryServer`

`lib/src/memory_server.dart` — wraps `MemoryToolSet` as a standalone MCP server so it can be shared across multiple agent processes via stdio or HTTP.

---

## Registered Tools

| Tool | Description |
|------|-------------|
| `${prefix}_list_topics` | Returns all topic names currently in memory |
| `${prefix}_recall_topic` | Loads the information string stored for a given topic; returns `"Unknown topic"` if not found |
| `${prefix}_memorize_topic` | Stores/updates information for a topic. `mode` must be `"set"` (replace) or `"update"` (append with `\n\n` separator) |
| `${prefix}_forget_topic` | Removes a topic from memory |

---

## Persistence & Sync

Memory is stored as a JSON object (`{"topic": "information", ...}`) in `memory_<owner>.json`.

`_sync()` is called before every read operation: it merges any topics found in the file that are not already in the in-memory map. This means:
- Topics written by another process/session are picked up on the next read.
- Local in-memory state takes precedence over file state (no two-way conflict resolution).

After every write (`memorize_topic`, `forget_topic`), the full in-memory map is serialized back to the file.

---

## Coding Conventions

- **Topics are case-insensitive**: All topic keys are `.toLowerCase()`-ed before storage and lookup. Always normalize topic names the same way.
- **Scope injection**: Non-empty `scope` is appended to every tool description as `**scope: <scope>**` to help the LLM pick the right memory toolset when multiple are registered.
- **`mode` validation**: `memorize_topic` requires `mode` to be exactly `"set"` or `"update"`. Returning an error (throwing) for invalid modes is correct behavior.
- **`MemoryFileSystem` default**: When no `FileSystem` is passed, an `InMemoryFileSystem` instance is used. The file `memory_<owner>.json` exists only in-process and is discarded on shutdown.
- **Owner naming**: Pick a stable, unique `owner` string per agent role (e.g., `"architect"`, `"reviewer"`). This keeps memory files separate on disk and log output identifiable.
- **Do not share a `MemoryToolSet` between agents**: Each agent should have its own instance (even if they share the same backing `FileSystem`) to keep ownership semantics clear.

---

## Dependencies

| Package | Role |
|---------|------|
| `agenteek` | `ToolSet`, `FileSystem`, `MemoryFileSystem`, `z.*`, `Log`, `Json` |
| `dartantic_interface` | `Tool` declaration type |
| `dart:convert` | `jsonEncode` / `jsonDecode` for persistence |

---

## Testing

```bash
dart test packages/toolsets/agenteek_memory
```

For tests, pass an `InMemoryFileSystem()` explicitly to keep state contained. Verify sync behavior by pre-populating the file system before constructing the toolset.
