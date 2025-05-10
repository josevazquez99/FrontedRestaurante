import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

class PagoScreen extends StatefulWidget {
  final double total;

  const PagoScreen({Key? key, required this.total}) : super(key: key);

  @override
  _PagoScreenState createState() => _PagoScreenState();
}

class _PagoScreenState extends State<PagoScreen> {
  Future<void> limpiarCarrito() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('carrito'); // 🔥 Borra el carrito tras el pago
  }

  void procesarPago() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Procesando pago...'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 10),
                Text('Validando tarjeta...'),
              ],
            ),
          ),
    );

    Timer(Duration(seconds: 3), () {
      Navigator.of(context).pop(); // Cierra el diálogo de carga
      limpiarCarrito(); // 🔥 Limpia el carrito al finalizar pago

      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text('Pago Exitoso'),
              content: Text(
                'Gracias por tu compra. Tu pedido ha sido procesado.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).popUntil(
                      (route) => route.isFirst,
                    ); // 🔥 Regresa a ProductListScreen
                  },
                  child: Text('Aceptar'),
                ),
              ],
            ),
      );
    });
  }

  // 🔥 Función para cerrar sesión
  Future<void> logoutUser(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('usuario_id');

    print("Sesión cerrada correctamente");

    // Redirigir a la pantalla de login
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Procesar Pago'),
        backgroundColor: Colors.blueGrey,
        actions: [
          // 🔥 Botón de logout
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              logoutUser(context);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.credit_card, size: 100, color: Colors.green),
            SizedBox(height: 20),
            Text(
              'Resumen del pago',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            Text(
              'Total a pagar: ${widget.total.toStringAsFixed(2)} €',
              style: TextStyle(fontSize: 20),
              textAlign: TextAlign.center,
            ),
            Spacer(),
            ElevatedButton.icon(
              onPressed: procesarPago,
              icon: Icon(Icons.check_circle),
              label: Text('Finalizar Pago'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(vertical: 15),
                textStyle: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
