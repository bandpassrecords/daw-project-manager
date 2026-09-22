import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart'
    if (dart.library.html) 'package:window_manager/window_manager_stub.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../providers/providers.dart';
import '../../utils/mobile_utils.dart';

/// Icon for the maximize/restore window-control button: a single square
/// when the window can still be maximized, two overlapping squares once it
/// already is (native Windows/Linux window-control convention).
@visibleForTesting
IconData windowMaximizeToggleIcon(bool isMaximized) =>
    isMaximized ? Icons.filter_none : Icons.crop_square_sharp;

/// A cross-platform desktop title bar widget.
///
/// **Windows / Linux (release mode):** Renders a full custom title bar with a
/// draggable area, title, optional back button, optional extra [actions], and
/// native-style window control buttons (minimize / maximize / close).
///
/// **macOS:** [TitleBarStyle.hidden] + fullSizeContentView is used so Flutter
/// content fills the entire window and the traffic-light buttons float over it.
/// This widget reserves 28 pt at the top when [showBack] is false, or renders
/// a slim back-navigation bar when [showBack] is true.
///
/// **Mobile / web:** Returns an empty widget.
class DesktopTitleBar extends ConsumerStatefulWidget {
  final String title;

  /// Show a back button that calls [Navigator.pop].
  final bool showBack;

  /// Extra action widgets placed before the window buttons.
  /// Only shown on Windows / Linux (not on macOS where they belong in the
  /// native menu bar via [MacOSMenuBar]).
  final List<Widget> actions;

  const DesktopTitleBar({
    super.key,
    required this.title,
    this.showBack = false,
    this.actions = const [],
  });

  @override
  ConsumerState<DesktopTitleBar> createState() => _DesktopTitleBarState();
}

