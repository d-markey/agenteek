# Agenteek Workspace 🤖

Welcome to the **Agenteek** monorepo! This workspace contains a collection of Dart packages designed to build powerful, flexible, and interactive agentic AI applications.

## 📁 Project Structure

This workspace is organized into several modular packages:

### Core & Framework
- **[agenteek](packages/agenteek)**: The core library containing the base `Agent` abstractions, conversation management, and toolset orchestration.

- **[agenteek_team](packages/agenteek_team)**: Configurable multi-agent harness for managing a team of Agenteek agents.

- **[agenteek_files](packages/agenteek_files)**: Utility classes for reading text files.

- **[agenteek_containers](packages/agenteek_containers)**: Utility classes for running workloads in containers, including a `podman` implementation via `PodmanContainer`.

### Toolsets
Specialized capabilities that can be plugged into any agent:
- **`agenteek_dart_toolset`**: Tools for Dart code analysis and execution.
- **`agenteek_files_toolset`**: Tools for file system interaction.
- **`agenteek_memory_toolset`**: Short/long-term memory management for agents.
- **`agenteek_tickets_toolset`**: Tools for managing tasks and tickets.

### Examples
- **[agenteek_web](packages/agenteek_web)**: A bare-bones web application for [chatting with agents in the browser](https://d-markey.github.io/agenteek/agenteek_web/).

## 🚀 Getting Started

Since this is a Dart workspace, you can initialize all packages from the root:

```bash
dart pub get
```

### Running the Web App
To serve the web application locally:
```bash
cd packages/agenteek_web
# Run your preferred dev server or use the provided tool
./tools/serve.bat
```

### Running the CLI
```bash
dart run packages/agenteek_cli/bin/main.dart
```

## 🛠️ Development

For detailed information on how to build agents, manage conversations, or create new toolsets, please refer to the **[Core Package README](packages/agenteek/README.md)**.

---
*Built with ❤️ for the Dart & AI community.*
