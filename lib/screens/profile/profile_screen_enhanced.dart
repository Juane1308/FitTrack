import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../models/app_models.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/progress_provider.dart';
import '../auth/login_screen.dart';
import 'profile_setup_screen.dart';

class ProfileScreenEnhanced extends StatelessWidget {
  const ProfileScreenEnhanced({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final state = context.watch<AppStateProvider>();
    final progress = context.watch<ProgressProvider>().data.summary;
    final user = auth.currentUser;
    if (user == null) return const SizedBox.shrink();
    final profile = state.profile;
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 110),
            children: [
              Row(children: [
                const Expanded(child: Text('Perfil', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900))),
                IconButton(onPressed: () => _edit(context), icon: const Icon(Icons.settings_outlined), tooltip: 'Editar perfil'),
              ]),
              const SizedBox(height: 12),
              Center(child: Column(children: [
                Container(width: 86, height: 86, decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.surface, border: Border.all(color: AppColors.primary, width: 2)), child: const Icon(Icons.person_outline, size: 44, color: AppColors.primary)),
                const SizedBox(height: 10),
                Text(user.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(user.email, style: const TextStyle(color: AppColors.mutedText)),
              ])),
              const SizedBox(height: 18),
              Row(children: [
                Expanded(child: _ProfileStat(value: '${profile.trainingDays}', label: 'Días/semana', icon: Icons.calendar_today_outlined)),
                const SizedBox(width: 10),
                Expanded(child: _ProfileStat(value: '${progress.completedDays}', label: 'Completados', icon: Icons.check_circle_outline)),
                const SizedBox(width: 10),
                Expanded(child: _ProfileStat(value: progress.currentWeight == null ? '--' : '${progress.currentWeight!.toStringAsFixed(1)} kg', label: 'Peso actual', icon: Icons.monitor_weight_outlined)),
              ]),
              const SizedBox(height: 20),
              _ProfileAction(icon: Icons.flag_outlined, title: 'Mi objetivo', subtitle: profile.goal, onTap: () => _edit(context)),
              _ProfileAction(icon: Icons.person_outline, title: 'Mis datos', subtitle: _profileSummary(profile), onTap: () => _edit(context)),
              const SizedBox(height: 12),
              _SettingsCard(
                icon: Icons.notifications_none,
                title: 'Notificaciones',
                subtitle: 'Recordatorios de entrenamiento y progreso',
                value: profile.notificationsEnabled,
                onChanged: (value) => _saveSettings(context, profile.copyWith(notificationsEnabled: value)),
              ),
              _SettingsCard(
                icon: Icons.lock_outline,
                title: 'Privacidad',
                subtitle: profile.privateProfile ? 'Perfil privado' : 'Perfil visible',
                value: profile.privateProfile,
                onChanged: (value) => _saveSettings(context, profile.copyWith(privateProfile: value)),
              ),
              _ProfileAction(icon: Icons.help_outline, title: 'Ayuda', subtitle: 'Consulta cómo usar FITTRACK', onTap: () => _showHelp(context)),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _logout(context),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent, side: const BorderSide(color: Colors.redAccent)),
                icon: const Icon(Icons.logout),
                label: const Text('Cerrar sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _profileSummary(UserProfile profile) {
    final weight = profile.weight == null ? 'Sin peso' : '${profile.weight!.toStringAsFixed(1)} kg';
    final height = profile.height == null ? 'sin altura' : '${profile.height!.toStringAsFixed(2)} m';
    return '$weight · $height · ${profile.trainingPlace.isEmpty ? 'lugar no indicado' : profile.trainingPlace}';
  }

  void _edit(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute<bool>(builder: (_) => const ProfileSetupScreen(editing: true)));
  }

  Future<void> _saveSettings(BuildContext context, UserProfile profile) async {
    final token = context.read<AuthProvider>().sessionToken;
    if (token == null) return;
    try {
      await context.read<AppStateProvider>().saveRemoteProfile(token, profile);
    } catch (_) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No se pudo actualizar la configuración.')));
    }
  }

  void _showHelp(BuildContext context) {
    const faqs = [
      ('¿Cómo se genera mi rutina?', 'FITTRACK usa tu objetivo, nivel, días disponibles, lugar de entrenamiento y las condiciones de salud que registraste para ordenar una rutina adecuada.'),
      ('¿Cómo marco un entrenamiento?', 'Entra en Entrenar, abre la rutina del día y pulsa el botón para marcarla como completada cuando termines. Ese registro actualiza tu avance semanal.'),
      ('¿Cuándo puedo subir una foto?', 'La foto se habilita cuando completas todos los entrenamientos planificados de la semana. Solo se permite una foto por semana.'),
      ('¿Cómo actualizo mis datos?', 'Abre Perfil, pulsa el icono de configuración y modifica tus datos. El peso objetivo se usa para calcular el avance en Progreso.'),
      ('¿Cómo funcionan las recomendaciones?', 'El asistente consulta los ejercicios y alimentos disponibles, y filtra sus sugerencias según tu objetivo, preferencias, lugar y restricciones.'),
      ('¿Qué hago si tengo una lesión?', 'Registra la lesión o el dolor en tu perfil y consulta a un profesional de salud antes de realizar una rutina. La app no sustituye una valoración médica.'),
    ];
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 18),
          child: SizedBox(
            height: MediaQuery.sizeOf(sheetContext).height * .72,
            child: ListView(
              children: [
                const ListTile(leading: Icon(Icons.help_outline, color: AppColors.primary), title: Text('Preguntas frecuentes', style: TextStyle(fontWeight: FontWeight.w900))),
                const Divider(),
                ...faqs.map((faq) => ExpansionTile(title: Text(faq.$1, style: const TextStyle(fontWeight: FontWeight.w700)), childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12), children: [Text(faq.$2, style: const TextStyle(color: AppColors.mutedText))])),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    await context.read<AuthProvider>().logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute<void>(builder: (_) => const LoginScreen()), (_) => false);
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({required this.value, required this.label, required this.icon});

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8), child: Column(children: [Icon(icon, color: AppColors.primary, size: 20), const SizedBox(height: 6), Text(value, style: const TextStyle(fontWeight: FontWeight.w900)), const SizedBox(height: 3), Text(label, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.mutedText, fontSize: 11))])));
}

class _ProfileAction extends StatelessWidget {
  const _ProfileAction({required this.icon, required this.title, required this.subtitle, required this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(child: ListTile(leading: Icon(icon, color: AppColors.primary), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text(subtitle, style: const TextStyle(color: AppColors.mutedText, fontSize: 12)), trailing: const Icon(Icons.chevron_right), onTap: onTap));
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.icon, required this.title, required this.subtitle, required this.value, required this.onChanged});

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Card(child: SwitchListTile(value: value, onChanged: onChanged, secondary: Icon(icon, color: AppColors.primary), title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)), subtitle: Text(subtitle, style: const TextStyle(color: AppColors.mutedText, fontSize: 12))));
}
