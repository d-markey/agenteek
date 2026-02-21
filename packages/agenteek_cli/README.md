# Agenteek CLI 💻

**Agenteek CLI** provides a powerful command-line interface for interacting with Agenteek agents. It's designed for developers who prefer the terminal or want to run agents as standalone tools.

## ✨ Features

- **Standard I/O Interface**: Uses the `stdio` channel for a seamless terminal experience.
- **Advanced CLI Tools**: Integrated commands for history management, summarization, and system prompt tuning.
- **Multi-Toolset Support**: Easily plugs into `agenteek_dart`, `agenteek_files`, and other toolsets for a productive dev environment.

## 🚀 Getting Started

1.  **Get dependencies**:
    ```bash
    dart pub get
    ```

2.  **Run the CLI**:
    ```bash
    dart run bin/main.dart
    ```

## 🛠️ Usage

Once the CLI is running, you can type your prompts normally. Special commands are available:
- `/history`: View the recent conversation history.
- `/summarize`: Summarize the current conversation to save context space.
- `/quit`: Exit the application.

---
*Part of the [Agenteek](file:///c:/_Projects/ai/agenteek2/README.md) ecosystem.*
