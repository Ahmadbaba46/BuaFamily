import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// Colours for charts: one hue for the data, a neutral for comparisons, and
/// recessive grid and axes (checked with the dataviz palette validator).
abstract final class ChartColors {
  static Color get series => Bua.green;
  static const previous = Color(0xFF9AA59E);
  static Color get grid => Bua.line;
  static Color get axisText => Bua.inkSubtle;
}

/// A metric over time: bars for counts, a line for "how many members". The
/// period before can be drawn as a dashed grey line. Tap or hover a point to
/// read it.
class TrendChart extends StatefulWidget {
  const TrendChart({
    super.key,
    required this.values,
    required this.labels,
    required this.format,
    this.previous,
    this.asLine = false,
    this.height = 220,
    this.seriesLabel,
    this.previousLabel,
  });

  final List<double> values;

  /// One per value, shown under the chart and in the tooltip.
  final List<String> labels;
  final String Function(double) format;

  /// The period before, same length as [values].
  final List<double>? previous;
  final bool asLine;
  final double height;
  final String? seriesLabel;
  final String? previousLabel;

  @override
  State<TrendChart> createState() => _TrendChartState();
}

class _TrendChartState extends State<TrendChart> {
  int? _selected;

  static const _left = 44.0;
  static const _bottom = 24.0;
  static const _top = 8.0;

  int? _indexAt(Offset p, Size size) {
    final n = widget.values.length;
    if (n == 0) return null;
    final w = size.width - _left;
    final i = ((p.dx - _left) / w * n).floor();
    return i.clamp(0, n - 1);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final size = Size(c.maxWidth, widget.height);
      void select(Offset p) => setState(() => _selected = _indexAt(p, size));
      return MouseRegion(
        onHover: (e) => select(e.localPosition),
        onExit: (_) => setState(() => _selected = null),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => select(d.localPosition),
          onHorizontalDragUpdate: (d) => select(d.localPosition),
          child: Stack(clipBehavior: Clip.none, children: [
            CustomPaint(
              size: size,
              painter: _TrendPainter(
                values: widget.values,
                previous: widget.previous,
                labels: widget.labels,
                format: widget.format,
                asLine: widget.asLine,
                selected: _selected,
              ),
            ),
            if (_selected != null) _tooltip(size),
          ]),
        ),
      );
    });
  }

  Widget _tooltip(Size size) {
    final i = _selected!;
    final n = widget.values.length;
    final step = (size.width - _left) / n;
    final x = _left + step * (i + 0.5);
    const width = 150.0;
    final double left = (x - width / 2).clamp(0.0, math.max(0.0, size.width - width)).toDouble();
    final prev = widget.previous != null && i < widget.previous!.length ? widget.previous![i] : null;
    return Positioned(
      left: left,
      top: 0,
      width: width,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Bua.ink,
            borderRadius: BorderRadius.circular(10),
            boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 8, offset: Offset(0, 2))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Text(widget.labels[i], style: const TextStyle(fontSize: 11, color: Color(0xFFCFD8D2))),
            Text(widget.format(widget.values[i]),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
            if (prev != null && widget.previousLabel != null)
              Text('${widget.previousLabel}: ${widget.format(prev)}',
                  style: const TextStyle(fontSize: 11, color: Color(0xFFCFD8D2))),
          ]),
        ),
      ),
    );
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter({
    required this.values,
    required this.previous,
    required this.labels,
    required this.format,
    required this.asLine,
    required this.selected,
  });

  final List<double> values;
  final List<double>? previous;
  final List<String> labels;
  final String Function(double) format;
  final bool asLine;
  final int? selected;

  static const left = _TrendChartState._left;
  static const bottom = _TrendChartState._bottom;
  static const top = _TrendChartState._top;

  /// A round top value for the axis: 1, 2, 2.5 or 5 × 10^n.
  static double niceMax(double v) {
    if (v <= 0) return 1;
    final mag = math.pow(10, (math.log(v) / math.ln10).floor()).toDouble();
    for (final f in const [1.0, 2.0, 2.5, 5.0, 10.0]) {
      if (v <= f * mag) return f * mag;
    }
    return 10 * mag;
  }

  void _text(Canvas canvas, String s, Offset at, {TextAlign align = TextAlign.left, double maxWidth = 80}) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: TextStyle(fontSize: 10.5, color: ChartColors.axisText)),
      textDirection: TextDirection.ltr,
      textAlign: align,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: maxWidth);
    final dx = switch (align) {
      TextAlign.right => at.dx - tp.width,
      TextAlign.center => at.dx - tp.width / 2,
      _ => at.dx,
    };
    tp.paint(canvas, Offset(dx, at.dy - tp.height / 2));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final n = values.length;
    if (n == 0) return;
    final plotW = size.width - left;
    final plotH = size.height - top - bottom;
    final maxV = niceMax([...values, ...?previous].fold<double>(0, math.max));
    double y(double v) => top + plotH * (1 - v / maxV);
    final step = plotW / n;
    double cx(int i) => left + step * (i + 0.5);

    // Grid: 0, half, top; values on the left.
    final grid = Paint()
      ..color = ChartColors.grid
      ..strokeWidth = 1;
    for (final f in const [0.0, 0.5, 1.0]) {
      final gy = y(maxV * f);
      canvas.drawLine(Offset(left, gy), Offset(size.width, gy), grid);
      _text(canvas, format(maxV * f), Offset(left - 6, gy), align: TextAlign.right, maxWidth: left - 6);
    }

    // Dates: first, middle and last.
    final marks = {0, n ~/ 2, n - 1};
    for (final i in marks) {
      _text(canvas, labels[i], Offset(cx(i), size.height - bottom / 2), align: TextAlign.center, maxWidth: 90);
    }

    // Selection crosshair.
    if (selected != null) {
      canvas.drawLine(
        Offset(cx(selected!), top),
        Offset(cx(selected!), top + plotH),
        Paint()
          ..color = Bua.inkSubtle.withValues(alpha: 0.5)
          ..strokeWidth = 1,
      );
    }

    final seriesPaint = Paint()..color = ChartColors.series;
    if (asLine) {
      final path = Path();
      for (var i = 0; i < n; i++) {
        final p = Offset(cx(i), y(values[i]));
        i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = ChartColors.series
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );
      if (n == 1) canvas.drawCircle(Offset(cx(0), y(values[0])), 4, seriesPaint);
    } else {
      // Bars with a 2px gap between them and rounded tops.
      final barW = math.max(1.0, step - 2);
      for (var i = 0; i < n; i++) {
        if (values[i] <= 0) continue;
        final rect = Rect.fromLTRB(cx(i) - barW / 2, y(values[i]), cx(i) + barW / 2, top + plotH);
        final r = Radius.circular(math.min(4, barW / 2));
        canvas.drawRRect(RRect.fromRectAndCorners(rect, topLeft: r, topRight: r),
            Paint()..color = selected == null || selected == i ? ChartColors.series : ChartColors.series.withValues(alpha: 0.55));
      }
    }

    // The period before: dashed grey line.
    final prev = previous;
    if (prev != null && prev.length == n) {
      final dash = Paint()
        ..color = ChartColors.previous
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      for (var i = 0; i < n - 1; i++) {
        final a = Offset(cx(i), y(prev[i]));
        final b = Offset(cx(i + 1), y(prev[i + 1]));
        final len = (b - a).distance;
        for (var d = 0.0; d < len; d += 8) {
          final t0 = d / len;
          final t1 = math.min(1.0, (d + 4) / len);
          canvas.drawLine(Offset.lerp(a, b, t0)!, Offset.lerp(a, b, t1)!, dash);
        }
      }
    }

    // Selected point: a marker with a ring of the surface around it.
    if (selected != null && asLine) {
      final p = Offset(cx(selected!), y(values[selected!]));
      canvas.drawCircle(p, 6, Paint()..color = Bua.surface);
      canvas.drawCircle(p, 4.5, seriesPaint);
    }
  }

  @override
  bool shouldRepaint(_TrendPainter old) =>
      old.values != values || old.previous != previous || old.selected != selected || old.asLine != asLine;
}

