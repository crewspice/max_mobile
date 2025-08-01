import 'package:flutter/material.dart';
import 'driver_selection_screen.dart';
import 'package:http/http.dart' as http;
import '../services/api_service.dart';


class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final ApiService apiService = ApiService();

  List<String> _names = [];
  String? _selectedName;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNames();
  }

    Future<void> _loadNames() async {
    try {
        print('📡 Fetching user names...');
        List<String> names = await apiService.fetchAllUserNames();
        print('✅ Received names: $names');
        setState(() {
        _names = names;
        _selectedName = names.isNotEmpty ? names.first : null;
        _isLoading = false;
        });
    } catch (e) {
        print('❌ Failed to load names: $e');
        setState(() {
        _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load users: $e')),
        );
    }
    }


  Future<void> _handleLogin() async {
    if (_selectedName == null || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a name and enter password.')),
      );
      return;
    }

    final url = 'http://api.maxhighreach.com:8080/user/login';
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'name': _selectedName!,
        'password': _passwordController.text,
      },
    );

    if (response.statusCode == 200) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DriverSelectionScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed. Try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  DropdownButtonFormField<String>(
                    value: _selectedName,
                    items: _names
                        .map((name) => DropdownMenuItem(
                              value: name,
                              child: Text(name),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedName = value;
                      });
                    },
                    decoration: const InputDecoration(labelText: 'Select Name'),
                  ),
                  TextField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _handleLogin,
                    child: const Text('Login'),
                  ),
                ],
              ),
            ),
    );
  }
}
