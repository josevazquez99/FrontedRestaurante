import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'carrito_screen.dart';
import 'contact_screen.dart';

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
      Uri.parse('https://backendrestaurante-4elz.onrender.com/api/productos'),
      headers: {'Content-Type': 'application/json'},
    );

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
        _carritoCount = 0;
      });
    }
  }

  Future<void> guardarCarrito() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('carrito', jsonEncode(_carrito));
    setState(() {
      _carritoCount = _carrito.length;
    });
  }

  Future<void> agregarAlCarrito(dynamic producto) async {
    final prefs = await SharedPreferences.getInstance();
    int? usuarioId = prefs.getInt('usuario_id');

    if (usuarioId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Por favor, inicia sesión para añadir productos.'),
          backgroundColor: Colors.orange.shade600,
        ),
      );
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
      Uri.parse(
        'https://backendrestaurante-4elz.onrender.com/api/carrito/crear',
      ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${producto['nombre']} añadido al carrito.'),
          backgroundColor: Colors.green.shade600,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al añadir ${producto['nombre']} al carrito.'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  Future<void> eliminarProducto(int id) async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Confirmar Eliminación'),
            content: Text(
              '¿Estás seguro de que quieres eliminar este producto?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Eliminar', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    final response = await http.delete(
      Uri.parse(
        'https://backendrestaurante-4elz.onrender.com/api/productos/$id',
      ),
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al eliminar producto')));
    }
  }

  Future<void> editarProducto(dynamic producto) async {
    final resultado = await Navigator.pushNamed(
      context,
      '/editar',
      arguments: producto,
    );

    if (resultado == true) {
      fetchProductos();
    }
  }

  Future<void> crearProducto() async {
    final resultado = await Navigator.pushNamed(context, '/crear');

    if (resultado == true) {
      fetchProductos();
    }
  }

  Future<void> confirmarEliminacionResena(
    BuildContext context,
    int resenaId,
    int productoId,
  ) async {
    final confirmacion = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text('¿Eliminar reseña?'),
            content: Text('¿Estás seguro de que deseas eliminar esta reseña?'),
            actions: [
              TextButton(
                child: Text('Cancelar'),
                onPressed: () => Navigator.pop(context, false),
              ),
              ElevatedButton(
                child: Text('Eliminar'),
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
    );

    if (confirmacion == true) {
      await eliminarResena(resenaId, productoId);
    }
  }

  Future<void> eliminarResena(int resenaId, int productoId) async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');

    if (token == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No autorizado')));
      return;
    }

    final response = await http.delete(
      Uri.parse(
        'https://backendrestaurante-4elz.onrender.com/api/resenas/$resenaId',
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Reseña eliminada con éxito')));
      Navigator.pop(context);
      mostrarResenas(productoId); // Recargar reseñas después de eliminar
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al eliminar reseña')));
    }
  }

  Future<void> logoutUser(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('usuario_id');
    Navigator.pushReplacementNamed(context, '/login');
  }

  void mostrarFormularioResena(int productoId) {
    TextEditingController comentarioController = TextEditingController();
    double calificacion = 5;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSB) {
            return AlertDialog(
              title: Text('Añadir Reseña'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: comentarioController,
                    decoration: InputDecoration(
                      labelText: 'Comentario',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    maxLines: 3,
                  ),
                  SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Calificación:', style: TextStyle(fontSize: 16)),
                      Row(
                        children: List.generate(5, (index) {
                          return IconButton(
                            icon: Icon(
                              index < calificacion
                                  ? Icons.star
                                  : Icons.star_border,
                              color: Colors.amber,
                            ),
                            onPressed: () {
                              setStateSB(() {
                                calificacion = (index + 1).toDouble();
                              });
                            },
                          );
                        }),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: Text('Cancelar'),
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton(
                  child: Text('Enviar'),
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    int? clienteId = prefs.getInt('usuario_id');

                    if (clienteId == null) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Debes iniciar sesión para reseñar.'),
                        ),
                      );
                      return;
                    }

                    final response = await http.post(
                      Uri.parse(
                        'https://backendrestaurante-4elz.onrender.com/api/resenas',
                      ),
                      headers: {
                        'Content-Type': 'application/json',
                        'Authorization':
                            'Bearer ${prefs.getString('auth_token')}',
                      },
                      body: jsonEncode({
                        'producto_id': productoId,
                        'cliente_id': clienteId,
                        'calificacion': calificacion.toInt(),
                        'comentario': comentarioController.text,
                        'fecha': DateTime.now().toIso8601String(),
                      }),
                    );

                    if (response.statusCode == 201) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Reseña enviada con éxito')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error al enviar reseña')),
                      );
                    }

                    Navigator.pop(context);
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> mostrarResenas(int productoId) async {
    showDialog(
      context: context,
      builder: (context) {
        return FutureBuilder<http.Response>(
          future: http.get(
            Uri.parse(
              'https://backendrestaurante-4elz.onrender.com/api/resenas/producto/$productoId',
            ),
            headers: {'Content-Type': 'application/json'},
          ),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return AlertDialog(
                title: Text('Reseñas'),
                content: Container(
                  height: 100,
                  child: Center(child: CircularProgressIndicator()),
                ),
              );
            } else if (snapshot.hasError) {
              return AlertDialog(
                title: Text('Reseñas'),
                content: Text('Error al cargar reseñas'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cerrar'),
                  ),
                ],
              );
            } else {
              if (snapshot.data!.statusCode == 200) {
                final List<dynamic> resenas = jsonDecode(snapshot.data!.body);
                if (resenas.isEmpty) {
                  return AlertDialog(
                    title: Text('Reseñas'),
                    content: Text('No hay reseñas para este producto.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cerrar'),
                      ),
                    ],
                  );
                } else {
                  return AlertDialog(
                    title: Text('Reseñas (${resenas.length})'),
                    content: Container(
                      width: double.maxFinite,
                      height: 300,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: resenas.length,
                        itemBuilder: (context, index) {
                          final resena = resenas[index];
                          return Card(
                            margin: EdgeInsets.symmetric(vertical: 6),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.star,
                                            color: Colors.amber,
                                            size: 20,
                                          ),
                                          SizedBox(width: 5),
                                          Text(
                                            '${resena['calificacion']} / 5',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        resena['fecha'] != null
                                            ? DateTime.parse(resena['fecha'])
                                                .toLocal()
                                                .toString()
                                                .substring(0, 10)
                                            : '',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    resena['comentario'] ?? 'Sin comentario',
                                    style: TextStyle(fontSize: 15),
                                  ),
                                  if (_userRole == 'administrador')
                                    Align(
                                      alignment: Alignment.bottomRight,
                                      child: IconButton(
                                        icon: Icon(
                                          Icons.delete,
                                          color: Colors.red.shade600,
                                        ),
                                        onPressed:
                                            () => confirmarEliminacionResena(
                                              context,
                                              resena['id'],
                                              productoId,
                                            ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cerrar'),
                      ),
                    ],
                  );
                }
              } else {
                return AlertDialog(
                  title: Text('Reseñas'),
                  content: Text('Error al cargar reseñas'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cerrar'),
                    ),
                  ],
                );
              }
            }
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Menú del Restaurante',
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
            icon: Icon(Icons.contact_mail_outlined),
            tooltip: 'Contacto',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ContactScreen()),
              );
            },
          ),
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.shopping_cart, size: 28),
                onPressed: () async {
                  await cargarCarrito();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CarritoScreen(carrito: _carrito),
                    ),
                  );
                },
                tooltip: 'Ver Carrito',
              ),
              Positioned(
                right: 5,
                top: 5,
                child:
                    _carritoCount > 0
                        ? Container(
                          padding: EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          constraints: BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          child: Text(
                            '$_carritoCount',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                        )
                        : SizedBox.shrink(),
              ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => logoutUser(context),
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body:
          _isLoading
              ? Center(child: CircularProgressIndicator(color: Colors.blueGrey))
              : _productos.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.local_dining_outlined,
                      size: 80,
                      color: Colors.grey.shade400,
                    ),
                    SizedBox(height: 20),
                    Text(
                      'No hay productos disponibles',
                      style: TextStyle(
                        fontSize: 22,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Vuelve más tarde para ver nuestras deliciosas ofertas.',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
              : ListView.builder(
                padding: EdgeInsets.all(12),
                itemCount: _productos.length,
                itemBuilder: (context, index) {
                  final producto = _productos[index];
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                color: Colors.blueGrey.shade100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.restaurant,
                                color: Colors.blueGrey.shade700,
                                size: 40,
                              ),
                            ),
                            title: Text(
                              producto['nombre'] ?? 'Producto Desconocido',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.blueGrey.shade900,
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 5.0),
                              child: Text(
                                producto['descripcion'] ?? 'Sin descripción',
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            trailing: Text(
                              '$precioText €', // Use the safely formatted price
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10.0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => agregarAlCarrito(producto),
                                    icon: Icon(
                                      Icons.add_shopping_cart,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    label: Text(
                                      'Añadir',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.teal.shade500,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      elevation: 3,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8),
                                if (_userRole == 'cliente') ...[
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed:
                                          () => mostrarFormularioResena(
                                            producto['id'],
                                          ),
                                      icon: Icon(
                                        Icons.rate_review,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      label: Text(
                                        'Reseñar',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.indigo.shade500,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        padding: EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                        elevation: 3,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                ],
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed:
                                        () => mostrarResenas(producto['id']),
                                    icon: Icon(
                                      Icons.comment,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    label: Text(
                                      'Reseñas',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.purple.shade500,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      padding: EdgeInsets.symmetric(
                                        vertical: 10,
                                      ),
                                      elevation: 3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_userRole == 'administrador')
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10.0,
                                vertical: 8.0,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () => editarProducto(producto),
                                      icon: Icon(
                                        Icons.edit,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      label: Text(
                                        'Editar',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange.shade500,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        padding: EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                        elevation: 3,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed:
                                          () =>
                                              eliminarProducto(producto['id']),
                                      icon: Icon(
                                        Icons.delete,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                      label: Text(
                                        'Eliminar',
                                        style: TextStyle(color: Colors.white),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red.shade500,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        padding: EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                        elevation: 3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      bottomNavigationBar: Container(
        height: 60,
        color: Colors.blueGrey.shade900,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          '© 2025 Restaurante Vazquez Tapas. Todos los derechos reservados.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.blueGrey.shade200,
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
      floatingActionButton:
          _userRole == 'administrador'
              ? FloatingActionButton.extended(
                onPressed: crearProducto,
                icon: Icon(Icons.add, color: Colors.white),
                label: Text(
                  'Añadir Producto',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                backgroundColor: Colors.teal.shade600,
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              )
              : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
