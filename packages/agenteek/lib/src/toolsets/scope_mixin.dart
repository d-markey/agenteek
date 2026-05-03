import 'toolset.dart';

mixin Scope on ToolSet {
  String get scope;

  String buildDescription(String description) =>
      scope.isEmpty ? description : '$description (**scope: $scope**)';
}
