import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class NotificationItem {
  final String id;
  final String title;
  final String message;
  final String time;
  final bool isRead;
  final String type; // appointment, reminder, system

  NotificationItem({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    this.isRead = false,
    required this.type,
  });
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationItem> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    // Örnek bildirimler (ileride JSON'dan gelecek)
    await Future.delayed(const Duration(milliseconds: 500));
    
    setState(() {
      _notifications = [
        NotificationItem(
          id: '1',
          title: 'Randevu Hatırlatması',
          message: 'Yarın saat 10:00\'da Gülümseme Diş Kliniği\'nde randevunuz var.',
          time: '2 saat önce',
          isRead: false,
          type: 'reminder',
        ),
        NotificationItem(
          id: '2',
          title: 'Randevu Onaylandı',
          message: 'Randevunuz başarıyla oluşturuldu. 20 Şubat 2024, 14:00',
          time: '1 gün önce',
          isRead: false,
          type: 'appointment',
        ),
        NotificationItem(
          id: '3',
          title: 'Randevu Hatırlatması',
          message: 'Yaklaşan randevunuz: 15 Şubat 2024, 10:00',
          time: '2 gün önce',
          isRead: true,
          type: 'reminder',
        ),
        NotificationItem(
          id: '4',
          title: 'Sistem Güncellemesi',
          message: 'Yeni özellikler eklendi! Uygulamayı güncelleyin.',
          time: '3 gün önce',
          isRead: true,
          type: 'system',
        ),
        NotificationItem(
          id: '5',
          title: 'Randevu İptal Edildi',
          message: 'Randevunuz iptal edildi. Yeni bir randevu oluşturabilirsiniz.',
          time: '5 gün önce',
          isRead: true,
          type: 'appointment',
        ),
      ];
      _isLoading = false;
    });
  }

  void _markAsRead(String id) {
    setState(() {
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        _notifications[index] = NotificationItem(
          id: _notifications[index].id,
          title: _notifications[index].title,
          message: _notifications[index].message,
          time: _notifications[index].time,
          isRead: true,
          type: _notifications[index].type,
        );
      }
    });
  }

  void _markAllAsRead() {
    setState(() {
      _notifications = _notifications.map((notification) {
        return NotificationItem(
          id: notification.id,
          title: notification.title,
          message: notification.message,
          time: notification.time,
          isRead: true,
          type: notification.type,
        );
      }).toList();
    });
  }

  void _deleteNotification(String id) {
    setState(() {
      _notifications.removeWhere((n) => n.id == id);
    });
  }

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'appointment':
        return Icons.calendar_today;
      case 'reminder':
        return Icons.notifications;
      case 'system':
        return Icons.info;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String type) {
    switch (type) {
      case 'appointment':
        return AppTheme.tealBlue;
      case 'reminder':
        return AppTheme.warningOrange;
      case 'system':
        return AppTheme.deepCyan;
      default:
        return AppTheme.iconGray;
    }
  }

  int get _unreadCount {
    return _notifications.where((n) => !n.isRead).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.backgroundLight,
              AppTheme.lightTurquoise.withOpacity(0.3),
            ],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.lightTurquoise,
                            AppTheme.mediumTurquoise,
                          ],
                        ),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: AppTheme.white),
                            onPressed: () => Navigator.pop(context),
                          ),
                          Expanded(
                            child: Text(
                              'Bildirimler',
                              style: AppTheme.headingLarge.copyWith(
                                color: AppTheme.white,
                              ),
                            ),
                          ),
                          if (_unreadCount > 0)
                            TextButton(
                              onPressed: _markAllAsRead,
                              child: Text(
                                'Tümünü Okundu İşaretle',
                                style: AppTheme.bodySmall.copyWith(
                                  color: AppTheme.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Bildirim Listesi
                    Expanded(
                      child: _notifications.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.notifications_none,
                                    size: 64,
                                    color: AppTheme.iconGray,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Bildirim bulunamadı',
                                    style: AppTheme.bodyLarge.copyWith(
                                      color: AppTheme.grayText,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadNotifications,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(20),
                                itemCount: _notifications.length,
                                itemBuilder: (context, index) {
                                  final notification = _notifications[index];
                                  return _buildNotificationCard(notification);
                                },
                              ),
                            ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem notification) {
    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          Icons.delete,
          color: AppTheme.white,
        ),
      ),
      onDismissed: (direction) {
        _deleteNotification(notification.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bildirim silindi'),
            backgroundColor: AppTheme.successGreen,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: notification.isRead ? AppTheme.white : AppTheme.lightTurquoise.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: notification.isRead
              ? null
              : Border.all(
                  color: AppTheme.tealBlue.withOpacity(0.3),
                  width: 1,
                ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              if (!notification.isRead) {
                _markAsRead(notification.id);
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // İkon
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _getNotificationColor(notification.type).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getNotificationIcon(notification.type),
                      color: _getNotificationColor(notification.type),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // İçerik
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                notification.title,
                                style: AppTheme.bodyMedium.copyWith(
                                  fontWeight: notification.isRead
                                      ? FontWeight.normal
                                      : FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (!notification.isRead)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: AppTheme.tealBlue,
                                  shape: BoxShape.circle,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notification.message,
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.grayText,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          notification.time,
                          style: AppTheme.bodySmall.copyWith(
                            color: AppTheme.iconGray,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}



