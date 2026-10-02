# FITTRACK

Aplicación multiplataforma para seguimiento del entrenamiento, alimentación y progreso físico.

## Estado actual

Etapas 1 y 2: proyecto base y autenticación MOCK funcionando con Flutter, Android, iOS y Web habilitados.

Incluye:

- Tema visual inicial en español.
- Navegación principal: Inicio, Entrenar, Alimentación, Progreso y Perfil.
- Datos mock separados en modelos y repositorio.
- Gestión de estado con Provider y ChangeNotifier.
- Botón único y contextual del asistente virtual.
- Diseño responsive inicial para móvil y Web.
- Login, registro, recuperación de contraseña y cierre de sesión preparado.
- Contraseñas mock representadas mediante huella SHA-256, nunca en texto plano.
- Identidad visual con logo FITTRACK y tema oscuro global.

## Tecnologías

- Flutter y Dart.
- Provider para gestión de estado.
- Git y GitHub.

## Requisitos

- Flutter SDK.
- Android Studio y Android SDK para Android.
- Google Chrome para Web.
- macOS y Xcode para compilar iOS.

## Instalación y ejecución

```bash
flutter pub get
flutter analyze
flutter test
flutter run -d chrome
```

Para Android, inicia un emulador o conecta un dispositivo y ejecuta:

```bash
flutter devices
flutter run
```

## Entregables

APK Release:

```bash
flutter build apk --release
```

Salida esperada:

```text
build/app/outputs/flutter-apk/app-release.apk
```

Web Release:

```bash
flutter build web --release
```

iOS se compila desde macOS con Xcode:

```bash
flutter build ios --release
```

## Arquitectura

```text
lib/
├── core/          # Constantes, tema y validadores
├── models/        # Modelos de datos
├── repositories/  # Fuentes de datos mock o reales
├── providers/     # Estado de la aplicación
├── services/      # Servicios, incluido el chatbot
├── screens/       # Pantallas por módulo
└── widgets/       # Componentes reutilizables
```

## Ramas Git

- `main`: rama estable.
- `develop`: rama principal de desarrollo.

Las funcionalidades se desarrollarán en ramas `feature/...` y se integrarán en `develop`.

## Flujo de autenticación MOCK

En esta etapa las cuentas viven únicamente en memoria mientras la aplicación está abierta. Registra una cuenta desde la pantalla de Login y después inicia sesión. No se envían correos reales ni se conecta un backend.

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
