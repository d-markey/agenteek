# AGENTS.md — `agenteek_tickets`

## Package Purpose

Provides `TicketToolSet`, a `ToolSet` for **managing tasks, bugs, and feature requests** as persistent tickets. Agents can open, list, update, and read tickets, which are stored as individual JSON files for easy tracking and sharing.

---

## Public API

### `TicketToolSet`

```dart
TicketToolSet({
  required String prefix,  // tool name namespace, e.g. "team"
  required String owner,   // owner of the tickets (e.g., agent name)
  String? scope,           // optional scope description
  FileSystem? fileSystem,  // backing file system for persistence
})
```

Tickets are stored as `ticket_<id>.json` files within the provided `fileSystem`.

---

## Registered Tools

Tools are prefixed with `${prefix}_`.

| Tool | Action | Description |
|------|--------|-------------|
| `${prefix}_list` | List Tickets | Lists all tickets, returning their IDs and titles. |
| `${prefix}_open` | Create Ticket | Creates a new ticket with a title and description. Generates a unique ID. |
| `${prefix}_update` | Update Ticket | Replaces the metadata/description of an existing ticket by ID. |
| `${prefix}_read` | Read Ticket | Retrieves the full details (JSON) of a specific ticket by ID. |

---

## Data Model

The `Ticket` class (in `lib/src/ticket.dart`) tracks:
- `id` (int)
- `owner` (String)
- `title` (String)
- `description` (String)
- `created` (DateTime)
- `updated` (DateTime)

---

## Coding Conventions

- **Persistence**: Use a persistent `FileSystem` (like `PersistentConversationManager`'s directory) to ensure tickets survive agent restarts.
- **IDs**: IDs are auto-incremented based on the existing files in the storage directory.
- **Owner**: The `owner` field is automatically populated from the toolset's `owner` parameter during creation/update.

---

## Dependencies

| Package | Role |
|---------|------|
| `agenteek` | `ToolSet` base, `FileSystem` abstractions, `Log` |
| `dartantic_interface` | `Tool` declaration type |
| `dart:convert` | JSON serialization |
