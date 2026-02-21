import 'dart:js_interop';

import 'package:markdown/markdown.dart';
import 'package:web/web.dart' as web;

class HtmlSink implements Sink<String> {
  HtmlSink(this._messages, dynamic label, this.cssClass)
    : _label = _wrap(label);

  final web.HTMLDivElement _messages;
  final String Function() _label;
  final String cssClass;

  static String Function() _wrap(dynamic label) {
    if (label is String Function()) {
      return label;
    } else {
      return () => label.toString();
    }
  }

  Sink<String> get nested => HtmlNestedSink(this);

  @override
  void add(String data) {
    _messages.appendMarkdown(_label(), data, cssClass);
    _messages.scrollTop = _messages.scrollHeight;
  }

  @override
  void close() {}
}

class HtmlNestedSink implements Sink<String> {
  HtmlNestedSink(this.parent);

  final HtmlSink parent;

  web.HTMLDivElement get output => parent._messages;
  String get cssClass => parent.cssClass;

  final _sb = StringBuffer();

  @override
  void add(String data) => _sb.writeln(data);

  @override
  void close() {
    parent.add(_sb.toString());
    _sb.clear();
  }
}

extension on web.HTMLDivElement {
  void appendMarkdown(String label, String message, String cssClass) {
    print('innerHTML = $innerHTML');
    final html =
        '$innerHTML\n'
        '<div class="message $cssClass">'
        '<aside>$label</aside>'
        '${markdownToHtml(message)}'
        '</div>';
    innerHTML = html.toJS;
  }
}
