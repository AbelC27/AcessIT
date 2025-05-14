// Root: lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final UserModel user;
  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? divisionName;

  @override
  void initState() {
    super.initState();
    _loadDivision();
  }

  Future<void> _loadDivision() async {
    print('Looking up divisionId: ${widget.user.divisionId}');

    final res = await Supabase.instance.client
        .from('divisions')
        .select('name')
        .eq('id', widget.user.divisionId)
        .maybeSingle();

    print('Division query result: $res');

    if (res != null && res.containsKey('name')) {
      setState(() => divisionName = res['name']);
    } else {
      setState(() => divisionName = 'Unknown');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: const Color.fromARGB(255, 176, 140, 235),
                backgroundImage: user.photoUrl.isNotEmpty
                    ? NetworkImage(user.photoUrl)
                    : null,
              ),
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 222, 209, 245),
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoRow("Name", user.name),
                    _infoRow("Email", user.email),
                    _infoRow("Division", divisionName ?? 'Loading...'),
                    _infoRow("Badge Number", user.badgeNumber),
                    _infoRow("Bluetooth Code", user.bluetoothCode),
                    Row(
                      children: [
                        Text(
                          "Access: ",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          user.accessEnabled ? 'Enabled' : 'Disabled',
                          style: TextStyle(
                            fontSize: 16,
                            color:
                                user.accessEnabled ? Colors.green : Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () async {
                  await Supabase.instance.client.auth.signOut();
                  if (!mounted) return;
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => LoginScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 222, 209, 245),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  textStyle: const TextStyle(fontSize: 16),
                ),
                child: Text('Log Out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _infoRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Text(
          "$label: ",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Flexible(
          child: Text(
            value,
            style: TextStyle(fontSize: 16),
          ),
        ),
      ],
    ),
  );
}
