import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../models/app_models.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import 'profile_setup_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppStateProvider>();
    final auth = context.watch<AuthProvider>();
    final user = auth.currentUser ?? state.currentUser;
    final profile = state.profile;

    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              Row(
                children: [
                  const Expanded(child: Text('Perfil', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900))),
                  IconButton(
                    tooltip: 'Editar perfil',
                    onPressed: () => _openEditor(context),
                    icon: const Icon(Icons.settings_outlined),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 86,
                      height: 86,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.surface,
                        border: Border.all(color: AppColors.primary.withValues(alpha: .65)),
                      ),
                      child: Image.asset('assets/images/fittrack_logo.png'),
                    ),
                    const SizedBox(height: 8),
                    Text(user.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                    Text(user.email, style: const TextStyle(color: AppColors.mutedText, fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              _ProfileRow(icon: Icons.track_changes_outlined, label: 'Mi objetivo', value: profile.goal, onTap: () => _openEditor(context)),
              _ProfileRow(icon: Icons.person_outline, label: 'Mis datos', value: _physicalData(profile), onTap: () => _openEditor(context)),
              _ProfileRow(icon: Icons.sports_outlined, label: 'Actividad y lugar', value: _activityData(profile), onTap: () => _openEditor(context)),
              _ProfileRow(icon: Icons.health_and_safety_outlined, label: 'Salud y restricciones', value: _healthData(profile), onTap: () => _openEditor(context)),
              _ProfileRow(icon: Icons.help_outline, label: 'Ayuda', onTap: () => _showHelp(context)),
              _ProfileRow(
                icon: Icons.logout,
                label: 'Cerrar sesión',
                danger: true,
                onTap: () async {
                  await context.read<AuthProvider>().logout();
                  if (!context.mounted) return;
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
                    (_) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _physicalData(UserProfile profile) =>
      '${profile.weight ?? '--'} kg · ${profile.height ?? '--'} m';

  String _activityData(UserProfile profile) => profile.trainingPlace.isEmpty
      ? 'Sin configurar'
      : '${profile.sport.isEmpty ? 'Actividad por definir' : profile.sport} · ${profile.trainingPlace}';

  String _healthData(UserProfile profile) {
    final values = [profile.injuries, profile.pain, profile.surgeries, profile.diseases, profile.allergies]
        .where((value) => value.trim().isNotEmpty)
        .length;
    return values == 0 ? 'Sin restricciones registradas' : '$values datos registrados';
  }

  Future<void> _openEditor(BuildContext context) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const ProfileSetupScreen(editing: true)),
    );
  }

  void _showHelp(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Ayuda'),
        content: const Text('Desde tu perfil puedes actualizar tu objetivo, datos físicos, actividad y condiciones que debamos considerar.'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar'))],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.icon, required this.label, this.value, this.danger = false, required this.onTap});

  final IconData icon;
  final String label;
  final String? value;
  final bool danger;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = danger ? Colors.redAccent : AppColors.text;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(13),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: .42),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: danger ? Colors.redAccent.withValues(alpha: .6) : AppColors.primary.withValues(alpha: .55)),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 22),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700)),
                      if (value != null) Text(value!, style: const TextStyle(color: AppColors.mutedText, fontSize: 11)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
