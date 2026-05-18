import 'package:flutter/material.dart';

class SocialLinkRow extends StatefulWidget {
  final String initialPlatform;
  final String initialUrl;
  final void Function(String platform, String url) onChanged;
  final VoidCallback onRemove;

  const SocialLinkRow({
    super.key,
    required this.initialPlatform,
    required this.initialUrl,
    required this.onChanged,
    required this.onRemove,
  });

  @override
  State<SocialLinkRow> createState() => _SocialLinkRowState();
}

class _SocialLinkRowState extends State<SocialLinkRow> {
  late TextEditingController _platformController;
  late TextEditingController _urlController;

  static const List<String> _suggestions = [
    'Telegram',
    'Instagram',
    'Facebook',
    'WhatsApp',
    'LinkedIn',
    'YouTube',
    'TikTok',
  ];

  @override
  void initState() {
    super.initState();
    _platformController = TextEditingController(text: widget.initialPlatform);
    _urlController = TextEditingController(text: widget.initialUrl);
  }

  @override
  void dispose() {
    _platformController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  void _notify() =>
      widget.onChanged(_platformController.text, _urlController.text);

  static const _fieldBorder = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(8)),
  );

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Autocomplete<String>(
                    initialValue:
                        TextEditingValue(text: _platformController.text),
                    optionsBuilder: (value) => value.text.isEmpty
                        ? _suggestions
                        : _suggestions.where((s) =>
                            s.toLowerCase().contains(value.text.toLowerCase())),
                    onSelected: (selection) {
                      _platformController.text = selection;
                      _notify();
                    },
                    fieldViewBuilder:
                        (context, controller, focusNode, onSubmitted) {
                      if (controller.text != _platformController.text &&
                          _platformController.text.isNotEmpty) {
                        controller.text = _platformController.text;
                      }
                      return TextField(
                        controller: controller,
                        focusNode: focusNode,
                        decoration: const InputDecoration(
                          labelText: 'Platform',
                          isDense: true,
                          border: _fieldBorder,
                        ),
                        textInputAction: TextInputAction.next,
                        onChanged: (v) {
                          _platformController.text = v;
                          _notify();
                        },
                      );
                    },
                  ),
                ),
                IconButton(
                  onPressed: widget.onRemove,
                  icon: Icon(
                    Icons.close,
                    color: Theme.of(context).colorScheme.error,
                    size: 20,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'Link / contact',
                isDense: true,
                border: _fieldBorder,
              ),
              textInputAction: TextInputAction.next,
              onChanged: (_) => _notify(),
            ),
          ],
        ),
      ),
    );
  }
}
