import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../l10n/app_localizations.dart';
import '../../auth/blocs/auth_cubit.dart';
import '../../auth/blocs/auth_state.dart';
import '../blocs/settings_cubit.dart';
import '../blocs/settings_state.dart';
import '../widgets/settings_choice_tile.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings), centerTitle: true),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          final userProfile = authState.maybeWhen(
            authenticated: (user) => user,
            orElse: () => null,
          );

          return ListView(
            padding: const EdgeInsets.all(
              SettingsUiConstants.horizontalPadding,
            ),
            children: [
              if (userProfile != null) ...[
                Card(
                  margin: const EdgeInsets.only(
                    bottom: SettingsUiConstants.userCardMarginBottom,
                  ),
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
                      '${userProfile.email} • ${userProfile.role == AppConstants.teacherRole ? l10n.teachers : l10n.students}',
                    ),
                  ),
                ),
                const SizedBox(
                  height: SettingsUiConstants.verticalPaddingSmall,
                ),
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
                          l10n.theme,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SettingsChoiceTile<ThemeMode>(
                        title: l10n.system,
                        value: ThemeMode.system,
                        groupValue: state.themeMode,
                        onChanged: (v) =>
                            context.read<SettingsCubit>().changeTheme(v!),
                      ),
                      SettingsChoiceTile<ThemeMode>(
                        title: l10n.light,
                        value: ThemeMode.light,
                        groupValue: state.themeMode,
                        onChanged: (v) =>
                            context.read<SettingsCubit>().changeTheme(v!),
                      ),
                      SettingsChoiceTile<ThemeMode>(
                        title: l10n.dark,
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
                          l10n.language,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SettingsChoiceTile<Locale>(
                        title: l10n.ukrainian,
                        value: const Locale('uk'),
                        groupValue: state.locale,
                        onChanged: (v) =>
                            context.read<SettingsCubit>().changeLocale(v!),
                      ),
                      SettingsChoiceTile<Locale>(
                        title: l10n.english,
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
                title: Text(
                  l10n.signOut,
                  style: const TextStyle(color: Colors.red),
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
