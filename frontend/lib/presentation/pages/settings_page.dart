import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/services/localization_service.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final localizationService = context.watch<LocalizationService>();
    
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: SizedBox(
                width: 200,
                child: ListView(
                  children: [
                    ListTile(
                      selected: true,
                      leading: const Icon(Icons.business),
                      title: Text(localizationService.translate('generalSettings')),
                    ),
                    ListTile(
                      leading: const Icon(Icons.work),
                      title: Text(localizationService.translate('departmentSettings')),
                    ),
                    ListTile(
                      leading: const Icon(Icons.access_time),
                      title: Text(localizationService.translate('workingHours')),
                    ),
                    ListTile(
                      leading: const Icon(Icons.notifications),
                      title: Text(localizationService.translate('notifications')),
                    ),
                    ListTile(
                      leading: const Icon(Icons.backup),
                      title: Text(localizationService.translate('backup')),
                    ),
                    ListTile(
                      leading: const Icon(Icons.security),
                      title: Text(localizationService.translate('security')),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        localizationService.translate('generalSettings'),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        textDirection: TextDirection.rtl,
                        decoration: InputDecoration(
                          labelText: localizationService.translate('appName'),
                          hintText: localizationService.translate('appName'),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        textDirection: TextDirection.rtl,
                        decoration: InputDecoration(
                          labelText: localizationService.translate('address'),
                          hintText: localizationService.translate('enterAddress'),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () {
                                // TODO: Implement logo upload
                              },
                              icon: const Icon(Icons.upload),
                              label: Text(localizationService.translate('uploadLogo')),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () {
                                // TODO: Save settings
                              },
                              icon: const Icon(Icons.save),
                              label: Text(localizationService.translate('save')),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 