/// A tiny line for a KPI tile: the shape of the period, no axes.
class Sparkline extends StatelessWidget {
  const Sparkline({super.key, required this.values, this.height = 28});

  final List<double> values;
  final double height;

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size(double.infinity, height), painter: _SparkPainter(values));
}

class _SparkPainter extends CustomPainter {
  _SparkPainter(this.values);

  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;
    final maxV = values.fold<double>(0, math.max);
    if (maxV <= 0) {
      canvas.drawLine(Offset(0, size.height - 1), Offset(size.width, size.height - 1),
          Paint()..color = ChartColors.grid..strokeWidth = 2);
      return;
    }
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final p = Offset(size.width * i / (values.length - 1), size.height - 1 - (size.height - 2) * values[i] / maxV);
      i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = ChartColors.series
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_SparkPainter old) => old.values != values;
}

/// Horizontal bars for a breakdown: label, bar, value. Every value is
/// written out, so nothing depends on reading the bar's length alone.
class BreakdownBars extends StatelessWidget {
  const BreakdownBars({super.key, required this.rows, required this.format});

  final List<(String, double)> rows;
  final String Function(double) format;

  @override
  Widget build(BuildContext context) {
    final maxV = rows.fold<double>(0, (m, r) => math.max(m, r.$2));
    return Column(children: [
      for (final (label, value) in rows)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(children: [
            SizedBox(
              width: 110,
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: LayoutBuilder(
                builder: (context, c) => Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    height: 12,
                    width: maxV <= 0 ? 0 : math.max(3, c.maxWidth * value / maxV),
                    decoration: BoxDecoration(color: ChartColors.series, borderRadius: BorderRadius.circular(4)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 64,
              child: Text(format(value),
                  textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ]),
        ),
    ]);
  }
}
