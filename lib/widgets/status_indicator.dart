import 'package:flutter/material.dart';
import '../models/user_model.dart';

class UserCard extends StatelessWidget {
  final UserModel user;

  const UserCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: NetworkImage(user.photoUrl),
          radius: 24,
        ),
        title: Text(user.name, style: TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Division: ${user.divisionId}'),
            Text('Badge: ${user.badgeNumber}'),
            Text('Access: ${user.accessEnabled ? 'Enabled' : 'Disabled'}'),
          ],
        ),
        trailing: Icon(Icons.keyboard_arrow_right),
        onTap: () {
          // Future use: navigate to profile or details
        },
      ),
    );
  }
}
