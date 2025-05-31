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
              title: Text('Seleccione tipo de entrega'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<String>(
                    title: Text('Servir a mesa'),
                    value: 'mesa',
                    groupValue: tipoEntregaSeleccionado,
                    onChanged: (value) {
                      setStateDialog(() {
                        tipoEntregaSeleccionado = value;
                      });
                    },
                  ),
                  if (tipoEntregaSeleccionado == 'mesa')
                    TextFormField(
                      controller: _numeroMesaController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Número de mesa',
                        border: OutlineInputBorder(),
                        hintText: 'Ejemplo: 5',
                      ),
                    ),
                  RadioListTile<String>(
                    title: Text('Recoger'),
                    value: 'recoger',
                    groupValue: tipoEntregaSeleccionado,
                    onChanged: (value) {
                      setStateDialog(() {
                        tipoEntregaSeleccionado = value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Cancelar'),
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
                  child: Text('Confirmar'),
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
                CircularProgressIndicator(),
                SizedBox(height: 10),
                Text('Validando tarjeta...'),
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
              title: Text('Pago Exitoso'),
              content: Text(
                'Gracias por tu compra. Tu pedido ha sido procesado.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  child: Text('Aceptar'),
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
        title: Text('Procesar Pago'),
        backgroundColor: Colors.blueGrey,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              logoutUser(context);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child:
            _procesandoPago
                ? Center(child: CircularProgressIndicator())
                : Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(Icons.credit_card, size: 100, color: Colors.green),
                      SizedBox(height: 20),
                      Text(
                        'Ingrese los datos de su tarjeta',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 20),
                      TextFormField(
                        controller: _numeroTarjetaController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Número de tarjeta',
                          border: OutlineInputBorder(),
                          hintText: '1234 5678 9012 3456',
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
                      SizedBox(height: 15),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _fechaExpiracionController,
                              keyboardType: TextInputType.datetime,
                              decoration: InputDecoration(
                                labelText: 'Fecha de expiración',
                                border: OutlineInputBorder(),
                                hintText: 'MM/AA',
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
                          SizedBox(width: 15),
                          Expanded(
                            child: TextFormField(
                              controller: _cvvController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'CVV',
                                border: OutlineInputBorder(),
                                hintText: '123',
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
                      SizedBox(height: 30),
                      Text(
                        'Total a pagar: ${widget.total.toStringAsFixed(2)} €',
                        style: TextStyle(fontSize: 20),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 30),
                      ElevatedButton.icon(
                        onPressed: mostrarDialogoEntrega,
                        icon: Icon(Icons.check_circle),
                        label: Text('Finalizar Pago'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: EdgeInsets.symmetric(vertical: 15),
                          textStyle: TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ),
                ),
      ),
    );
  }
}
