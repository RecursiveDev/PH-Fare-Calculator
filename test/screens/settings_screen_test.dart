import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:ph_fare_estimator/src/l10n/app_localizations.dart';
import 'package:ph_fare_estimator/src/models/fare_formula.dart';
import 'package:ph_fare_estimator/src/presentation/screens/settings_screen.dart';
import 'package:ph_fare_estimator/src/repositories/fare_repository.dart';
import 'package:ph_fare_estimator/src/services/settings_service.dart';

import '../helpers/mocks.dart';

void main() {
  late MockSettingsService mockSettingsService;
  late MockFareRepository mockFareRepository;

  setUp(() {
    mockSettingsService = MockSettingsService();
    mockFareRepository = MockFareRepository();

    final getIt = GetIt.instance;
    if (getIt.isRegistered<SettingsService>()) {
      getIt.unregister<SettingsService>();
    }
    if (getIt.isRegistered<FareRepository>()) {
      getIt.unregister<FareRepository>();
    }
    getIt.registerSingleton<SettingsService>(mockSettingsService);
    getIt.registerSingleton<FareRepository>(mockFareRepository);
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const SettingsScreen(),
    );
  }

  testWidgets('SettingsScreen renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Provincial Mode'), findsOneWidget);
    expect(find.text('High Contrast Mode'), findsOneWidget);
    expect(find.text('Traffic Factor'), findsOneWidget);
    expect(find.text('Passenger Type'), findsOneWidget);
    expect(find.text('Transport Modes'), findsOneWidget);
  });

  testWidgets('Toggles update settings service', (WidgetTester tester) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // 1. Toggle Provincial Mode
    final provincialSwitch = find.widgetWithText(
      SwitchListTile,
      'Provincial Mode',
    );
    await tester.tap(provincialSwitch);
    await tester.pumpAndSettle();

    expect(mockSettingsService.provincialMode, true);

    // 2. Toggle High Contrast
    final highContrastSwitch = find.widgetWithText(
      SwitchListTile,
      'High Contrast Mode',
    );
    await tester.tap(highContrastSwitch);
    await tester.pumpAndSettle();

    expect(mockSettingsService.highContrast, true);
  });

  testWidgets('Traffic Factor selection updates settings service', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Select High Traffic
    final highTrafficRadio = find.widgetWithText(
      RadioListTile<TrafficFactor>,
      'High',
    );
    await tester.tap(highTrafficRadio);
    await tester.pumpAndSettle();

    expect(mockSettingsService.trafficFactor, TrafficFactor.high);
  });

  testWidgets('Transport modes are grouped by category', (
    WidgetTester tester,
  ) async {
    // Add formulas to mock so we can test category grouping
    mockFareRepository.formulasToReturn = [
      FareFormula(
        mode: 'Jeepney',
        subType: 'Traditional',
        baseFare: 13.0,
        perKmRate: 1.80,
      ),
    ];

    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // The Phase 5 refactor groups modes by category (Road, Rail, Water)
    expect(find.text('Transport Modes'), findsOneWidget);
    // With Jeepney formula, we should see the Road category
    expect(find.text('Road'), findsOneWidget);
  });
}
