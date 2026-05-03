import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:dartantic_ai/dartantic_ai.dart' as dartantic;
import 'package:markdown/markdown.dart' as md;
import 'package:pdf/pdf.dart' as pdf;
import 'package:pdf/widgets.dart' as pdf;
import 'package:web/web.dart' as web;

/// Export the conversation history to a PDF file.
Future<void> exportConversationToPdf(
  Iterable<dartantic.ChatMessage> history,
) async {
  final document = pdf.Document();

  // For pure Dart web, we use standard fonts or bundle TTFs.
  // Standard fonts are always available without needing to fetch.
  final fontRegular = pdf.Font.helvetica();
  final fontBold = pdf.Font.helveticaBold();
  final fontMono = pdf.Font.courier();

  document.addPage(
    pdf.MultiPage(
      pageFormat: pdf.PdfPageFormat.a4,
      margin: const pdf.EdgeInsets.all(40),
      footer: (pdf.Context context) {
        return pdf.Container(
          alignment: pdf.Alignment.centerRight,
          margin: const pdf.EdgeInsets.only(top: 1.0 * pdf.PdfPageFormat.cm),
          child: pdf.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: pdf.TextStyle(
              color: pdf.PdfColors.grey,
              fontSize: 9,
              font: fontRegular,
            ),
          ),
        );
      },
      build: (pdf.Context context) {
        return [
          pdf.Header(
            level: 0,
            padding: const pdf.EdgeInsets.only(bottom: 8),
            decoration: const pdf.BoxDecoration(
              border: pdf.Border(
                bottom: pdf.BorderSide(color: pdf.PdfColors.blue800, width: 2),
              ),
            ),
            child: pdf.Row(
              mainAxisAlignment: pdf.MainAxisAlignment.spaceBetween,
              children: [
                pdf.Text(
                  'Agenteek Chat Session',
                  style: pdf.TextStyle(
                    font: fontBold,
                    fontSize: 24,
                    color: pdf.PdfColors.blue800,
                  ),
                ),
                pdf.Text(
                  DateTime.now().toString().split('.')[0],
                  style: pdf.TextStyle(
                    font: fontRegular,
                    fontSize: 10,
                    color: pdf.PdfColors.grey700,
                  ),
                ),
              ],
            ),
          ),
          pdf.SizedBox(height: 24),
          ...history
              .where((m) {
                // Clean export: skip system messages and intermediate tool steps
                if (m.role == .system) return false;
                if (m.hasToolCalls || m.hasToolResults) return false;
                return m.text.trim().isNotEmpty;
              })
              .map((m) {
                final isUser = m.role == .user;
                final label = isUser ? 'YOU' : 'WEB AGENT';

                // Premium colors matching the UI
                final bgColor = isUser
                    ? pdf.PdfColor.fromInt(0xFFF1F8E9)
                    : pdf.PdfColor.fromInt(0xFFE3F2FD);
                final borderColor = isUser
                    ? pdf.PdfColor.fromInt(0xFFC5E1A5)
                    : pdf.PdfColor.fromInt(0xFFBBDEFB);
                final accentColor = isUser
                    ? pdf.PdfColor.fromInt(0xFF2E7D32)
                    : pdf.PdfColor.fromInt(0xFF1565C0);

                return pdf.Container(
                  width: double.infinity,
                  margin: const pdf.EdgeInsets.only(bottom: 20),
                  padding: const pdf.EdgeInsets.all(14),
                  decoration: pdf.BoxDecoration(
                    color: bgColor,
                    borderRadius: const pdf.BorderRadius.all(
                      pdf.Radius.circular(10),
                    ),
                    border: pdf.Border.all(color: borderColor, width: 1),
                  ),
                  child: pdf.Column(
                    crossAxisAlignment: pdf.CrossAxisAlignment.start,
                    children: [
                      pdf.Text(
                        label,
                        style: pdf.TextStyle(
                          font: fontBold,
                          fontSize: 10,
                          color: accentColor,
                          letterSpacing: 1.2,
                        ),
                      ),
                      pdf.SizedBox(height: 8),
                      ..._renderMarkdown(
                        m.text,
                        fontRegular,
                        fontBold,
                        fontMono,
                      ),
                    ],
                  ),
                );
              }),
        ];
      },
    ),
  );

  final bytes = await document.save();
  _downloadPdf(bytes, 'agenteek-conversation.pdf');
}

