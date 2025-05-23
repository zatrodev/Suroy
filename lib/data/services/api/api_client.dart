import 'dart:convert';
import 'dart:io';
import 'package:app/utils/result.dart';

typedef AuthHeaderProvider = String? Function();

class ApiClient {
  ApiClient({String? host, int? port, HttpClient Function()? clientFactory})
    : _host = host ?? "192.168.1.14",
      _port = port ?? 4000,
      _clientFactory = clientFactory ?? HttpClient.new;

  final String _host;
  final int _port;
  final HttpClient Function() _clientFactory;

  AuthHeaderProvider? _authHeaderProvider;

  set authHeaderProvider(AuthHeaderProvider authHeaderProvider) {
    _authHeaderProvider = authHeaderProvider;
  }

  Future<void> _authHeader(HttpHeaders headers) async {
    final header = _authHeaderProvider?.call();
    if (header != null) {
      headers.add(HttpHeaders.authorizationHeader, header);
    }
  }

  Future<Result<void>> pushAddFriendNotification(
    String senderUid,
    String receiverUid,
  ) async {
    final client = _clientFactory();
    client.connectionTimeout = const Duration(seconds: 5);

    try {
      final request = await client.post(_host, _port, "/send-notif");
      request.headers.contentType = ContentType.json;

      final Map<String, String> body = {
        'senderUid': senderUid,
        'receiverUid': receiverUid,
      };
      final String jsonBody = jsonEncode(body);
      request.write(jsonBody);

      final response = await request.close();

      if (response.statusCode == 200) {
        return const Result.ok(null);
      } else {
        return const Result.error(HttpException("Invalid response"));
      }
    } on Exception catch (error) {
      return Result.error(error);
    } finally {
      client.close();
    }
  }
}
