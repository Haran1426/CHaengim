import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'data/schedule_store.dart';
import 'screens/home_screen.dart';
import 'design/app_theme.dart';
import 'platform/widget_bridge.dart';
import 'platform/notification_bridge.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'Paperlogy',
    ], await rootBundle.loadString('assets/fonts/OFL.txt'));
  });
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, this.storage});
  final ScheduleStorage? storage;
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final ScheduleStore store;
  final bridge = WidgetBridge();
  @override
  void initState() {
    super.initState();
    store = ScheduleStore(
      widget.storage ?? LocalScheduleStorage(),
      onChanged: widget.storage == null ? bridge.sync : null,
      onRemindersChanged: widget.storage == null
          ? NotificationBridge().sync
          : null,
    )..load();
  }

  @override
  void dispose() {
    store.dispose();
    bridge.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: '챙김',
    debugShowCheckedModeBanner: false,
    locale: const Locale('ko'),
    supportedLocales: const [Locale('ko')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    theme: buildAppTheme(),
    home: HomeScreen(store: store, bridge: bridge),
  );
}
