import 'package:flutter/foundation.dart';

class ApiConfig {
  const ApiConfig._();

  /// La app consulta el backend real por defecto. En producción se debe
  /// definir FITTRACK_API_URL con la URL pública del servicio desplegado.
  static const _useApiFlag = bool.fromEnvironment(
    'FITTRACK_USE_API',
    defaultValue: true,
  );

  static const _configuredBaseUrl = String.fromEnvironment(
    'FITTRACK_API_URL',
  );

  static bool get useApi => _useApiFlag || _configuredBaseUrl.isNotEmpty;

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
