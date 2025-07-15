import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'models/cart_item.dart';
import 'providers/canteen_status_provider.dart';
import 'themes/theme.dart';

// User Screens
import 'user_screens/home_screen.dart';
import 'user_screens/change_password.dart';
import 'user_screens/previous_orders.dart';
import 'user_screens/favourites.dart';
import 'user_screens/cart.dart';

// Admin Screens
import 'admin_screens/admin_dashboard.dart';
import 'admin_screens/manage_stocks.dart';
import 'admin_screens/analytics_page.dart';
import 'admin_screens/view_all_orders.dart';
import 'admin_screens/qr_scanner_page.dart';
import 'admin_screens/pickupControlPage.dart';

// Login Page
import 'admin_login_page.dart';

// Login Page
import 'splash_screen/animated_splash_page.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.dumpErrorToConsole(details);
  };

  await initializeApp();
  await loadThemePreference();
  final initialScreen = await getInitialScreen();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CanteenStatusProvider()),
      ],
      child: AnimatedBuilder(
        animation: themeNotifier,
        builder: (context, _) {
          return MyApp(initialScreen: initialScreen);
        },
      ),
    ),
  );
}

Future<void> initializeApp() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final appDocDir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(appDocDir.path);
  Hive.registerAdapter(CartItemAdapter());

  if (!Hive.isBoxOpen('cart')) {
    await Hive.openBox<CartItem>('cart');
  }
}

Future<void> loadThemePreference() async {
  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('isDarkTheme') ?? false;
  themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
}

Future<void> saveThemePreference(bool isDark) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('isDarkTheme', isDark);
}

Future<Widget> getInitialScreen() async {
  final prefs = await SharedPreferences.getInstance();
  final user = FirebaseAuth.instance.currentUser;

  if (user != null) {
    try {
      final rollNo = user.email!.split('@').first;
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(rollNo)
              .get();

      if (!doc.exists || doc.data() == null) {
        return const LoginPage();
      }

      final isAdmin = doc.data()?['isAdmin'] ?? false;
      await prefs.setBool('isAdmin', isAdmin);

      return isAdmin ? const AdminDashboard() : const HomeScreen();
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  return const LoginPage();
}

class MyApp extends StatelessWidget {
  final Widget initialScreen;

  const MyApp({super.key, required this.initialScreen});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'KMIT Portal',
          debugShowCheckedModeBanner: false,
          themeMode: mode,
          theme: lightTheme,
          darkTheme: darkTheme,
          home: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: initialScreen,
          ),
          routes: {
            '/changePassword': (context) => const ChangePasswordPage(),
            '/previousOrders': (context) => const PreviousOrdersPage(),
            '/allOrders': (context) => const ViewAllOrdersPage(),
            '/favourites': (context) => const FavouritesPage(),
            '/cart': (context) => const CartScreen(),
            '/loginPage': (context) => const LoginPage(),
            '/manageStocks': (context) => const ManageStocksPage(),
            '/analytics': (context) => const AnalyticsPage(),
            '/scanner': (_) => const QRScannerPage(),
            '/pickupControl': (_) => const PickupControlPage(),
          },
        );
      },
    );
  }
}

// // import 'package:flutter/material.dart';
// // import 'package:firebase_core/firebase_core.dart';
// // import 'package:hive_flutter/hive_flutter.dart';
// // import 'package:path_provider/path_provider.dart';
// // import 'package:shared_preferences/shared_preferences.dart';

// // import 'firebase_options.dart';
// // import 'models/cart_item.dart';
// // import 'user_screens/home_screen.dart';
// // import 'user_screens/change_password.dart';
// // import 'user_screens/previous_orders.dart';
// // import 'user_screens/favourites.dart';
// // import 'user_screens/cart.dart';
// // import 'admin_screens/admin_dashboard.dart';
// // import 'admin_login_page.dart';
// // import 'admin_screens/manage_stocks.dart';
// // import 'admin_screens/analytics_page.dart';
// // import 'admin_screens/view_all_orders.dart';

// // final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

