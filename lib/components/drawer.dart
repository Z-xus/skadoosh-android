import 'package:flutter/material.dart';
import 'package:skadoosh_app/components/drawer_tile.dart';
import 'package:skadoosh_app/pages/settings.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          // header
          DrawerHeader(child: const Icon(Icons.edit, size: 30)),

          // notes tile
          const SizedBox(height: 25),

          DrawerTile(
            title: "Notes",
            leading: const Icon(Icons.note),
            onTap: () => Navigator.pop(context),
          ),
          // settings tile
          DrawerTile(
            title: "Settings",
            leading: const Icon(Icons.settings),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}
