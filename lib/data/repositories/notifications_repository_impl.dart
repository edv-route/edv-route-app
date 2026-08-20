import '../../core/storage/token_storage.dart';
import '../../domain/entities/notification_item.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../datasources/driver_remote_data_source.dart';
import 'session_bound_repository.dart';

class NotificationsRepositoryImpl extends SessionBoundRepository
    implements NotificationsRepository {
  const NotificationsRepositoryImpl(this._remote, TokenStorage tokenStorage) : super(tokenStorage);

  final DriverRemoteDataSource _remote;

  @override
  Future<NotificationPage> load({int limit = 20, String? before}) async {
    return NotificationPage.fromJson(
      await _remote.notifications(token: await requireToken(), limit: limit, before: before),
    );
  }

  @override
  Future<void> markRead(String id) async {
    await _remote.markNotificationRead(id, token: await requireToken());
  }

  @override
  Future<int> markAllRead() async {
    final json = await _remote.markAllNotificationsRead(token: await requireToken());
    return (json['marked'] as num?)?.toInt() ?? 0;
  }
}
