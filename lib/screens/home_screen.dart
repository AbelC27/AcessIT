// lib/screens/home_screen.dart
import 'package:access_control_app/screens/bluetooth_access_screen.dart';
import 'package:flutter/material.dart';
import '../services/local_storage_service.dart';
import '../models/user_model.dart';
import '../screens/presence_report_screen.dart';
import '../screens/profile_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'bluetooth_send_screen.dart'; // <-- importă noul ecran
import '../models/access_log_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final LocalStorageService _localStorage = LocalStorageService();
  final bool _sending = false;
  UserModel? currentUser;
  bool isVisitor = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _sendAccessCode() {
    if (currentUser == null) return;
    final code = currentUser!.bluetoothCode ?? '';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BluetoothSendScreen(
          bluetoothCode: code,
          currentUserId: currentUser!.id,
        ),
      ),
    );
  }

  Future<void> _loadUserData() async {
    final userId = await _localStorage.getUserId();
    final sessionUser = Supabase.instance.client.auth.currentUser;

    if (sessionUser != null) {
      final response = await Supabase.instance.client
          .from('employees')
          .select(
              'id, name, division_id, photo_url, badge_number, bluetooth_code, access_enabled')
          .eq('id', sessionUser.id)
          .maybeSingle();

      if (response != null) {
        setState(() {
          currentUser = UserModel.fromMap({
            ...response,
            'email': sessionUser.email,
          });

          isVisitor = false;
          _loading = false;
        });
        return;
      }
    }

    if (userId != null) {
      final visitorRes = await Supabase.instance.client
          .from('visitors')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (visitorRes != null) {
        setState(() {
          currentUser = UserModel(
            id: visitorRes['id'],
            name: visitorRes['name'],
            email: '',
            divisionId: -1,
            photoUrl: 'https://via.placeholder.com/150',
            badgeNumber: visitorRes['license_plate'] ?? '-',
            bluetoothCode: visitorRes['ble_temp_code'],
            accessEnabled: true,
          );
          isVisitor = true;
          _loading = false;
        });
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _goToBluetoothSendScreen() {
    if (currentUser == null) return;
    final code = currentUser!.bluetoothCode ?? '';
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BluetoothAccessScreen(
          bluetoothCode: code,
          userName: currentUser!.name,
          currentUserId: currentUser!.id,
        ),
      ),
    );
  }

  List<Widget> get _visitorOptions => [
        Center(
          child: _sending
              ? CircularProgressIndicator()
              : ElevatedButton(
                  onPressed: _goToBluetoothSendScreen,
                  child: Text('Request Access'),
                ),
        ),
        if (currentUser != null) ProfileScreen(user: currentUser!),
      ];

  List<Widget> get _employeeOptions => [
        Center(
          child: _sending
              ? CircularProgressIndicator()
              : ElevatedButton(
                  onPressed: _sendAccessCode,
                  child: Text('Request Access via Bluetooth'),
                ),
        ),
        PresenceReportScreen(), // simplu și curat
        if (currentUser != null) ProfileScreen(user: currentUser!),
      ];

  List<BottomNavigationBarItem> get _visitorNavItems => [
        BottomNavigationBarItem(
          icon: Icon(Icons.lock_open),
          label: 'Access',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ];

  List<BottomNavigationBarItem> get _employeeNavItems => [
        BottomNavigationBarItem(
          icon: Icon(Icons.lock_open),
          label: 'Access',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.list),
          label: 'History',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ];

  @override
  Widget build(BuildContext context) {
    if (_loading || currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Access Control'),
          backgroundColor: const Color.fromARGB(255, 222, 176, 230),
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final options = isVisitor ? _visitorOptions : _employeeOptions;
    final navItems = isVisitor ? _visitorNavItems : _employeeNavItems;

    return Scaffold(
      appBar: AppBar(
        title: Text('Hello, ${currentUser!.name}!'),
        backgroundColor: const Color.fromARGB(255, 176, 140, 235),
      ),
      body: options[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: navItems,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.indigo,
        onTap: _onItemTapped,
      ),
    );
  }
}