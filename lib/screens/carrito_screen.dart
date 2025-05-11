import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'pago_screen.dart';

class CarritoScreen extends StatefulWidget {
  final List<dynamic> carrito;

  const CarritoScreen({Key? key, required this.carrito}) : super(key: key);

  @override
  _CarritoScreenState createState() => _CarritoScreenState();
}

class _CarritoScreenState extends State<CarritoScreen> {
  List<dynamic> carrito = [];

  @override
  void initState() {
    super.initState();
    cargarCarrito();
  }

  Future<void> cargarCarrito() async {
    final prefs = await SharedPreferences.getInstance();
    final carritoString = prefs.getString('carrito');

    if (carritoString != null) {
      final carritoData = jsonDecode(carritoString);
      setState(() {
        carrito = carritoData;
      });
    }
  }

  double calcularTotal() {
    return carrito.fold(0, (sum, producto) {
      final precio = double.tryParse(producto['precio'].toString()) ?? 0.0;
      return sum + precio;
    });
  }

  Future<void> eliminarProducto(int? productoId) async {
    if (productoId == null || productoId <= 0) {
      mostrarMensaje(context, "Error: ID del producto no válido.", false);
      return;
    }

    String? token = await obtenerTokenDePreferencias();

    if (token == null) {
      mostrarMensaje(
        context,
        "No se encontró el token de autenticación",
        false,
      );
      return;
    }

    try {
      final response = await http.delete(
        Uri.parse("http://localhost:3000/api/carrito/$productoId"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          carrito.removeWhere((producto) => producto["id"] == productoId);
        });

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('carrito', jsonEncode(carrito));

        mostrarMensaje(context, "Producto eliminado correctamente", true);
      } else {
        final errorData = jsonDecode(response.body);
        mostrarMensaje(context, "Error: ${errorData['mensaje']}", false);
      }
    } catch (e) {
      mostrarMensaje(context, "Error al conectar con el servidor", false);
    }
  }

  void mostrarMensaje(BuildContext context, String mensaje, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(mensaje, style: TextStyle(color: Colors.white)),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  Future<String?> obtenerTokenDePreferencias() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("auth_token");
  }

  Future<void> logoutUser(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("auth_token");
    await prefs.remove("usuario_id");

    Navigator.pushReplacementNamed(context, "/login");
  }

  @override
  Widget build(BuildContext context) {
    final total = calcularTotal();

    return Scaffold(
      appBar: AppBar(
        title: Text("Carrito de Compras"),
        backgroundColor: Colors.blueGrey,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              logoutUser(context);
            },
          ),
        ],
      ),
      body:
          carrito.isEmpty
              ? Center(
                child: Text(
                  "Tu carrito está vacío",
                  style: TextStyle(fontSize: 20, color: Colors.grey),
                ),
              )
              : ListView.builder(
                padding: EdgeInsets.all(8),
                itemCount: carrito.length,
                itemBuilder: (context, index) {
                  final producto = carrito[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 15,
                        horizontal: 20,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: Colors.blueGrey,
                        child: Icon(Icons.shopping_cart, color: Colors.white),
                      ),
                      title: Text(
                        producto["nombre"] ?? "Producto",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        "${producto["precio"]} €",
                        style: TextStyle(fontSize: 16, color: Colors.green),
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          eliminarProducto(producto["id"]);
                        },
                      ),
                    ),
                  );
                },
              ),
      bottomNavigationBar:
          carrito.isNotEmpty
              ? Padding(
                padding: EdgeInsets.all(15),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    padding: EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => PagoScreen(total: calcularTotal()),
                      ),
                    );
                  },
                  child: Text(
                    "Ir a Pagar (${total.toStringAsFixed(2)} €)",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              )
              : null,
    );
  }
}
