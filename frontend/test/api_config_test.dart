import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/api_config.dart';

void main() {
  test('hosted API is the default backend', () {
    expect(ApiConfig.baseUrl, 'https://paper-rabbit-api.onrender.com');
  });
}
