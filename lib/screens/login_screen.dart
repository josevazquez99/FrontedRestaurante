import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  //  Función para guardar el usuario y el token en SharedPreferences
  Future<void> guardarUsuario(int usuarioId, String token, String rol) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('usuario_id', usuarioId); // Guarda el ID del usuario
    await prefs.setString(
      'auth_token',
      token,
    ); // Guarda el token de autenticación
    await prefs.setString('user_role', rol); // Guarda el rol correctamente

    print("Usuario guardado: $usuarioId");
    print("Token guardado: $token");
    print(
      "Rol guardado en SharedPreferences: $rol",
    ); //  Verificación del rol guardado
  }

  Future<void> logoutUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('usuario_id');
    await prefs.remove('auth_token');
    await prefs.remove('user_role'); //  Elimina el rol al cerrar sesión
    print("Usuario deslogueado");
    Navigator.pushReplacementNamed(context, "/login");
  }

  //  Función para hacer login y obtener el token, usuario_id y rol
  Future<void> loginUser() async {
    final email = _emailController.text;
    final password = _passwordController.text;

    final response = await http.post(
      Uri.parse('http://localhost:3000/api/auth/login'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({'email': email, 'password': password}),
    );

    print(
      "🔹 Respuesta del servidor: ${response.body}",
    ); // 🔍 Verifica la respuesta JSON real

    if (response.statusCode == 200) {
      final Map<String, dynamic> responseData = jsonDecode(response.body);

      //  Extraer el rol correctamente desde `usuario`
      final String rol = responseData['usuario']['rol'] ?? 'usuario';

      print(
        "🔹 Rol extraído de la API correctamente: $rol",
      ); // 🔍 Confirmación antes de guardarlo

      final String token = responseData['token'];
      final int usuarioId = responseData['usuario']['id'];

      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setInt('usuario_id', usuarioId);
      await prefs.setString('auth_token', token);
      await prefs.setString('user_role', rol); //  Guarda el rol correctamente

      print(
        "🔹 Rol guardado en SharedPreferences después del login: ${prefs.getString('user_role')}",
      ); // 🔍 Última verificación

      Navigator.pushReplacementNamed(context, '/productos');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error de autenticación. Verifica tus credenciales.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Iniciar Sesión'),
        backgroundColor: Colors.blueGrey,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/logo.png', height: 150),
                SizedBox(height: 20),
                Text(
                  'Bienvenido de nuevo',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey,
                  ),
                ),
                SizedBox(height: 40),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingresa tu email';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: 'Contraseña',
                          prefixIcon: Icon(Icons.lock),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingresa tu contraseña';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 40),
                      ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            loginUser();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey,
                          padding: EdgeInsets.symmetric(
                            horizontal: 100,
                            vertical: 15,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Iniciar Sesión',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                      SizedBox(height: 20),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/registro');
                        },
                        child: Text(
                          '¿No tienes cuenta? Regístrate',
                          style: TextStyle(color: Colors.blueGrey),
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
    );
  }
}
