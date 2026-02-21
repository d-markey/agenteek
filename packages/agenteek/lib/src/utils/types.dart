import 'dart:async';

import 'package:http/http.dart';

import '../commands/command.dart';

typedef Json = Map<String, Object?>;

typedef ToolFunction = FutureOr<dynamic> Function(Json);
typedef JsonToolFunction = FutureOr<Json> Function(Json);
typedef StrToolFunction = FutureOr<String> Function(Json);

typedef PromptCallback = FutureOr<String> Function();

typedef NewConversationCallback = FutureOr<void> Function();

typedef UserCommandHandler = Command? Function(String);

typedef CustomErrorHandler = Future<Duration?> Function(Response, int);

typedef ErrorCallback =
    FutureOr<String?> Function(Object error, [StackTrace? stackTrace]);
