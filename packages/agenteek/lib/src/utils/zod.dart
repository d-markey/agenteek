import 'package:dartantic_ai/dartantic_ai.dart' as dartantic show Schema;

typedef S = dartantic.Schema;

extension DescriptionExt on String {
  String optional([String defaultValue = '']) => defaultValue.isEmpty
      ? '${toString()} (optional)'
      : '${toString()} (optional; defaults to "$defaultValue")';

  String sideEffect(String sideEffect) => sideEffect.isEmpty
      ? '${toString()}; **WARNING: this tool has side effects**'
      : '${toString()}; **WARNING: this tool has side effects** $sideEffect';
}
