import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:app_links/app_links.dart';

import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/visitor_register_screen.dart';
import 'screens/reset_password_screen.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // Access environment variables
  final supabaseUrl = dotenv.env['SUPABASE_URL']!;
  final supabaseKey = dotenv.env['SUPABASE_SERVICE_KEY']!;

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  late final AppLinks _appLinks;

  @override
  void initState() {
    super.initState();
    _appLinks = AppLinks();
    _listenLinks();
    _handleInitialLink();
  }

  void _listenLinks() {
    _appLinks.uriLinkStream.listen((Uri? uri) {
      _handleUri(uri);
    });
  }

  Future<void> _handleInitialLink() async {
    final uri = await _appLinks.getInitialAppLink();
    _handleUri(uri);
  }
  
  void _handleUri(Uri? uri) async {
  print('Received URI: $uri');
  if (uri != null &&
      uri.scheme == 'parkaccess' &&
      uri.host == 'reset-password' &&
      uri.queryParameters.containsKey('code')) {
    final code = uri.queryParameters['code']!;
    String? email = uri.queryParameters['email'];
    if (email == null) {
      email = await Navigator.of(navigatorKey.currentContext!).push<String>(
        MaterialPageRoute(
          builder: (_) => EnterEmailScreen(code: code),
        ),
      );
    }
    if (email != null && email.isNotEmpty) {
      await Supabase.instance.client.auth.signOut(); // asigură-te că nu ești logat
      try {
        final response = await Supabase.instance.client.auth.verifyOTP(
          type: OtpType.recovery,
          token: code,
          email: email,
        );
        print('verifyOTP response: ${response.user}');
        if (response.user != null) {
          print('Recovery verified, user: ${response.user!.id}');
          navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (_) => ResetPasswordScreen(),
            ),
          );
        } else {
          print('Recovery failed: No user returned');
          ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
            SnackBar(content: Text('Link invalid sau expirat!')),
          );
        }
      } catch (e) {
        print('Exception at verifyOTP: $e');
        ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
          SnackBar(content: Text('Eroare la resetare: $e')),
        );
      }
    }
  }
}




  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Access Control App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.indigo),
      home: Supabase.instance.client.auth.currentUser == null
          ? LoginScreen()
          : HomeScreen(),
      routes: {
        '/visitor-register': (_) => VisitorRegisterScreen(),
        '/reset-password': (_) => ResetPasswordScreen(),
      },
    );
  }
}

// Ecran pentru introducerea emailului
class EnterEmailScreen extends StatefulWidget {
  final String code;
  const EnterEmailScreen({super.key, required this.code});

  @override
  State<EnterEmailScreen> createState() => _EnterEmailScreenState();
}

class _EnterEmailScreenState extends State<EnterEmailScreen> {
  final _emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Enter your email')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Introdu adresa de email folosită la cont:',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(_emailController.text.trim());
              },
              child: Text('Continuă'),
            ),
          ],
        ),
      ),
    );
  }
}
