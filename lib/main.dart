import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'DataBaseHelper.dart';
import 'package:url_launcher/url_launcher.dart';

import 'contact.dart';

void main() {
  runApp(MyApp());
}

class ThemeManager with ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }
}

class MyApp extends StatelessWidget {
  final ThemeManager _themeManager = ThemeManager();

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ThemeManager>(
      create: (_) => _themeManager,
      child: Consumer<ThemeManager>(
        builder: (context, themeManager, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Contact App',
            theme: ThemeData(
              primarySwatch: Colors.blue,
              brightness: themeManager.isDarkMode ? Brightness.dark : Brightness.light,
            ),
            home: ContactList(),
          );
        },
      ),
    );
  }
}

class ContactList extends StatefulWidget {
  @override
  _ContactListState createState() => _ContactListState();
}

class _ContactListState extends State<ContactList> {
  List<Contact> _contacts = [];
  List<Contact> _filteredContacts = [];
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _refreshContacts();
    _searchController.addListener(() {
      _filterContacts();
    });
  }

  void _refreshContacts() async {
    final data = await DatabaseHelper().queryAllContacts();
    setState(() {
      _contacts = data
          .map((item) => Contact(
        id: item['id'],
        name: item['name'],
        firstName: item['firstName'],
        number: item['number'],
      ))
          .toList();
      _filteredContacts = _contacts;
    });
  }

  void _filterContacts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredContacts = _contacts.where((contact) {
        return contact.name.toLowerCase().contains(query) ||
            contact.firstName.toLowerCase().contains(query) ||
            contact.number.contains(query);
      }).toList();
    });
  }

  void _addOrUpdateContact({Contact? contact}) async {
    final result = await showDialog<Contact>(
      context: context,
      builder: (BuildContext context) {
        return ContactDialog(contact: contact);
      },
    );

    if (result != null) {
      bool exists = await DatabaseHelper().contactExists(result.name, result.firstName, result.number);
      if (exists && contact == null) {
        // Show a message that the contact already exists
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ce contact existe déjà!'),
          ),
        );
      } else {
        if (result.id == null) {
          await DatabaseHelper().insertContact(result.toMap());
        } else {
          await DatabaseHelper().updateContact(result.toMap());
        }
        _refreshContacts();
      }
    }
  }

  void _deleteContact(int id) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmation'),
          content: Text('Êtes-vous sûr de vouloir supprimer ce contact ?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Annuler'),
            ),
            TextButton(
              onPressed: () async {
                await DatabaseHelper().deleteContact(id);
                _refreshContacts();
                Navigator.of(context).pop();
              },
              child: Text(
                'Supprimer',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _callNumber(String number) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: number,
    );
    await launchUrl(launchUri);
  }
  Map<String, List<Contact>> _groupByAlphabet(List<Contact> contacts) {
    Map<String, List<Contact>> groupedContacts = {};
    for (var contact in contacts) {
      String firstLetter = contact.firstName[0].toUpperCase();
      if (groupedContacts[firstLetter] == null) {
        groupedContacts[firstLetter] = [];
      }
      groupedContacts[firstLetter]!.add(contact);
    }
    return groupedContacts;
  }
  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context, listen: false);
    var groupedContacts = _groupByAlphabet(_filteredContacts);
    var sortedKeys = groupedContacts.keys.toList()..sort();
    return Scaffold(
      appBar: AppBar(
        title: Text('Contacts'),
        actions: [
          IconButton(
            icon: Icon(themeManager.isDarkMode ? Icons.wb_sunny : Icons.nights_stay),
            onPressed: () => themeManager.toggleDarkMode(),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 7,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Rechercher...',
                  prefixIcon: Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _filterContacts();
                    },
                  )
                      : null,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16.0),
                ),
                onChanged: (value) {
                  _filterContacts();
                },
              ),
            ),
            SizedBox(height: 16.0),
            Expanded(
              child: _filteredContacts.isEmpty
                  ? Center(
                child: _searchController.text.isEmpty
                    ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.search_off,
                      size: 80.0,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16.0),
                    Text(
                      'Commencez à chercher pour voir vos contacts!',
                      style: TextStyle(fontSize: 16.0),
                      textAlign: TextAlign.center,
                    ),
                  ],
                )
                    : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.sentiment_dissatisfied,
                      size: 80.0,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16.0),
                    Text(
                      'Aucun contact trouvé. Essayez un autre terme de recherche!',
                      style: TextStyle(fontSize: 16.0),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                itemCount: sortedKeys.length,
                itemBuilder: (context, index) {
                  String key = sortedKeys[index];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding:
                        const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          key,
                          style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ...groupedContacts[key]!.map((contact) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16.0),
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Icon(Icons.person),
                              backgroundColor:
                              Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                            ),
                            title: Text(
                              '${contact.firstName} ${contact.name}',
                            ),
                            subtitle: Text(contact.number),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.call),
                                  onPressed: () =>
                                      _callNumber(contact.number),
                                ),
                                IconButton(
                                  icon: Icon(Icons.edit),
                                  onPressed: () => _addOrUpdateContact(
                                      contact: contact),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete),
                                  onPressed: () =>
                                      _deleteContact(contact.id!),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrUpdateContact(),
        child: Icon(Icons.add),
      ),
    );
  }

}

class ContactDialog extends StatefulWidget {
  final Contact? contact;

  ContactDialog({this.contact});

  @override
  _ContactDialogState createState() => _ContactDialogState();
}

class _ContactDialogState extends State<ContactDialog> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _firstName;
  late String _number;

  @override
  void initState() {
    super.initState();
    _name = widget.contact?.name ?? '';
    _firstName = widget.contact?.firstName ?? '';
    _number = widget.contact?.number ?? '';
  }

  String? _validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer un numéro de téléphone';
    } else if (value.length != 8 || int.tryParse(value) == null) {
      return ' 8 chiffres';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.contact == null ? 'Ajouter un contact' : 'Modifier un contact'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              initialValue: _name,
              decoration: InputDecoration(
                labelText: 'Nom',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey[200],
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer un nom';
                }
                return null;
              },
              onSaved: (value) {
                _name = value!;
              },
            ),
            SizedBox(height: 8),
            TextFormField(
              initialValue: _firstName,
              decoration: InputDecoration(
                labelText: 'Prénom',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey[200],
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer un prénom';
                }
                return null;
              },
              onSaved: (value) {
                _firstName = value!;
              },
            ),
            SizedBox(height: 8),
            TextFormField(
              initialValue: _number,
              decoration: InputDecoration(
                labelText: 'Numéro de téléphone',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.grey[200],
              ),
              validator: _validatePhoneNumber,
              onSaved: (value) {
                _number = value!;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();
              Navigator.of(context).pop(Contact(
                id: widget.contact?.id,
                name: _name,
                firstName: _firstName,
                number: _number,
              ));
            }
          },
          child: Text('Enregistrer'),
        ),
      ],
    );
  }
}
