import 'package:material_ui/material_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'data/schedule_store.dart';
import 'screens/home_screen.dart';
import 'design/app_theme.dart';
import 'platform/widget_bridge.dart';
import 'platform/notification_bridge.dart';
import 'data/appearance_store.dart';
import 'data/plus_store.dart';
import 'platform/ads_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    yield LicenseEntryWithLineBreaks([
      'MaruBuri',
    ], await rootBundle.loadString('assets/fonts/maruburi/OFL.txt'));
    yield LicenseEntryWithLineBreaks([
      'Pretendard',
    ], await rootBundle.loadString('assets/fonts/pretendard/OFL.txt'));
  });
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({
    super.key,
    this.storage,
    this.appearanceStorage,
    this.plusGateway,
    this.adsController,
  });
  final ScheduleStorage? storage;
  final AppearanceStorage? appearanceStorage;
  final PlusGateway? plusGateway;
  final AdsController? adsController;
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final ScheduleStore store;
  final bridge = WidgetBridge();
  late final AppearanceStore appearance;
  late final PlusStore plus;
  late final AdsController ads;
  @override
  void initState() {
    super.initState();
    appearance = AppearanceStore(
      widget.appearanceStorage ?? LocalAppearanceStorage(),
      syncWidget: widget.storage == null ? bridge.syncAppearance : null,
    )..load();
    ads =
        widget.adsController ?? AdsController(enabled: widget.storage == null);
    plus = PlusStore(widget.plusGateway ?? RevenueCatGateway());
    plus.addListener(updatePlus);
    plus.refresh();
    store = ScheduleStore(
      widget.storage ?? LocalScheduleStorage(),
      onChanged: widget.storage == null ? bridge.sync : null,
      onRemindersChanged: widget.storage == null
          ? NotificationBridge().sync
          : null,
    )..load();
  }

  void updatePlus() {
    appearance.setPlus(plus.isPlus);
  }

  @override
  void dispose() {
    store.dispose();
    plus.removeListener(updatePlus);
    plus.dispose();
    appearance.dispose();
    ads.dispose();
    bridge.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: appearance,
    builder: (context, _) => MaterialApp(
      title: '챙김',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ko'),
      supportedLocales: const [Locale('ko')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: buildAppTheme(appearance.active),
      home: HomeScreen(
        store: store,
        bridge: bridge,
        appearance: appearance,
        plus: plus,
        ads: ads,
      ),
    ),
  );
}
