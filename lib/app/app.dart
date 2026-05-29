import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sprouts_manager/core/app_config.dart';
import 'package:sprouts_manager/core/responsive/app_breakpoints.dart';
import 'package:sprouts_manager/features/auth/presentation/screens/start_mode_screen.dart';
import 'package:sprouts_manager/features/dashboard/manager_dashboard_screen.dart';
import 'package:sprouts_manager/firebase_options.dart';

import 'state/app_state_providers.dart';

class SproutsManagerApp extends StatelessWidget {
  const SproutsManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Eventsprouts Manager',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1D3557)),
        useMaterial3: true,
      ),
      home: const _AppBootstrap(),
    );
  }
}

class _AppBootstrap extends ConsumerStatefulWidget {
  const _AppBootstrap();

  @override
  ConsumerState<_AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends ConsumerState<_AppBootstrap> {
  late Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = _initializeAppData();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
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

  Future<void> _initializeAppData() async {
    await Future<void>.delayed(Duration.zero);

    if (AppConfig.useFirebaseInDevelopment) {
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      } on UnsupportedError catch (error) {
        debugPrint(
          'Firebase is not configured for this platform. Running with local dummy data. $error',
        );
      }
    }

    await ref.read(eventListProvider.notifier).initialize();
    await ref.read(userListProvider.notifier).initialize();
  }
}
