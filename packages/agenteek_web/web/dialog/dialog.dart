import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

import 'html_controls.dart';
import 'dialog_field_type.dart';

part 'dialog_field.dart';
part 'dialog_dropdown_field.dart';
part 'dialog_complex_field.dart';

sealed class IDialogField {
  final String label;
  final String key;

  IDialogField({required this.label, required this.key});

  void render(web.HTMLDivElement fieldDiv, Map<String, web.HTMLElement> inputs);

  void setValue(
    Map<String, Object?> results,
    Map<String, web.HTMLElement> inputs,
  );
}

class DialogConfig {
  final String title;
  final List<IDialogField> fields;

  DialogConfig({required this.title, required this.fields});
}

class ModalDialog {
  static final _overlay = getEltById<web.HTMLDivElement>('dlg-overlay');
  static final _title = getEltById<web.HTMLHeadingElement>('dlg-title');
  static final _content = getEltById<web.HTMLDivElement>('dlg-content');
  static final _cancelBtn = getEltById<web.HTMLButtonElement>('dlg-cancel');
  static final _submitBtn = getEltById<web.HTMLButtonElement>('dlg-submit');

  static Future<Map<String, Object?>?> show(DialogConfig config) {
    final completer = Completer<Map<String, Object?>?>();

    _title.innerText = config.title;
    _content.innerHTML = ''.toJS;

    final inputs = <String, web.HTMLElement>{};

    for (final field in config.fields) {
      final fieldDiv = createDiv(className: 'dlg-field');
      fieldDiv.appendChild(createLabel(text: field.label));

      field.render(fieldDiv, inputs);
      _content.appendChild(fieldDiv);
    }

    void close(Map<String, Object?>? result) {
      _overlay.classList.add('hidden');
      _cancelBtn.onclick = null;
      _submitBtn.onclick = null;
      if (!completer.isCompleted) {
        completer.complete(result);
      }
    }

    _cancelBtn.onclick = (web.Event e) {
      close(null);
    }.toJS;

    _submitBtn.onclick = (web.Event e) {
      final results = <String, Object?>{};
      for (final field in config.fields) {
        field.setValue(results, inputs);
      }
      close(results);
    }.toJS;

    _overlay.classList.remove('hidden');

    // Focus first input
    if (config.fields.isNotEmpty) {
      inputs[config.fields.first.key]?.focus();
    }

    return completer.future;
  }
}
