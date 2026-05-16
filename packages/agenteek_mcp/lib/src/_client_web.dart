import 'package:http/browser_client.dart';
import 'package:http/http.dart';

Client initClient({required bool withCredentials}) =>
    BrowserClient()..withCredentials = withCredentials;