// // void main() async {
// //   WidgetsFlutterBinding.ensureInitialized();
// //   await _initializeApp();
// //   final initialScreen = await _getInitialScreen();
// //   runApp(MyApp(initialScreen: initialScreen));
// // }

// // Future<void> _initializeApp() async {
// //   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

// //   final appDocDir = await getApplicationDocumentsDirectory();
// //   await Hive.initFlutter(appDocDir.path);
// //   Hive.registerAdapter(CartItemAdapter());

// //   if (!Hive.isBoxOpen('cart')) {
// //     await Hive.openBox<CartItem>('cart');
// //   }
// // }

// // /// 🔥 DEV MODE: Directly opens Admin Dashboard
// // Future<Widget> _getInitialScreen() async {
// //   return const AdminDashboard();
// // }

// // class MyApp extends StatelessWidget {
// //   final Widget initialScreen;

// //   const MyApp({super.key, required this.initialScreen});

// //   @override
// //   Widget build(BuildContext context) {
// //     return ValueListenableBuilder<ThemeMode>(
// //       valueListenable: themeNotifier,
// //       builder: (context, mode, _) {
// //         return MaterialApp(
// //           title: 'KMIT Portal',
// //           debugShowCheckedModeBanner: false,
// //           themeMode: mode,
// //           theme: ThemeData(
// //             colorSchemeSeed: Colors.orange,
// //             brightness: Brightness.light,
// //             visualDensity: VisualDensity.adaptivePlatformDensity,
// //           ),
// //           darkTheme: ThemeData(
// //             colorSchemeSeed: Colors.orange,
// //             brightness: Brightness.dark,
// //             visualDensity: VisualDensity.adaptivePlatformDensity,
// //           ),
// //           home: initialScreen,
// //           routes: {
// //             '/changePassword': (context) => const ChangePasswordPage(),
// //             '/previousOrders': (context) => const PreviousOrdersPage(),
// //             '/favourites': (context) => const FavouritesPage(),
// //             '/cart': (context) => const CartScreen(),
// //             '/loginPage': (context) => const LoginPage(),
// //             '/manageStocks': (context) => const ManageStocksPage(),
// //             '/analytics': (context) => const AnalyticsPage(),
// //             '/allOrders': (context) => const ViewAllOrdersPage(),
// //           },
// //         );
// //       },
// //     );
// //   }
// // }
// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:hive_flutter/hive_flutter.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// import 'firebase_options.dart';
// import 'models/cart_item.dart';
// import 'user_screens/home_screen.dart';
// import 'user_screens/change_password.dart';
// import 'user_screens/previous_orders.dart';
// import 'user_screens/favourites.dart';
// import 'user_screens/cart.dart';
// import 'admin_screens/admin_dashboard.dart';
// import 'admin_login_page.dart';
// import 'admin_screens/manage_stocks.dart';
// import 'admin_screens/analytics_page.dart';
// import 'admin_screens/view_all_orders.dart';

// final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await _initializeApp();
//   final initialScreen = await _getInitialScreen();
//   runApp(MyApp(initialScreen: initialScreen));
// }

// Future<void> _initializeApp() async {
//   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

//   final appDocDir = await getApplicationDocumentsDirectory();
//   await Hive.initFlutter(appDocDir.path);
//   Hive.registerAdapter(CartItemAdapter());

//   if (!Hive.isBoxOpen('cart')) {
//     await Hive.openBox<CartItem>('cart');
//   }
// }

// Future<Widget> _getInitialScreen() async {
//   // Redirect directly to HomeScreen
//   return const HomeScreen();
// }

// class MyApp extends StatelessWidget {
//   final Widget initialScreen;

//   const MyApp({super.key, required this.initialScreen});

