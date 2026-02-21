import 'dart:async';
import 'dart:io';

import 'package:agenteek/agenteek.dart';
import 'package:agenteek/agenteek_dbg.dart' as dbg show trace;
import 'package:dart_mcp/server.dart' as mcp;

void main() async {
  MathMCP(stdioChannel(input: stdin, output: stdout));
}

final impl = mcp.Implementation(name: 'Arithmetic', version: '1.0.0');

base class MathMCP extends mcp.MCPServer with mcp.ToolsSupport {
  MathMCP(super.channel) : super.fromStreamChannel(implementation: impl) {
    registerTool(_addSpec, _add);
    registerTool(_mulSpec, _mul);
    registerTool(_divSpec, _div);
    registerTool(_modSpec, _mod);
  }

  final _addSpec = mcp.Tool(
    name: 'add',
    description: 'given two integers a and b, returns the sum a+b',
    inputSchema: mcp.Schema.object(
      properties: {
        'a': mcp.Schema.int(description: 'First number'),
        'b': mcp.Schema.int(description: 'Second number'),
      },
      required: ['a', 'b'],
    ),
    outputSchema: mcp.Schema.object(
      properties: {'sum': mcp.Schema.int(description: 'Result of a+b')},
      required: ['sum'],
    ),
  );

  FutureOr<mcp.CallToolResult> _add(mcp.CallToolRequest request) {
    final a = request.$int('a')!, b = request.$int('b')!;
    return mcp.CallToolResult(content: [], structuredContent: {'sum': a + b});
  }

  final _mulSpec = mcp.Tool(
    name: 'mul',
    description: 'given two integers a and b, returns the product a*b',
    inputSchema: mcp.Schema.object(
      properties: {
        'a': mcp.Schema.int(description: 'First number'),
        'b': mcp.Schema.int(description: 'Second number'),
      },
      required: ['a', 'b'],
    ),
    outputSchema: mcp.Schema.object(
      properties: {'product': mcp.Schema.int(description: 'Result of a*b')},
      required: ['product'],
    ),
  );

  FutureOr<mcp.CallToolResult> _mul(mcp.CallToolRequest request) {
    final a = request.$int('a')!, b = request.$int('b')!;
    return mcp.CallToolResult(
      content: [],
      structuredContent: {'product': a * b},
    );
  }

  final _divSpec = mcp.Tool(
    name: 'div',
    description:
        'given two integers a and b, returns the integral quotient a/b (i.e. the truncated value of a/b).',
    inputSchema: mcp.Schema.object(
      properties: {
        'a': mcp.Schema.int(description: 'First number'),
        'b': mcp.Schema.int(description: 'Second number'),
      },
      required: ['a', 'b'],
    ),
    outputSchema: mcp.Schema.object(
      properties: {
        'quotient': mcp.Schema.int(
          description: 'Result of integral division of a by b',
        ),
      },
      required: ['quotient'],
    ),
  );

  FutureOr<mcp.CallToolResult> _div(mcp.CallToolRequest request) {
    final a = request.$int('a')!, b = request.$int('b')!;
    return mcp.CallToolResult(
      content: [],
      structuredContent: {'quotient': a ~/ b},
    );
  }

  final _modSpec = mcp.Tool(
    name: 'mod',
    description:
        'given two integers a and b, returns the remainder of dividing a by b.',
    inputSchema: mcp.Schema.object(
      properties: {
        'a': mcp.Schema.int(description: 'First number'),
        'b': mcp.Schema.int(description: 'Second number'),
      },
      required: ['a', 'b'],
    ),
    outputSchema: mcp.Schema.object(
      properties: {
        'remainder': mcp.Schema.int(
          description: 'Remainder of integral division of a by b',
        ),
      },
      required: ['remainder'],
    ),
  );

  FutureOr<mcp.CallToolResult> _mod(mcp.CallToolRequest request) {
    final a = request.$int('a')!, b = request.$int('b')!;
    return mcp.CallToolResult(
      content: [],
      structuredContent: {'remainder': a % b},
    );
  }

  @override
  void registerRequestHandler<T extends mcp.Request?, R extends mcp.Result?>(
    String name,
    FutureOr<R> Function(T args) impl,
  ) {
    FutureOr<R> dbgImpl(dynamic args) {
      if (name == 'tools/call') {
        args as Map;
        var info = Map.fromEntries(
          args.entries.where((e) => e.key != 'name' && e.key != 'arguments'),
        ).toString();
        if (info.isNotEmpty) info = ' / $info';
        dbg.trace('$name: ${args['name']}(${args['arguments']})$info');
      } else {
        dbg.trace('$name: $args');
      }
      return impl(args);
    }

    super.registerRequestHandler(name, dbgImpl);
  }
}

extension on mcp.CallToolRequest {
  // ignore: unused_element
  int? $int(String name) => arguments?[name] as int?;

  // ignore: unused_element
  bool? $bool(String name) => arguments?[name] as bool?;

  // ignore: unused_element
  String? $string(String name) => arguments?[name]?.toString();
}
