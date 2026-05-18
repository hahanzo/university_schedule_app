import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/constants/dev_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../blocs/auth_cubit.dart';
import '../blocs/auth_state.dart';

const bool _kUseEmulators = bool.fromEnvironment(
  'USE_FIREBASE_EMULATORS',
  defaultValue: true,
);

class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key});

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> {
  bool _isLoading = false;
  String? _error;

  Future<void> _onGoogleButtonPressed() async {
    if (_kUseEmulators) {
      await _showEmulatorRoleDialog();
    } else {
      await _signInWithGoogle();
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await context.read<AuthCubit>().signInWithGoogle();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  Future<void> _showEmulatorRoleDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const _EmulatorRoleDialog(),
    );
    if (result == null) return;
    await _devSignIn(account: result);
  }

  Future<void> _devSignIn({required Map<String, dynamic> account}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final email = account['email'] as String;
      final isTeacher = account['role'] == 'teacher';

      UserCredential cred;
      try {
        cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: DevConstants.testPassword,
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found' ||
            e.code == 'CONFIGURATION_NOT_FOUND' ||
            e.code == 'invalid-credential') {
          cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: email,
            password: DevConstants.testPassword,
          );
        } else {
          rethrow;
        }
      }

      final uid = cred.user!.uid;
      final doc = FirebaseFirestore.instance.collection('users').doc(uid);
      if (!(await doc.get()).exists) {
        final name = account['name'] as String;
        await doc.set({
          'name': name,
          'nameLower': name.toLowerCase(),
          'email': email,
          'role': account['role'],
          if (isTeacher) 'teacherId': account['teacherId'],
          if (!isTeacher) 'groupId': account['groupId'],
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final primaryColor = AppTheme.getAuthPrimaryColor(context);
    final l10n = AppLocalizations.of(context)!;

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        state.maybeWhen(
          loading: () {
            if (mounted) setState(() => _isLoading = true);
          },
          authenticated: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
          unauthenticated: () {
            if (mounted) setState(() => _isLoading = false);
          },
          error: (message) {
            if (mounted) {
              setState(() {
                _isLoading = false;
                _error = message;
              });
            }
          },
          orElse: () {},
        );
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: SvgPicture.asset(
                          'assets/images/logo.svg',
                          height: MediaQuery.of(context).size.height * 0.35,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'Forestry Time',
                        style: theme.textTheme.headlineLarge?.copyWith(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.appTitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                Column(
                  children: [
                    if (_error != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: colorScheme.onErrorContainer,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _error!,
                                style: TextStyle(
                                  color: colorScheme.onErrorContainer,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : _onGoogleButtonPressed,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: primaryColor, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isLoading
                            ? SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: primaryColor,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SvgPicture.asset(
                                    'assets/images/material-icon-theme_google.svg',
                                    height: 24,
                                    width: 24,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    l10n.signInWithGoogle,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.useUniversityEmail,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmulatorRoleDialog extends StatefulWidget {
  const _EmulatorRoleDialog();

  @override
  State<_EmulatorRoleDialog> createState() => _EmulatorRoleDialogState();
}

class _EmulatorRoleDialogState extends State<_EmulatorRoleDialog> {
  bool _isLoading = true;
  String? _error;
  List<dynamic> _students = [];
  List<dynamic> _teachers = [];

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('config')
          .doc('test_accounts')
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        _students = data['students'] as List<dynamic>? ?? [];
        _teachers = data['teachers'] as List<dynamic>? ?? [];
      }
      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  Widget _buildContent(ThemeData theme) {
    final l10n = AppLocalizations.of(context)!;
    if (_isLoading) {
      return const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          '${l10n.errorPrefix}: $_error',
          style: TextStyle(color: theme.colorScheme.error),
        ),
      );
    }
    if (_students.isEmpty && _teachers.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          l10n.noTestAccounts,
          textAlign: TextAlign.center,
        ),
      );
    }

    return SizedBox(
      width: double.maxFinite,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_students.isNotEmpty) ...[
              Text(
                l10n.students,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              ..._students.map((s) {
                final Map<String, dynamic> acc = Map<String, dynamic>.from(
                  s as Map,
                );
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: _RoleCard(
                    icon: Icons.school_outlined,
                    title: acc['name'] as String? ?? '',
                    subtitle: '${acc['email']}\n${l10n.group}: ${acc['groupId']}',
                    color: theme.colorScheme.primary,
                    onTap: () => Navigator.of(context).pop(acc),
                  ),
                );
              }),
              const SizedBox(height: 16),
            ],
            if (_teachers.isNotEmpty) ...[
              Text(
                l10n.teachers,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.teal,
                ),
              ),
              const SizedBox(height: 8),
              ..._teachers.map((t) {
                final Map<String, dynamic> acc = Map<String, dynamic>.from(
                  t as Map,
                );
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: _RoleCard(
                    icon: Icons.person_outlined,
                    title: acc['name'] as String? ?? '',
                    subtitle: '${acc['email']}\nID: ${acc['teacherId']}',
                    color: Colors.teal,
                    onTap: () => Navigator.of(context).pop(acc),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.developer_mode,
              color: Colors.orange,
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          Text(l10n.emulatorMode, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 4),
          Text(
            l10n.chooseRoleForTesting,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      titleTextStyle: theme.textTheme.titleLarge,
      content: _buildContent(theme),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text(
            l10n.cancel,
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
