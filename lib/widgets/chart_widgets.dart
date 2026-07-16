import 'dart:math' as math;
import 'package:flutter/material.dart';

/// 柱状图组件（纯CustomPainter实现）
class BarChart extends StatelessWidget {
  final List<BarChartData> data;
  final double barWidth;
  final double maxBarHeight;
  final Color barColor;
  final Color gridColor;
  final String? Function(int index)? labelBuilder;

  const BarChart({
    super.key,
    required this.data,
    this.barWidth = 24,
    this.maxBarHeight = 160,
    required this.barColor,
    required this.gridColor,
    this.labelBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return CustomPaint(
      size: Size.infinite,
      painter: _BarChartPainter(
        data: data,
        barWidth: barWidth,
        maxBarHeight: maxBarHeight,
        barColor: barColor ?? colorScheme.primary,
        gridColor: gridColor ?? colorScheme.outlineVariant.withOpacity(0.2),
        labelBuilder: labelBuilder,
      ),
    );
  }
}

class BarChartData {
  final String label;
  final double value;
  final Color? color;

  const BarChartData({
    required this.label,
    required this.value,
    this.color,
  });
}

class _BarChartPainter extends CustomPainter {
  final List<BarChartData> data;
  final double barWidth;
  final double maxBarHeight;
  final Color barColor;
  final Color gridColor;
  final String? Function(int index)? labelBuilder;

  _BarChartPainter({
    required this.data,
    required this.barWidth,
    required this.maxBarHeight,
    required this.barColor,
    required this.gridColor,
    this.labelBuilder,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final maxValue = data.map((d) => d.value).reduce(math.max);
    if (maxValue == 0) return;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final totalWidth = data.length * (barWidth + 12);
    final startX = (size.width - totalWidth) / 2;
    if (startX < 0) return;

    for (int i = 0; i < data.length; i++) {
      final item = data[i];
      final barH = (item.value / maxValue) * maxBarHeight;
      final x = startX + i * (barWidth + 12);
      final y = size.height - barH - 24;

      final barPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = item.color ?? barColor;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barWidth, barH),
          const Radius.circular(4),
        ),
        barPaint,
      );

      textPainter.text = TextSpan(
        text: '${item.value.toInt()}',
        style: TextStyle(fontSize: 10, color: barColor.withOpacity(0.8)),
      );
      textPainter.layout();
      textPainter.paint(
        canvas, Offset(x + (barWidth - textPainter.width) / 2, y - 14),
      );

      final label = labelBuilder != null ? labelBuilder!(i) : item.label;
      textPainter.text = TextSpan(text: label, style: const TextStyle(fontSize: 9));
      textPainter.layout();
      textPainter.paint(
        canvas, Offset(x + (barWidth - textPainter.width) / 2, size.height - 18),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) =>
      oldDelegate.data != data;
}

/// 折线图组件（纯CustomPainter实现）
class LineChartWidget extends StatelessWidget {
  final List<LineChartPoint> points;
  final Color lineColor;
  final Color fillColor;
  final Color pointColor;
  final double lineWidth;
  final String? Function(int index)? labelBuilder;

  const LineChartWidget({
    super.key,
    required this.points,
    required this.lineColor,
    required this.fillColor,
    required this.pointColor,
    this.lineWidth = 2.0,
    this.labelBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return CustomPaint(
      size: Size.infinite,
      painter: _LineChartPainter(
        points: points,
        lineColor: lineColor ?? colorScheme.primary,
        fillColor: fillColor ?? colorScheme.primary.withOpacity(0.15),
        pointColor: pointColor ?? colorScheme.primary,
        lineWidth: lineWidth,
        labelBuilder: labelBuilder,
      ),
    );
  }
}

class LineChartPoint {
  final String label;
  final double value;

  const LineChartPoint({required this.label, required this.value});
}

class _LineChartPainter extends CustomPainter {
  final List<LineChartPoint> points;
  final Color lineColor;
  final Color fillColor;
  final Color pointColor;
  final double lineWidth;
  final String? Function(int index)? labelBuilder;

  _LineChartPainter({
    required this.points,
    required this.lineColor,
    required this.fillColor,
    required this.pointColor,
    required this.lineWidth,
    this.labelBuilder,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final maxValue = points.map((p) => p.value).reduce(math.max);
    if (maxValue == 0) return;

    final chartHeight = size.height - 30;
    final padding = 20.0;
    final stepX = points.length > 1
        ? (size.width - padding * 2) / (points.length - 1)
        : 0.0;

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = lineWidth
      ..color = lineColor
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()..style = PaintingStyle.fill..color = fillColor;
    final dotPaint = Paint()..style = PaintingStyle.fill..color = pointColor;

    final pathPoints = <Offset>[];
    for (int i = 0; i < points.length; i++) {
      final x = points.length > 1 ? padding + i * stepX : size.width / 2;
      final y = chartHeight - (points[i].value / maxValue) * (chartHeight - 20);
      pathPoints.add(Offset(x, y));
    }

    if (pathPoints.length >= 2) {
      final fillPath = Path()
        ..moveTo(pathPoints.first.dx, chartHeight);
      for (final pt in pathPoints) fillPath.lineTo(pt.dx, pt.dy);
      fillPath.lineTo(pathPoints.last.dx, chartHeight);
      fillPath.close();
      canvas.drawPath(fillPath, fillPaint);

      final linePath = Path()
        ..moveTo(pathPoints.first.dx, pathPoints.first.dy);
      for (int i = 1; i < pathPoints.length; i++) {
        linePath.lineTo(pathPoints[i].dx, pathPoints[i].dy);
      }
      canvas.drawPath(linePath, linePaint);
    }

    for (final pt in pathPoints) canvas.drawCircle(pt, 3, dotPaint);

    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 0; i < points.length; i++) {
      final label = labelBuilder != null ? labelBuilder!(i) : points[i].label;
      textPainter.text = TextSpan(text: label, style: const TextStyle(fontSize: 9));
      textPainter.layout();
      textPainter.paint(
        canvas, Offset(pathPoints[i].dx - textPainter.width / 2, chartHeight + 6),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) =>
      oldDelegate.points != points;
}
