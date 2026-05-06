# AGENTS.md — `agenteek_web`

## Package Purpose

A **browser-based chatbot UI** that lets users interact with an Agenteek `InteractiveAgent` from the browser. Compiled to JavaScript via `dart2js` / `build_web_compilers`. The entry point is `web/main.dart`; all UI logic lives alongside it in other `web/*.dart` files.

This package is a **demo/application** rather than a library — it has no `lib/` exports.

---

## Architecture

```
web/main.dart
    → AgentUI          initializes DOM event listeners, streams user input / model output
    → initializeToolSets()  builds and returns a CombinedToolSet (from _toolsets.dart)
    → InteractiveAgent   bound to AgentUI I/O streams
    → agent.interactWithUser(agentUI.userCommandHandler)
```

The agent's configuration (model info and API key) is entered by the user through the chatbot UI itself (via a custom dialog before the normal chat begins). Once confirmed the agent reconstructs itself with the new `AgentConfiguration`.

---

## Key Files (`web/`)

| File | What it Does |
|------|-------------|
| `main.dart` | Application entry point. Prompts for GitHub PAT, initializes toolsets, builds `InteractiveAgent`, runs the interaction loop, handles agent reconfiguration when the user submits new model info |
| `_agent_ui.dart` | `AgentUI` — wraps DOM elements; exposes `userInput` (prompt stream), `modelOutput` (sink), `systemOutput` (sink), `agentConfiguration` (stream of new model configs), `userCommandHandler`, `clearMessages()`, `shutdown()`. Also manages the **prompt history** (see below) |
| `_toolsets.dart` | `initializeToolSets(secrets)` — constructs and returns the `CombinedToolSet` (e.g., `FileToolSet`, `MemoryToolSet`, MCP-connected toolsets) using secrets for authentication |
| `_user_command_handler.dart` | Slash-command handler for the web UI (subset of the CLI commands, adapted for browser context) |
| `_html_sink.dart` | `HtmlSink implements Sink<String>` — renders agent markdown output as HTML into a DOM container element |
| `_export_pdf.dart` | PDF export helper using the `pdf` package — allows users to save the current conversation as a PDF |
| `index.html` | Shell HTML page — loads `main.dart.js`, provides the chat container and input elements |
| `messages.js` | JavaScript code for the chat UI |
| `styles.css` | Chat UI stylesheet |

---

## Compilation & Development

The web package uses `build_runner` + `build_web_compilers`. A pre-compiled `main.dart.js` is checked in for convenience (do not hand-edit it).

The `build.yaml` controls compiler output settings.

---

## Coding Conventions

- **No secrets in source**: API keys and tokens are entered by the user at runtime (via `window.prompt` or through the chatbot UI). Never hardcode or commit credentials.
- **Platform target is `web` only**: This package imports `package:web/web.dart` for DOM access. Do not import `dart:io`. Keep all I/O through DOM APIs or the `http` package.
- **`InteractiveAgent` lifecycle**: The agent may be replaced when the user changes model config. Always call `agent.stopInteracting()` then `await agent.dispose()` before creating a new agent instance, to avoid dangling event listeners.
- **Output rendering**: Use `HtmlSink` (which renders markdown to HTML) for model responses. Use a plain text sink for system messages. Never write raw HTML from model output — sanitize/escape.
- **Toolset initialization is async**: `initializeToolSets()` may need to await MCP server connections. Show a loading indicator in `AgentUI.systemOutput` while it completes.
- **Conversation persistence**: Uses `PersistentConversationManager(MemoryFileSystem())` — history is lost on page reload. If persistence is needed, implement a `PersistentFileSystem`-backed manager using `localStorage` or an API.
- **Prompt history**: The `AgentUI` keeps a list of submitted prompts in memory and persists it to `sessionStorage` (key: `agenteek_prompt_history`) as a JSON array. This survives page reloads within the same browser tab session but is automatically cleared when the tab or browser is closed. Users navigate through previous prompts with the **↑ / ↓ arrow keys** while the composer textarea is focused. Consecutive duplicate entries are suppressed. The cursor resets to the "new prompt" position at the start of each input session, preserving any in-progress draft.

---

## Dependencies

| Package | Role |
|---------|------|
| `agenteek` | Core agent framework |
| `web ^1.1.1` | Browser DOM interop |
| `dartantic_ai` | LLM provider abstraction |
| `dart_mcp` | MCP client |
| `markdown` | Renders model Markdown output to HTML |
| `pdf ^3.11.0` | PDF export of conversation |
| `http ^1.2.0` | HTTP requests from the browser |
| `better_future ^2.0.3` | Async utilities |
| `cors_enabler` (dev) | Local dev server with CORS headers |
| `build_runner` (dev) | Build system orchestrator |
| `build_web_compilers` (dev) | `dart2js` integration |
| `preload` (dev) | Resource preloading for build |
