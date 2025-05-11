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
  String? _userRole;

  @override
  void initState() {
    super.initState();
    fetchProductos();
    cargarCarrito();
    verificarRolUsuario();
  }

  Future<void> verificarRolUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userRole = prefs.getString('user_role');
    });
  }

  Future<void> fetchProductos() async {
    final response = await http.get(
      Uri.parse('http://localhost:3000/api/productos'),
      headers: {'Content-Type': 'application/json'},
    );
    print(
      "🔹 Datos recibidos desde el backend: ${response.body}",
    ); // 🔍 Verifica la respuesta

    if (response.statusCode == 200) {
      final List<dynamic> productos = json.decode(response.body);
      setState(() {
        _productos.clear();
        _productos.addAll(productos);
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
      final carritoData = jsonDecode(carritoString);
      setState(() {
        _carrito = carritoData;
        _carritoCount = _carrito.length;
      });
    } else {
      setState(() {
        _carrito = [];
        _carritoCount =
            0; //  Asegurar que el contador se reinicia correctamente
      });
    }
  }

  Future<void> guardarCarrito() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('carrito', jsonEncode(_carrito));
    setState(() {
      _carritoCount = _carrito.length; //  Actualizar contador del carrito
    });
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

    if (response.statusCode >= 200 && response.statusCode < 300) {
      print("Producto agregado al carrito correctamente en el backend.");
    } else {
      print("Error al agregar producto al carrito: ${response.body}");
    }
  }

  Future<void> eliminarProducto(int id) async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');

    final response = await http.delete(
      Uri.parse('http://localhost:3000/api/productos/$id'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        _productos.removeWhere((producto) => producto['id'] == id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Producto eliminado correctamente')),
      );
    } else {
      print("Error al eliminar producto: ${response.body}");
    }
  }

  Future<void> editarProducto(dynamic producto) async {
    final resultado = await Navigator.pushNamed(
      context,
      '/editar',
      arguments: producto,
    );

    if (resultado == true) {
      fetchProductos(); // 🔥 Recargar productos tras edición exitosa
    }
  }

  Future<void> crearProducto() async {
    final resultado = await Navigator.pushNamed(context, '/crear');

    if (resultado == true) {
      fetchProductos(); // 🔥 Recargar productos tras creación exitosa
    }
  }

  Future<void> logoutUser(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('usuario_id');

    print("Sesión cerrada correctamente");

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
            onTap: () async {
              await cargarCarrito();
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
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => logoutUser(context),
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
                      subtitle: Text(
                        'Descripción: ${producto['descripcion'] ?? 'Sin descripción'}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.add_shopping_cart,
                              color: Colors.blueGrey,
                            ),
                            onPressed: () => agregarAlCarrito(producto),
                          ),
                          if (_userRole == 'administrador') ...[
                            IconButton(
                              icon: Icon(Icons.edit, color: Colors.orange),
                              onPressed: () => editarProducto(producto),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () => eliminarProducto(producto['id']),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
      floatingActionButton:
          _userRole == 'administrador'
              ? FloatingActionButton(
                backgroundColor: Colors.blueGrey,
                child: Icon(Icons.add),
                onPressed: crearProducto,
              )
              : null,
    );
  }
}
