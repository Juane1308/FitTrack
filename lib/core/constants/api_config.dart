import 'package:flutter/foundation.dart';

class ApiConfig {
  const ApiConfig._();

  /// La app usa autenticación simulada por defecto para poder probar el flujo
  /// sin levantar el backend. Activa la API al ejecutar con
  /// --dart-define=FITTRACK_USE_API=true.
  static const useApi = bool.fromEnvironment(
    'FITTRACK_USE_API',
    defaultValue: false,
  );

  static const _configuredBaseUrl = String.fromEnvironment(
    'FITTRACK_API_URL',
  );

  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) {
      return _configuredBaseUrl.replaceFirst(RegExp(r'/$'), '');
    }

    if (kIsWeb) {
      return 'http://localhost:3000/api';
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000/api';
    }

    return 'http://localhost:3000/api';
  }
}
