import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Connect to real notification API
    final notifications = [
      {
        'title': 'System Update',
        'body': 'Gatekeeper has been updated to version 2.0. Check out the new features!',
        'time': '2 hrs ago',
        'isRead': false,
      },
      {
        'title': 'Guest Arrival',
        'body': 'Your guest John Doe has arrived at the gate.',
        'time': 'Yesterday',
        'isRead': true,
      },
      {
        'title': 'Bill Due',
        'body': 'Your functionality bill for October is due next week.',
        'time': '2 days ago',
        'isRead': true,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.checkCheck),
            tooltip: 'Mark all as read',
            onPressed: () {},
          ),
        ],
      ),
      body: notifications.isEmpty 
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.bellOff, size: 64, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                const Text('No notifications', style: TextStyle(color: Colors.grey)),
              ],
            ),
          )
        : ListView.separated(
            itemCount: notifications.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final notif = notifications[index];
              final isRead = notif['isRead'] as bool;
              
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isRead ? Colors.grey.shade200 : Theme.of(context).primaryColor.withOpacity(0.1),
                  child: Icon(
                    LucideIcons.bell, 
                    size: 20, 
                    color: isRead ? Colors.grey : Theme.of(context).primaryColor
                  ),
                ),
                title: Text(
                  notif['title'] as String,
                  style: isRead ? null : const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(notif['body'] as String),
                    const SizedBox(height: 4),
                    Text(
                      notif['time'] as String,
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                    ),
                  ],
                ),
                tileColor: isRead ? null : Theme.of(context).primaryColor.withOpacity(0.02),
                onTap: () {},
              );
            },
          ),
    );
  }
}
