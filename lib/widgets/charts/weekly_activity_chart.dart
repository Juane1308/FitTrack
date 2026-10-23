import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../models/app_models.dart';

class WeeklyActivityChart extends StatelessWidget {
  const WeeklyActivityChart({required this.points, super.key});

  final List<WeeklyProgressPoint> points;

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return const SizedBox(height: 150, child: Center(child: Text('Aún no hay actividad registrada.')));
    }
    return SizedBox(height: 170, child: CustomPaint(painter: _WeeklyActivityPainter(points), child: const SizedBox.expand()));
  }
}

class _WeeklyActivityPainter extends CustomPainter {
  _WeeklyActivityPainter(this.points);

  final List<WeeklyProgressPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    final baseline = size.height - 28;
    final chartHeight = size.height - 48;
    final gridPaint = Paint()..color = const Color(0xFF22342C);
    final barPaint = Paint()..color = AppColors.primary;
    final mutedBarPaint = Paint()..color = const Color(0xFF29463A);
    final slotWidth = size.width / points.length;
    final barWidth = slotWidth * .42;
    for (var line = 0; line <= 3; line++) {
      final y = baseline - chartHeight * (line / 3);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    for (var index = 0; index < points.length; index++) {
      final point = points[index];
      final x = slotWidth * index + (slotWidth - barWidth) / 2;
      final height = point.planned ? (point.completed ? chartHeight * .88 : chartHeight * .42) : chartHeight * .14;
      final rect = RRect.fromRectAndRadius(Rect.fromLTWH(x, baseline - height, barWidth, height), const Radius.circular(7));
      canvas.drawRRect(rect, point.completed ? barPaint : mutedBarPaint);
      final labelPainter = TextPainter(
        text: TextSpan(text: point.label, style: TextStyle(color: point.completed ? AppColors.primary : AppColors.mutedText, fontSize: 11, fontWeight: point.completed ? FontWeight.w800 : FontWeight.normal)),
        textDirection: TextDirection.ltr,
      )..layout();
      labelPainter.paint(canvas, Offset(x + (barWidth - labelPainter.width) / 2, baseline + 8));
    }
  }

  @override
  bool shouldRepaint(covariant _WeeklyActivityPainter oldDelegate) => oldDelegate.points != points;
}
