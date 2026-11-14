import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../models/app_models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/progress_provider.dart';
import '../../widgets/charts/weekly_activity_chart.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/section_title.dart';

class ProgressScreenEnhanced extends StatefulWidget {
  const ProgressScreenEnhanced({super.key});

  @override
  State<ProgressScreenEnhanced> createState() => _ProgressScreenEnhancedState();
}

class _ProgressScreenEnhancedState extends State<ProgressScreenEnhanced> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final token = context.read<AuthProvider>().sessionToken;
      if (token != null) context.read<ProgressProvider>().load(token);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProgressProvider>();
    final data = provider.data;
    final summary = data.summary;
    return SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: RefreshIndicator(
            onRefresh: () async {
              final token = context.read<AuthProvider>().sessionToken;
              if (token != null) await context.read<ProgressProvider>().load(token, forceRefresh: true);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
              children: [
                Row(children: [
                  const Expanded(child: SectionTitle(title: 'Mi progreso', subtitle: 'Registra tus mediciones y revisa tu actividad real')),
                  IconButton(onPressed: provider.isLoading ? null : () => _showAddMeasurement(context), icon: const Icon(Icons.add_circle_outline, color: AppColors.primary), tooltip: 'Añadir medición'),
                ]),
                const SizedBox(height: 18),
                if (provider.isLoading && data == ProgressData.empty) const LinearProgressIndicator(),
                LayoutBuilder(builder: (context, constraints) {
                  final columns = constraints.maxWidth > 650 ? 4 : 2;
                  return GridView.count(crossAxisCount: columns, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.35, children: [
                    _ProgressMetric(icon: Icons.monitor_weight_outlined, label: 'Peso actual', value: summary.currentWeight == null ? 'Sin registro' : '${summary.currentWeight!.toStringAsFixed(1)} kg'),
                    _ProgressMetric(icon: Icons.swap_vert, label: 'Cambio', value: summary.weightChange == null ? 'Sin registro' : _weightChange(summary.weightChange!)),
                    _ProgressMetric(icon: Icons.fitness_center_outlined, label: 'Entrenamientos', value: '${summary.completedDays}/${summary.plannedDays}'),
                    _ProgressMetric(icon: Icons.timer_outlined, label: 'Tiempo total', value: '${summary.totalMinutes} min'),
                  ]);
                }),
                const SizedBox(height: 18),
                _GoalProgressCard(summary: summary),
                const SizedBox(height: 18),
                _ProgressPhotosCard(
                  data: data,
                  onUpload: provider.isLoading ? null : () => _uploadPhoto(context, data),
                ),
                const SizedBox(height: 18),
                AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const SectionTitle(title: 'Cumplimiento semanal', subtitle: 'Rutinas completadas según tu plan actual'),
                  const SizedBox(height: 12),
                  WeeklyActivityChart(points: data.weekly),
                ])),
                const SizedBox(height: 18),
                AppCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const SectionTitle(title: 'Evolución del peso', subtitle: 'Basada en las mediciones guardadas'),
                  const SizedBox(height: 16),
                  if (data.entries.length < 2)
                    const SizedBox(height: 120, child: Center(child: Text('Registra al menos dos mediciones para ver la evolución.')))
                  else
                    SizedBox(height: 170, child: CustomPaint(painter: _WeightChartPainter(data.entries))),
                ])),
                const SizedBox(height: 18),
                if (summary.bmi != null) AppCard(child: Row(children: [
                  const Icon(Icons.health_and_safety_outlined, color: AppColors.primary, size: 30),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Índice de masa corporal', style: TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text('${summary.bmi!.toStringAsFixed(1)} · Es una referencia orientativa, no un diagnóstico.', style: const TextStyle(color: AppColors.mutedText, fontSize: 12)),
                  ])),
                ])),
                const SizedBox(height: 18),
                const SectionTitle(title: 'Mediciones registradas'),
                const SizedBox(height: 10),
                if (data.entries.isEmpty)
                  const AppCard(child: Text('Todavía no has guardado mediciones.'))
                else
                  ...data.entries.reversed.take(8).map((entry) => _MeasurementRow(entry: entry)),
                if (provider.error != null) ...[
                  const SizedBox(height: 12),
                  Text(provider.error!, style: const TextStyle(color: Colors.redAccent)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _weightChange(double value) => '${value > 0 ? '+' : ''}${value.toStringAsFixed(1)} kg';

  Future<void> _uploadPhoto(BuildContext context, ProgressData data) async {
    if (!data.photoEligible) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(data.photoMessage)));
      return;
    }
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (file == null || !mounted) return;
    final bytes = await file.readAsBytes();
    final mimeType = _mimeType(file.name);
    final token = context.read<AuthProvider>().sessionToken;
    if (token == null) return;
    await context.read<ProgressProvider>().uploadPhoto(
      token: token,
      bytes: bytes,
      mimeType: mimeType,
      fileName: file.name,
    );
    if (!mounted) return;
    final error = context.read<ProgressProvider>().error;
    if (error != null) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
  }

  String _mimeType(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  Future<void> _showAddMeasurement(BuildContext context) async {
    final weight = TextEditingController();
    final height = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nueva medición'),
        content: Form(key: formKey, child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextFormField(controller: weight, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Peso (kg)', prefixIcon: Icon(Icons.monitor_weight_outlined)), validator: _positive),
          const SizedBox(height: 12),
          TextFormField(controller: height, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Altura (m)', prefixIcon: Icon(Icons.height)), validator: _positive),
        ])),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () { if (formKey.currentState!.validate()) Navigator.pop(dialogContext, true); }, child: const Text('Guardar')),
        ],
      ),
    );
    if (result != true || !mounted) { weight.dispose(); height.dispose(); return; }
    final token = context.read<AuthProvider>().sessionToken;
    if (token != null) {
      await context.read<ProgressProvider>().addEntry(token: token, weight: double.parse(weight.text.replaceAll(',', '.')), height: double.parse(height.text.replaceAll(',', '.')));
    }
    weight.dispose();
    height.dispose();
  }

  String? _positive(String? value) {
    final number = double.tryParse((value ?? '').replaceAll(',', '.'));
    return number == null || number <= 0 ? 'Ingresa un valor válido.' : null;
  }
}

