import 'dart:js_interop';
import 'package:web/web.dart' as web;

import 'dialog_field_type.dart';

({web.HTMLInputElement input, web.HTMLElement? control}) buildInput({
  required DialogFieldType type,
  Object? initialValue,
  String? placeholder,
}) {
  final input = switch (type) {
    DialogFieldType.password => createInput(type: 'password'),
    DialogFieldType.checkbox => createInput(type: 'checkbox'),
    DialogFieldType.number => createInput(type: 'number'),
    _ => createInput(type: 'text'),
  };

  final val = initialValue?.toString().trim() ?? '';
  if (val.isNotEmpty) {
    if (type == DialogFieldType.checkbox) {
      input.checked = (val == 'true');
    } else {
      input.value = val.toString();
    }
  }

  if (placeholder != null) {
    input.placeholder = placeholder;
  }

  return (
    input: input,
    control: (type == DialogFieldType.password)
        ? _wrapPasswordField(input)
        : null,
  );
}

web.HTMLElement _wrapPasswordField(web.HTMLInputElement input) {
  late final web.HTMLButtonElement toggle;

  var visible = false;
  toggle = createBtn(className: 'password-toggle')
    ..ariaLabel = 'Toggle password visibility'
    ..innerHTML = _showPwdIcon
    ..onclick = (web.Event e) {
      visible = !visible;
      input.type = visible ? 'text' : 'password';
      toggle.innerHTML = visible ? _hidePwdIcon : _showPwdIcon;
    }.toJS;

  input.autocomplete = 'off';
  final wrapper = createDiv(className: 'input-wrapper');
  wrapper.appendChild(input);
  wrapper.appendChild(toggle);
  return wrapper;
}

final _hidePwdIcon =
    '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24"><line x1="1" y1="1" x2="23" y2="23"/></svg>'
        .toJS;
final _showPwdIcon =
    '<svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/><circle cx="12" cy="12" r="3"/></svg>'
        .toJS;

web.HTMLSelectElement buildDropdown(
  List<String>? options, {
  Object? initialValue,
}) {
  final selector = createElt<web.HTMLSelectElement>('select');
  if (options != null) {
    for (final opt in options) {
      final option = createElt<web.HTMLOptionElement>('option');
      option.value = opt;
      option.innerText = opt;
      if (initialValue != null && initialValue.toString() == opt) {
        option.selected = true;
      }
      selector.appendChild(option);
    }
  }
  return selector;
}

T getEltById<T extends web.HTMLElement>(String id) =>
    web.document.getElementById(id) as T;

T createElt<T extends web.HTMLElement>(
  String tag, {
  String? id,
  String? className,
}) {
  final elt = web.document.createElement(tag) as T;
  id = id?.trim() ?? '';
  if (id.isNotEmpty) elt.id = id;
  className = className?.trim() ?? '';
  if (className.isNotEmpty) elt.className = className;
  return elt;
}

web.HTMLDivElement createDiv({String? id, String? className}) =>
    createElt<web.HTMLDivElement>('div', id: id, className: className);

web.HTMLButtonElement createBtn({String? id, String? className}) =>
    createElt<web.HTMLButtonElement>('button', id: id, className: className)
      ..type = 'button';

web.HTMLLabelElement createLabel({
  String? id,
  String? className,
  required String text,
}) =>
    createElt<web.HTMLLabelElement>('label', id: id, className: className)
      ..innerText = text;

web.HTMLInputElement createInput({
  String? id,
  String? className,
  required String type,
}) =>
    createElt<web.HTMLInputElement>('input', id: id, className: className)
      ..type = type;

web.HTMLTableElement createTable({String? id, String? className}) =>
    createElt<web.HTMLTableElement>('table', id: id, className: className);

extension HTMLTableElementExt on web.HTMLTableElement {
  web.HTMLTableSectionElement addHeader() {
    final header = createElt<web.HTMLTableSectionElement>('thead');
    appendChild(header);
    return header;
  }

  web.HTMLTableSectionElement addBody() {
    final body = createElt<web.HTMLTableSectionElement>('tbody');
    appendChild(body);
    return body;
  }
}

extension HTMLTableSectionElementExt on web.HTMLTableSectionElement {
  web.HTMLTableRowElement addRow() {
    final row = createElt<web.HTMLTableRowElement>('tr');
    appendChild(row);
    return row;
  }
}

extension HTMLTableRowElementExt on web.HTMLTableRowElement {
  bool get isHeader => parentElement?.tagName.toLowerCase() == 'thead';

  web.HTMLTableCellElement addCell({String? className}) {
    final cell = createElt<web.HTMLTableCellElement>(isHeader ? 'th' : 'td');
    className = className?.trim() ?? '';
    if (className.isNotEmpty) cell.className = className;
    appendChild(cell);
    return cell;
  }
}
