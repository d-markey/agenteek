# AGENTS.md — Agenteek Workspace Overview

## Workspace Purpose

**Agenteek** is a modular Dart monorepo for building **agentic AI applications**. It provides abstractions for creating AI agents, managing conversations with history and checkpoints, and equipping agents with security-scoped toolsets.

---

## Workspace Structure

The workspace is divided into several categories of packages:

### Core Framework

- **[agenteek](packages/agenteek)**: The foundational library. Defines the `Agent` and `InteractiveAgent` classes, `ConversationManager` for history (memory/persistent), `ToolSet` architecture, and `McpToolSet` for Model Context Protocol integration.

- **[agenteek_containers](packages/agenteek_containers)**: library adding support for running workloads in containers. Provides a `PodmanContainer` implementation.

- **[agenteek_files](packages/agenteek_files)**: utility library for reading text files.

- **[agenteek_team](packages/agenteek_team)**: Agenteek team configuration library. Configure a team of agents via YAML files and Markdown instructions.

### Interfaces (Frontends)

- **[agenteek_web](packages/agenteek_web)**: A browser-based chatbot UI for interacting with agents via a web interface.

### Toolsets (Capabilities)

Modular building blocks that can be plugged into any agent:

- **[agenteek_files_toolset](packages/toolsets/agenteek_files_toolset)**: File system access (list, search, read, write) with root-path security.

- **[agenteek_memory_toolset](packages/toolsets/agenteek_memory_toolset)**: Persistent topic-based memory (recall, memorize, forget).

- **[agenteek_dart_toolset](packages/toolsets/agenteek_dart_toolset)**: Dart-specific developer tools (analyze, format, test, run).

- **[agenteek_tickets_toolset](packages/toolsets/agenteek_tickets_toolset)**: Simple task/ticket management system for agents to track their work.

---

## Technical Stack

- **Language**: Dart (SDK ^3.11.0)

- **AI Core**: Powered by **[dartantic_ai](https://github.com/d-markey/dartantic_ai)**, an abstraction layer supporting multiple providers (Google, OpenAI, Anthropic, Mistral, Ollama, etc.).

- **Protocol**: Implements **MCP (Model Context Protocol)** via the `dart_mcp` package for extensible tool sharing.

- **Transports**: Supports **Stdio** and **HTTP/SSE** for agent communication and tool execution.

---

## Getting Started for Agents

If you are an agent working in this repository:

1. **Check the individual `AGENTS.md`** files within each package for specific internal details and coding conventions.

2. **Explore `packages/agenteek`** to understand the base classes (`Agent`, `ToolSet`).

3. **Secrets**: Ensure a `.secret.keys` file exists in the directory tree for API key resolution.

---

## Coding Conventions

- **Modular Toolsets**: When adding new functionality, create a new package in `packages/toolsets/` and implement the `ToolSet` interface.

- **Security**: Always use `root` path scoping for file-system operations.

- **Uniqueness**: Tool names within a `CombinedToolSet` must be unique; use package-specific prefixes.

- **Documentation**:
  * Every package **must** have an `AGENTS.md` file summarizing its purpose and internals for future AI collaborators.
  * Public APIs must be documented with /// comments.

---

## Development Workflow Tools

While specialized toolsets are provided, agents also have access to standard CLI tools for development:
- `flutter pub get` / `dart pub get`: Dependency management.
- `flutter analyze` / `dart analyze`: Static analysis.
- `flutter test` / `dart test`: Automated testing.
- `dart format`: Code formatting.

**CRITICAL: Mandatory Approval Policy**
- **Non-Systematic**: These tools must NOT be used systematically or automatically after code changes.
- **User Approval Required**: You **MUST** always ask for and receive explicit user approval before executing any of these commands. Never run them in the background without the user's consent.

