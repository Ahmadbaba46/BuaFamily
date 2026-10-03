import 'package:flutter/material.dart';

/// For pages that open on a coloured band with the back button on it (a
/// person, an event, a memorial): once the band scrolls away, a solid bar
/// with back, the title and the page's actions stays pinned at the top.
class HeroPage extends StatefulWidget {
  const HeroPage({
    super.key,
    required this.title,
    required this.color,
    required this.bandHeight,
    required this.onBack,
    required this.child,
    this.actions = const [],
  });

  final String title;
  final Color color;

  /// Height of the band; the bar appears once it has scrolled out of view.
  final double bandHeight;
  final VoidCallback onBack;
  final List<Widget> actions;

  /// The page's scroll view.
  final Widget child;

  @override
  State<HeroPage> createState() => _HeroPageState();
}

class _HeroPageState extends State<HeroPage> {
  bool _pinned = false;

  bool _onScroll(ScrollNotification n) {
    if (n.depth != 0 || n.metrics.axis != Axis.vertical) return false;
    final pinned = n.metrics.pixels > widget.bandHeight - kToolbarHeight;
    if (pinned != _pinned) setState(() => _pinned = pinned);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      NotificationListener<ScrollNotification>(onNotification: _onScroll, child: widget.child),
      Positioned(
        top: 0,
        left: 0,
        right: 0,
        // Only built while shown, so the page's title isn't there twice.
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 160),
          child: !_pinned
              ? const SizedBox.shrink()
              : Material(
                  color: widget.color,
                  elevation: 2,
                  child: SafeArea(
                    bottom: false,
                    child: SizedBox(
                      height: kToolbarHeight,
                      child: Row(children: [
                        const SizedBox(width: 4),
                        BackButton(color: Colors.white, onPressed: widget.onBack),
                        Expanded(
                          child: Text(
                            widget.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                        ),
                        ...widget.actions,
                        const SizedBox(width: 4),
                      ]),
                    ),
                  ),
                ),
        ),
      ),
    ]);
  }
}
