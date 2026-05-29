import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sprouts_manager/core/app_config.dart';
import 'package:sprouts_manager/core/responsive/app_breakpoints.dart';
import 'package:sprouts_manager/features/auth/presentation/screens/start_mode_screen.dart';
import 'package:sprouts_manager/features/dashboard/manager_dashboard_screen.dart';
import 'package:sprouts_manager/firebase_options.dart';
import 'package:sprouts_manager/utils/event_manager.dart';
import 'package:sprouts_manager/utils/user_manager.dart';

class SproutsManagerApp extends StatelessWidget {
  const SproutsManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<EventManager>(
          create: (_) => EventManager(),
        ),
        ChangeNotifierProvider<UserManager>(
          create: (_) => UserManager(),
        ),
      ],
      child: MaterialApp(
        title: 'Eventsprouts Manager',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1D3557)),
          useMaterial3: true,
        ),
        home: const _AppBootstrap(),
      ),
    );
  }
}

class _AppBootstrap extends StatefulWidget {
  const _AppBootstrap();

  @override
  State<_AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<_AppBootstrap> {
  late Future<void> _initFuture;
  bool _didInitFuture = false;

  @override
  Widget build(BuildContext context) {
    if (!_didInitFuture) {
      _initFuture = _initializeAppData(context);
      _didInitFuture = true;
    }

    return FutureBuilder(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'App konnte nicht initialisiert werden.\n\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        if (AppBreakpoints.shouldOpenManagerDirectly(context)) {
          return const ManagerDashboardScreen();
        }

        return const StartModeScreen();
      },
    );
  }

  Future<void> _initializeAppData(BuildContext context) async {
    final eventManager = context.read<EventManager>();
    final userManager = context.read<UserManager>();

    // Defer data loading to the next event-loop tick so provider notifications
    // are not fired while _AppBootstrap is still in its build phase.
    await Future<void>.delayed(Duration.zero);

    if (!AppConfig.useFirebaseInDevelopment) {
      eventManager.loadDummyEvents();
      userManager.loadDummyUsers();
      return;
    }

    bool firebaseInitialized = false;

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      firebaseInitialized = true;
    } on UnsupportedError catch (error) {
      debugPrint(
        'Firebase is not configured for this platform. Running with local dummy data. $error',
      );
    }

    if (!firebaseInitialized) {
      eventManager.loadDummyEvents();
      userManager.loadDummyUsers();
      return;
    }

    await eventManager.loadEventsFromFirestore();
    await userManager.loadUsersFromFirestore();
  }
}
