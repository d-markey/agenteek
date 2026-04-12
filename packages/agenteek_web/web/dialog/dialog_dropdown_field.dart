part of 'dialog.dart';

class DialogDropdownField extends IDialogField {
  final List<String>? options;
  final Object? initialValue;

  DialogDropdownField({
    required super.label,
    required super.key,
    this.initialValue,
    this.options,
  });

  @override
  void render(
    web.HTMLDivElement fieldDiv,
    Map<String, web.HTMLElement> inputs,
  ) {
    final selector = buildDropdown(options, initialValue: initialValue);
    fieldDiv.appendChild(selector);
    inputs[key] = selector;
  }

  @override
  void setValue(
    Map<String, Object?> results,
    Map<String, web.HTMLElement> inputs,
  ) {
    results[key] = (inputs[key]! as web.HTMLSelectElement).value;
  }
}
