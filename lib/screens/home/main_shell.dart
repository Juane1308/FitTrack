import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/app_constants.dart';
import '../../models/app_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/progress_provider.dart';
import '../../providers/training_provider.dart';
import '../../widgets/chatbot/contextual_chat_button.dart';
import '../nutrition/nutrition_screen.dart';
import '../profile/profile_screen_enhanced.dart';
import '../progress/progress_screen_enhanced.dart';
import '../training/training_screen.dart';
import 'home_screen_enhanced.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  WorkoutDay? _routineToStart;

  static const _sections = AppSection.values;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final token = context.read<AuthProvider>().sessionToken;
      if (token == null) return;
      context.read<TrainingProvider>().loadWeeklyPlan(token);
      context.read<ProgressProvider>().load(token);
    });
  }

  void _startRecommendedRoutine(WorkoutDay day) {
    setState(() {
      _selectedIndex = 1;
      _routineToStart = day;
    });
  }

  void _routineRequestHandled() {
    if (!mounted || _routineToStart == null) return;
    setState(() => _routineToStart = null);
  }

  @override
  Widget build(BuildContext context) {
    final section = _sections[_selectedIndex];
    final screens = [
      HomeScreenEnhanced(
        onOpenTraining: () => setState(() => _selectedIndex = 1),
        onStartRoutine: _startRecommendedRoutine,
        onOpenProgress: () => setState(() => _selectedIndex = 3),
      ),
      TrainingScreen(
        routineToStart: _routineToStart,
        onRoutineStarted: _routineRequestHandled,
      ),
      const NutritionScreen(),
      const ProgressScreenEnhanced(),
      const ProfileScreenEnhanced(),
    ];

    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(index: _selectedIndex, children: screens),
          ContextualChatButton(section: section),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.fitness_center_outlined),
            selectedIcon: Icon(Icons.fitness_center),
            label: 'Entrenar',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_outlined),
            selectedIcon: Icon(Icons.restaurant),
            label: 'Alimentación',
          ),
          NavigationDestination(
            icon: Icon(Icons.show_chart_outlined),
            selectedIcon: Icon(Icons.show_chart),
            label: 'Progreso',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
