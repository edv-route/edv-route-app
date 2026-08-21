import '../entities/notification_item.dart';

/// The affiliate's inbox. Needs his session, like everything under `me`.
///
/// The inbox is not decoration around push: a push is swiped away and gone, and
/// there are drivers who will never receive one (Huawei without Play Services
/// since 2019, or the permission denied on Android 13+). For them this is the
/// only channel there is.
abstract interface class NotificationsRepository {
  /// One page, newest first. [before] continues from a previous page's cursor.
  Future<NotificationPage> load({int limit, String? before});

  /// Marks one as read. Idempotent: opening the same notice twice is not an error.
  Future<void> markRead(String id);

  /// Clears the bell in one go. Returns how many were marked.
  Future<int> markAllRead();

  /// Registers this phone to receive push. Idempotent: the app re-sends the
  /// token on every start and whenever FCM rotates it.
  Future<void> registerDevice(String deviceToken);

  /// Logout: stops this phone from receiving HIS notices. Not optional — the
  /// next person to use the handset must not get his amounts and rejections.
  Future<void> revokeDevice(String deviceToken);
}
