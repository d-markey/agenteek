# Agenteek Web 🌐

**Agenteek Web** is a bare-bones, premium-looking web application designed for interacting with Agenteek agents directly in your browser. It provides a modern, responsive chat interface with support for real-time model output and tool-calling visualization.

## ✨ Features

- **Interactive Chat UI**: A clean and responsive interface built with Dart and standard Web technologies.
- **Dynamic Configuration**: Change models and providers on the fly.
- **Tool Progress**: Visual feedback as the agent uses tools (MCP servers, local toolsets).
- **Secure Secret Handling**: Uses Agenteek's `Secrets` abstraction to handle API keys safely in the browser without environment variable access.

## 🚀 Getting Started

Ensure you have the Dart SDK installed.

1.  **Get dependencies**:
    ```bash
    dart pub get
    ```

2.  **Serve the application**:
    You can use the provided batch script on Windows:
    ```bash
    ./tools/serve.bat
    ```
    Or use `webdev` if you have it installed:
    ```bash
    dart pub global run webdev serve
    ```

3.  **Open in Browser**:
    Navigate to `http://localhost:8080`.

## 🏗️ Architecture

- `web/main.dart`: Entry point that initializes the `ChatbotUI` and starts the `InteractiveAgent`.
- `web/_chatbot_ui.dart`: Handles the DOM-based chat interface and user input streams.
- `web/_toolsets.dart`: Configuration for MCP servers and local toolsets used by the web agent.

---
*Part of the [Agenteek](file:///c:/_Projects/ai/agenteek2/README.md) ecosystem.*
