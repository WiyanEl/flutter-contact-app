import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter/src/widgets/container.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Text fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _numbertlcController = TextEditingController();

  final CollectionReference _contactss =
      FirebaseFirestore.instance.collection('contacts');

  // Fungsi yang dijalankan ketika salah satu tombol ditekan
  // Tambah produk jika tidak ada data yang diteruskan
  // jika data != null maka perbarui data yang sudah ada

  Future<void> _createOrUpdate([DocumentSnapshot? documentSnapshot]) async {
    String action = 'create';
    if (documentSnapshot != null) {
      action = 'update';
      _nameController.text = documentSnapshot['name'];
      _numbertlcController.text = documentSnapshot['numbertlp'].toString();
    }

    await showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (BuildContext ctx) {
          return Padding(
            padding: EdgeInsets.only(
                top: 20,
                right: 20,
                left: 20,
                // Mencegah keyboard menutupi text fields
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nama'),
                ),
                TextField(
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  controller: _numbertlcController,
                  decoration: const InputDecoration(labelText: 'Nomor Telepon'),
                ),
                const SizedBox(
                  height: 20,
                ),
                ElevatedButton(
                  child: Text(action == 'create' ? 'Create' : 'Update'),
                  onPressed: () async {
                    final String? name = _nameController.text;
                    final double? numbertlp =
                        double.tryParse(_numbertlcController.text);
                    if (name != null && numbertlp != null) {
                      if (action == 'create') {
                        // Kirim kontak baru ke Firestore
                        await _contactss
                            .add({'name': name, 'numbertlp': numbertlp});
                      }
                    }
                    if (action == 'update') {
                      // perbarui kontak
                      await _contactss
                          .doc(documentSnapshot!.id)
                          .update({'name': name, 'numbertlp': numbertlp});
                    }

                    // Kosongkan text field
                    _nameController.text = '';
                    _numbertlcController.text = '';

                    // hiddde bottom
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          );
        });
  }

  // Hapus contact by id
  Future<void> _deleteContacts(String contactsId) async {
    await _contactss.doc(contactsId).delete();

    // Show Snackbar
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anda berhasil menghapus kontak!')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kontak'),
      ),
      body: StreamBuilder(
        stream: _contactss.snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> streamSnapshot) {
          if (streamSnapshot.hasData) {
            return ListView.builder(
              itemCount: streamSnapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final DocumentSnapshot documentSnapshot =
                    streamSnapshot.data!.docs[index];
                return Card(
                  margin: const EdgeInsets.all(10),
                  child: ListTile(
                    title: Text(documentSnapshot['name']),
                    subtitle: Text(documentSnapshot['numbertlp'].toString()),
                    trailing: SizedBox(
                        width: 100,
                        child: Row(
                          children: [
                            IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () =>
                                    _createOrUpdate(documentSnapshot)),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () =>
                                  _deleteContacts(documentSnapshot.id),
                            )
                          ],
                        )),
                  ),
                );
              },
            );
          }

          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      ),

      // Tambah contact baru
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createOrUpdate(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
