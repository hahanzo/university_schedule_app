import 'package:flutter/material.dart';
import 'package:university_schedule_app/l10n/app_localizations.dart';
import '../../../../core/constants/app_constants.dart';

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
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => FocusManager.instance.primaryFocus?.unfocus(),
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
