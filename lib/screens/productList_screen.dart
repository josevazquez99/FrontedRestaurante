import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'carrito_screen.dart';

class ProductListScreen extends StatefulWidget {
  @override
  _ProductListScreenState createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  List<dynamic> _productos = [];
  bool _isLoading = true;
  List<dynamic> _carrito = [];
  int _carritoCount = 0;

  @override
  void initState() {
    super.initState();
    fetchProductos();
    cargarCarrito();
  }

  Future<void> fetchProductos() async {
    final response = await http.get(
      Uri.parse('http://localhost:3000/api/productos'),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final List<dynamic> productos = json.decode(response.body);
      setState(() {
        _productos = productos;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> cargarCarrito() async {
    final prefs = await SharedPreferences.getInstance();
    final carritoString = prefs.getString('carrito');
    if (carritoString != null) {
      setState(() {
        _carrito = jsonDecode(carritoString);
        _carritoCount = _carrito.length;
      });
    }
  }

  Future<void> guardarCarrito() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString('carrito', jsonEncode(_carrito));
  }

  Future<void> agregarAlCarrito(dynamic producto) async {
    final prefs = await SharedPreferences.getInstance();
    int? usuarioId = prefs.getInt('usuario_id');

    if (usuarioId == null) {
      print("Error: Usuario no autenticado.");
      return;
    }

    setState(() {
      _carrito.add(producto);
      _carritoCount = _carrito.length;
    });

    guardarCarrito();

    String? token = prefs.getString('auth_token');
    if (token == null) {
      print("Error: Token de usuario no encontrado.");
      return;
    }

    final response = await http.post(
      Uri.parse('http://localhost:3000/api/carrito/crear'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'usuario_id': usuarioId,
        'producto_id': producto['id'],
        'cantidad': 1,
      }),
    );

    if (response.statusCode == 201) {
      print("Producto agregado al carrito correctamente en el backend.");
    } else {
      print("Error al agregar producto al carrito: ${response.body}");
    }
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
        title: Text('Listado de Productos'),
        backgroundColor: Colors.blueGrey,
        elevation: 0,
        actions: [
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CarritoScreen(carrito: _carrito),
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.shopping_cart, size: 28),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: CircleAvatar(
                      radius: 10,
                      backgroundColor: Colors.red,
                      child: Text(
                        '$_carritoCount',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          //  Botón de logout
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              logoutUser(context);
            },
          ),
        ],
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator())
              : _productos.isEmpty
              ? Center(
                child: Text(
                  'No hay productos disponibles',
                  style: TextStyle(fontSize: 18, color: Colors.grey),
                ),
              )
              : ListView.builder(
                padding: EdgeInsets.all(8),
                itemCount: _productos.length,
                itemBuilder: (context, index) {
                  final producto = _productos[index];
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
                        producto['nombre'] ?? 'Sin nombre',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 5),
                          Text(
                            'Descripción: ${producto['descripcion'] ?? 'Sin descripción'}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Precio: ${producto['precio']} €',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          Icons.add_shopping_cart,
                          color: Colors.blueGrey,
                        ),
                        onPressed: () {
                          agregarAlCarrito(producto);
                        },
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
