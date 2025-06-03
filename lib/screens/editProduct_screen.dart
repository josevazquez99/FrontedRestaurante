import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class EditProductScreen extends StatefulWidget {
  final dynamic producto;

  EditProductScreen({required this.producto});

  @override
  _EditProductScreenState createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _precioController = TextEditingController();
  final TextEditingController _categoriaController = TextEditingController();
  @override
  void initState() {
    super.initState();
    _nombreController.text = widget.producto['nombre'] ?? '';
    _descripcionController.text = widget.producto['descripcion'] ?? '';
    _precioController.text = widget.producto['precio'].toString();
    _categoriaController.text = widget.producto['categoria'] ?? '';
  }

  Future<void> actualizarProducto() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('auth_token');

    final response = await http.put(
      Uri.parse(
        'https://backendrestaurante-4elz.onrender.com/api/productos/${widget.producto['id']}',
      ),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'nombre': _nombreController.text.trim(),
        'descripcion': _descripcionController.text.trim(),
        'precio': _precioController.text.trim(),
        'categoria': _categoriaController.text.trim(),
      }),
    );

    print("🔹 Respuesta del servidor: ${response.body}");

    if (response.statusCode == 200) {
      print("✅ Producto actualizado correctamente");
      Navigator.pop(context, true);
    } else {
      print("❌ Error al actualizar producto: ${response.body}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error al actualizar el producto")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Editar Producto',
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
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 30.0),
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: EdgeInsets.all(25.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Actualizar Producto",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey.shade700,
                    ),
                  ),
                  SizedBox(height: 30),
                  _buildTextField(
                    _nombreController,
                    "Nombre del Producto",
                    Icons.fastfood,
                  ),
                  SizedBox(height: 20),
                  _buildTextField(
                    _descripcionController,
                    "Descripción Detallada",
                    Icons.description,
                    maxLines: 3,
                  ),
                  SizedBox(height: 20),
                  _buildTextField(
                    _precioController,
                    "Precio (€)",
                    Icons.attach_money,
                    isNumeric: true,
                  ),
                  SizedBox(height: 20),
                  _buildTextField(
                    _categoriaController,
                    "Categoría",
                    Icons.category,
                  ),
                  SizedBox(height: 40),
                  Container(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          actualizarProducto();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal.shade500,
                        padding: EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 5,
                      ),
                      child: Text(
                        'Guardar Cambios',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isNumeric = false,
    int? maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blueGrey.shade600),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: Colors.blueGrey.shade50,
        contentPadding: EdgeInsets.symmetric(vertical: 15, horizontal: 15),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blueGrey.shade200, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.teal.shade400, width: 2),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Por favor ingresa un $label válido';
        }
        if (isNumeric && double.tryParse(value) == null) {
          return 'Por favor ingresa un número válido';
        }
        return null;
      },
    );
  }
}