class _GoalProgressCard extends StatelessWidget {
  const _GoalProgressCard({required this.summary});

  final ProgressSummary summary;

  @override
  Widget build(BuildContext context) {
    final percent = (summary.completionPercent ?? 0).clamp(0, 100).toDouble();
    final hasGoal = summary.targetWeight != null;
    return AppCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Objetivo', style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(
                  hasGoal ? '${summary.targetWeight!.toStringAsFixed(1)} kg' : 'Sin definir',
                  style: const TextStyle(color: AppColors.primary, fontSize: 22, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  hasGoal ? '${percent.toStringAsFixed(0)}% de avance calculado por tus mediciones' : 'Define un peso objetivo desde tu perfil.',
                  style: const TextStyle(color: AppColors.mutedText, fontSize: 12),
                ),
              ],
            ),
          ),
          if (hasGoal)
            SizedBox(
              width: 78,
              height: 78,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(value: percent / 100, strokeWidth: 8, backgroundColor: Colors.white12, color: AppColors.primary),
                  Text('${percent.toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.w900)),
                ],
              ),
            )
          else
            const Icon(Icons.flag_outlined, color: AppColors.primary, size: 34),
        ],
      ),
    );
  }
}

class _ProgressPhotosCard extends StatelessWidget {
  const _ProgressPhotosCard({required this.data, required this.onUpload});

  final ProgressData data;
  final VoidCallback? onUpload;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(title: 'Fotos de progreso', subtitle: 'Una comparación semanal basada en tus registros reales'),
          const SizedBox(height: 10),
          if (data.photos.isEmpty)
            const Text('Aún no tienes fotos guardadas.', style: TextStyle(color: AppColors.mutedText))
          else
            SizedBox(
              height: 150,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: data.photos.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, index) => _PhotoPreview(photo: data.photos[index]),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: Text(data.photoMessage, style: const TextStyle(color: AppColors.mutedText, fontSize: 12))),
              const SizedBox(width: 12),
              FilledButton.icon(onPressed: onUpload, icon: const Icon(Icons.add_a_photo_outlined), label: const Text('Subir foto')),
            ],
          ),
        ],
      ),
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({required this.photo});

  final ProgressPhotoData photo;

  @override
  Widget build(BuildContext context) {
    final uri = photo.dataUrl == null ? null : Uri.tryParse(photo.dataUrl!);
    final bytes = uri?.data?.contentAsBytes();
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 120,
        child: bytes == null
            ? Container(color: AppColors.surface, child: const Icon(Icons.image_not_supported_outlined))
            : Image.memory(bytes, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: AppColors.surface, child: const Icon(Icons.broken_image_outlined))),
      ),
    );
  }
}

class _ProgressMetric extends StatelessWidget {
  const _ProgressMetric({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => AppCard(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Icon(icon, color: AppColors.primary), Text(label, style: const TextStyle(color: AppColors.mutedText, fontSize: 12)), Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900))]));
}

class _MeasurementRow extends StatelessWidget {
  const _MeasurementRow({required this.entry});

  final ProgressEntry entry;

  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: 8), child: AppCard(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12), child: Row(children: [const Icon(Icons.event_note_outlined, color: AppColors.primary), const SizedBox(width: 12), Expanded(child: Text(entry.date)), Text('${entry.weight.toStringAsFixed(1)} kg', style: const TextStyle(fontWeight: FontWeight.w800)), const SizedBox(width: 12), Text('${entry.height.toStringAsFixed(2)} m', style: const TextStyle(color: AppColors.mutedText))])));
}

class _WeightChartPainter extends CustomPainter {
  _WeightChartPainter(this.entries);

  final List<ProgressEntry> entries;

  @override
  void paint(Canvas canvas, Size size) {
    final values = entries.map((entry) => entry.weight).toList();
    final min = values.reduce((a, b) => a < b ? a : b) - 1;
    final max = values.reduce((a, b) => a > b ? a : b) + 1;
    final linePaint = Paint()..color = AppColors.primary..strokeWidth = 3..style = PaintingStyle.stroke;
    final dotPaint = Paint()..color = AppColors.accent;
    final gridPaint = Paint()..color = const Color(0xFF22342C)..strokeWidth = 1;
    final path = Path();
    for (var index = 0; index < values.length; index++) {
      final x = values.length == 1 ? size.width / 2 : index * size.width / (values.length - 1);
      final y = size.height - ((values[index] - min) / (max - min)) * (size.height - 28) - 14;
      if (index == 0) path.moveTo(x, y); else path.lineTo(x, y);
      canvas.drawCircle(Offset(x, y), 5, dotPaint);
    }
    for (var index = 0; index < 3; index++) {
      final y = 14 + index * (size.height - 28) / 2;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant _WeightChartPainter oldDelegate) => oldDelegate.entries != entries;
}
