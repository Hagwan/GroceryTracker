import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';
import 'package:widget_and_text_animator/widget_and_text_animator.dart';

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _groceryItemsController = TextEditingController();
  final TextEditingController _feesController = TextEditingController();
  final CollectionReference _groceryCollection =
      FirebaseFirestore.instance.collection('groceries');

  String? _username;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _username = prefs.getString('username');
      _isLoading = false;
    });
  }

  Future<void> _saveUsername(String username) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('username', username);
    setState(() {
      _username = username;
    });
  }

  Future<void> _addGroceryRecord(String username, String items, double fees) {
    return _groceryCollection.add({
      'username': username,
      'groceryItems': items,
      'fees': fees,
      'datestamp': Timestamp.now(),
    });
  }

  Future<void> _updateGroceryRecord(
      String id, String username, String items, double fees) {
    return _groceryCollection.doc(id).update({
      'username': username,
      'groceryItems': items,
      'fees': fees,
      'datestamp': Timestamp.now(),
    });
  }

  Future<void> _deleteGroceryRecord(String id) {
    return _groceryCollection.doc(id).delete();
  }

  Stream<QuerySnapshot> _getGroceryRecords() {
    return _groceryCollection
        .orderBy('datestamp', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Grocery Tracker'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(child: Text('$_username')),
          ),
          IconButton(
            icon: const Icon(Icons.brightness_6),
            onPressed: () {
              Provider.of<ThemeProvider>(context, listen: false).toggleTheme();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _username == null ? _buildUsernameInput() : _buildMainContent(),
      ),
    );
  }

  Widget _buildUsernameInput() {
    final TextEditingController _usernameController = TextEditingController();

    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        const Text(
          'Welcome to Grocery Tracker',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.blueAccent,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 2,
                blurRadius: 7,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            child: TextField(
              style: const TextStyle(color: Colors.black),
              controller: _usernameController,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Enter your name',
                hintStyle: TextStyle(color: Colors.grey),
                icon: Icon(Icons.person, color: Colors.blueAccent),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: () {
            if (_usernameController.text.isNotEmpty) {
              _saveUsername(_usernameController.text);
            }
          },
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            textStyle:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            foregroundColor: Colors.blueAccent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          child: const Text('Save Name'),
        ),
      ],
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        TextField(
          cursorColor: Colors.blueAccent,
          controller: _groceryItemsController,
          decoration: const InputDecoration(
              labelText: 'Items',
              icon: Icon(
                Icons.shopping_cart,
                color: Colors.blueAccent,
              )),
        ),
        TextField(
          cursorColor: Colors.blueAccent,
          controller: _feesController,
          decoration: const InputDecoration(
            labelText: 'Bill Amount',
            icon: Icon(Icons.attach_money, color: Colors.blueAccent),
            focusColor: Colors.blueAccent,
            fillColor: Colors.blueAccent,
            hoverColor: Colors.blueAccent,
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 30),
        ElevatedButton(
          style: ButtonStyle(
            padding: MaterialStateProperty.all(
                const EdgeInsets.symmetric(horizontal: 15, vertical: 15)),
            textStyle: MaterialStateProperty.all(
                const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            foregroundColor: MaterialStateProperty.all(Colors.blueAccent),
            shape: MaterialStateProperty.all(RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15))),
          ),
          onPressed: () {
            if (_groceryItemsController.text.isNotEmpty &&
                _feesController.text.isNotEmpty) {
              final double fees = double.tryParse(_feesController.text) ?? 0.0;
              _addGroceryRecord(_username!, _groceryItemsController.text, fees)
                  .then((_) {
                _groceryItemsController.clear();
                _feesController.clear();
              });
            }
          },
          child: const Text('Add Record'),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _getGroceryRecords(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final data = snapshot.data;
              if (data == null || data.docs.isEmpty) {
                return const Center(child: Text('No records added yet.'));
              }

              double totalFees = data.docs
                  .map((doc) => doc['fees'] as double)
                  .reduce((value, element) => value + element);

              return Column(
                children: [
                  const SizedBox(height: 10),
                  Text(
                    'Total Fees: \$${totalFees.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),

                  // Add WidgetAndTextAnimator here

                  Expanded(
                    child: ListView.builder(
                      itemCount: data.docs.length,
                      itemBuilder: (context, index) {
                        final doc = data.docs[index];
                        final docId = doc.id;
                        final username = doc['username'];
                        final groceryItems = doc['groceryItems'];
                        final fees = doc['fees'];
                        final date = (doc['datestamp'] as Timestamp).toDate();

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            title: Text('$username spent \$${fees.toString()}'),
                            subtitle: Text(
                                'Items: $groceryItems\nDate: ${date.toString().split(' ')[0]}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () {
                                    _editGroceryRecord(
                                        docId, username, groceryItems, fees);
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () {
                                    _deleteGroceryRecord(docId);
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  void _editGroceryRecord(
      String docId, String username, String items, double fees) {
    _groceryItemsController.text = items;
    _feesController.text = fees.toString();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Grocery Record'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _groceryItemsController,
                decoration: const InputDecoration(labelText: 'Grocery Items'),
              ),
              TextField(
                controller: _feesController,
                decoration: const InputDecoration(labelText: 'Fees'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                final double updatedFees =
                    double.tryParse(_feesController.text) ?? 0.0;
                _updateGroceryRecord(docId, username,
                        _groceryItemsController.text, updatedFees)
                    .then((_) {
                  _groceryItemsController.clear();
                  _feesController.clear();
                  Navigator.of(context).pop();
                });
              },
              child: const Text('Save'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}