class _DesktopTitleBarState extends ConsumerState<DesktopTitleBar>
    with WindowListener {
  /// Identity of this bar's breadcrumb, stable for the life of the widget.
  ///
  /// The title bar is the one thing every page already has, which is what
  /// makes it the right place to register the trail — no page has to know
  /// breadcrumbs exist, and the trail can only ever describe pages that are
  /// really on screen.
  late final String _crumbId = _nextCrumbId();

  /// Captured while the element is still active. Looking the container up in
  /// dispose() is unsafe — the ancestor lookup asserts once the widget is
  /// deactivated — and the notifier outlives every page, so holding it is
  /// safe where holding a BuildContext would not be.
  BreadcrumbTrailNotifier? _trail;
  // Manual double-tap detection for the drag area — avoids placing a
  // DoubleTapGestureRecognizer over the entire bar (which would delay the
  // window-control buttons by the double-tap timeout).
  DateTime? _lastDragAreaTap;

  bool _isMaximized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _trail = ref.read(breadcrumbTrailProvider.notifier);
    _registerCrumb();
  }

  @override
  void initState() {
    super.initState();
    if (!kIsWeb && !MobileUtils.isMobile()) {
      windowManager.addListener(this);
      windowManager.isMaximized().then((maximized) {
        if (mounted) setState(() => _isMaximized = maximized);
      });
    }
  }

  @override
  void didUpdateWidget(DesktopTitleBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A page can rename itself while open — a release being retitled, say.
    if (widget.title != oldWidget.title) _registerCrumb();
  }

  @override
  void dispose() {
    // Deferred: dispose runs during a frame, and a provider write here would
    // land mid-build for whatever is replacing this page.
    final id = _crumbId;
    final trail = _trail;
    if (trail != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => trail.remove(id));
    }
    if (!kIsWeb && !MobileUtils.isMobile()) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  /// Puts this page's title into the trail. Deferred for the same reason the
  /// removal is: initState runs while the route above is still building.
  void _registerCrumb() {
    final crumb = Breadcrumb(id: _crumbId, label: widget.title);
    final trail = _trail;
    if (trail == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      trail.push(crumb);
    });
  }

  /// Pops back to the page at [index] in the trail.
  void _goToCrumb(int index, int length) {
    final pops = breadcrumbPopCount(index: index, length: length);
    if (pops <= 0) return;
    var popped = 0;
    Navigator.of(context).popUntil((_) => popped++ >= pops);
  }

  @override
  void onWindowMaximize() {
    if (mounted) setState(() => _isMaximized = true);
  }

  @override
  void onWindowUnmaximize() {
    if (mounted) setState(() => _isMaximized = false);
  }

  void _handleDragAreaTap() {
    final now = DateTime.now();
    if (_lastDragAreaTap != null &&
        now.difference(_lastDragAreaTap!) < const Duration(milliseconds: 350)) {
      _lastDragAreaTap = null;
      _toggleMaximize();
    } else {
      _lastDragAreaTap = now;
    }
  }

  Future<void> _toggleMaximize() async {
    if (await windowManager.isMaximized()) {
      windowManager.restore();
    } else {
      windowManager.maximize();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || MobileUtils.isMobile()) {
      return const SizedBox.shrink();
    }

    // macOS: TitleBarStyle.hidden + fullSizeContentView means Flutter content
    // starts at y=0, with the traffic lights floating over the top-left area.
    // Reserve 28pt at the top so content doesn't slide under the buttons.
    if (Platform.isMacOS) {
      if (!widget.showBack) {
        // Drag and double-click-to-maximize are handled natively in
        // MainFlutterWindow.swift via NSEvent monitors — no Flutter
        // gesture detection needed here.
        return const SizedBox(height: 28, width: double.infinity);
      }
      return Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border(
            bottom: BorderSide(color: Theme.of(context).dividerColor, width: 1),
          ),
        ),
        height: 40,
        child: Row(
          children: [
            // Reserve space for macOS traffic lights (~75pt from left edge).
            const SizedBox(width: 75),
            IconButton(
              icon: Icon(
                Icons.arrow_back,
                size: 20,
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
              onPressed: () => Navigator.pop(context),
              tooltip: AppLocalizations.of(context)!.back,
            ),
            Flexible(
              child: _TitleOrTrail(
                title: widget.title,
                fontSize: 15,
                onCrumbTap: _goToCrumb,
              ),
            ),
          ],
        ),
      );
    }

    // Windows / Linux: full custom title bar.
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      height: 40,
      child: Row(
        children: [
          // ── Drag area: pan-to-drag + manual double-tap-to-maximize ──────────
          // The GestureDetector here covers only the title/drag region, NOT the
          // window-control buttons. This prevents DoubleTapGestureRecognizer
          // from delaying button tap callbacks.
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onPanStart: (_) => windowManager.startDragging(),
              onTapDown: (_) => _handleDragAreaTap(),
              child: SizedBox.expand(
                child: Row(
                  children: [
                    if (widget.showBack)
                      IconButton(
                        icon: Icon(
                          Icons.arrow_back,
                          size: 20,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    Flexible(
                      child: Padding(
                        padding:
                            EdgeInsets.only(left: widget.showBack ? 4 : 12),
                        child: _TitleOrTrail(
                          title: widget.title,
                          fontSize: 16,
                          bold: !widget.showBack,
                          onCrumbTap: _goToCrumb,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // ── Window controls: completely outside the drag-area detector ──────
          ...widget.actions,
          _WindowControlButtons(
            isMaximized: _isMaximized,
            onToggleMaximize: _toggleMaximize,
          ),
        ],
      ),
    );
  }
}

/// Minimize / Maximize / Close buttons for Windows and Linux only.
class _WindowControlButtons extends StatelessWidget {
  final bool isMaximized;
  final VoidCallback onToggleMaximize;

  const _WindowControlButtons({
    required this.isMaximized,
    required this.onToggleMaximize,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(Icons.minimize, size: 18,
              color: Theme.of(context).textTheme.bodyMedium?.color),
          onPressed: () => windowManager.minimize(),
        ),
        IconButton(
          icon: Icon(
            windowMaximizeToggleIcon(isMaximized),
            size: isMaximized ? 15 : 18,
            color: Theme.of(context).textTheme.bodyMedium?.color,
          ),
          onPressed: onToggleMaximize,
        ),
        IconButton(
          icon: Icon(Icons.close, size: 18,
              color: Theme.of(context).textTheme.bodyMedium?.color),
          onPressed: () => windowManager.close(),
          highlightColor: const Color(0xFFC42B1C),
        ),
      ],
    );
  }
}

/// Monotonic ids for breadcrumb entries — unique per title bar instance, so
/// two pages that happen to share a title still remove the right entry.
int _crumbSeq = 0;
String _nextCrumbId() => 'crumb-${_crumbSeq++}';

/// The title bar's text: a breadcrumb trail once the user is more than one
/// page deep, and the plain title otherwise.
///
/// Falls back to the plain title whenever the trail does not end on this page
/// — during the frame after a push or pop, the trail and the widget tree are
/// briefly out of step, and showing a stale path is worse than showing none.
class _TitleOrTrail extends ConsumerWidget {
  const _TitleOrTrail({
    required this.title,
    required this.fontSize,
    required this.onCrumbTap,
    this.bold = false,
  });

  final String title;
  final double fontSize;
  final bool bold;
  final void Function(int index, int length) onCrumbTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final color = theme.textTheme.titleMedium?.color;
    final trail = ref.watch(breadcrumbTrailProvider);

    final plain = Text(
      title,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
      ),
    );

    // One entry is the root page: a trail of one is just the title.
    if (trail.length < 2) return plain;
    if (trail.last.label != title) return plain;

    final muted = color?.withValues(alpha: 0.6);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      // The trail can outgrow a narrow window; scrolling it keeps the window
      // controls reachable instead of overflowing the bar.
      reverse: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < trail.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Icon(Icons.chevron_right, size: 16, color: muted),
              ),
            if (i == trail.length - 1)
              Text(
                trail[i].label,
                style: TextStyle(color: color, fontSize: fontSize),
              )
            else
              InkWell(
                onTap: () => onCrumbTap(i, trail.length),
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Text(
                    trail[i].label,
                    style: TextStyle(color: muted, fontSize: fontSize),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
