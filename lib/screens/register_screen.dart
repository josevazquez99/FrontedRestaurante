import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatelessWidget {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Registro")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: _emailController, decoration: InputDecoration(labelText: 'Email')),
            TextField(controller: _passwordController, decoration: InputDecoration(labelText: 'Password'), obscureText: true),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final success = await _authService.register(
                  _emailController.text,
                  _passwordController.text,
                );
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Registro exitoso")));
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error al registrar")));
                }
              },
              child: Text("Registrarse"),
            ),
          ],
        ),
      ),
    );
  }
}
