import 'package:flutter/material.dart';

class IsiProfilScreen extends StatelessWidget {
  const IsiProfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Isi Profil")),
      body: const Center(
        child: Text("Halaman isi profil pengguna"),
      ),
    );
  }
}