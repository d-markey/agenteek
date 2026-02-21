# Agenteek Workspace 🤖

Welcome to the **Agenteek** monorepo! This workspace contains a collection of Dart packages designed to build powerful, flexible, and interactive agentic AI applications.

## 📁 Project Structure

This workspace is organized into several modular packages:

### Core & Framework
- **[agenteek](packages/agenteek)**: The core library containing the base `Agent` abstractions, conversation management, and toolset orchestration.

### Interfaces
- **[agenteek_cli](packages/agenteek_cli)**: Command-line interface for interacting with Agenteek agents.
- **[agenteek_web](packages/agenteek_web)**: A bare-bones web application for chatting with agents in the browser.

### Toolsets
Specialized capabilities that can be plugged into any agent:
- **`agenteek_dart`**: Tools for Dart code analysis and execution.
- **`agenteek_files`**: Tools for file system interaction.
- **`agenteek_memory`**: Short/long-term memory management for agents.
- **`agenteek_tickets`**: Tools for managing tasks and tickets.

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