/// Helper function to trigger a browser download of the PDF.
void _downloadPdf(Uint8List bytes, String filename) {
  final blob = web.Blob(
    [bytes.buffer.toJS].toJS,
    web.BlobPropertyBag(type: 'application/pdf'),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
  anchor.href = url;
  anchor.download = filename;
  web.document.body!.append(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);
}

List<pdf.Widget> _renderMarkdown(
  String text,
  pdf.Font font,
  pdf.Font fontBold,
  pdf.Font fontMono,
) {
  try {
    final nodes = md.Document(
      extensionSet: md.ExtensionSet.gitHubFlavored,
    ).parseLines(text.split('\n'));
    return _renderNodes(nodes, font, fontBold, fontMono);
  } catch (e) {
    // Fallback for parsing errors
    return [
      pdf.Text(
        text,
        style: pdf.TextStyle(font: font, fontSize: 11, height: 1.4),
      ),
    ];
  }
}

/// Helper to render a list of nodes, grouping inlines as needed.
List<pdf.Widget> _renderNodes(
  List<md.Node>? nodes,
  pdf.Font font,
  pdf.Font fontBold,
  pdf.Font fontMono,
) {
  if (nodes == null || nodes.isEmpty) return [];

  final List<pdf.Widget> widgets = [];
  final List<md.Node> currentInlines = [];

  void flushInlines() {
    if (currentInlines.isNotEmpty) {
      widgets.add(
        pdf.Padding(
          padding: const pdf.EdgeInsets.symmetric(vertical: 4),
          child: pdf.RichText(
            text: pdf.TextSpan(
              style: pdf.TextStyle(font: font, fontSize: 11, height: 1.4),
              children: currentInlines
                  .map((c) => _convertInline(c, font, fontBold, fontMono))
                  .toList(),
            ),
          ),
        ),
      );
      currentInlines.clear();
    }
  }

  for (final node in nodes) {
    if (_isBlock(node)) {
      flushInlines();
      widgets.add(_convertNode(node, font, fontBold, fontMono));
    } else {
      currentInlines.add(node);
    }
  }
  flushInlines();

  return widgets;
}

bool _isBlock(md.Node node) {
  if (node is md.Element) {
    return const {
      'p',
      'h1',
      'h2',
      'h3',
      'h4',
      'h5',
      'h6',
      'ul',
      'ol',
      'li',
      'blockquote',
      'pre',
      'hr',
      'table',
      'thead',
      'tbody',
      'tr',
      'th',
      'td',
    }.contains(node.tag);
  }
  return false;
}

pdf.Widget _convertNode(
  md.Node node,
  pdf.Font font,
  pdf.Font fontBold,
  pdf.Font fontMono, {
  String? listMarker,
}) {
  if (node is md.Element) {
    switch (node.tag) {
      case 'p':
        return pdf.Padding(
          padding: const pdf.EdgeInsets.symmetric(vertical: 4),
          child: pdf.RichText(
            text: pdf.TextSpan(
              style: pdf.TextStyle(font: font, fontSize: 11, height: 1.4),
              children:
                  node.children
                      ?.map((c) => _convertInline(c, font, fontBold, fontMono))
                      .toList() ??
                  [],
            ),
          ),
        );
      case 'h1':
        return pdf.Padding(
          padding: const pdf.EdgeInsets.only(top: 12, bottom: 4),
          child: pdf.RichText(
            text: pdf.TextSpan(
              style: pdf.TextStyle(font: fontBold, fontSize: 16),
              children:
                  node.children
                      ?.map((c) => _convertInline(c, font, fontBold, fontMono))
                      .toList() ??
                  [],
            ),
          ),
        );
      case 'h2':
        return pdf.Padding(
          padding: const pdf.EdgeInsets.only(top: 10, bottom: 4),
          child: pdf.RichText(
            text: pdf.TextSpan(
              style: pdf.TextStyle(font: fontBold, fontSize: 14),
              children:
                  node.children
                      ?.map((c) => _convertInline(c, font, fontBold, fontMono))
                      .toList() ??
                  [],
            ),
          ),
        );
      case 'h3':
        return pdf.Padding(
          padding: const pdf.EdgeInsets.only(top: 8, bottom: 4),
          child: pdf.RichText(
            text: pdf.TextSpan(
              style: pdf.TextStyle(font: fontBold, fontSize: 12),
              children:
                  node.children
                      ?.map((c) => _convertInline(c, font, fontBold, fontMono))
                      .toList() ??
                  [],
            ),
          ),
        );
      case 'li':
        return pdf.Padding(
          padding: const pdf.EdgeInsets.only(left: 12, top: 2, bottom: 2),
          child: pdf.Row(
            crossAxisAlignment: pdf.CrossAxisAlignment.start,
            children: [
              pdf.SizedBox(
                width: 18,
                child: pdf.Text(
                  listMarker ?? '* ',
                  style: pdf.TextStyle(font: font, fontSize: 11),
                ),
              ),
              pdf.Expanded(
                child: pdf.Column(
                  crossAxisAlignment: pdf.CrossAxisAlignment.start,
                  children: _renderNodes(
                    node.children,
                    font,
                    fontBold,
                    fontMono,
                  ),
                ),
              ),
            ],
          ),
        );
      case 'ul':
      case 'ol':
        final isOrdered = node.tag == 'ol';
        final children = node.children ?? [];
        return pdf.Column(
          crossAxisAlignment: pdf.CrossAxisAlignment.start,
          children: List.generate(children.length, (i) {
            final marker = isOrdered ? '${i + 1}. ' : '* ';
            return _convertNode(
              children[i],
              font,
              fontBold,
              fontMono,
              listMarker: marker,
            );
          }),
        );
      case 'code':
        return pdf.Container(
          padding: const pdf.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: pdf.BoxDecoration(
            color: pdf.PdfColors.grey200,
            borderRadius: const pdf.BorderRadius.all(pdf.Radius.circular(4)),
          ),
          child: pdf.Text(
            _decodeHtml(node.textContent),
            style: pdf.TextStyle(font: fontMono, fontSize: 10),
          ),
        );
      case 'pre':
        return pdf.Container(
          margin: const pdf.EdgeInsets.symmetric(vertical: 8),
          padding: const pdf.EdgeInsets.all(10),
          decoration: pdf.BoxDecoration(
            color: pdf.PdfColors.grey100,
            borderRadius: const pdf.BorderRadius.all(pdf.Radius.circular(6)),
            border: pdf.Border.all(color: pdf.PdfColors.grey300),
          ),
          width: double.infinity,
          child: pdf.Text(
            _decodeHtml(node.textContent),
            style: pdf.TextStyle(font: fontMono, fontSize: 9, height: 1.2),
          ),
        );
      case 'blockquote':
        return pdf.Container(
          margin: const pdf.EdgeInsets.symmetric(vertical: 8),
          padding: const pdf.EdgeInsets.only(left: 12, top: 4, bottom: 4),
          decoration: const pdf.BoxDecoration(
            border: pdf.Border(
              left: pdf.BorderSide(color: pdf.PdfColors.grey400, width: 4),
            ),
          ),
          child: pdf.Column(
            crossAxisAlignment: pdf.CrossAxisAlignment.start,
            children: _renderNodes(node.children, font, fontBold, fontMono),
          ),
        );
      case 'table':
        return _buildTable(node, font, fontBold, fontMono);
      default:
        if (node.children != null) {
          return pdf.Column(
            crossAxisAlignment: pdf.CrossAxisAlignment.start,
            children: _renderNodes(node.children, font, fontBold, fontMono),
          );
        }
    }
  }
  return pdf.Text(
    _decodeHtml(node.textContent),
    style: pdf.TextStyle(font: font, fontSize: 11),
  );
}

/// Build a PDF table from a markdown `<table>` element.
pdf.Widget _buildTable(
  md.Element tableNode,
  pdf.Font font,
  pdf.Font fontBold,
  pdf.Font fontMono,
) {
  // Collect (row element, isHeader) pairs by scanning thead/tbody children.
  final List<(md.Element, bool)> rows = [];
  for (final section in (tableNode.children ?? [])) {
    if (section is! md.Element) continue;
    final isHeader = section.tag == 'thead';
    for (final child in (section.children ?? [])) {
      if (child is md.Element && child.tag == 'tr') {
        rows.add((child, isHeader));
      }
    }
  }

  if (rows.isEmpty) {
    // Fallback: render as plain text.
    return pdf.Text(
      _decodeHtml(tableNode.textContent),
      style: pdf.TextStyle(font: font, fontSize: 11),
    );
  }

  // Determine the max column count for uniform column widths.
  int maxCols = 0;
  for (final (row, _) in rows) {
    final cellCount = row.children?.whereType<md.Element>().length ?? 0;
    if (cellCount > maxCols) maxCols = cellCount;
  }

  // Define column widths based on the number of columns.
  // For 2-column tables, use Intrinsic for the first and Flex for the second.
  // This is typical for key-value or labeled data.
  final Map<int, pdf.TableColumnWidth> columnWidths;
  if (maxCols == 2) {
    columnWidths = const {
      0: pdf.IntrinsicColumnWidth(),
      1: pdf.FlexColumnWidth(),
    };
  } else {
    columnWidths = {
      for (var i = 0; i < maxCols; i++) i: const pdf.FlexColumnWidth(),
    };
  }

  final tableRows = <pdf.TableRow>[];
  for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) {
    final (rowEl, isHeader) = rows[rowIndex];
    final cells = rowEl.children?.whereType<md.Element>().toList() ?? [];

    // Alternating background: headers = grey200, even rows = white, odd rows = grey50.
    final pdf.PdfColor rowBg = isHeader
        ? pdf.PdfColors.grey300
        : (rowIndex.isEven ? pdf.PdfColors.white : pdf.PdfColors.grey100);

    final pdfCells = <pdf.Widget>[];
    for (var i = 0; i < cells.length; i++) {
      final cell = cells[i];
      // In a 2-column table, treat the first column as a header (bold)
      final isFirstCol = i == 0 && maxCols == 2;
      final cellFont = (isHeader || isFirstCol) ? fontBold : font;

      final cellContent = _renderNodes(
        cell.children,
        cellFont,
        fontBold,
        fontMono,
      );

      pdfCells.add(
        pdf.Container(
          color: rowBg,
          padding: const pdf.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: pdf.BoxDecoration(
            border: pdf.Border.all(color: pdf.PdfColors.grey400, width: 0.5),
          ),
          child: pdf.Column(
            crossAxisAlignment: pdf.CrossAxisAlignment.start,
            children: cellContent.isEmpty
                ? [
                    pdf.Text(
                      '',
                      style: pdf.TextStyle(font: cellFont, fontSize: 10),
                    ),
                  ]
                : cellContent,
          ),
        ),
      );
    }

    tableRows.add(pdf.TableRow(children: pdfCells));
  }

  return pdf.Padding(
    padding: const pdf.EdgeInsets.symmetric(vertical: 8),
    child: pdf.Table(columnWidths: columnWidths, children: tableRows),
  );
}

