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
      Uri.parse('https://backendrestaurante-4elz.onrender.com/api/auth/login'),
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
          content: Text(
            'Error de autenticación. Verifica tus credenciales.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: EdgeInsets.all(15),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blueGrey.shade900, Colors.blueGrey.shade600],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(25.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Hero(
                  tag: 'logo', // Unique tag for hero animation
                  child: Image.asset(
                    'assets/logo.png', // Ensure this path is correct
                    height: 180,
                    width: 180,
                  ),
                ),
                SizedBox(height: 30),
                Text(
                  'Bienvenido de nuevo',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 10.0,
                        color: Colors.black.withOpacity(0.3),
                        offset: Offset(3.0, 3.0),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 50),
                Card(
                  elevation: 10,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(25.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              hintText: 'tu_email@example.com',
                              prefixIcon: Icon(
                                Icons.email,
                                color: Colors.blueGrey,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.blueGrey.shade50,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 15,
                                horizontal: 15,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor ingresa tu email';
                              }
                              if (!value.contains('@')) {
                                return 'Ingresa un email válido';
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
                              hintText: '********',
                              prefixIcon: Icon(
                                Icons.lock,
                                color: Colors.blueGrey,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Colors.blueGrey.shade50,
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 15,
                                horizontal: 15,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor ingresa tu contraseña';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 40),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  loginUser();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.teal.shade500,
                                padding: EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                elevation: 5,
                                shadowColor: Colors.teal.shade700,
                              ),
                              child: Text(
                                'Iniciar Sesión',
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/registro');
                            },
                            child: Text(
                              '¿No tienes cuenta? Regístrate aquí',
                              style: TextStyle(
                                color: Colors.blueGrey.shade700,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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
