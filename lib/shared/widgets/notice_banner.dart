import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

/// A notice that arrived WHILE THE APP IS OPEN, shown the way the system shows
/// a push: a card that drops from the top, over the status bar area, and leaves
/// on its own.
///
/// It replaces a Material `SnackBar` at the bottom, which read as a debug
/// message: grey slab, wrong end of the screen, and nothing to do with a phone
/// notification. Android draws nothing itself while the app is in the
/// foreground, so this IS the notification as far as the driver is concerned —
/// it has to look like one.
///
/// Dismisses by tap (which also opens it), by swiping UP, or on its own after a
/// few seconds. Never blocks what is underneath.
void showNoticeBanner(
  BuildContext context, {
  required String title,
  required String body,
  required VoidCallback onTap,
}) {
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;

  late OverlayEntry entry;
  entry = OverlayEntry(
    builder: (_) => _NoticeBanner(
      title: title,
      body: body,
      onTap: () {
        entry.remove();
        onTap();
      },
      onDismiss: entry.remove,
    ),
  );
  overlay.insert(entry);
}

class _NoticeBanner extends StatefulWidget {
  final String title;
  final String body;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NoticeBanner({
    required this.title,
    required this.body,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  State<_NoticeBanner> createState() => _NoticeBannerState();
}

class _NoticeBannerState extends State<_NoticeBanner> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
    reverseDuration: const Duration(milliseconds: 200),
  );
  late final Animation<Offset> _slide = Tween(
    begin: const Offset(0, -1.2),
    end: Offset.zero,
    // A slight overshoot on the way in is what makes it feel like it LANDED
    // instead of appearing; linear entrances read as cheap.
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

  Timer? _timer;
  bool _leaving = false;

  @override
  void initState() {
    super.initState();
    _controller.forward();
    // Long enough to read two lines without hurry, short enough not to sit on
    // top of what he was doing.
    _timer = Timer(const Duration(seconds: 5), _leave);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _leave() async {
    if (_leaving || !mounted) return;
    _leaving = true;
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slide,
        child: Padding(
          padding: EdgeInsets.fromLTRB(12, topInset + 8, 12, 0),
          child: Material(
            color: Colors.transparent,
            child: Dismissible(
              key: const ValueKey('notice-banner'),
              direction: DismissDirection.up,
              onDismissed: (_) => widget.onDismiss(),
              child: InkWell(
                onTap: widget.onTap,
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
                  decoration: BoxDecoration(
                    // The brand gradient, the same one the header wears: the
                    // notice belongs to the app, it is not a system chip.
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.gradientStart, AppColors.gradientEnd],
                    ),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x40000000),
                        blurRadius: 18,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: AppColors.gold,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.notifications_rounded,
                              size: 15,
                              color: AppColors.primary900,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              widget.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const Text(
                            'ahora',
                            style: TextStyle(color: Colors.white54, fontSize: 11.5),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Text(
                        widget.body,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // The grabber doubles as the affordance: it says the card
                      // can be pushed away, without spending a row on a button.
                      Center(
                        child: Container(
                          width: 34,
                          height: 3,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