/// Convert a markdown node into a pdf.InlineSpan to preserve nested styles.
pdf.InlineSpan _convertInline(
  md.Node node,
  pdf.Font font,
  pdf.Font fontBold,
  pdf.Font fontMono,
) {
  if (node is md.Text) {
    return pdf.TextSpan(text: _decodeHtml(node.text));
  }

  if (node is md.Element) {
    switch (node.tag) {
      case 'strong':
        return pdf.TextSpan(
          style: pdf.TextStyle(font: fontBold),
          children: node.children
              ?.map((c) => _convertInline(c, font, fontBold, fontMono))
              .toList(),
        );
      case 'em':
        // Standard PDF fonts usually don't support italic unless using a variation.
        // We'll approximate with italic style if the font allows it.
        return pdf.TextSpan(
          style: pdf.TextStyle(fontStyle: pdf.FontStyle.italic),
          children: node.children
              ?.map((c) => _convertInline(c, font, fontBold, fontMono))
              .toList(),
        );
      case 'code':
        return pdf.TextSpan(
          text: _decodeHtml(node.textContent),
          style: pdf.TextStyle(
            font: fontMono,
            fontSize: 10,
            background: pdf.BoxDecoration(color: pdf.PdfColors.grey200),
          ),
        );
      case 'a':
        // Add basic link support
        final href = node.attributes['href']?.trim() ?? '';
        pdf.AnnotationLink? link;
        if (href.isNotEmpty) {
          link = pdf.AnnotationLink(href);
        }
        return pdf.TextSpan(
          text: _decodeHtml(node.textContent),
          style: pdf.TextStyle(
            color: (link == null)
                ? pdf.PdfColors.red700
                : pdf.PdfColors.blue700,
            decoration: pdf.TextDecoration.underline,
          ),
          annotation: link,
        );
      default:
        return pdf.TextSpan(
          children: node.children
              ?.map((c) => _convertInline(c, font, fontBold, fontMono))
              .toList(),
        );
    }
  }

  return pdf.TextSpan(text: _decodeHtml(node.textContent));
}

/// Decode HTML entities using a temporary browser DOM element.
String _decodeHtml(String input) {
  try {
    final div = web.document.createElement('div') as web.HTMLDivElement;
    div.innerHTML = input.toJS;
    return div.textContent ?? input;
  } catch (e) {
    // If browser interop fails for any reason, return the original input
    return input;
  }
}
