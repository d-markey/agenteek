import 'package:agenteek/agenteek.dart';
import 'package:logging/logging.dart';

import 'ticket.dart';

import 'tools/close_ticket.dart';
import 'tools/comment_on_ticket.dart';
import 'tools/list_tickets.dart';
import 'tools/open_ticket.dart';
import 'tools/update_ticket.dart';
import 'tools/read_ticket.dart';

/// A `ToolSet` that provides tools for managing tickets.
class TicketToolSet extends ToolSet with Prefix, Scope {
  TicketToolSet({
    required this.prefix,
    required this.owner,
    String? scope,
    this.fileSystem,
  }) : scope = scope?.trim() ?? '' {
    // register tools
    register(listTicketsTool(this));
    register(openTicketTool(this));
    register(updateTicketTool(this));
    register(readTicketTool(this));
    register(commentOnTicketTool(this));
    register(closeTicketTool(this));
  }

  /// The prefix used as a namespace for ticket-related tools.
  @override
  final String prefix;

  /// The name of the owner of this toolset.
  final String owner;

  /// A description of the scope covered by this toolset.
  @override
  final String scope;

  /// The root file system for ticket files.
  final FileSystem? fileSystem;

  final tickets = <int, Ticket>{};

  @override
  Logger get logger => Logger('${super.logger.name}.$owner');

  final pattern = RegExp('ticket_(\\d+)\\.json');

  String getTicketFileName(int id) => 'ticket_$id.json';

  Stream<String> listTicketFiles(FileSystem fs) =>
      fs.list().where(pattern.hasMatch);

  Future<int> getNextTicketId() async {
    var maxId = tickets.length - 1;
    if (fileSystem != null) {
      await for (var f in listTicketFiles(fileSystem!)) {
        final id = int.parse(pattern.firstMatch(f)!.group(1)!);
        if (id > maxId) maxId = id;
      }
    }
    return maxId + 1;
  }

  String scoped(String description) =>
      scope.isEmpty ? '$description.' : '$description; **scope: $scope**. ';
}
