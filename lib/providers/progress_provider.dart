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
  int _userDataGeneration = 0;
  int _requestSequence = 0;

  ProgressData get data => _data;
  ProgressLoadStatus get status => _status;
  bool get isLoading => _status == ProgressLoadStatus.loading;
  String? get error => _error;

  void clearUserData() {
    _userDataGeneration++;
    _requestSequence++;
    _data = ProgressData.empty;
    _status = ProgressLoadStatus.idle;
    _error = null;
    notifyListeners();
  }

  Future<void> load(String token, {bool forceRefresh = false}) async {
    if ((!forceRefresh && isLoading) ||
        (_status == ProgressLoadStatus.ready && !forceRefresh)) {
      return;
    }
    final requestGeneration = _userDataGeneration;
    final requestSequence = ++_requestSequence;
    _status = ProgressLoadStatus.loading;
    _error = null;
    notifyListeners();
    try {
      final data = await _repository.fetch(token);
      if (requestGeneration == _userDataGeneration &&
          requestSequence == _requestSequence) {
        _data = data;
        _status = ProgressLoadStatus.ready;
      }
    } catch (_) {
      if (requestGeneration == _userDataGeneration &&
          requestSequence == _requestSequence) {
        _status = ProgressLoadStatus.error;
        _error = 'No se pudo cargar tu progreso.';
      }
    }
    if (requestGeneration == _userDataGeneration &&
        requestSequence == _requestSequence) {
      notifyListeners();
    }
  }

  Future<void> addEntry({
    required String token,
    required double weight,
    required double height,
    DateTime? recordedAt,
    double? targetWeight,
  }) async {
    final requestGeneration = _userDataGeneration;
    final requestSequence = ++_requestSequence;
    _status = ProgressLoadStatus.loading;
    _error = null;
    notifyListeners();
    try {
      final data = await _repository.addEntry(
        token: token,
        weight: weight,
        height: height,
        recordedAt: recordedAt,
        targetWeight: targetWeight,
      );
      if (requestGeneration == _userDataGeneration &&
          requestSequence == _requestSequence) {
        _data = data;
        _status = ProgressLoadStatus.ready;
      }
    } catch (_) {
      if (requestGeneration == _userDataGeneration &&
          requestSequence == _requestSequence) {
        _status = ProgressLoadStatus.error;
        _error = 'No se pudo guardar la medición.';
      }
    }
    if (requestGeneration == _userDataGeneration &&
        requestSequence == _requestSequence) {
      notifyListeners();
    }
  }

  Future<void> uploadPhoto({
    required String token,
    required Uint8List bytes,
    required String mimeType,
    String fileName = 'progreso.jpg',
  }) async {
    final requestGeneration = _userDataGeneration;
    final requestSequence = ++_requestSequence;
    _status = ProgressLoadStatus.loading;
    _error = null;
    notifyListeners();
    try {
      final data = await _repository.uploadPhoto(
        token: token,
        bytes: bytes,
        mimeType: mimeType,
        fileName: fileName,
      );
      if (requestGeneration == _userDataGeneration &&
          requestSequence == _requestSequence) {
        _data = data;
        _status = ProgressLoadStatus.ready;
      }
    } catch (_) {
      if (requestGeneration == _userDataGeneration &&
          requestSequence == _requestSequence) {
        _status = ProgressLoadStatus.error;
        _error = 'No se pudo guardar la foto. Verifica que hayas completado la semana.';
      }
    }
    if (requestGeneration == _userDataGeneration &&
        requestSequence == _requestSequence) {
      notifyListeners();
    }
  }
}
