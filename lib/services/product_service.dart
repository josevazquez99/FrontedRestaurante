import 'package:http/http.dart' as http;
import 'dart:convert';

class ProductService {
  final String apiUrl = 'http://localhost:3000/api/productos';

  Future<List<dynamic>> fetchProductos() async {
    final response = await http.get(Uri.parse(apiUrl));

    if (response.statusCode == 200) {
      final List<dynamic> productos = json.decode(response.body);
      return productos;
    } else {
      throw Exception('Error al cargar los productos');
    }
  }
}
