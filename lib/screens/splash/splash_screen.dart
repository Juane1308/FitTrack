import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/api_config.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/progress_provider.dart';
import '../../providers/recommendation_provider.dart';
import '../../providers/training_provider.dart';
import '../../repositories/profile_repository.dart';
import '../auth/login_screen.dart';
import '../home/main_shell.dart';
import '../profile/profile_setup_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AuthProvider>().initialization.then((_) {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      final appState = context.read<AppStateProvider>();
      _openNext(auth, appState);
    });
  }

  Future<void> _openNext(AuthProvider auth, AppStateProvider appState) async {
    final progressProvider = context.read<ProgressProvider>();
    final trainingProvider = context.read<TrainingProvider>();
    final recommendationProvider = context.read<RecommendationProvider>();
    if (auth.isAuthenticated && auth.sessionToken != null && ApiConfig.useApi) {
      try {
        await appState.loadRemoteProfile(auth.sessionToken!);
      } catch (error) {
        // Una sesión vencida no debe dejar al usuario atrapado en onboarding.
        if (error is ProfileRequestException && error.statusCode == 401) {
          appState.clearUserData();
          progressProvider.clearUserData();
          trainingProvider.clearUserData();
          recommendationProvider.clearUserData();
          await auth.logout();
        }
      }
      if (appState.isProfileComplete) {
        try {
          await appState.loadRemoteTraining(auth.sessionToken!);
        } catch (_) {
          // El home puede mostrar el estado vacío mientras se recupera el plan.
        }
        await progressProvider.load(auth.sessionToken!);
      }
    }
    if (!mounted) return;
    final destination = !auth.isAuthenticated
        ? const LoginScreen()
        : ApiConfig.useApi && !appState.isProfileComplete
        ? const ProfileSetupScreen()
        : const MainShell();
    Navigator.of(context)
        .pushReplacement(MaterialPageRoute<void>(builder: (_) => destination));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              AppConstants.logoAsset,
              width: 280,
              height: 280,
              fit: BoxFit.contain,
              semanticLabel: 'Logo de FITTRACK',
            ),
          ],
        ),
      ),
    );
  }
}
