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
    cargarCarrito(); // 🔥 Cargar carrito desde SharedPreferences
  }

  Future<void> cargarCarrito() async {
    final prefs = await SharedPreferences.getInstance();
    final carritoString = prefs.getString('carrito');

    if (carritoString != null) {
      final carritoData = jsonDecode(carritoString);
      print(
        "Contenido del carrito recibido: $carritoData",
      ); // 🔥 Verificar datos

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
    print(
      "Intentando eliminar producto ID: $productoId",
    ); // 🔥 Verificar ID antes de eliminar

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
          carrito.removeWhere(
            (producto) => producto["id"] == productoId,
          ); // 🔥 Cambié "producto_id" por "id"
        });

        Future.delayed(Duration(milliseconds: 300), () {
          setState(() {});
        });

        mostrarMensaje(context, "Producto eliminado correctamente", true);
      } else {
        final errorData = jsonDecode(response.body);
        mostrarMensaje(context, "Error: ${errorData['mensaje']}", false);
      }
    } catch (e) {
      mostrarMensaje(context, "Error al conectar con el servidor", false);
    }
  }

  Future<void> crearPedido(BuildContext context) async {
    String? token = await obtenerTokenDePreferencias();

    if (token == null) {
      mostrarMensaje(
        context,
        "No se encontró el token de autenticación",
        false,
      );
      return;
    }

    if (carrito.isEmpty) {
      mostrarMensaje(context, "El carrito está vacío", false);
      return;
    }

    final productos =
        carrito.map((producto) {
          return {
            "producto_id":
                producto["id"] ?? 0, // 🔥 Cambié "producto_id" por "id"
            "cantidad": producto["cantidad"] ?? 1,
          };
        }).toList();

    try {
      final response = await http.post(
        Uri.parse("http://localhost:3000/api/carrito/confirmar"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({"productos": productos}),
      );

      if (response.statusCode == 201) {
        mostrarMensaje(context, "Pedido creado con éxito!", true);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PagoScreen(total: calcularTotal()),
          ),
        );
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

  // 🔥 Función para cerrar sesión
  Future<void> logoutUser(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("auth_token");
    await prefs.remove("usuario_id");

    print("Sesión cerrada correctamente");

    // Redirigir a la pantalla de login
    Navigator.pushReplacementNamed(context, "/login");
  }

  @override
  Widget build(BuildContext context) {
    final total = calcularTotal();

    return Scaffold(
      appBar: AppBar(
        title: Text("Carrito de Compras"),
        backgroundColor: Colors.blueAccent,
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
      body:
          carrito.isEmpty
              ? Center(
                child: Text(
                  "Tu carrito está vacío",
                  style: TextStyle(fontSize: 20, color: Colors.grey),
                ),
              )
              : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: EdgeInsets.all(10),
                      itemCount: carrito.length,
                      itemBuilder: (context, index) {
                        final producto = carrito[index];
                        return Card(
                          elevation: 4,
                          margin: EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 15,
                          ),
                          child: ListTile(
                            leading: Icon(
                              Icons.shopping_cart,
                              color: Colors.blue,
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
                              style: TextStyle(fontSize: 16),
                            ),
                            trailing: IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                print(
                                  "Intentando eliminar producto ID: ${producto["id"]}",
                                ); // 🔥 Verificar ID

                                if (producto["id"] != null &&
                                    producto["id"] is int) {
                                  eliminarProducto(producto["id"]);
                                } else {
                                  mostrarMensaje(
                                    context,
                                    "Error: ID del producto no válido.",
                                    false,
                                  );
                                }
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
    );
  }
}
