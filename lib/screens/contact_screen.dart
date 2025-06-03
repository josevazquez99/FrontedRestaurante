import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> sendEmail(String name, String message) async {
    const serviceId = 'service_6gr2dpu';
    const templateId = 'template_c63w4rm';
    const publicKey = '_MmarVqR0eoQsZSwS';

    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');
    final response = await http.post(
      url,
      headers: {
        'origin': 'http://localhost',
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'service_id': serviceId,
        'template_id': templateId,
        'user_id': publicKey,
        'template_params': {
          'name': 'Restaurante Vazquez', // fijo, quien recibe el mensaje
          'user_name': name, // quien envía el mensaje
          'user_message': message,
        },
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Mensaje enviado correctamente!',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.green,
        ),
      );
      _nameController.clear();
      _messageController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error al enviar el mensaje: ${response.body}',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      sendEmail(_nameController.text.trim(), _messageController.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Contáctanos',
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.blueGrey.shade50,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueGrey.shade100,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.restaurant_menu,
                    size: 60,
                    color: Colors.blueGrey.shade700,
                  ),
                  const SizedBox(height: 15),
                  const Text(
                    '¡Estamos aquí para ayudarte!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'No dudes en contactarnos para reservas, eventos o cualquier consulta.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Contact Information
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Encuéntranos en:',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey.shade700,
                      ),
                    ),
                    const Divider(height: 25, thickness: 1),
                    _buildContactInfoTile(
                      Icons.location_on,
                      'Calle Principal #123, Ciudad Restaurante',
                    ),
                    _buildContactInfoTile(Icons.phone, '+34 600 123 456'),
                    _buildContactInfoTile(
                      Icons.email,
                      'contacto@restaurante.com',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Contact Form
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Envíanos un mensaje:',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey.shade700,
                        ),
                      ),
                      const Divider(height: 25, thickness: 1),
                      TextFormField(
                        controller: _nameController,
                        decoration: _inputDecoration('Tu Nombre', Icons.person),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Por favor, ingresa tu nombre';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 15),
                      TextFormField(
                        controller: _messageController,
                        decoration: _inputDecoration(
                          'Tu Mensaje',
                          Icons.message,
                        ),
                        maxLines: 5,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Por favor, ingresa un mensaje';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 30),
                      Center(
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.send, color: Colors.white),
                            label: const Text(
                              'Enviar Mensaje',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal.shade500,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 5,
                            ),
                            onPressed: _submit,
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
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.blueGrey.shade600),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      prefixIcon: Icon(icon, color: Colors.blueGrey.shade500),
      filled: true,
      fillColor: Colors.blueGrey.shade50,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.blueGrey.shade200, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.teal.shade400, width: 2),
      ),
    );
  }

  Widget _buildContactInfoTile(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.teal.shade600, size: 28),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 17, color: Colors.blueGrey.shade800),
            ),
          ),
        ],
      ),
    );
  }
}
