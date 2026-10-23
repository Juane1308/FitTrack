import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
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

  static const _sections = AppSection.values;

  @override
  Widget build(BuildContext context) {
    final section = _sections[_selectedIndex];
    final screens = [
      HomeScreenEnhanced(
        onOpenTraining: () => setState(() => _selectedIndex = 1),
        onOpenProgress: () => setState(() => _selectedIndex = 3),
      ),
      const TrainingScreen(),
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
