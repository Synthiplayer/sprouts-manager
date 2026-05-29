import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/user_manager.dart';

class UserManagementPage extends StatelessWidget {
  const UserManagementPage({super.key});

  @override
  Widget build(BuildContext context) {
    final userManager = Provider.of<UserManager>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Benutzerverwaltung'),
      ),
      body: ListView.builder(
        itemCount: userManager.users.length,
        itemBuilder: (context, index) {
          final user = userManager.users[index];
          return ListTile(
            title: Text('${user.vorname} ${user.nachname}'),
            subtitle: Text('E-Mail: ${user.email ?? 'Keine E-Mail'}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    // Hier könnte ein Bearbeitungsdialog geöffnet werden
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    userManager.deleteUser(user.id);
                  },
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Hier kann ein Dialog zum Hinzufügen neuer Benutzer geöffnet werden
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
