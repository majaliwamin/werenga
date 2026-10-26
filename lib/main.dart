import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'state/bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _registerFontLicenses();

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
    ),
  );

  try {
    final bootstrap = await createBootstrap();
    runApp(WerengaApp(bootstrap: bootstrap));
  } catch (error, stackTrace) {
    debugPrint('Werenga could not start: $error\n$stackTrace');
    runApp(_StartupFailureApp(error: error));
  }
}

void _registerFontLicenses() {
  LicenseRegistry.addLicense(() async* {
    const fonts = [
      ('Cormorant Garamond', 'assets/licenses/OFL-CormorantGaramond.txt'),
      ('Manrope', 'assets/licenses/OFL-Manrope.txt'),
    ];
    for (final (name, asset) in fonts) {
      try {
        final text = await rootBundle.loadString(asset);
        yield LicenseEntryWithLineBreaks([name], text);
      } catch (error) {
        debugPrint('Could not load the $name license: $error');
      }
    }
  });
}

class _StartupFailureApp extends StatelessWidget {
  const _StartupFailureApp({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Werenga',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B1612),
        fontFamily: 'Manrope',
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFC6A664),
          surface: Color(0xFF0B1612),
        ),
      ),
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xFFC6A664),
                  size: 56,
                ),
                const SizedBox(height: 24),
                const Text(
                  'Werenga could not open\nyour local library.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'CormorantGaramond',
                    fontSize: 30,
                    height: 1.1,
                    color: Color(0xFFF2E9D8),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Please close the application and open it again. Your '
                  'recordings and listening history remain on this device.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Color(0xFFA4B3A7),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    height: 1.4,
                    color: Color(0xFF6F8377),
                  ),
                ),
                const SizedBox(height: 28),
                FilledButton(
                  onPressed: () => SystemNavigator.pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFC6A664),
                    foregroundColor: const Color(0xFF082E24),
                  ),
                  child: const Text('Close application'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
