import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_uk.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('uk'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In uk, this message translates to:
  /// **'Розклад Університету'**
  String get appTitle;

  /// No description provided for @monday.
  ///
  /// In uk, this message translates to:
  /// **'Понеділок'**
  String get monday;

  /// No description provided for @tuesday.
  ///
  /// In uk, this message translates to:
  /// **'Вівторок'**
  String get tuesday;

  /// No description provided for @wednesday.
  ///
  /// In uk, this message translates to:
  /// **'Середа'**
  String get wednesday;

  /// No description provided for @thursday.
  ///
  /// In uk, this message translates to:
  /// **'Четвер'**
  String get thursday;

  /// No description provided for @friday.
  ///
  /// In uk, this message translates to:
  /// **'П\'ятниця'**
  String get friday;

  /// No description provided for @saturday.
  ///
  /// In uk, this message translates to:
  /// **'Субота'**
  String get saturday;

  /// No description provided for @sunday.
  ///
  /// In uk, this message translates to:
  /// **'Неділя'**
  String get sunday;

  /// No description provided for @teacher.
  ///
  /// In uk, this message translates to:
  /// **'Викладач'**
  String get teacher;

  /// No description provided for @subject.
  ///
  /// In uk, this message translates to:
  /// **'Предмет'**
  String get subject;

  /// No description provided for @time.
  ///
  /// In uk, this message translates to:
  /// **'Година'**
  String get time;

  /// No description provided for @loading.
  ///
  /// In uk, this message translates to:
  /// **'Завантаження...'**
  String get loading;

  /// No description provided for @noResults.
  ///
  /// In uk, this message translates to:
  /// **'Нічого не знайдено 🔍'**
  String get noResults;

  /// No description provided for @add.
  ///
  /// In uk, this message translates to:
  /// **'Додати'**
  String get add;

  /// No description provided for @completed.
  ///
  /// In uk, this message translates to:
  /// **'Завершено'**
  String get completed;

  /// No description provided for @searchPlaceholder.
  ///
  /// In uk, this message translates to:
  /// **'Викладач, предмет...'**
  String get searchPlaceholder;

  /// No description provided for @clearFilter.
  ///
  /// In uk, this message translates to:
  /// **'Скинути фільтр'**
  String get clearFilter;

  /// No description provided for @lecture.
  ///
  /// In uk, this message translates to:
  /// **'лекція'**
  String get lecture;

  /// No description provided for @lab.
  ///
  /// In uk, this message translates to:
  /// **'лаб. роб'**
  String get lab;

  /// No description provided for @practice.
  ///
  /// In uk, this message translates to:
  /// **'прак. роб'**
  String get practice;

  /// No description provided for @selectGroups.
  ///
  /// In uk, this message translates to:
  /// **'Виберіть групи'**
  String get selectGroups;

  /// No description provided for @selectedGroups.
  ///
  /// In uk, this message translates to:
  /// **'Вибрані групи'**
  String get selectedGroups;

  /// No description provided for @searchGroup.
  ///
  /// In uk, this message translates to:
  /// **'Пошук групи...'**
  String get searchGroup;

  /// No description provided for @groupsForSelection.
  ///
  /// In uk, this message translates to:
  /// **'Групи для вибору'**
  String get groupsForSelection;

  /// No description provided for @groupsNotFound.
  ///
  /// In uk, this message translates to:
  /// **'Групи не знайдені'**
  String get groupsNotFound;

  /// No description provided for @save.
  ///
  /// In uk, this message translates to:
  /// **'Зберегти'**
  String get save;

  /// No description provided for @done.
  ///
  /// In uk, this message translates to:
  /// **'Готово'**
  String get done;

  /// No description provided for @minOneGroup.
  ///
  /// In uk, this message translates to:
  /// **'Мінімум одна група повинна бути вибрана'**
  String get minOneGroup;

  /// No description provided for @searchSchedule.
  ///
  /// In uk, this message translates to:
  /// **'Пошук розкладу'**
  String get searchSchedule;

  /// No description provided for @numerator.
  ///
  /// In uk, this message translates to:
  /// **'Чисельник'**
  String get numerator;

  /// No description provided for @denominator.
  ///
  /// In uk, this message translates to:
  /// **'Знаменник'**
  String get denominator;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'uk'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'uk':
      return AppLocalizationsUk();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
