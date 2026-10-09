enum AppSection { home, training, nutrition, progress, profile }

extension AppSectionInfo on AppSection {
  String get label => switch (this) {
    AppSection.home => 'Inicio',
    AppSection.training => 'Entrenar',
    AppSection.nutrition => 'Alimentación',
    AppSection.progress => 'Progreso',
    AppSection.profile => 'Perfil',
  };

  String get description => switch (this) {
    AppSection.home => 'Tu resumen de hoy',
    AppSection.training => 'Rutinas y ejercicios',
    AppSection.nutrition => 'Alimentación y hábitos',
    AppSection.progress => 'Tu evolución física',
    AppSection.profile => 'Datos y preferencias',
  };
}

abstract final class AppConstants {
  static const appName = 'FITTRACK';
  static const appTagline = 'Entrena. Aliméntate. Evoluciona.';
  static const logoAsset = 'assets/images/fittrack_logo.png';
}
