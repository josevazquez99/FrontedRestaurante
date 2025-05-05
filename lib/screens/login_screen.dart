import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatelessWidget {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(controller: _emailController, decoration: InputDecoration(labelText: 'Email')),
            TextField(controller: _passwordController, decoration: InputDecoration(labelText: 'Password'), obscureText: true),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final success = await _authService.login(
                  _emailController.text,
                  _passwordController.text,
                );
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Login exitoso")));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Credenciales incorrectas")));
                }
              },
              child: Text("Iniciar sesión"),
            ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, '/register'),
              child: Text("¿No tienes cuenta? Regístrate"),
            )
          ],
        ),
      ),
    );
  }
}
