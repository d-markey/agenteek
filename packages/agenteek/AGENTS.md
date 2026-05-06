# AGENTS.md — `agenteek` (Core Library)

## Package Purpose

This is the **foundational library** of the Agenteek workspace. It provides all core abstractions for building agentic AI applications in Dart: agents, conversation management, toolsets, communication channels, and MCP (Model Context Protocol) integration.

All other packages in this workspace depend on `agenteek`.

---
## Architecture Overview

```
Agent / InteractiveAgent
    └── ConversationManager  (history, checkpoints, persistence)
    └── ToolSetBase          (tools given to the LLM)
    └── CommandRegistry      (slash-commands: /help, /quit, etc.)
    └── dartantic.Agent      (underlying LLM call via dartantic_ai)

ToolSet hierarchy:
    ToolSetBase
    ├── ToolSet          (concrete, mutable, used directly or combined)
    │   ├── McpToolSet   (wraps an MCP server connection)
    │   └── AgentToolSet (delegates prompts to a sub-agent)
    ├── CombinedToolSet  (merges multiple ToolSets, requires unique tool names)
    └── EmptyToolSet     (sentinel / no-op)

Channels:
    HttpChannel   — HTTP/SSE transport for MCP
    HttpClient    — thin wrapper over platform http
    StdioChannel  — stdin/stdout transport for MCP
```

---

## Key Source Files

| Path | What it Does |
|------|-------------|
| `lib/src/agents/agent.dart` | `Agent` class — wraps `dartantic.Agent`, owns conversation history, invokes the model, exposes `invoke()`, `startNewConversation()`, `summarizeConversation()` |
| `lib/src/agents/agent_interactive.dart` | `InteractiveAgent extends Agent` — runs a prompt loop (`interactWithUser()`), dispatches slash commands via `CommandRegistry`, stops with `stopInteracting()` |
| `lib/src/agents/agent_configuration.dart` | `AgentConfiguration` — YAML-driven config: model string, API key name, role, system instructions, roots, MCP ACLs, team membership |
| `lib/src/conversations/conversation_manager.dart` | Abstract `ConversationManager` interface — history, checkpoints, start/switch/delete conversations |
| `lib/src/conversations/persistent_conversation_manager.dart` | `PersistentConversationManager` — Uses `FileSystem` to persist or keep conversations in memory. |
| `lib/src/toolsets/toolset.dart` | `ToolSet` — holds `dartantic.Tool` list, registers tools, invokes by name, thread-safe disposal |
| `lib/src/toolsets/toolset_combined.dart` | `CombinedToolSet` — merges multiple `ToolSet`s (tool names must be unique across sources) |
| `lib/src/toolsets/mcp/mcp_toolset.dart` | `McpToolSet` — connects to an MCP server via a channel, discovers tools, proxies calls; applies `AccessControlList` white/black lists |
| `lib/src/toolsets/mcp/mcp_tool_support.dart` | Helpers for building `McpToolSet` from HTTP or stdio channels |
| `lib/src/toolsets/agent/agent_toolset.dart` | `AgentToolSet` — exposes a sub-agent as a single tool callable by a parent agent |
| `lib/src/channels/http_channel.dart` | `HttpChannel` — `StreamChannel<String>` over HTTP/SSE; handles redirects and 429 retry-after |
| `lib/src/channels/stdio_channel.dart` | `StdioChannel` — `StreamChannel<String>` over process stdin/stdout |
| `lib/src/secrets/secrets.dart` | `Secrets` abstract + `InMemorySecrets`; platform-conditional loading (IO / web) |
| `lib/src/commands/command.dart` | `Command` base — interface for slash-commands with metadata (`name`, `description`, `aliases`) and argument-aware `handle()` |
| `lib/src/commands/command_registry.dart` | `CommandRegistry` — indexes commands by name and alias for fast lookup; supports case-insensitive matching |
| `lib/src/commands/help_command.dart` | `HelpCommand` — dynamic discovery; lists all registered commands and their aliases |
| `lib/src/utils/zod.dart` | `z.*` helpers — generates JSON Schema objects for tool input schemas |
| `lib/src/utils/access_control_list.dart` | `AccessControlList` — white-list / black-list filtering of tool names (supports `String`, `Glob`, `RegExp`) |
| `lib/src/utils/types.dart` | `Json`, `NewConversationCallback`, `ErrorCallback`, `PromptCallback`, `UserCommandHandler` type aliases |
| `lib/src/utils/log.dart` | `Log`, `chatLogger`, `modelLogger` — lightweight append-only loggers |

---

## Coding Conventions

- **Platform-conditional imports**: Use the `_stub.dart` / `_io.dart` / `_web.dart` triple pattern for code that must differ between VM and browser (see `secrets/`).
- **Tool naming**: Tools registered on a `ToolSet` must have **unique names**. The convention is `${prefix}_${action}` (e.g., `file_read_lines`, `mcp_list_tools`).  `CombinedToolSet` enforces uniqueness at construction time and will throw `StateError` on collision.
- **Slash Commands**: Use the `CommandRegistry` on `InteractiveAgent.commandRegistry`. Register custom commands there to make them discoverable via `/help`. Commands should implement `name` and `description` for auto-documentation.
- **ToolSet disposal**: Always `await toolSet.dispose()` when shutting down. After disposal, `invoke()` throws `StateError`. The `EmptyToolSet` singleton never disposes.
- **Accessing the underlying dartantic agent**: Use `agent.agent` (the `dartantic.Agent` field). Do not cache `agent.agent.tools`; let the `ToolSet` own that list.
- **Conversation flow**: `startNewConversation()` must be called before `invoke()`. `summarizeConversation()` uses a structured prompt to capture key information and major outcomes while ignoring meta-questions.
- **Schema helpers (`z.`)**: Use `z.object({...}, required: [...])`, `z.string(...)`, `z.int(...)`, `z.bool(...)` to declare tool input schemas. These produce JSON Schema maps compatible with `dartantic_ai`.
- **Error handling in tools**: Catch exceptions inside `onCall` and return `{'error': message}` rather than rethrowing, so the LLM gets a useful error message instead of a crash.

---

## Dependencies

| Package | Role |
|---------|------|
| `dartantic_ai ^3.0.0` | LLM provider abstraction (Google, OpenAI, Mistral, Cohere, Ollama, Anthropic) |
| `dart_mcp ^0.4.0` | Model Context Protocol client/server primitives |
| `stream_channel ^2.1.4` | `StreamChannel<T>` interface used by HTTP and stdio channels |
| `http ^1.4.0` | HTTP transport (platform-conditional wrapper in `_client_io.dart` / `_client_web.dart`) |
| `async ^2.13.0` | `StreamQueue`, `unawaited`, etc. |
| `better_future ^2.0.3` | Extended `Future` utilities |
| `glob ^2.1.3` | Glob pattern matching for ACLs |
| `yaml ^3.1.3` | YAML parsing for config loading |
| `path ^1.9.1` | Cross-platform path manipulation |
| `collection ^1.19.1` | `lowerBound`, sorted collections |
| `web ^1.1.1` | Browser DOM interop (used conditionally) |
| `meta ^1.17.0` | `@immutable`, `@protected`, etc. |

---

## Testing

Tests live in `test/`. Run with:
```bash
dart test packages/agenteek
```

When writing new tests:
- Prefer `PersistentConversationManager(MemoryFileSystem())` to avoid file I/O.
- Use `ToolSet.empty` for agents that do not need tools.
- Stub `dartantic.Agent` where possible to avoid real LLM calls.
