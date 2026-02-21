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
                if (m.role == dartantic.ChatMessageRole.system) return false;
                if (m.hasToolCalls || m.hasToolResults) return false;
                return m.text.trim().isNotEmpty;
              })
              .map((m) {
                final isUser = m.role == dartantic.ChatMessageRole.user;
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
  final List<pdf.Widget> widgets = [];
  try {
    final nodes = md.Document().parseLines(text.split('\n'));
    for (final node in nodes) {
      widgets.add(_convertNode(node, font, fontBold, fontMono));
    }
  } catch (e) {
    // Fallback for parsing errors
    widgets.add(
      pdf.Text(
        text,
        style: pdf.TextStyle(font: font, fontSize: 11, height: 1.4),
      ),
    );
  }

  return widgets;
}

pdf.Widget _convertNode(
  md.Node node,
  pdf.Font font,
  pdf.Font fontBold,
  pdf.Font fontMono,
) {
  if (node is md.Element) {
    switch (node.tag) {
      case 'p':
        return pdf.Padding(
          padding: const pdf.EdgeInsets.symmetric(vertical: 4),
          child: pdf.Text(
            node.textContent,
            style: pdf.TextStyle(font: font, fontSize: 11, height: 1.4),
          ),
        );
      case 'h1':
        return pdf.Padding(
          padding: const pdf.EdgeInsets.only(top: 12, bottom: 4),
          child: pdf.Text(
            node.textContent,
            style: pdf.TextStyle(font: fontBold, fontSize: 16),
          ),
        );
      case 'h2':
        return pdf.Padding(
          padding: const pdf.EdgeInsets.only(top: 10, bottom: 4),
          child: pdf.Text(
            node.textContent,
            style: pdf.TextStyle(font: fontBold, fontSize: 14),
          ),
        );
      case 'h3':
        return pdf.Padding(
          padding: const pdf.EdgeInsets.only(top: 8, bottom: 4),
          child: pdf.Text(
            node.textContent,
            style: pdf.TextStyle(font: fontBold, fontSize: 12),
          ),
        );
      case 'li':
        return pdf.Padding(
          padding: const pdf.EdgeInsets.only(left: 12, top: 2, bottom: 2),
          child: pdf.Row(
            crossAxisAlignment: pdf.CrossAxisAlignment.start,
            children: [
              pdf.Text('• ', style: pdf.TextStyle(font: font, fontSize: 11)),
              pdf.Expanded(
                child: pdf.Text(
                  node.textContent,
                  style: pdf.TextStyle(font: font, fontSize: 11, height: 1.4),
                ),
              ),
            ],
          ),
        );
      case 'ul':
        return pdf.Column(
          crossAxisAlignment: pdf.CrossAxisAlignment.start,
          children:
              node.children
                  ?.map((c) => _convertNode(c, font, fontBold, fontMono))
                  .toList() ??
              [],
        );
      case 'code':
        return pdf.Container(
          padding: const pdf.EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: pdf.BoxDecoration(
            color: pdf.PdfColors.grey200,
            borderRadius: const pdf.BorderRadius.all(pdf.Radius.circular(4)),
          ),
          child: pdf.Text(
            node.textContent,
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
            node.textContent,
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
          child: pdf.Text(
            node.textContent,
            style: pdf.TextStyle(
              font: font,
              fontSize: 11,
              color: pdf.PdfColors.grey700,
              fontStyle: pdf.FontStyle.italic,
            ),
          ),
        );
      default:
        if (node.children != null) {
          return pdf.Column(
            crossAxisAlignment: pdf.CrossAxisAlignment.start,
            children: node.children!
                .map((c) => _convertNode(c, font, fontBold, fontMono))
                .toList(),
          );
        }
    }
  }
  return pdf.Text(
    node.textContent,
    style: pdf.TextStyle(font: font, fontSize: 11),
  );
}
