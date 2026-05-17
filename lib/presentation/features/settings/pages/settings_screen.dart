import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../l10n/app_localizations.dart';
import '../../auth/blocs/auth_cubit.dart';
import '../../auth/blocs/auth_state.dart';
import '../blocs/settings_cubit.dart';
import '../blocs/settings_state.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Налаштування'),
        centerTitle: true,
      ),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          final userProfile = authState.maybeWhen(
            authenticated: (user) => user,
            orElse: () => null,
          );

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (userProfile != null) ...[
                Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Icon(
                        Icons.person,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    title: Text(
                      userProfile.name,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      '${userProfile.email} • ${userProfile.role == 'teacher' ? l10n.teachers : l10n.students}',
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // Theme section
              BlocBuilder<SettingsCubit, SettingsState>(
                builder: (context, state) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Text(
                          'Тема',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _ThemeOption(
                        title: 'Системна',
                        value: ThemeMode.system,
                        groupValue: state.themeMode,
                        onChanged: (v) =>
                            context.read<SettingsCubit>().changeTheme(v!),
                      ),
                      _ThemeOption(
                        title: 'Світла',
                        value: ThemeMode.light,
                        groupValue: state.themeMode,
                        onChanged: (v) =>
                            context.read<SettingsCubit>().changeTheme(v!),
                      ),
                      _ThemeOption(
                        title: 'Темна',
                        value: ThemeMode.dark,
                        groupValue: state.themeMode,
                        onChanged: (v) =>
                            context.read<SettingsCubit>().changeTheme(v!),
                      ),
                    ],
                  );
                },
              ),
              const Divider(height: 32),

              // Locale section
              BlocBuilder<SettingsCubit, SettingsState>(
                builder: (context, state) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Text(
                          'Мова',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _LocaleOption(
                        title: 'Українська',
                        value: const Locale('uk'),
                        groupValue: state.locale,
                        onChanged: (v) =>
                            context.read<SettingsCubit>().changeLocale(v!),
                      ),
                      _LocaleOption(
                        title: 'English',
                        value: const Locale('en'),
                        groupValue: state.locale,
                        onChanged: (v) =>
                            context.read<SettingsCubit>().changeLocale(v!),
                      ),
                    ],
                  );
                },
              ),
              const Divider(height: 32),

              // Sign out
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Вийти',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () => context.read<AuthCubit>().signOut(),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final String title;
  final ThemeMode value;
  final ThemeMode groupValue;
  final ValueChanged<ThemeMode?> onChanged;

  const _ThemeOption({
    required this.title,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      leading: GestureDetector(
        onTap: () => onChanged(value),
        child: Icon(
          groupValue == value
              ? Icons.radio_button_checked
              : Icons.radio_button_off,
          color: groupValue == value
              ? Theme.of(context).colorScheme.primary
              : null,
        ),
      ),
      onTap: () => onChanged(value),
    );
  }
}

class _LocaleOption extends StatelessWidget {
  final String title;
  final Locale value;
  final Locale groupValue;
  final ValueChanged<Locale?> onChanged;

  const _LocaleOption({
    required this.title,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      leading: GestureDetector(
        onTap: () => onChanged(value),
        child: Icon(
          groupValue == value
              ? Icons.radio_button_checked
              : Icons.radio_button_off,
          color: groupValue == value
              ? Theme.of(context).colorScheme.primary
              : null,
        ),
      ),
      onTap: () => onChanged(value),
    );
  }
}
