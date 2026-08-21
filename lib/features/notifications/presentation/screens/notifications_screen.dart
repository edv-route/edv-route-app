import 'package:flutter/material.dart';

import '../../../../core/di.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../domain/entities/notification_item.dart';
import '../../../../shared/widgets/gradient_header.dart';
import '../../../../theme/app_colors.dart';
import '../widgets/notification_detail_sheet.dart';
import '../widgets/notification_tile.dart';

/// The affiliate's inbox, opened from the bell in the header.
///
/// Stacked, not a tab: notices are consulted and closed, they are not a place
/// where one *is* (that is what the island nav is for, and its slots are needed
/// for Viajes). Pops with the resulting unread count so the shell can repaint
/// the bell without asking the backend again.
///
/// Reading is not something the driver should have to DO. Opening a notice
/// marks it, because he has already read it by then — a separate "mark as read"
/// button would be an extra tap to tell the app what it just watched happen.
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _repository = Dependencies.instance.notificationsRepository;
  final _scroll = ScrollController();

  final List<NotificationItem> _items = [];
  String? _cursor;
  int _unread = 0;

  bool _loading = true;
  bool _loadingMore = false;
  bool _markingAll = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// Loads the next page well before the bottom, so the list never stops under
  /// the thumb waiting for the network.
  void _onScroll() {
    if (!_scroll.hasClients || _loadingMore || _cursor == null) return;
    if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 300) _loadMore();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await _repository.load();
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(page.items);
        _cursor = page.nextCursor;
        _unread = page.unread;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    try {
      final page = await _repository.load(before: _cursor);
      if (!mounted) return;
      setState(() {
        _items.addAll(page.items);
        _cursor = page.nextCursor;
        _unread = page.unread;
        _loadingMore = false;
      });
    } on ApiException {
      // A failed page is not worth an error screen over a list that already has
      // content: the scroll listener retries on the next nudge.
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  /// Marks locally FIRST and then tells the backend. The notice is already open
  /// in front of him; making him wait for a round trip to see it stop looking
  /// unread would be the app doubting what he just did. If the call fails, the
  /// row stays read on screen and the next refresh brings back the truth.
  Future<void> _open(NotificationItem item) async {
    if (item.isUnread) {
      final index = _items.indexOf(item);
      setState(() {
        _items[index] = item.markRead();
        if (_unread > 0) _unread--;
      });
      unawaited(_repository.markRead(item.id));
    }
    // Opening it is the point. The list can only show a summary; this is where
    // he reads the whole thing — above all the reason a payment was turned down,
    // which is what he has to act on.
    await showNotificationDetail(context, item);
  }

  Future<void> _markAll() async {
    setState(() => _markingAll = true);
    try {
      await _repository.markAllRead();
      if (!mounted) return;
      setState(() {
        for (var i = 0; i < _items.length; i++) {
          _items[i] = _items[i].markRead();
        }
        _unread = 0;
        _markingAll = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _markingAll = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    // The count goes back with the pop: the bell is owned by the shell, and it
    // must not have to re-ask the backend for something this screen already knows.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_unread);
      },
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: Column(
          children: [
            _header(context),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return GradientHeader(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 4, 16, 16),
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).pop(_unread),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              tooltip: 'Volver',
            ),
            const Expanded(
              child: Text(
                'Avisos',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (_unread > 0)
              TextButton(
                onPressed: _markingAll ? null : _markAll,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  backgroundColor: Colors.white24,
                  shape: const StadiumBorder(),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: _markingAll
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Marcar todo',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return _errorState();
    if (_items.isEmpty) return _emptyState();

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: _items.length + (_cursor == null ? 0 : 1),
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          if (index >= _items.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            );
          }
          final item = _items[index];
          return NotificationTile(item: item, onTap: () => _open(item));
        },
      ),
    );
  }

  Widget _emptyState() {
    return LayoutBuilder(
      builder: (context, constraints) => RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 80),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.notifications_none_rounded, size: 56, color: AppColors.muted),
                  SizedBox(height: 14),
                  Text(
                    'No tienes avisos',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Aquí te avisamos de tus cobros, tus pagos y las respuestas de la oficina.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: AppColors.muted, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _errorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.muted),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.muted, height: 1.4),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _load,
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fire-and-forget without importing `dart:async` just for this: marking a
/// notice read must never block the UI, and its failure is not the driver's
/// problem — the next refresh corrects it.
void unawaited(Future<void> future) {
  future.catchError((_) {});
}
