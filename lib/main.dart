import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/productList_screen.dart';
import 'screens/pago_screen.dart';
import 'firebase_options.dart';
import 'screens/editProduct_screen.dart';
import 'screens/addProduct_screen.dart';
import 'screens/contact_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Auth',
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/',
      routes: {
        '/': (context) => LoginScreen(),
        '/registro': (context) => RegisterScreen(),
        '/login': (context) => LoginScreen(),
        '/productos': (context) => ProductListScreen(),
        '/contacto': (context) => ContactScreen(),
        '/pago': (context) => PagoScreen(total: 0),
        '/editar':
            (context) => EditProductScreen(
              producto:
                  ModalRoute.of(context)!.settings.arguments
                      as Map<String, dynamic>,
            ),
        '/crear': (context) => AddProductScreen(),
      },
    );
  }
}
