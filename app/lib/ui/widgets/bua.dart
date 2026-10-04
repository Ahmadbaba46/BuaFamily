import 'package:flutter/material.dart';

import '../theme.dart';

/// The zanen-gida motif: nested diamonds with gold centres, tiled.
class ZanenGidaPainter extends CustomPainter {
  const ZanenGidaPainter({this.goldOpacity = 0.35, this.whiteOpacity = 0.10});

  final double goldOpacity;
  final double whiteOpacity;

  static const _tile = 48.0;

  @override
  void paint(Canvas canvas, Size size) {
    final outer = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Bua.gold.withValues(alpha: goldOpacity);
    final inner = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Colors.white.withValues(alpha: whiteOpacity);
    final dot = Paint()..color = Bua.gold.withValues(alpha: goldOpacity + 0.1);

    for (var y = 0.0; y < size.height; y += _tile) {
      for (var x = 0.0; x < size.width; x += _tile) {
        final c = Offset(x + _tile / 2, y + _tile / 2);
        canvas.drawPath(_diamond(c, 22), outer);
        canvas.drawPath(_diamond(c, 12), inner);
        canvas.drawCircle(c, 2.5, dot);
      }
    }
  }

  Path _diamond(Offset c, double r) => Path()
    ..moveTo(c.dx, c.dy - r)
    ..lineTo(c.dx + r, c.dy)
    ..lineTo(c.dx, c.dy + r)
    ..lineTo(c.dx - r, c.dy)
    ..close();

  @override
  bool shouldRepaint(ZanenGidaPainter old) => old.goldOpacity != goldOpacity || old.whiteOpacity != whiteOpacity;
}

/// A coloured band with the zanen-gida pattern behind [child].
class PatternBand extends StatelessWidget {
  const PatternBand({super.key, required this.height, this.color, this.child});

  final double height;
  final Color? color;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final color = this.color ?? Bua.green;
    return SizedBox(
      height: height,
      child: ClipRect(
        child: DecoratedBox(
          decoration: BoxDecoration(color: color),
          child: CustomPaint(
            painter: ZanenGidaPainter(goldOpacity: color == Bua.green ? 0.35 : 0.28),
            child: child ?? const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}

/// White rounded card with an uppercase green title, as used on profiles.
class SectionCard extends StatelessWidget {
  const SectionCard({super.key, this.title, this.trailing, required this.children, this.padding});

  final String? title;
  final Widget? trailing;
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Bua.surface, borderRadius: BorderRadius.all(Radius.circular(20))),
      padding: padding ?? const EdgeInsets.only(top: 6, bottom: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (title != null)
          Padding(
            padding: EdgeInsets.fromLTRB(16, trailing == null ? 12 : 4, trailing == null ? 16 : 4, 4),
            child: Row(children: [
              Expanded(child: CardTitle(title!)),
              ?trailing,
            ]),
          ),
        ...children,
      ]),
    );
  }
}

class CardTitle extends StatelessWidget {
  const CardTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.4, color: Bua.green),
      );
}

/// Small grey label above a group of rows inside a card.
class SubLabel extends StatelessWidget {
  const SubLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 2),
        child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Bua.inkSubtle)),
      );
}

/// Grey heading between cards on list pages.
class GroupHeading extends StatelessWidget {
  const GroupHeading(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 0),
        child: Text(text, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Bua.inkMuted)),
      );
}

enum BannerTone { gold, green, danger }

class InfoBanner extends StatelessWidget {
  const InfoBanner({super.key, required this.icon, required this.text, this.tone = BannerTone.gold});

  final IconData icon;
  final String text;
  final BannerTone tone;

  @override
  Widget build(BuildContext context) {
    final (bg, border, fg, textColor) = switch (tone) {
      BannerTone.gold => (Bua.goldTint, Bua.goldLine, Bua.goldInk, Bua.goldInkDark),
      BannerTone.green => (Bua.greenTint, Bua.greenIndicator, Bua.green, Bua.greenDark),
      BannerTone.danger => (
        Bua.dangerTint,
        Bua.dark ? const Color(0xFF5A2A26) : const Color(0xFFF1C4BF),
        Bua.danger,
        Bua.dark ? Bua.dangerInk : const Color(0xFF6B2520),
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 20, color: fg),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: TextStyle(fontSize: 13, height: 1.45, color: textColor))),
      ]),
    );
  }
}

/// 40×40 rounded icon square used at the start of rows and cards.
class IconTile extends StatelessWidget {
  const IconTile(this.icon, {super.key, this.background, this.color, this.size = 40});

  final IconData icon;
  final Color? background;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final background = this.background ?? Bua.surfaceMuted;
    final color = this.color ?? Bua.green;
    return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(size * 0.3)),
        child: Icon(icon, size: size / 2, color: color),
      );
  }
}

