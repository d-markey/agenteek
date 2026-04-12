# AGENTS.md — `agenteek_cli`

## Package Purpose

Provides **command-line interfaces** for running Agenteek agent teams. There are two executable applications in `bin/`:

| Directory | Binary | What it runs |
|-----------|--------|-------------|
| `bin/devteam/` | `agentic_team_interactive.dart` | Interactive multi-agent dev team (read-line loop) |
| `bin/devteam/` | `agentic_team_batch.dart` | Batch mode: reads a prompt file, runs team, exits |
| `bin/calc/` | `agentic_calculator_cli.dart` | Demo: single-agent calculator that uses an MCP arithmetic server |

The shared `lib/` has only one file: `file_locator.dart` — a helper to find `.secret.keys` by walking up the directory tree.

---

## Application Structure — Dev Team

The dev-team binaries are the main workhorses. Their startup flow is:

```
main()
  → Args.parse()             parse --team-conf, --secrets, --prompt CLI flags
  → InMemorySecrets.load()   read .secret.keys
  → loadAgentsConf()         parse YAML team config → List<AgentConf>
  → buildTeam()              instantiate all InteractiveAgent / Agent instances
  → rootAgent.interactWithUser(userCommandHandler)   run the prompt loop
  → dispose all agents on exit
```

### Key Files

| File | What it Does |
|------|-------------|
| `bin/devteam/agent_conf.dart` | `AgentConf extends AgentConfiguration` — parses one agent node from YAML; handles `llm`, `api-key`, `name`, `role`, `instructions` (with template vars), `roots`, `mcp` ACLs, `tools`, `code-tools`, `language` |
| `bin/devteam/agent_loader.dart` | `loadAgentsConf()` — parses the full team YAML file into `List<AgentConf>`, resolves inter-agent instructor references, calls `prepareInstructions()` on each |
| `bin/devteam/team_builder.dart` | `buildTeam()` — instantiates `FileToolSet`, `MemoryToolSet`, `TicketToolSet`, `DartToolSet`, `McpToolSet` per agent config; wires instructor→sub-agent relationships; returns `Map<String, Agent>` |
| `bin/devteam/agentic_team_interactive.dart` | Entry point for interactive mode; wires console I/O (`stdin.readLineSync` / `stdout.writeln`), finds `.secret.keys`, calls `buildTeam()`, starts the root agent's interaction loop |
| `bin/devteam/agentic_team_batch.dart` | Entry point for batch mode; reads a `--prompt:` file, sends it to the root agent, prints output and exits |
| `bin/devteam/user_command_handler.dart` | Slash-command extension: `/new`, `/switch <id>`, `/delete <id>`, `/history`, `/summarize`, `/system-prompt`, `/tools` |
| `bin/devteam/error_handler.dart` | `ErrorHandler` — catches LLM errors, trims history and retries when context is exceeded |
| `bin/devteam/agent_sink.dart` | `AgentSink implements Sink<String>` — prints model output to console with ANSI-colored headers |
| `bin/devteam/args.dart` | Simple argument parser: `--secrets:`, `--team-conf:`, `--prompt:`, `--help` |
| `bin/calc/agentic_calculator_cli.dart` | Minimal single-agent demo wiring to an MCP arithmetic server |
| `bin/calc/mcp_arithmetic.dart` | In-process MCP server exposing `add`, `subtract`, `multiply`, `divide` tools |
| `lib/src/file_locator.dart` | `FileLocator.find(dir, name)` — walks up from `dir` searching for `name` |

---

## YAML Team Configuration

Team configurations live alongside the binaries (e.g., `personas_dev_team.yaml`). Each agent entry follows this schema:

```yaml
<role_key>:
  name: "Display Name"
  llm: "google/gemini-2.5-pro"   # provider/model string parsed by dartantic_ai
  api-key: "GEMINI_API_KEY"       # key name looked up in .secret.keys (optional)
  instructor: "Other Agent Name"  # if this agent is instructed by another
  language: "Dart"                # injected into instructions as ${language}
  code-tools: true                # registers DartToolSet for this agent
  tools:
    - memory                      # registers MemoryToolSet
    - tickets                     # registers TicketToolSet
  roots:
    source:
      path: "."
      display: "workspace"
  mcp:
    some-server:
      white-list: ["allowed_tool*"]
      black-list: ["dangerous_tool"]
  instructions: |
    You are ${name}, a ${role} on the ${team} team. ...
```

Template variables available in `instructions`: `${name}`, `${role}`, `${language}`, `${team}`.

---

## Secrets File

API keys are loaded from a `.secret.keys` file (searched upward from the binary's directory). Format is one `KEY=VALUE` per line:

```
GEMINI_API_KEY=AIza...
OPENAI_API_KEY=sk-...
GITHUB_PAT=ghp_...
```

The `FileLocator` in `lib/` handles discovery. Pass `--secrets:<path>` to override.

---

## Coding Conventions

- **Agent ordering in YAML matters**: `buildTeam()` treats the **last** entry in the team config as the **root agent** (the one that talks to the user). All preceding agents are sub-agents instructed by the root.
- **Toolset prefixing**: Every toolset registered for an agent uses the agent's `role` key as the `prefix` (e.g., `architect_file_list`, `reviewer_memorize_topic`). This keeps tool names globally unique within a `CombinedToolSet`.
- **MCP ACLs**: Use `white-list` / `black-list` patterns in YAML to narrow which MCP server tools an agent can see. Patterns can be plain strings, globs (e.g., `"file_*"`), or regex (e.g., `"/^git_.*/"`).
- **Error recovery**: Wrap root-agent I/O in an `ErrorHandler` that detects context-limit exceptions, trims the oldest messages, and retries — see `error_handler.dart`.
- **Console colors**: Use ANSI escape codes (`\x1B[44m` = blue background, `\x1B[94m` = bright blue, `\x1B[0m` = reset) for agent output headers so each speaker is visually distinct.

---

## Dependencies

| Package | Role |
|---------|------|
| `agenteek` | Core agent abstractions |
| `agenteek_memory` | `MemoryToolSet` |
| `agenteek_files` | `FileToolSet` |
| `agenteek_dart` | `DartToolSet` |
| `agenteek_tickets` | `TicketToolSet` |
| `dartantic_ai` | Model provider (resolved via workspace) |
| `dart_mcp` | MCP client for external tool servers |
| `better_future` | Async utilities |
| `path`, `yaml`, `glob` | Path handling, YAML parsing, glob patterns |

---

## Running

```bash
# Interactive mode (default team config)
dart run packages/agenteek_cli/bin/devteam/agentic_team_interactive.dart

# With custom config and secrets
dart run packages/agenteek_cli/bin/devteam/agentic_team_interactive.dart \
  --team-conf:my_team.yaml \
  --secrets:/path/to/.secret.keys

# Batch mode
dart run packages/agenteek_cli/bin/devteam/agentic_team_batch.dart \
  --prompt:my_prompt.md

# Calculator demo
dart run packages/agenteek_cli/bin/calc/agentic_calculator_cli.dart
```
