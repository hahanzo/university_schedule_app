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
  late String _selectedPlatform;
  late TextEditingController _urlController;

  static const List<String> _platforms = [
    'Phone',
    'Telegram',
    'Instagram',
    'Facebook',
    'WhatsApp',
    'LinkedIn',
    'YouTube',
    'TikTok',
    'Website',
  ];

  @override
  void initState() {
    super.initState();
    final initial = widget.initialPlatform.trim();
    if (_platforms.contains(initial)) {
      _selectedPlatform = initial;
    } else if (initial.isEmpty) {
      _selectedPlatform = 'Telegram';
    } else {
      _selectedPlatform = 'Website';
    }
    _urlController = TextEditingController(text: widget.initialUrl);
    
    // If initially empty, notify the parent of the default 'Telegram' choice
    if (widget.initialPlatform.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _notify();
      });
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _notify() => widget.onChanged(_selectedPlatform, _urlController.text);

  IconData _getPlatformIcon(String platform) {
    switch (platform) {
      case 'Phone':
        return Icons.phone;
      case 'Telegram':
        return Icons.send;
      case 'Instagram':
        return Icons.camera_alt;
      case 'Facebook':
        return Icons.facebook;
      case 'WhatsApp':
        return Icons.chat;
      case 'LinkedIn':
        return Icons.work;
      case 'YouTube':
        return Icons.play_circle;
      case 'TikTok':
        return Icons.music_note;
      default:
        return Icons.link;
    }
  }

  static const _fieldBorder = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(12)),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedPlatform,
                    decoration: const InputDecoration(
                      labelText: 'Платформа',
                      isDense: true,
                      border: _fieldBorder,
                    ),
                    items: _platforms.map((platform) {
                      return DropdownMenuItem<String>(
                        value: platform,
                        child: Row(
                          children: [
                            Icon(
                              _getPlatformIcon(platform),
                              size: 18,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 10),
                            Text(platform),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedPlatform = value;
                        });
                        _notify();
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: widget.onRemove,
                  icon: Icon(
                    Icons.delete_outline,
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'Посилання або номер телефону',
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
