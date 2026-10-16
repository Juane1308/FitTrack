import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants/api_config.dart';
import '../../core/theme/app_colors.dart';
import '../../models/app_models.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/auth_provider.dart';
import '../home/main_shell.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({this.editing = false, super.key});

  final bool editing;

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _birthDate = TextEditingController();
  final _weight = TextEditingController();
  final _height = TextEditingController();
  final _sport = TextEditingController();
  final _injuries = TextEditingController();
  final _pain = TextEditingController();
  final _surgeries = TextEditingController();
  final _diseases = TextEditingController();
  final _allergies = TextEditingController();

  String _goal = 'Mantenerme activo';
  String _trainingPlace = 'Gimnasio';
  DateTime? _selectedBirthDate;
  int _trainingDays = 4;
  int _step = 0;
  bool _saving = false;

  static const _goals = [
    ('Perder grasa', Icons.local_fire_department_outlined, 'Quiero un cuerpo más saludable.'),
    ('Ganar masa muscular', Icons.fitness_center_outlined, 'Quiero ser más fuerte.'),
    ('Mantenerme activo', Icons.favorite_border, 'Quiero mantener mi estado actual.'),
    ('Mejorar resistencia', Icons.eco_outlined, 'Quiero sentirme mejor.'),
  ];

  @override
  void initState() {
    super.initState();
    final profile = context.read<AppStateProvider>().profile;
    if (profile.goal != 'Definir objetivo') _goal = profile.goal;
    _selectedBirthDate = profile.birthDate;
    _birthDate.text = _formatDate(profile.birthDate);
    _weight.text = profile.weight?.toString() ?? '';
    _height.text = profile.height?.toString() ?? '';
    _sport.text = profile.sport;
    _trainingPlace = profile.trainingPlace.isEmpty ? _trainingPlace : profile.trainingPlace;
    _trainingDays = profile.trainingDays;
    _injuries.text = profile.injuries;
    _pain.text = profile.pain;
    _surgeries.text = profile.surgeries;
    _diseases.text = profile.diseases;
    _allergies.text = profile.allergies;
  }

  @override
  void dispose() {
    for (final controller in [_birthDate, _weight, _height, _sport, _injuries, _pain, _surgeries, _diseases, _allergies]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _continue() {
    if (_step == 0) {
      setState(() => _step = 1);
    } else {
      _save();
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final profile = UserProfile(
      goal: _goal,
      birthDate: _selectedBirthDate,
      weight: double.parse(_weight.text.trim().replaceAll(',', '.')),
      height: double.parse(_height.text.trim().replaceAll(',', '.')),
      sport: _sport.text.trim(),
      trainingPlace: _trainingPlace,
      injuries: _injuries.text.trim(),
      pain: _pain.text.trim(),
      surgeries: _surgeries.text.trim(),
      diseases: _diseases.text.trim(),
      allergies: _allergies.text.trim(),
      trainingDays: _trainingDays,
    );

    try {
      final token = context.read<AuthProvider>().sessionToken;
      if (ApiConfig.useApi && token != null) {
        await context.read<AppStateProvider>().saveRemoteProfile(token, profile);
      } else {
        context.read<AppStateProvider>().updateProfile(profile);
      }
      if (!mounted) return;
      if (widget.editing) {
        Navigator.of(context).pop(true);
      } else {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (_) => const MainShell()),
          (_) => false,
        );
      }
    } catch (_) {
      if (mounted) _showMessage('No se pudo guardar tu perfil. Intenta nuevamente.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _selectBirthDate() async {
    final today = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime(today.year - 18),
      firstDate: DateTime(1900),
      lastDate: today,
      helpText: 'Selecciona tu fecha de nacimiento',
    );
    if (selected != null) {
      setState(() {
        _selectedBirthDate = selected;
        _birthDate.text = _formatDate(selected);
      });
    }
  }

  String _formatDate(DateTime? date) => date == null
      ? ''
      : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

  String? _positiveNumber(String? value) {
    final number = double.tryParse((value ?? '').trim().replaceAll(',', '.'));
    return number == null || number <= 0 ? 'Ingresa un valor válido.' : null;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 18, 0),
                    child: Row(
                      children: [
                        if (_step > 0)
                          IconButton(
                            onPressed: _saving ? null : () => setState(() => _step = 0),
                            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                          ),
                        Expanded(
                          child: Text(
                            widget.editing ? 'Editar perfil' : 'Personaliza FITTRACK',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                    child: _ProgressDots(step: _step),
                  ),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                      children: [_step == 0 ? _goalStep() : _dataStep()],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _saving ? null : _continue,
                        child: _saving
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : Text(_step == 0 ? 'Continuar' : 'Guardar y continuar'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _goalStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const Text('¿Cuál es tu objetivo principal?', style: TextStyle(fontSize: 28, height: 1.05, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        const Text('Usaremos esta selección para personalizar tus recomendaciones.', style: TextStyle(color: AppColors.mutedText)),
        const SizedBox(height: 24),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: .92,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: _goals.map((goal) {
            final selected = _goal == goal.$1;
            return InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => setState(() => _goal = goal.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary.withValues(alpha: .16) : AppColors.surface.withValues(alpha: .42),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: selected ? AppColors.primary : const Color(0xFF26352F), width: selected ? 2 : 1),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Align(alignment: Alignment.topRight, child: Icon(selected ? Icons.check_circle : Icons.circle_outlined, color: selected ? AppColors.primary : Colors.transparent, size: 22)),
                    Icon(goal.$2, color: selected ? AppColors.primary : AppColors.text, size: 38),
                    const SizedBox(height: 14),
                    Text(goal.$1, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 7),
                    Text(goal.$3, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.mutedText, fontSize: 11)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _dataStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        const Text('Tus datos', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
        const SizedBox(height: 8),
        const Text('Estos datos se guardan en tu perfil para adaptar el contenido.', style: TextStyle(color: AppColors.mutedText)),
        const SizedBox(height: 24),
        TextFormField(controller: _birthDate, readOnly: true, onTap: _selectBirthDate, decoration: const InputDecoration(labelText: 'Fecha de nacimiento', prefixIcon: Icon(Icons.cake_outlined))),
        const SizedBox(height: 14),
        TextFormField(controller: _weight, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Peso (kg)', prefixIcon: Icon(Icons.monitor_weight_outlined)), validator: _positiveNumber),
        const SizedBox(height: 14),
        TextFormField(controller: _height, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Altura (m, ejemplo 1.74)', prefixIcon: Icon(Icons.height)), validator: _positiveNumber),
        const SizedBox(height: 14),
        TextFormField(controller: _sport, decoration: const InputDecoration(labelText: 'Actividad deportiva actual', prefixIcon: Icon(Icons.sports_outlined)),),
        const SizedBox(height: 14),
        DropdownButtonFormField<int>(
          initialValue: _trainingDays,
          decoration: const InputDecoration(labelText: '¿Cuántos días entrenas por semana?', prefixIcon: Icon(Icons.calendar_today_outlined)),
          items: List.generate(7, (index) => index + 1).map((days) => DropdownMenuItem(value: days, child: Text('$days ${days == 1 ? 'día' : 'días'}'))).toList(),
          onChanged: (value) => setState(() => _trainingDays = value ?? _trainingDays),
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<String>(
          initialValue: _trainingPlace,
          decoration: const InputDecoration(labelText: '¿Dónde entrenas normalmente?', prefixIcon: Icon(Icons.place_outlined)),
          items: const [
            DropdownMenuItem(value: 'Casa', child: Text('Casa')),
            DropdownMenuItem(value: 'Aire libre', child: Text('Aire libre')),
            DropdownMenuItem(value: 'Gimnasio', child: Text('Gimnasio equipado')),
          ],
          onChanged: (value) => setState(() => _trainingPlace = value ?? _trainingPlace),
        ),
        const SizedBox(height: 14),
        _multiline(_injuries, 'Lesiones pasadas', Icons.healing_outlined, 'Ninguna'),
        const SizedBox(height: 14),
        _multiline(_pain, 'Dolores articulares', Icons.accessibility_new_outlined, 'Ninguno'),
        const SizedBox(height: 14),
        _multiline(_surgeries, 'Cirugías', Icons.medical_services_outlined, 'Ninguna'),
        const SizedBox(height: 14),
        _multiline(_diseases, 'Enfermedades crónicas', Icons.health_and_safety_outlined, 'Ninguna'),
        const SizedBox(height: 14),
        _multiline(_allergies, 'Alergias alimentarias', Icons.warning_amber_outlined, 'Ninguna conocida'),
      ],
    );
  }

  Widget _multiline(TextEditingController controller, String label, IconData icon, String hint) => TextFormField(
        controller: controller,
        maxLines: 2,
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon), hintText: hint),
      );
}

class _ProgressDots extends StatelessWidget {
  const _ProgressDots({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        2,
        (index) => Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 3),
            height: 4,
            decoration: BoxDecoration(
              color: index <= step ? AppColors.primary : Colors.white24,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ),
      ),
    );
  }
}
