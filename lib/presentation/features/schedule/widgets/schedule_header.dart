import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:university_schedule_app/l10n/app_localizations.dart';
import '../../../../core/constants/app_constants.dart';
import '../../auth/blocs/auth_cubit.dart';
import '../../auth/blocs/auth_state.dart';
import '../pages/notifications_screen.dart';

class ScheduleHeader extends StatefulWidget {
  final VoidCallback onFilterPressed;
  final ValueChanged<String> onSearchChanged;

  const ScheduleHeader({
    super.key,
    required this.onFilterPressed,
    required this.onSearchChanged,
  });

  @override
  State<ScheduleHeader> createState() => _ScheduleHeaderState();
}

class _ScheduleHeaderState extends State<ScheduleHeader>
    with WidgetsBindingObserver {
  final FocusNode _focusNode = FocusNode();
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_focusNode.hasFocus) {
        _focusNode.unfocus();
        Future.delayed(const Duration(milliseconds: 50), () {
          if (mounted) _focusNode.requestFocus();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ScheduleUiConstants.scheduleHeaderPaddingHorizontal,
        ScheduleUiConstants.scheduleHeaderPaddingTop,
        ScheduleUiConstants.scheduleHeaderPaddingHorizontal,
        ScheduleUiConstants.scheduleHeaderPaddingBottom,
      ),
      child: Row(
        children: [
          Builder(
            builder: (context) {
              final authState = context.watch<AuthCubit>().state;
              final user = authState.maybeWhen(
                authenticated: (u) => u,
                orElse: () => null,
              );

              if (user == null) {
                return IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {},
                );
              }

              final bool isTeacher = user.role == AppConstants.teacherRole;
              Query query = FirebaseFirestore.instance.collection('notifications');
              if (isTeacher) {
                query = query.where('teacherName', isEqualTo: user.name);
              } else {
                query = query.where('groupId', isEqualTo: user.groupId ?? '');
              }

              return StreamBuilder<QuerySnapshot>(
                stream: query.snapshots(),
                builder: (context, snapshot) {
                  int unreadCount = 0;
                  if (snapshot.hasData) {
                    if (isTeacher) {
                      unreadCount = 0;
                    } else {
                      unreadCount = snapshot.data!.docs.where((doc) {
                        final data = doc.data() as Map<String, dynamic>? ?? {};
                        final isReadBy = data['isReadBy'] as Map<String, dynamic>? ?? {};
                        return isReadBy[user.uid] != true;
                      }).length;
                    }
                  }

                  return Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined),
                        onPressed: () {
                          FocusManager.instance.primaryFocus?.unfocus();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const NotificationsScreen(),
                            ),
                          );
                        },
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.error,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 14,
                              minHeight: 14,
                            ),
                            child: Text(
                              '$unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TapRegion(
              onTapOutside: (event) => _focusNode.unfocus(),
              child: Container(
                height: ScheduleUiConstants.scheduleHeaderHeight,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(
                    ScheduleUiConstants.scheduleHeaderBorderRadius,
                  ),
                ),
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _controller,
                  builder: (context, value, _) {
                    return TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      onTap: () {
                        if (!_focusNode.hasFocus) {
                          _focusNode.requestFocus();
                        }
                      },
                      onChanged: widget.onSearchChanged,
                      onSubmitted: (value) => _focusNode.unfocus(),
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(context)!.searchSchedule,
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: value.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () {
                                  _controller.clear();
                                  widget.onSearchChanged('');
                                  _focusNode.unfocus();
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 15,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () {
              _focusNode.unfocus();
              widget.onFilterPressed();
            },
          ),
        ],
      ),
    );
  }
}
