import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PagoScreen extends StatefulWidget {
  final double total;

  const PagoScreen({Key? key, required this.total}) : super(key: key);

  @override
  _PagoScreenState createState() => _PagoScreenState();
}

class _PagoScreenState extends State<PagoScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _numeroTarjetaController =
      TextEditingController();
  final TextEditingController _fechaExpiracionController =
      TextEditingController();
  final TextEditingController _cvvController = TextEditingController();
  final TextEditingController _numeroMesaController = TextEditingController();

  bool _procesandoPago = false;

  Future<void> limpiarCarrito() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('carrito'); // Borra el carrito tras el pago
  }

  Future<String?> obtenerTokenDePreferencias() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("auth_token");
  }

  Future<bool> comprobarMesa(String mesaId, String token) async {
    try {
      final response = await http.get(
        Uri.parse(
          "https://backendrestaurante-4elz.onrender.com/api/pedidos/$mesaId/mesa",
        ),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<void> crearPedido(
    BuildContext context, {
    String? tipoEntrega,
    String? numeroMesa,
  }) async {
    String? token = await obtenerTokenDePreferencias();

    if (token == null) {
      mostrarMensaje(
        context,
        "No se encontró el token de autenticación",
        false,
      );
      return;
    }

    if (tipoEntrega == "mesa" && (numeroMesa == null || numeroMesa.isEmpty)) {
      mostrarMensaje(context, "Debe ingresar el número de mesa", false);
      return;
    }

    // Validar que la mesa exista antes de enviar el pedido
    if (tipoEntrega == "mesa" && numeroMesa != null) {
      bool mesaValida = await comprobarMesa(numeroMesa, token);
      if (!mesaValida) {
        mostrarMensaje(context, "La mesa $numeroMesa no existe", false);
        return;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final carritoString = prefs.getString('carrito');

    if (carritoString == null) {
      mostrarMensaje(context, "El carrito está vacío", false);
      return;
    }

    final carrito = jsonDecode(carritoString);
    final productos =
        carrito.map((producto) {
          return {
            "producto_id": producto["id"] ?? 0,
            "cantidad": producto["cantidad"] ?? 1,
          };
        }).toList();

    Map<String, dynamic> pedidoData = {
      "productos": productos,
      "tipo_entrega": tipoEntrega ?? "recoger",
    };

    if (tipoEntrega == "mesa" && numeroMesa != null) {
      pedidoData["mesa_id"] = numeroMesa;
    }

    print("Enviando pedido al backend con datos: $pedidoData");

    try {
      final response = await http.post(
        Uri.parse("https://backendrestaurante-4elz.onrender.com/api/pedidos"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode(pedidoData),
      );

      if (response.statusCode == 201) {
        mostrarMensaje(context, "Pedido creado con éxito!", true);
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

  void mostrarDialogoEntrega() {
    showDialog(
      context: context,
      builder: (context) {
        String? tipoEntregaSeleccionado;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(
                'Seleccione tipo de entrega',
                style: TextStyle(
                  color: Colors.blueGrey.shade800,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<String>(
                    title: Text(
                      'Servir a mesa',
                      style: TextStyle(color: Colors.blueGrey.shade700),
                    ),
                    value: 'mesa',
                    groupValue: tipoEntregaSeleccionado,
                    onChanged: (value) {
                      setStateDialog(() {
                        tipoEntregaSeleccionado = value;
                      });
                    },
                    activeColor: Colors.teal,
                  ),
                  if (tipoEntregaSeleccionado == 'mesa')
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0, right: 8.0),
                      child: TextFormField(
                        controller: _numeroMesaController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Número de mesa',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          hintText: 'Ejemplo: 5',
                          prefixIcon: Icon(
                            Icons.table_bar,
                            color: Colors.blueGrey,
                          ),
                        ),
                        validator: (value) {
                          if (tipoEntregaSeleccionado == 'mesa' &&
                              (value == null || value.isEmpty)) {
                            return 'Por favor, ingrese el número de mesa';
                          }
                          return null;
                        },
                      ),
                    ),
                  RadioListTile<String>(
                    title: Text(
                      'Recoger en local',
                      style: TextStyle(color: Colors.blueGrey.shade700),
                    ),
                    value: 'recoger',
                    groupValue: tipoEntregaSeleccionado,
                    onChanged: (value) {
                      setStateDialog(() {
                        tipoEntregaSeleccionado = value;
                      });
                    },
                    activeColor: Colors.teal,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    'Cancelar',
                    style: TextStyle(color: Colors.blueGrey),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (tipoEntregaSeleccionado == null) {
                      mostrarMensaje(
                        context,
                        'Por favor seleccione un tipo de entrega',
                        false,
                      );
                      return;
                    }
                    if (tipoEntregaSeleccionado == 'mesa' &&
                        _numeroMesaController.text.trim().isEmpty) {
                      mostrarMensaje(
                        context,
                        'Ingrese el número de mesa',
                        false,
                      );
                      return;
                    }
                    Navigator.of(context).pop();
                    procesarPagoConEntrega(
                      tipoEntregaSeleccionado!,
                      _numeroMesaController.text.trim(),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                  child: Text(
                    'Confirmar',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void procesarPagoConEntrega(String tipoEntrega, String numeroMesa) async {
    if (!_formKey.currentState!.validate()) {
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

    // Validar solo si es tipo "mesa"
    if (tipoEntrega == "mesa") {
      if (numeroMesa.isEmpty) {
        mostrarMensaje(context, "Debe ingresar el número de mesa", false);
        return;
      }

      bool mesaValida = await comprobarMesa(numeroMesa, token);
      if (!mesaValida) {
        mostrarMensaje(context, "La mesa $numeroMesa no existe", false);
        return;
      }
    }

    setState(() {
      _procesandoPago = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            title: Text('Procesando pago...'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
                ),
                SizedBox(height: 15),
                Text(
                  'Validando tarjeta y procesando pedido...',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.blueGrey.shade700),
                ),
              ],
            ),
          ),
    );

    Timer(Duration(seconds: 3), () async {
      Navigator.of(context).pop();

      // Aquí solo pasas la mesa si aplica
      await crearPedido(
        context,
        tipoEntrega: tipoEntrega,
        numeroMesa: tipoEntrega == "mesa" ? numeroMesa : null,
      );
      await limpiarCarrito();

      setState(() {
        _procesandoPago = false;
        _numeroMesaController.clear();
      });

      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: Colors.green,
                    size: 30,
                  ),
                  SizedBox(width: 10),
                  Text(
                    '¡Pago Exitoso!',
                    style: TextStyle(color: Colors.green.shade700),
                  ),
                ],
              ),
              content: Text(
                'Gracias por tu compra. Tu pedido ha sido procesado con éxito y está en camino.',
                style: TextStyle(fontSize: 16, color: Colors.blueGrey.shade700),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: Text('Aceptar', style: TextStyle(color: Colors.teal)),
                ),
              ],
            ),
      );
    });
  }

  Future<void> logoutUser(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('usuario_id');

    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  void dispose() {
    _numeroTarjetaController.dispose();
    _fechaExpiracionController.dispose();
    _cvvController.dispose();
    _numeroMesaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Finalizar Pedido',
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
      body: Padding(
        padding: const EdgeInsets.all(25.0),
        child:
            _procesandoPago
                ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Procesando su pago, por favor espere...',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.blueGrey.shade700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
                : SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.teal.shade50,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.teal.shade200),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.credit_card,
                                size: 50,
                                color: Colors.teal.shade700,
                              ),
                              SizedBox(width: 15),
                              Text(
                                'Pago con Tarjeta',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.teal.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 30),
                        TextFormField(
                          controller: _numeroTarjetaController,
                          keyboardType: TextInputType.number,
                          decoration: _inputDecoration(
                            'Número de Tarjeta',
                            Icons.credit_card,
                            '1234 5678 9012 3456',
                          ),
                          maxLength: 19,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingrese el número de tarjeta';
                            }
                            if (value.replaceAll(' ', '').length != 16) {
                              return 'El número de tarjeta debe tener 16 dígitos';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _fechaExpiracionController,
                                keyboardType: TextInputType.datetime,
                                decoration: _inputDecoration(
                                  'Fecha de Exp.',
                                  Icons.calendar_today,
                                  'MM/AA',
                                ),
                                maxLength: 5,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Ingrese la fecha de expiración';
                                  }
                                  final regex = RegExp(
                                    r'^(0[1-9]|1[0-2])\/?([0-9]{2})$',
                                  );
                                  if (!regex.hasMatch(value)) {
                                    return 'Formato inválido MM/AA';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            SizedBox(width: 20),
                            Expanded(
                              child: TextFormField(
                                controller: _cvvController,
                                keyboardType: TextInputType.number,
                                decoration: _inputDecoration(
                                  'CVV',
                                  Icons.lock_outline,
                                  '123',
                                ),
                                maxLength: 3,
                                obscureText: true,
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Ingrese el CVV';
                                  }
                                  if (value.length != 3) {
                                    return 'El CVV debe tener 3 dígitos';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 40),
                        Container(
                          padding: EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.blueGrey.shade50,
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.blueGrey.shade200),
                          ),
                          child: Text(
                            'Total a pagar: ${widget.total.toStringAsFixed(2)} €',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: mostrarDialogoEntrega,
                            icon: Icon(Icons.check_circle, color: Colors.white),
                            label: Text(
                              'Finalizar Pago',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal.shade600,
                              padding: EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              elevation: 5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, String hint) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.blueGrey.shade600),
      prefixIcon: Icon(icon, color: Colors.blueGrey.shade500),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      filled: true,
      fillColor: Colors.blueGrey.shade50,
      hintText: hint, // Correctly placed hintText
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
}