/// Small rounded label, e.g. "PENDING" or "Shared with family".
class Pill extends StatelessWidget {
  const Pill(this.text, {super.key, this.background, this.color, this.icon});

  final String text;
  final Color? background;
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final background = this.background ?? Bua.greenTint;
    final color = this.color ?? Bua.greenDark;
    return Container(
        height: 26,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(13)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon, size: 13, color: color), const SizedBox(width: 5)],
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
            ),
          ),
        ]),
      );
  }
}

/// Grey track with a white selected segment (language, visibility, …).
class PillSegmented<T> extends StatelessWidget {
  const PillSegmented({
    super.key,
    required this.values,
    required this.labelOf,
    required this.selected,
    required this.onChanged,
    this.height = 40,
    this.expand = false,
  });

  final List<T> values;
  final String Function(T) labelOf;
  final T selected;
  final ValueChanged<T> onChanged;
  final double height;

  /// Fill the available width, sharing it equally (long labels shrink).
  final bool expand;

  @override
  Widget build(BuildContext context) {
    Widget wrap(Widget child) => expand ? Expanded(child: child) : child;
    final pill = Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Bua.track, borderRadius: BorderRadius.circular(height)),
      child: Row(mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min, children: [
        for (final v in values)
          wrap(Semantics(
              selected: v == selected,
              button: true,
              child: InkWell(
                borderRadius: BorderRadius.circular(height),
                onTap: () => onChanged(v),
                child: Container(
                  height: height,
                  alignment: Alignment.center,
                  decoration: v == selected
                      ? BoxDecoration(
                          color: Bua.surface,
                          borderRadius: BorderRadius.circular(height),
                          boxShadow: const [BoxShadow(color: Color(0x1F000000), blurRadius: 3, offset: Offset(0, 1))],
                        )
                      : null,
                  padding: EdgeInsets.symmetric(horizontal: expand ? 8 : 18),
                  child: Text(
                    labelOf(v),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: v == selected ? FontWeight.w600 : FontWeight.w500,
                      color: v == selected ? Bua.ink : Bua.inkMuted,
                    ),
                  ),
                ),
              ),
            )),
      ]),
    );
    // With larger text, a toggle that doesn't fill the row shrinks to fit it.
    return expand ? pill : FittedBox(fit: BoxFit.scaleDown, alignment: AlignmentDirectional.centerStart, child: pill);
  }
}

/// A label above a form field, as in the design.
class LabeledField extends StatelessWidget {
  const LabeledField({super.key, required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Bua.inkMuted)),
        const SizedBox(height: 6),
        child,
      ]);
}

/// Title + optional subtitle with a trailing switch, full-row tappable.
class ToggleRow extends StatelessWidget {
  const ToggleRow({super.key, required this.title, this.subtitle, required this.value, required this.onChanged});

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: InkWell(
        onTap: onChanged == null ? null : () => onChanged!(!value),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                if (subtitle != null)
                  Text(subtitle!, style: TextStyle(fontSize: 12, height: 1.4, color: Bua.inkSubtle)),
              ]),
            ),
            const SizedBox(width: 12),
            Switch(value: value, onChanged: onChanged),
          ]),
        ),
      ),
    );
  }
}

/// Tappable settings-style row: icon, title, optional value and chevron.
class NavRow extends StatelessWidget {
  const NavRow({
    super.key,
    required this.icon,
    required this.title,
    this.value,
    this.onTap,
    this.color,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String? value;
  final VoidCallback? onTap;
  final Color? color;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final color = this.color ?? Bua.ink;
    final iconColor = this.iconColor ?? Bua.green;
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: 14),
            Expanded(child: Text(title, style: TextStyle(fontSize: 15, color: color))),
            if (value != null) Text(value!, style: TextStyle(fontSize: 12, color: Bua.inkSubtle)),
            if (onTap != null && color == Bua.ink) ...[
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, size: 20, color: Bua.inkSubtle),
            ],
          ]),
        ),
      ),
    );
  }
}

/// Divider indented past a leading icon or avatar.
class InsetDivider extends StatelessWidget {
  const InsetDivider({super.key, this.indent = 50});

  final double indent;

  @override
  Widget build(BuildContext context) => Divider(indent: indent, height: 1);
}

/// A rounded box with a dashed outline, for "record" and "choose a file" areas.
class DashedBox extends StatelessWidget {
  const DashedBox({super.key, required this.child, this.onTap, this.color, this.fill});

  final Widget child;
  final VoidCallback? onTap;
  final Color? color;
  final Color? fill;

  @override
  Widget build(BuildContext context) {
    final color = this.color ?? Bua.lineStrong;
    return CustomPaint(
      painter: _DashedBorderPainter(color),
      child: Material(
        color: fill ?? Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(onTap: onTap, child: child),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(20)).deflate(0.75));
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 10) {
        canvas.drawPath(metric.extractPath(d, d + 6), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) => old.color != color;
}
