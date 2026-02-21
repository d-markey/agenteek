# Agenteek 🤖

**Agenteek** is a powerful and flexible Dart toolkit for building agentic AI applications. It provides a robust abstraction layer for creating intelligent agents that can interact with users, use tools (MCP support), manage complex conversation histories, and handle errors gracefully.

Built on top of [dartantic_ai](https://pub.dev/packages/dartantic_ai), Agenteek simplifies the process of turning large language models into useful, interactive assistants.

## ✨ Key Features

- **Interactive Agents**: Built-in `InteractiveAgent` for seamless CLI or Web-based chat loops.
- **Conversation Management**: Easily manage, persist, and restore conversation states using `ConversationManager`. Supports FileSystem and In-Memory storage.
- **Flexible ToolSets**: Native support for tool-calling, including easy integration with **Model Context Protocol (MCP)**.
- **Smart Error Handling**: Advanced `ErrorCallback` mechanism that allows user code to catch errors and provide recovery responses.
- **Customizable Lifecycle**: Hooks for conversation starts, user prompts, and command handling.
- **Multi-Provider Support**: Supports OpenAI, Google (Gemini), Anthropic, Mistral, and more via `dartantic_ai`.

## 🚀 Quick Start

While default [dartantic_ai](https://pub.dev/packages/dartantic_ai) providers attempt to load API keys from environment variables, this is often restricted in Web environments. Agenteek provides a `Secrets` abstraction and `AgentConfiguration` to handle this securely and flexibly.

### Setup with AgentConfiguration

```dart
import 'package:agenteek/agenteek.dart';

void main() async {
  // 1. Setup secrets (manual for web or loaded for CLI)
  final secrets = InMemorySecrets({'openai_key': 'sk-your-key-here'});

  // 2. Define your agent configuration
  // This automatically registers a custom provider alias with your API key
  final config = AgentConfiguration(
    modelInfo: 'openai:gpt-4o',
    apiKeyName: 'openai_key',
    displayName: 'Agenteek Assistant',
    secrets: secrets,
  );

  final conversationManager = InMemoryConversationManager();

  // 3. Create and start the interactive agent
  final agent = InteractiveAgent(
    config.modelInfo, // Uses the automatically created custom provider alias
    displayName: config.displayName,
    conversationManager: conversationManager,
    prompt: () async {
      // In a real CLI app, use stdin.readLineSync(); 
      // in Web, return the value from your custom text area.
      return "Hello!";
    },
    onError: (error, st) async {
      return "I encountered an error. Let's try to stay on track!";
    },
  );

  await agent.interactWithUser();
}
```

## 🏗️ Core Concepts

### AgentConfiguration ⚙️
`AgentConfiguration` is the recommended way to initialize your agents. It:
- **Validates** model strings (e.g., `openai:gpt-4o`).
- **Resolves** API keys from a `Secrets` provider.
- **Creates Alias Providers**: On platforms where `Platform.environment` isn't available (like Web), it creates a unique, transient provider instance specifically for that agent, ensuring your keys are handled correctly without global environment access.

### Conversation Management
Don't lose context. Use `CheckPoint` to save and restore the state of your conversation.
- `FileSystemConversationManager`: Persists history to JSON files.
- `InMemoryConversationManager`: Light-weight manager for transient sessions.

### Error Recovery 🛡️
Agenteek features a unique error recovery system. Your `onError` callback can return a `String` which the agent will use as its output if an error occurs, allowing the conversation to continue smoothly even when APIs fail.

```dart
final agent = Agent(
  // ...
  onError: (e, st) => "The service is temporarily unavailable. Let's try something else!"
);
```

### Tools & MCP
Extend your agents with tools. Agenteek makes it easy to register custom toolsets or connect to MCP servers to give your agents superpowers.

## 📦 Installation

Add `agenteek` to your `pubspec.yaml`:

```yaml
dependencies:
  agenteek: ^1.0.0
```

## 💖 Funding

If you find this project useful, please consider supporting its development:

[![GitHub Sponsors](https://img.shields.io/badge/Sponsor-GitHub-ea4aaa?style=flat&logo=github)](https://github.com/sponsors/d-markey)

## 📄 License
This project is licensed under the MIT License - see the LICENSE file for details.