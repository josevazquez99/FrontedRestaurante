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
      // Safely parse the price to a double before summing
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
        Uri.parse(
          "https://backendrestaurante-4elz.onrender.com/api/carrito/$productoId",
        ),
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
        title: Text(
          "Tu Carrito",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueGrey.shade800, Colors.blueGrey.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              logoutUser(context);
            },
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body:
          carrito.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.remove_shopping_cart,
                      size: 80,
                      color: Colors.grey.shade400,
                    ),
                    SizedBox(height: 20),
                    Text(
                      "Tu carrito está vacío",
                      style: TextStyle(
                        fontSize: 22,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "¡Añade algunos productos para empezar!",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                padding: EdgeInsets.all(12),
                itemCount: carrito.length,
                itemBuilder: (context, index) {
                  final producto = carrito[index];
                  // Safely parse and format the price to avoid NoSuchMethodError
                  final String precioText =
                      (double.tryParse(producto['precio'].toString()) ?? 0.0)
                          .toStringAsFixed(2);
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.teal.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              Icons.restaurant_menu,
                              color: Colors.teal.shade700,
                              size: 30,
                            ),
                          ),
                          SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  producto["nombre"] ?? "Producto Desconocido",
                                  style: TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueGrey.shade800,
                                  ),
                                ),
                                SizedBox(height: 5),
                                Text(
                                  "$precioText €", // Use the safely formatted price
                                  style: TextStyle(
                                    fontSize: 17,
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.delete_forever,
                              color: Colors.red.shade600,
                              size: 28,
                            ),
                            onPressed: () {
                              eliminarProducto(producto["id"]);
                            },
                            tooltip: 'Eliminar del carrito',
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      bottomNavigationBar:
          carrito.isNotEmpty
              ? Container(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 3,
                      blurRadius: 7,
                      offset: Offset(0, -3),
                    ),
                  ],
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Total a Pagar:",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey.shade900,
                          ),
                        ),
                        Text(
                          "${total.toStringAsFixed(2)} €",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.payment, color: Colors.white),
                        label: Text(
                          'Proceder al Pago',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal.shade600,
                          padding: EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          elevation: 5,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PagoScreen(total: total),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              )
              : null,
    );
  }
}
