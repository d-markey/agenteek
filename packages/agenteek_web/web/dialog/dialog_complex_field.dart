part of 'dialog.dart';

sealed class IDialogComplexItem {
  final String label;
  final String key;
  final List<Object?> initialValues;

  IDialogComplexItem({
    required this.label,
    required this.key,
    required this.initialValues,
  });

  void render(
    String fieldKey,
    int idx,
    web.HTMLElement fieldDiv,
    Map<String, web.HTMLElement> inputs,
  );

  void setValue(int idx, Map<String, Object?> results, web.HTMLElement element);
}

class DialogComplexInputItem extends IDialogComplexItem {
  final DialogFieldType type;
  final String? placeholder;

  DialogComplexInputItem({
    required super.label,
    required super.key,
    this.type = DialogFieldType.text,
    this.placeholder,
    required super.initialValues,
  });

  @override
  void render(
    String fieldKey,
    int idx,
    web.HTMLElement fieldDiv,
    Map<String, web.HTMLElement> inputs,
  ) {
    final (:input, :control) = buildInput(
      type: type,
      initialValue: (idx < initialValues.length) ? initialValues[idx] : null,
      placeholder: placeholder,
    );
    fieldDiv.appendChild(control ?? input);
    inputs['$fieldKey-$key-$idx'] = input;
  }

  @override
  void setValue(
    int idx,
    Map<String, Object?> results,
    web.HTMLElement element,
  ) {
    element as web.HTMLInputElement;
    results[key] = switch (type) {
      DialogFieldType.number => num.tryParse(element.value),
      DialogFieldType.checkbox => element.checked ? true : null,
      _ => element.value,
    };
  }
}

class DialogComplexDropdownItem extends IDialogComplexItem {
  final List<String>? options;

  DialogComplexDropdownItem({
    required super.label,
    required super.key,
    required super.initialValues,
    this.options,
  });

  @override
  void render(
    String fieldKey,
    int idx,
    web.HTMLElement fieldDiv,
    Map<String, web.HTMLElement> inputs,
  ) {
    final selector = buildDropdown(
      options,
      initialValue: (idx < initialValues.length) ? initialValues[idx] : null,
    );
    fieldDiv.appendChild(selector);
    inputs['$fieldKey-$key-$idx'] = selector;
  }

  @override
  void setValue(
    int idx,
    Map<String, Object?> results,
    web.HTMLElement element,
  ) {
    results[key] = (element as web.HTMLSelectElement).value;
  }
}

class DialogComplexField extends IDialogField {
  final List<IDialogComplexItem> items;
  final bool isFixed;

  DialogComplexField({
    required super.label,
    required super.key,
    required this.items,
    this.isFixed = false,
  }) : super();

  @override
  void render(
    web.HTMLDivElement fieldDiv,
    Map<String, web.HTMLElement> inputs,
  ) {
    final container = createDiv(className: 'complex-field-container');
    final tableContainer = createDiv(className: 'complex-table-container');
    final table = createTable(className: 'complex-table');

    final thead = table.addHeader();
    final headerRow = thead.addRow();
    for (final item in items) {
      headerRow.addCell().innerText = item.label;
    }
    if (!isFixed) {
      headerRow.addCell(className: 'complex-table-actions').innerText = '';
    }

    final tbody = table.addBody();

    void $addRow() {
      final currentRowIdx = tbody.rows.length;
      final row = tbody.addRow();
      row.dataset['idx'] = currentRowIdx.toString();

      for (final item in items) {
        final td = row.addCell();
        item.render(key, currentRowIdx, td, inputs);
      }

      if (!isFixed) {
        final actionTd = row.addCell(className: 'complex-table-actions');
        final deleteBtn = createBtn(className: 'delete-row-btn')
          ..innerHTML = _deleteIcon
          ..onclick = ((web.Event e) => row.remove()).toJS;
        actionTd.appendChild(deleteBtn);
      }
    }

    // Initial rows
    var initialRows = 0;
    for (final item in items) {
      if (item.initialValues.length > initialRows) {
        initialRows = item.initialValues.length;
      }
    }

    // At least one row if fixed
    if (isFixed && initialRows == 0) initialRows = 1;

    for (var i = 0; i < initialRows; i++) {
      // No need to pass the index, it's derived from the number of rows in the table
      $addRow();
    }

    tableContainer.appendChild(table);
    container.appendChild(tableContainer);

    if (!isFixed) {
      final addBtn = createBtn(className: 'button add-row-btn')
        ..innerHTML = '$_addIcon Add Line'.toJS
        ..onclick = ((web.Event e) => $addRow()).toJS;
      container.appendChild(addBtn);
    }

    fieldDiv.appendChild(container);
    inputs[key] = tbody;
  }

  @override
  void setValue(
    Map<String, Object?> results,
    Map<String, web.HTMLElement> inputs,
  ) {
    final tbody = inputs[key]! as web.HTMLTableSectionElement;
    final rowList = <Map<String, Object?>>[];

    for (var i = 0; i < tbody.rows.length; i++) {
      final rowData = <String, Object?>{};
      var empty = true;
      for (var j = 0; j < items.length; j++) {
        final item = items[j];
        final inputElement = inputs['$key-${item.key}-$i']!;
        item.setValue(i, rowData, inputElement);
        final val = rowData[item.key];
        if (val != null && val.toString().isNotEmpty) {
          empty = false;
        }
      }
      if (!empty) rowList.add(rowData);
    }

    results[key] = rowList;
  }
}

final _addIcon =
    '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>';

final _deleteIcon =
    '<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"><path d="M3 6h18m-2 0v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6m3 0V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2"/></svg>'
        .toJS;
