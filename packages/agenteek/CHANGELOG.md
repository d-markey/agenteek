## 1.0.0

Initial release of Agenteek, a powerful and flexible toolkit for building agentic AI applications with Dart.

### 🚀 Key Features
- **AI Agent Orchestration**: High-level abstractions for building intelligent agents on top of `dartantic_ai`.
- **Interactive Interaction Loop**: Pre-built `InteractiveAgent` for seamless chat-style interaction in CLI and Web environments.
- **Model Context Protocol (MCP)**: Native support for connecting agents to external tools and data sources via MCP servers.
- **Robust Tool Management**: Flexible `ToolSet` system for defining and combining local and remote tools.
- **Conversation Persistence**: Advanced `ConversationManager` with support for history tracking, checkpoints, and storage (FileSystem & In-Memory).
- **Advanced Error Handling**: Sophisticated `ErrorCallback` mechanism with support for catching exceptions and providing recovery responses.
- **Secure Configuration**: `AgentConfiguration` and `Secrets` abstraction for safe API key management across all platforms, including restricted Web environments.
- **Extensible Commands**: Built-in infrastructure for handling slash-commands (e.g., `/quit`, `/history`, `/tools`).
- **Comprehensive Lifecycle Hooks**: Callbacks for new conversations, user prompts, model outputs, and error states.