//   @override
//   Widget build(BuildContext context) {
//     return ValueListenableBuilder<ThemeMode>(
//       valueListenable: themeNotifier,
//       builder: (context, mode, _) {
//         return MaterialApp(
//           title: 'KMIT Portal',
//           debugShowCheckedModeBanner: false,
//           themeMode: mode,
//           theme: ThemeData(
//             colorSchemeSeed: Colors.orange,
//             brightness: Brightness.light,
//             visualDensity: VisualDensity.adaptivePlatformDensity,
//           ),
//           darkTheme: ThemeData(
//             colorSchemeSeed: Colors.orange,
//             brightness: Brightness.dark,
//             visualDensity: VisualDensity.adaptivePlatformDensity,
//           ),
//           home: initialScreen,
//           routes: {
//             '/changePassword': (context) => const ChangePasswordPage(),
//             '/previousOrders': (context) => const PreviousOrdersPage(),
//             '/favourites': (context) => const FavouritesPage(),
//             '/cart': (context) => const CartScreen(),
//             '/loginPage': (context) => const LoginPage(),
//             '/manageStocks': (context) => const ManageStocksPage(),
//             '/analytics': (context) => const AnalyticsPage(),
//             '/allOrders': (context) => const ViewAllOrdersPage(),
//           },
//         );
//       },
//     );
//   }
// }
// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:hive_flutter/hive_flutter.dart';
// import 'package:path_provider/path_provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// import 'firebase_options.dart';
// import 'models/cart_item.dart';
// import 'user_screens/home_screen.dart';
// import 'user_screens/change_password.dart';
// import 'user_screens/previous_orders.dart';
// import 'user_screens/favourites.dart';
// import 'user_screens/cart.dart';
// import 'admin_screens/admin_dashboard.dart';
// import 'admin_login_page.dart';
// import 'admin_screens/manage_stocks.dart';
// import 'admin_screens/analytics_page.dart';
// import 'admin_screens/view_all_orders.dart';

// final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await _initializeApp();
//   await _autoLogin(); // 👈 Added for default login
//   final initialScreen = await _getInitialScreen();
//   runApp(MyApp(initialScreen: initialScreen));
// }

// Future<void> _initializeApp() async {
//   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

//   final appDocDir = await getApplicationDocumentsDirectory();
//   await Hive.initFlutter(appDocDir.path);
//   Hive.registerAdapter(CartItemAdapter());

//   if (!Hive.isBoxOpen('cart')) {
//     await Hive.openBox<CartItem>('cart');
//   }
// }

// // 🔐 Auto login with known user
// Future<void> _autoLogin() async {
//   try {
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) {
//       await FirebaseAuth.instance.signInWithEmailAndPassword(
//         email: '23bd1a050r@kmit.in',
//         password: 'Kmit123\$', // ✅ Use actual password set in Firebase
//       );
//       print('✅ Auto login success: 050r@kmit.in');
//     } else {
//       print('👤 Already logged in: ${user.email}');
//     }
//   } catch (e) {
//     print('❌ Auto login failed: $e');
//   }
// }

// Future<Widget> _getInitialScreen() async {
//   // Redirect directly to HomeScreen
//   return const HomeScreen();
// }

// class MyApp extends StatelessWidget {
//   final Widget initialScreen;

//   const MyApp({super.key, required this.initialScreen});

//   @override
//   Widget build(BuildContext context) {
//     return ValueListenableBuilder<ThemeMode>(
//       valueListenable: themeNotifier,
//       builder: (context, mode, _) {
//         return MaterialApp(
//           title: 'KMIT Portal',
//           debugShowCheckedModeBanner: false,
//           themeMode: mode,
//           theme: ThemeData(
//             colorSchemeSeed: Colors.orange,
//             brightness: Brightness.light,
//             visualDensity: VisualDensity.adaptivePlatformDensity,
//           ),
//           darkTheme: ThemeData(
//             colorSchemeSeed: Colors.orange,
//             brightness: Brightness.dark,
//             visualDensity: VisualDensity.adaptivePlatformDensity,
//           ),
//           home: initialScreen,
//           routes: {
//             '/changePassword': (context) => const ChangePasswordPage(),
//             '/previousOrders': (context) => const PreviousOrdersPage(),
//             '/favourites': (context) => const FavouritesPage(),
//             '/cart': (context) => const CartScreen(),
//             '/loginPage': (context) => const LoginPage(),
//             '/manageStocks': (context) => const ManageStocksPage(),
//             '/analytics': (context) => const AnalyticsPage(),
//             '/allOrders': (context) => const ViewAllOrdersPage(),
//           },
//         );
//       },
//     );
//   }
// }
