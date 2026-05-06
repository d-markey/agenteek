import 'dart:async';
import 'dart:js_interop';

import 'package:agenteek/agenteek.dart';
import 'package:markdown/markdown.dart';
import 'package:web/web.dart' as web;

typedef StringFunc = String Function();

String _getLabelHtml(String label, String? id, bool collapsible) {
  final toggleHtml = collapsible && id != null && id.isNotEmpty
      ? ' onclick="toggleMessage(\'$id\')"'
      : '';
  return '<aside$toggleHtml>$label</aside>';
}

final _copyButtonHtml =
    '<button class="copy-btn" onclick="copyMessageHtml(event, this)" title="Copy HTML" style="position: absolute; top: 8px; right: 8px; background: transparent; border: none; cursor: pointer; color: var(--muted); font-size: 16px;">'
    '📋'
    '</button>';

class HtmlOutputController {
  HtmlOutputController(this._div) {
    _div.onscroll = _onScroll.toJS;
  }

  final web.HTMLDivElement _div;
  bool _autoScroll = true;
  static const int _scrollThreshold = 12;

  void _onScroll(web.Event _) {
    final scrollBottom = _div.scrollHeight - _div.clientHeight - _div.scrollTop;
    _autoScroll = scrollBottom <= _scrollThreshold;
  }

  void requestScroll() {
    if (_autoScroll) {
      _div.scrollTop = _div.scrollHeight;
    }
  }

  void clear() {
    _div.innerHTML = ''.toJS;
    _div.scrollTop = 0;
    _autoScroll = true;
  }

  void appendMarkdown(
    String label,
    String markdown,
    String cssClass, {
    String? id,
  }) {
    _div.appendMarkdown(label, markdown, cssClass, id: id);
    requestScroll();
  }
}

class HtmlSink implements OutputSink {
  HtmlSink(this._controller, dynamic label, this.cssClass)
    : _label = _wrap(label);

  final HtmlOutputController _controller;
  final StringFunc _label;
  final String cssClass;

  NestedOutputSink get nested => HtmlNestedSink(this);

  @override
  void add(String data) {
    _controller.appendMarkdown(_label(), data, cssClass);
  }

  @override
  void writeln(String message) => add(message);

  @override
  void close() {}
}

class HtmlStreamingSink implements StreamingOutputSink {
  HtmlStreamingSink(
    this._controller,
    dynamic label,
    this.cssClass, {
    this.collapsible = false,
  }) : _label = _wrap(label);

  final HtmlOutputController _controller;
  final StringFunc _label;
  final String cssClass;
  final bool collapsible;

  static final _uniqueId = UniqueIdGenerator();

  String _id = '';
  String _current = '';

  web.HTMLDivElement? _getDiv() =>
      _controller._div.ownerDocument?.getElementById(_id)
          as web.HTMLDivElement?;

  void _start() {
    _id = _uniqueId.string(12);
    _controller.appendMarkdown(_label(), '', cssClass, id: _id);
    final div = _getDiv();
    if (div != null) {
      if (collapsible) {
        div.classList.add('collapsible-active');
      }
      div.innerHTML = '${div.innerHTML}$_jumpingBullets'.toJS;
    }
    _controller.requestScroll();
  }

  @override
  Future<void> start() {
    if (_id.isNotEmpty) {
      throw StateError('A streaming operation has already been started');
    }
    _start();
    return Future.value();
  }

  static const _jumpingBullets =
      '<div class="loading-container">'
      ' <svg class="bullet" viewBox="0 0 50 50"><circle cx="25" cy="25" r="8" fill="#0175C2" /></svg>'
      ' <svg class="bullet" viewBox="0 0 50 50"><circle cx="25" cy="25" r="8" fill="#13B9FD" /></svg>'
      ' <svg class="bullet" viewBox="0 0 50 50"><circle cx="25" cy="25" r="8" fill="#40D0FD" /></svg>'
      '</div>';

  @override
  Future<void> finish() {
    final div = _getDiv();
    if (div != null) {
      if (collapsible && _current.isNotEmpty) {
        final label = _getLabelHtml(_label(), _id, true);
        div.innerHTML = '$label$_copyButtonHtml${_current.toHtml()}'.toJS;
        div.classList.add('collapsed');
      } else {
        div.remove();
      }
    }
    _id = '';
    _current = '';
    return Future.value();
  }

  @override
  void add(String data) {
    data = data.trimRight();
    if (data.isEmpty) return;

    if (_id.isEmpty) {
      _start();
    }

    final div = _getDiv();
    if (div != null) {
      _current += data;
      final label = _getLabelHtml(_label(), _id, collapsible);
      div.innerHTML = '$label$_copyButtonHtml${'$_current...'.toHtml()}'.toJS;
      _controller.requestScroll();
    }
  }

  @override
  void writeln(String message) => add(message);

  @override
  void close() {}
}

class HtmlNestedSink implements NestedOutputSink {
  HtmlNestedSink(this.parent);

  final HtmlSink parent;

  web.HTMLDivElement get output => parent._controller._div;
  String get cssClass => parent.cssClass;

  final _sb = StringBuffer();

  @override
  void add(String data) => _sb.writeln(data);

  @override
  void writeln(String message) => add(message);

  @override
  void close() {
    parent.add(_sb.toString());
    _sb.clear();
  }
}

extension on String {
  String toHtml() =>
      markdownToHtml(this, extensionSet: ExtensionSet.gitHubFlavored);
}

extension on web.HTMLDivElement {
  void appendMarkdown(
    String label,
    String markdown,
    String cssClass, {
    String? id,
  }) {
    final labelHtml = _getLabelHtml(label, id, id != null && id.isNotEmpty);
    innerHTML =
        '$innerHTML\n'
                '<div class="message $cssClass"${id != null ? ' id="$id"' : ''} style="position: relative;">'
                '$labelHtml$_copyButtonHtml${markdown.toHtml()}'
                '</div>'
            .toJS;
  }
}

StringFunc _wrap(dynamic label) => switch (label) {
  StringFunc() => label,
  _ => () => label.toString(),
};
