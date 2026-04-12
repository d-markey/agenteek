part of 'dialog.dart';

class DialogField extends IDialogField {
  final DialogFieldType type;
  final Object? initialValue;
  final String? placeholder;

  DialogField({
    required super.label,
    required super.key,
    this.type = DialogFieldType.text,
    this.initialValue,
    this.placeholder,
  });

  @override
  void render(
    web.HTMLDivElement fieldDiv,
    Map<String, web.HTMLElement> inputs,
  ) {
    final (:input, :control) = buildInput(
      type: type,
      initialValue: initialValue,
      placeholder: placeholder,
    );

    fieldDiv.appendChild(control ?? input);
    inputs[key] = input;
  }

  @override
  void setValue(
    Map<String, Object?> results,
    Map<String, web.HTMLElement> inputs,
  ) {
    final element = inputs[key]! as web.HTMLInputElement;
    results[key] = switch (type) {
      DialogFieldType.checkbox => element.checked ? true : null,
      DialogFieldType.number => num.tryParse(element.value),
      _ => element.value,
    };
  }
}
