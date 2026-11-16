import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymmane/l10n/l10n.dart';
import 'package:gymmane/screens/help_topics.dart';
import 'package:gymmane/screens/settings_screen.dart';
import 'package:gymmane/services/local_store.dart';
import 'package:gymmane/services/rest_alarm.dart';
import 'package:gymmane/state/fit_state.dart';
import 'package:gymmane/theme/app_theme.dart';
import 'package:gymmane/widgets/nfc_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('#181 negro AMOLED', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await Store.instance.init();
      fit.resetAllData();
      fit.onboarded = true;
    });

    test('es un tema oscuro aparte y se recuerda', () {
      fit.setThemePref('amoled');
      expect(fit.dark, isTrue);
      expect(fit.themeMode, ThemeMode.dark);
      fit.persistNow();
      fit.loadFromStore();
      expect(fit.themePref, 'amoled');
      fit.setThemePref('dark');
      expect(fit.themePref, 'dark');
    });
  });

  group('#206 fotos tapadas en Progreso', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await Store.instance.init();
      fit.resetAllData();
      fit.onboarded = true;
    });

    test('se recuerda al reiniciar', () {
      expect(fit.hideShots, isFalse);
      fit.toggleHideShots();
      fit.persistNow();
      fit.hideShots = false;
      fit.loadFromStore();
      expect(fit.hideShots, isTrue);
      fit.resetAllData();
      expect(fit.hideShots, isFalse);
    });
  });

  group('settings', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await Store.instance.init();
      fit.resetAllData();
      fit.setUnits('kg');
    });

    tearDown(() {
      if (fit.session != null) fit.saveAndExit();
    });

    test('the theme can follow the phone and older backups still load', () {
      fit.setThemePref('system');
      fit.persistNow();
      fit.loadFromStore();
      expect(fit.themePref, 'system');
      fit.applyBackup({'dark': false});
      expect(fit.themePref, 'light');
      fit.setThemePref('dark');
    });

    test('NFC is opt-in for older backups and remembers when turned off', () {
      fit.applyBackup({'theme': 'light'});
      expect(fit.nfcTag, isFalse);
      expect(fit.toJson(), isNot(contains('nfc')));

      fit.setNfcTag(true);
      fit.persistNow();
      fit.loadFromStore();
      expect(fit.nfcTag, isTrue);

      fit.setNfcTag(false);
      fit.persistNow();
      fit.loadFromStore();
      expect(fit.nfcTag, isFalse);
    });

    testWidgets('the NFC shortcut opens the scheduled routine only when enabled', (tester) async {
      fit.onboarded = true;
      fit.setNfcTag(false);
      const name = 'NFC scheduled fixture';
      final id = fit.createRoutine(name);
      fit.toggleRoutineExercise(id, fit.allExercises.first.id);
      fit.weeklyPlan[DateTime.now().weekday] = id;
      late BuildContext context;
      await tester.pumpWidget(MaterialApp(
        theme: AppTheme.dark,
        home: Scaffold(body: Builder(builder: (ctx) {
          context = ctx;
          return const SizedBox();
        })),
      ));

      openTodayFromTag(context);
      await tester.pumpAndSettle();
      expect(find.text(name), findsNothing);
      expect(fit.session, isNull);

      fit.setNfcTag(true);
      openTodayFromTag(context);
      await tester.pumpAndSettle();
      expect(find.text(name), findsOneWidget);
      expect(fit.session, isNull);
      expect(fit.weeklyPlan[DateTime.now().weekday], id);
      await tester.pumpWidget(const SizedBox.shrink());
      fit.setNfcTag(false);
      fit.persistNow();
    });

    test('light palette persists independently of brightness and round trips in backups', () {
      fit.setThemePref('amoled');
      fit.setLightPalette('original');
      fit.persistNow();
      fit.lightPalette = 'sage';
      fit.loadFromStore();
      expect(fit.lightPalette, 'original');
      expect(fit.themePref, 'amoled');
      final backup = fit.toJson();
      fit.setLightPalette('sage');
      fit.applyBackup(backup);
      expect(fit.lightPalette, 'original');
      fit.setLightPalette('unknown');
      expect(fit.lightPalette, 'original');
      fit.applyBackup({'theme': 'light'});
      expect(fit.lightPalette, 'sage');
      fit.applyBackup({'theme': 'system', 'lightPalette': 42});
      expect(fit.lightPalette, 'sage');
      expect(fit.themePref, 'system');
    });

    test('the rest alarm style is kept and handed to the alarm', () {
      fit.setAlarmStyle('silent');
      expect(RestAlarm.instance.style, 'silent');
      fit.persistNow();
      fit.loadFromStore();
      expect(fit.alarmStyle, 'silent');
      fit.setAlarmStyle('loud');
    });

    test('legacy vibration-only backups load without sound or vibration', () {
      fit.applyBackup({'alarmStyle': 'vibrate'});
      expect(fit.alarmStyle, 'silent');
      expect(RestAlarm.instance.style, 'silent');
    });

    test('height reads in feet and inches for imperial users', () {
      fit.setUnits('lb');
      expect(fit.heightLabel(175), '5′ 9″');
      fit.setUnits('kg');
      expect(fit.heightLabel(175), '175 cm');
    });
  });

  group('tamaño del texto y animaciones', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await Store.instance.init();
      fit.resetAllData();
      fit.onboarded = true;
    });

    test('se eligen, se recuerdan y lo raro no entra', () {
      expect(fit.textFactor, 1.0);
      fit.setTextSize('large');
      fit.setTextSize('giant');
      fit.setCalmMotion(true);
      fit.persistNow();
      fit.loadFromStore();
      expect(fit.textSize, 'large');
      expect(fit.textFactor, greaterThan(1));
      expect(fit.calmMotion, isTrue);
    });

    test('independent display effects survive persistence and older backups', () {
      fit.applyBackup({'blur': false, 'calm': true, 'fine': true, 'hz': true});
      expect((fit.blurOn, fit.calmMotion), (false, true));
      expect(fit.toJson(), isNot(contains('fine')));
      expect(fit.toJson(), isNot(contains('hz')));

      fit.setBlur(true);
      expect((fit.blurOn, fit.calmMotion), (true, true));
      fit.persistNow();
      fit.loadFromStore();
      expect((fit.blurOn, fit.calmMotion), (true, true));

      fit.setCalmMotion(false);
      expect((fit.blurOn, fit.calmMotion), (true, false));
      fit.applyBackup({'onboarded': true});
      expect((fit.blurOn, fit.calmMotion), (true, false));
    });
  });

  group('#92 inicio de semana', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await Store.instance.init();
      fit.resetAllData();
      fit.setUnits('kg');
    });

    tearDown(() {
      if (fit.session != null) fit.saveAndExit();
    });

    test('empezar en domingo mueve toda la semana', () {
      fit.setWeekStart(DateTime.sunday);
      expect(fit.weekStartDate.weekday, DateTime.sunday);
      expect(fit.weekdayAt(0), DateTime.sunday);
      expect(fit.dateForWeekday(fit.todayIndex).day, DateTime.now().day);
    });

    test('se guarda con el resto de ajustes', () {
      fit.setWeekStart(DateTime.saturday);
      expect(fit.toJson()['weekStart'], DateTime.saturday);
      fit.setWeekStart(4);
      expect(fit.weekStartDay, DateTime.saturday, reason: 'solo lunes, sábado o domingo');
    });
  });

  test('el texto de Apoyo pide primero el café y luego la estrella, en todos los idiomas', () {
    for (final locale in AppLocalizations.supportedLocales) {
      final t = lookupAppLocalizations(locale);
      final body = t.supportThanksBody;
      expect(t.supportThanksTitle, contains('🤍'), reason: '$locale');
      expect(body.split('\n\n').length, 2, reason: '$locale: dos párrafos');
      final coffee = body.indexOf('☕'), star = body.indexOf('⭐');
      expect(coffee, greaterThan(0), reason: '$locale');
      expect(star, greaterThan(coffee), reason: '$locale: la estrella va después del café');
    }
  });

  group('guía en el buscador', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await Store.instance.init();
      fit.resetAllData();
      fit.onboarded = true;
      fit.nutritionBeta = true;
    });

    for (final lang in ['en', 'es']) {
      test('cada respuesta que lleva a Ajustes apunta a una fila que existe ($lang)', () {
        setAppLanguage(lang);
        final rows = const SettingsScreen().searchRows.toSet();
        final topics = helpTopics();
        expect(topics.map((h) => h.id).toSet().length, topics.length, reason: 'ids repetidos');
        for (final h in topics) {
          if (h.section == null) continue;
          if (h.row == null) {
            expect(rows.any((r) => r.$1 == h.section), isTrue, reason: '${h.id} lleva a ${h.section}');
            continue;
          }
          expect(rows.contains((h.section!, h.row!)), isTrue, reason: '${h.id} lleva a ${h.section} › ${h.row}');
        }
        for (final id in kHelpCommon.where((id) => id != 'steps')) {
          expect(topics.any((h) => h.id == id), isTrue, reason: 'frecuente sin entrada: $id');
        }
        for (final h in topics) {
          expect(h.answer.contains('{'), isFalse, reason: '${h.id} con hueco sin rellenar');
        }
      });
    }

    test('se encuentra preguntando con palabras sueltas, sin tildes ni orden', () {
      setAppLanguage('es');
      final topics = helpTopics();
      List<String> find(String q) => [for (final h in topics) if (h.matches(q)) h.id];
      expect(find('superserie'), contains('superset'));
      expect(find('movil nuevo'), contains('phone'));
      expect(find('lenta'), contains('slow'));
      expect(find('lyfta'), contains('import'));
      expect(find('hevy'), contains('import'));
      expect(find('8-12'), contains('range'));
      expect(find('mancuernas'), contains('pair'));
      expect(find('x'), isEmpty);
      setAppLanguage('en');
    });
  });
}
