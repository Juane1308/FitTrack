import 'package:flutter/foundation.dart';

import '../models/app_models.dart';
import '../repositories/progress_repository.dart';

enum ProgressLoadStatus { idle, loading, ready, error }

class ProgressProvider extends ChangeNotifier {
  ProgressProvider({ProgressRepository? repository}) : _repository = repository ?? ProgressRepository();

  final ProgressRepository _repository;
  ProgressData _data = ProgressData.empty;
  ProgressLoadStatus _status = ProgressLoadStatus.idle;
  String? _error;

  ProgressData get data => _data;
  ProgressLoadStatus get status => _status;
  bool get isLoading => _status == ProgressLoadStatus.loading;
  String? get error => _error;

  Future<void> load(String token, {bool forceRefresh = false}) async {
    if (isLoading || (_status == ProgressLoadStatus.ready && !forceRefresh)) return;
    _status = ProgressLoadStatus.loading;
    _error = null;
    notifyListeners();
    try {
      _data = await _repository.fetch(token);
      _status = ProgressLoadStatus.ready;
    } catch (_) {
      _status = ProgressLoadStatus.error;
      _error = 'No se pudo cargar tu progreso.';
    }
    notifyListeners();
  }

  Future<void> addEntry({
    required String token,
    required double weight,
    required double height,
    DateTime? recordedAt,
    double? targetWeight,
  }) async {
    _status = ProgressLoadStatus.loading;
    _error = null;
    notifyListeners();
    try {
      _data = await _repository.addEntry(
        token: token,
        weight: weight,
        height: height,
        recordedAt: recordedAt,
        targetWeight: targetWeight,
      );
      _status = ProgressLoadStatus.ready;
    } catch (_) {
      _status = ProgressLoadStatus.error;
      _error = 'No se pudo guardar la medición.';
    }
    notifyListeners();
  }

  Future<void> uploadPhoto({
    required String token,
    required Uint8List bytes,
    required String mimeType,
    String fileName = 'progreso.jpg',
  }) async {
    _status = ProgressLoadStatus.loading;
    _error = null;
    notifyListeners();
    try {
      _data = await _repository.uploadPhoto(
        token: token,
        bytes: bytes,
        mimeType: mimeType,
        fileName: fileName,
      );
      _status = ProgressLoadStatus.ready;
    } catch (_) {
      _status = ProgressLoadStatus.error;
      _error = 'No se pudo guardar la foto. Verifica que hayas completado la semana.';
    }
    notifyListeners();
  }
}
