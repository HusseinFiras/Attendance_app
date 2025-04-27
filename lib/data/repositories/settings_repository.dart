import '../database/database.dart';

class SettingsRepository {
  final AppDatabase _db;

  SettingsRepository(this._db);

  Future<String?> getSetting(String key) => _db.getSetting(key);

  Future<void> setSetting(String key, String value) =>
      _db.setSetting(key, value);

  Future<Map<String, String>> getAllSettings() async {
    final settings = await _db.select(_db.settings).get();
    return {for (var setting in settings) setting.key: setting.value};
  }

  Future<void> setCompanyInfo({
    required String name,
    required String address,
    required String phone,
    required String email,
    String? description,
  }) async {
    await setSetting('company_name', name);
    await setSetting('company_address', address);
    await setSetting('company_phone', phone);
    await setSetting('company_email', email);
    if (description != null) {
      await setSetting('company_description', description);
    }
  }

  Future<Map<String, String>> getCompanyInfo() async {
    final companyInfo = await Future.wait([
      getSetting('company_name'),
      getSetting('company_address'),
      getSetting('company_phone'),
      getSetting('company_email'),
      getSetting('company_description'),
    ]);

    return {
      'name': companyInfo[0] ?? '',
      'address': companyInfo[1] ?? '',
      'phone': companyInfo[2] ?? '',
      'email': companyInfo[3] ?? '',
      'description': companyInfo[4] ?? '',
    };
  }

  Future<void> setWorkingHours({
    required String startTime,
    required String endTime,
    required List<String> workingDays,
  }) async {
    await setSetting('working_hours_start', startTime);
    await setSetting('working_hours_end', endTime);
    await setSetting('working_days', workingDays.join(','));
  }

  Future<Map<String, dynamic>> getWorkingHours() async {
    final workingHours = await Future.wait([
      getSetting('working_hours_start'),
      getSetting('working_hours_end'),
      getSetting('working_days'),
    ]);

    return {
      'startTime': workingHours[0] ?? '09:00',
      'endTime': workingHours[1] ?? '17:00',
      'workingDays': (workingHours[2] ?? 'Monday,Tuesday,Wednesday,Thursday,Friday')
          .split(','),
    };
  }
} 