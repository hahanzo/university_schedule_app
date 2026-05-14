import 'package:flutter/material.dart';

class SelectionBottomSheet extends StatelessWidget {
  final String title;
  final List<String> items;
  final Function(String) onItemSelected;

  const SelectionBottomSheet({
    super.key, 
    required this.title, 
    required this.items, 
    required this.onItemSelected
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const Divider(),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: items.length,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return ListTile(
                    leading: const Icon(Icons.refresh, color: Colors.red),
                    title: const Text('Скинути фільтр', style: TextStyle(color: Colors.red)),
                    onTap: () {
                      // Pass null to clear the filter in Cubit
                      onItemSelected('RESET'); 
                      Navigator.pop(context);
                    },
                  );
                }
                
                return ListTile(
                  title: Text(items[index]),
                  onTap: () {
                    onItemSelected(items[index]);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}