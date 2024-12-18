import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleManager {
  LocaleManager._();
  static final LocaleManager instance = LocaleManager._();

  Future<Locale> getLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('lang') ?? 'ko';
    return Locale(languageCode);
  }

  Future<void> setLocale(BuildContext context, String lang) async {
    final Locale locale = Locale(lang);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lang', locale.languageCode);
    if (context.mounted) {
      await context.setLocale(locale);
    }
  }
}
