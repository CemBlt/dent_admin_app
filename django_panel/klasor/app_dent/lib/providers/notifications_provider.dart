import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final String time;
  final bool isRead;
  final String type;

  const NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.type,
    this.isRead = false,
  });

  NotificationItem copyWith({
    String? id,
    String? title,
    String? message,
    String? time,
    bool? isRead,
    String? type,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      time: time ?? this.time,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
    );
  }
}

class NotificationsState {
  final bool isLoading;
  final List<NotificationItem> notifications;

  const NotificationsState({
    required this.isLoading,
    required this.notifications,
  });

  factory NotificationsState.initial() => const NotificationsState(
        isLoading: true,
        notifications: [],
      );

  NotificationsState copyWith({
    bool? isLoading,
    List<NotificationItem>? notifications,
  }) {
    return NotificationsState(
      isLoading: isLoading ?? this.isLoading,
      notifications: notifications ?? this.notifications,
    );
  }

  int get unreadCount =>
      notifications.where((notification) => !notification.isRead).length;
}

class NotificationsController extends StateNotifier<NotificationsState> {
  NotificationsController() : super(NotificationsState.initial()) {
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    state = state.copyWith(isLoading: true);
    await Future.delayed(const Duration(milliseconds: 500));

    final sample = [
      NotificationItem(
        id: '1',
        title: 'Randevu Hatırlatması',
        message: 'Yarın saat 10:00\'da Gülümseme Diş Kliniği\'nde randevunuz var.',
        time: '2 saat önce',
        type: 'reminder',
        isRead: false,
      ),
      NotificationItem(
        id: '2',
        title: 'Randevu Onaylandı',
        message: 'Randevunuz başarıyla oluşturuldu. 20 Şubat 2024, 14:00',
        time: '1 gün önce',
        type: 'appointment',
        isRead: false,
      ),
      NotificationItem(
        id: '3',
        title: 'Randevu Hatırlatması',
        message: 'Yaklaşan randevunuz: 15 Şubat 2024, 10:00',
        time: '2 gün önce',
        type: 'reminder',
        isRead: true,
      ),
      NotificationItem(
        id: '4',
        title: 'Sistem Güncellemesi',
        message: 'Yeni özellikler eklendi! Uygulamayı güncelleyin.',
        time: '3 gün önce',
        type: 'system',
        isRead: true,
      ),
      NotificationItem(
        id: '5',
        title: 'Randevu İptal Edildi',
        message: 'Randevunuz iptal edildi. Yeni bir randevu oluşturabilirsiniz.',
        time: '5 gün önce',
        type: 'appointment',
        isRead: true,
      ),
    ];

    state = state.copyWith(
      notifications: sample,
      isLoading: false,
    );
  }

  void markAsRead(String id) {
    final updated = state.notifications.map((notification) {
      if (notification.id == id) {
        return notification.copyWith(isRead: true);
      }
      return notification;
    }).toList();
    state = state.copyWith(notifications: updated);
  }

  void markAllAsRead() {
    final updated = state.notifications
        .map((notification) => notification.copyWith(isRead: true))
        .toList();
    state = state.copyWith(notifications: updated);
  }

  void deleteNotification(String id) {
    final updated =
        state.notifications.where((notification) => notification.id != id).toList();
    state = state.copyWith(notifications: updated);
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsController, NotificationsState>(
  (ref) => NotificationsController(),
);

