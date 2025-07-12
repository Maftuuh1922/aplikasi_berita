import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Membuat atau menimpa dokumen profil pengguna
  Future<void> setUserProfile({required User user, String? bio}) async {
    try {
      // Menggunakan SetOptions(merge: true) agar bisa untuk membuat data baru
      // atau memperbarui data yang sudah ada tanpa menghapus field lain.
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'displayName': user.displayName,
        'email': user.email,
        'photoURL': user.photoURL,
        'bio': bio ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); 
    } catch (e) {
      print('Error setting user profile: $e');
      throw Exception('Gagal menyimpan profil pengguna.');
    }
  }

  // Mengambil data profil dari Firestore berdasarkan UID
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final docSnapshot = await _firestore.collection('users').doc(uid).get();
      if (docSnapshot.exists) {
        return docSnapshot.data();
      }
      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  // Memperbarui data profil di Firestore
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
    } catch (e) {
      print('Error updating user profile: $e');
      throw Exception('Gagal memperbarui profil.');
    }
  }
}
