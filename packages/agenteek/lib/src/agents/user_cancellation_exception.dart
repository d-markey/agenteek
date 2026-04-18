import 'package:cancelation_token/cancelation_token.dart';

class UserCancellationException extends CanceledException {
  UserCancellationException({String? message, String? pendingOutput})
    : pendingOutput = pendingOutput?.trim() ?? '',
      super(message ?? 'User cancelled.');

  UserCancellationException.withStackTrace({
    String? message,
    String? pendingOutput,
  }) : pendingOutput = pendingOutput?.trim() ?? '',
       super.withStackTrace(message ?? 'User cancelled.');

  final String pendingOutput;
}
