import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

void main() async {
  // Inizializza Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Test delle regole Firestore
  await testFirestoreRules();
}

Future<void> testFirestoreRules() async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('❌ Nessun utente autenticato');
      return;
    }

    print('✅ Utente autenticato: ${user.email}');
    print('🆔 User ID: ${user.uid}');

    // Test 1: Creare un documento utente
    print('\n📝 Test 1: Creazione documento utente...');
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set({
      'username': 'Test User',
      'email': user.email,
      'lastLogin': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    print('✅ Documento utente creato/aggiornato');

    // Test 2: Creare una password
    print('\n🔐 Test 2: Creazione password...');
    final passwordId = 'test_password_${DateTime.now().millisecondsSinceEpoch}';
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('passwords')
        .doc(passwordId)
        .set({
      'id': passwordId,
      'title': 'Test Password',
      'username': 'test@example.com',
      'password': 'test123',
      'notes': 'Password di test',
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    });
    print('✅ Password creata con successo');

    // Test 3: Leggere le password
    print('\n📖 Test 3: Lettura password...');
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('passwords')
        .get();
    
    print('✅ Trovate ${querySnapshot.docs.length} password');

    // Test 4: Aggiornare una password
    print('\n✏️ Test 4: Aggiornamento password...');
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('passwords')
        .doc(passwordId)
        .update({
      'title': 'Test Password Updated',
      'updatedAt': Timestamp.now(),
    });
    print('✅ Password aggiornata con successo');

    // Test 5: Eliminare la password di test
    print('\n🗑️ Test 5: Eliminazione password di test...');
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('passwords')
        .doc(passwordId)
        .delete();
    print('✅ Password eliminata con successo');

    print('\n🎉 Tutti i test sono passati! Le regole Firestore funzionano correttamente.');

  } catch (e) {
    print('❌ Errore durante il test: $e');
  }
} 