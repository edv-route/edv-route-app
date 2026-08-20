/// One notice in the affiliate's inbox (GET /driver-auth/me/notifications).
///
/// [title] and [body] arrive ALREADY WRITTEN by the backend. The app renders
/// them as they come and composes nothing: if the phone built the wording, the
/// inbox and the push would say different things, and fixing a word would mean
/// publishing an APK.
class NotificationItem {
  final String id;

  /// What happened (`payment_rejected`, `debt_overdue`…). Used ONLY to choose an
  /// icon and a colour — never to build the text.
  final String type;

  final String title;
  final String body;

  /// Structured context (amounts, ids, rejection reason) for the day a notice
  /// needs to open a specific screen. Everything the driver has to READ is
  /// already in [body].
  final Map<String, dynamic> payload;

  final DateTime createdAt;
  final DateTime? readAt;

  const NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    this.payload = const {},
    this.readAt,
  });

  bool get isUnread => readAt == null;

  NotificationItem markRead() => NotificationItem(
        id: id,
        type: type,
        title: title,
        body: body,
        payload: payload,
        createdAt: createdAt,
        readAt: readAt ?? DateTime.now(),
      );

  static NotificationItem fromJson(Map<String, dynamic> json) => NotificationItem(
        id: json['id'] as String,
        type: json['type'] as String? ?? '',
        title: json['title'] as String? ?? '',
        body: json['body'] as String? ?? '',
        payload: json['payload'] is Map
            ? (json['payload'] as Map).cast<String, dynamic>()
            : const {},
        createdAt:
            DateTime.tryParse(json['createdAt'] as String? ?? '')?.toLocal() ?? DateTime.now(),
        readAt: DateTime.tryParse(json['readAt'] as String? ?? '')?.toLocal(),
      );
}

/// A page of the inbox plus the badge count, which the backend recomputes on
/// every page so the bell can never drift from the list.
class NotificationPage {
  final List<NotificationItem> items;

  /// Pass to the next request to continue; null means there is nothing older.
  final String? nextCursor;
  final int unread;

  const NotificationPage({
    required this.items,
    this.nextCursor,
    this.unread = 0,
  });

  bool get hasMore => nextCursor != null;

  static NotificationPage fromJson(Map<String, dynamic> json) => NotificationPage(
        items: (json['items'] as List<dynamic>? ?? const [])
            .map((e) => NotificationItem.fromJson((e as Map).cast<String, dynamic>()))
            .toList(),
        nextCursor: json['nextCursor'] as String?,
        unread: (json['unread'] as num?)?.toInt() ?? 0,
      );
}
