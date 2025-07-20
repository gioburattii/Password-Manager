// auth_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  bool isLogin = true;
  bool isLoading = false;
  String email = '';
  String username = '';
  String name = '';
  String surname = '';
  String password = '';
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  Future<void> _submit() async {
    if (isLoading) return;
    
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;
    _formKey.currentState?.save();

    if (mounted) setState(() => isLoading = true);

    try {
      UserCredential userCredential;
      if (isLogin) {
        userCredential = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        // Salva i dati dell'utente per il login
        await _saveUserData(userCredential.user!);
      } else {
        userCredential = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Salva i dati in Firestore per la registrazione
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'username': username,
          'email': email,
          'name': name,
          'surname': surname,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLoginAt': FieldValue.serverTimestamp(),
        });
        
        // Salva anche in SharedPreferences e aggiorna l'UID
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('username', username);
        await prefs.setString('email', email);
        await prefs.setString('user_uid', userCredential.user!.uid);
        
        // Flag per indicare che l'utente si è appena registrato
        await prefs.setBool('is_new_registration', true);
        
        // Chiama _saveUserData per assicurarsi che tutto sia aggiornato
        await _saveUserData(userCredential.user!);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }



      Future<void> _signInWithGoogle() async {
    if (isLoading) return;
    
    if (mounted) setState(() => isLoading = true);
    
    try {
      print('Starting Google Sign-In...');
      
      if (kIsWeb) {
        print('Web platform detected');
        
        // Crea il provider Google
        GoogleAuthProvider authProvider = GoogleAuthProvider();
        
        // Configurazione ottimizzata per il web
        authProvider.setCustomParameters({
          'prompt': 'select_account',
        });
        
        try {
          print('Attempting Google popup sign-in...');
          
          // Prova prima con popup
          final userCredential = await _auth.signInWithPopup(authProvider);
          
          if (userCredential.user != null) {
            print('User signed in successfully: ${userCredential.user!.email}');
            await _saveUserData(userCredential.user!);
            print('User data saved successfully');
          } else {
            throw Exception('No user data received from Google');
          }
        } catch (popupError) {
          print('Popup failed, trying redirect: $popupError');
          
          // Se il popup fallisce, usa redirect
          await _auth.signInWithRedirect(authProvider);
          // Il redirect gestirà automaticamente il resto
          return;
        }
        
      } else {
        print('Mobile/Desktop platform detected');
        
        // Per macOS e mobile, usa GoogleSignIn
        final googleSignIn = GoogleSignIn(
          scopes: ['email', 'profile'],
          clientId: '383840777707-d98q725stdvtfqqe7se51pbcqadpstpi.apps.googleusercontent.com', // iOS/macOS client ID
        );
        
        // Assicurati di fare logout prima
        await googleSignIn.signOut();
        
        final googleUser = await googleSignIn.signIn();
        
        if (googleUser == null) {
          print('User cancelled Google Sign-In');
          return;
        }

        print('Getting authentication tokens...');
        final googleAuth = await googleUser.authentication;
        
        if (googleAuth.accessToken == null || googleAuth.idToken == null) {
          throw Exception('Failed to get Google authentication tokens');
        }
        
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        print('Signing in with credential...');
        final userCredential = await _auth.signInWithCredential(credential);
        
        if (userCredential.user != null) {
          print('Successfully signed in with Google: ${userCredential.user!.email}');
          await _saveUserData(userCredential.user!);
        } else {
          throw Exception('No user data received after credential sign-in');
        }
      }
      
      print('Google Sign-In process completed successfully');
      
      // Mostra un messaggio di successo
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Accesso effettuato con successo!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
      
    } catch (e) {
      print('Google Sign-In error: $e');
      print('Error type: ${e.runtimeType}');
      
      // Gestione specifica degli errori
      String errorMessage = 'Errore durante l\'accesso con Google';
      
      if (e.toString().contains('cancelled-popup-request') || 
          e.toString().contains('popup-closed-by-user') ||
          e.toString().contains('auth/popup-blocked') ||
          e.toString().contains('popup-blocked-by-browser')) {
        print('Popup cancelled or blocked, user action required');
        errorMessage = 'Popup bloccato. Permetti i popup per questo sito e riprova.';
      } else if (e.toString().contains('auth/network-request-failed')) {
        print('Network error during sign-in');
        errorMessage = 'Errore di rete. Controlla la connessione internet.';
      } else if (e.toString().contains('auth/too-many-requests')) {
        errorMessage = 'Troppi tentativi. Attendi qualche minuto e riprova.';
      } else if (e.toString().contains('auth/operation-not-allowed')) {
        errorMessage = 'Login Google non configurato correttamente.';
      } else if (e.toString().contains('client_id')) {
        errorMessage = 'Configurazione Google non valida. Contatta il supporto.';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _saveUserData(User user) async {
    try {
      // Salva in SharedPreferences per accesso rapido
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', user.displayName ?? user.email?.split('@')[0] ?? 'Utente');
      await prefs.setString('email', user.email ?? '');
      await prefs.setString('user_uid', user.uid);
      
      // Crea o aggiorna il documento utente in Firestore
      await _firestore.collection('users').doc(user.uid).set({
        'username': user.displayName ?? user.email?.split('@')[0] ?? 'Utente',
        'email': user.email ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); // merge: true per non sovrascrivere dati esistenti
      
      print('User data saved: ${user.displayName ?? user.email}');
      print('User document created/updated in Firestore');
      
    } catch (e) {
      print('Error saving user data: $e');
      // Non blocchiamo il login se il salvataggio fallisce
    }
  }

  Future<void> _resetPassword() async {
    // Mostra un dialog per inserire l'email
    final TextEditingController emailController = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.lock_reset,
                  color: Color(0xFF8B5CF6),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Reset Password',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Inserisci la tua email per ricevere un link per il reset della password.',
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (val) => val == null || !val.contains('@')
                    ? "Inserisci un'email valida"
                    : null,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Annulla',
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextButton(
                onPressed: () async {
                  final email = emailController.text.trim();
                  if (email.isEmpty || !email.contains('@')) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Inserisci un\'email valida'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  
                  Navigator.of(context).pop(email);
                },
                child: const Text(
                  'Invia',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        );
      },
    );

    if (result != null) {
      try {
        await _auth.sendPasswordResetEmail(email: result);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Email di reset inviata a $result. Controlla la tua casella di posta.',
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        String errorMessage = 'Errore durante l\'invio dell\'email di reset';
        
        if (e.toString().contains('user-not-found')) {
          errorMessage = 'Nessun account trovato con questa email';
        } else if (e.toString().contains('invalid-email')) {
          errorMessage = 'Email non valida';
        } else if (e.toString().contains('too-many-requests')) {
          errorMessage = 'Troppi tentativi. Attendi qualche minuto e riprova';
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(child: Text(errorMessage)),
                ],
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE0E7FF), // Viola molto tenue
              Color(0xFFFCE7F3), // Fuchsia molto tenue
              Color(0xFFDBEAFE), // Blu molto tenue
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo e titolo professionale
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFF8B5CF6), // Viola
                            Color(0xFFEC4899), // Fuchsia
                            Color(0xFF3B82F6), // Blu
                          ],
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                      child: const Icon(
                        Icons.security,
                        size: 24,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Password Manager',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: const Color(0xFF8B5CF6),
                      fontWeight: FontWeight.w300,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isLogin ? 'Accesso sicuro al tuo account' : 'Registrazione nuovo account',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: const Color(0xFF6B7280),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // Card del form professionale
                  Card(
                    elevation: 8,
                    shadowColor: Colors.black.withOpacity(0.15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxWidth: 400),
                      padding: const EdgeInsets.all(40),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              isLogin ? 'Login' : 'Registrazione',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1F2937),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isLogin ? 'Inserisci le tue credenziali' : 'Compila tutti i campi richiesti',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: const Color(0xFF6B7280),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),
                            
                            // Campi del form
                            if (!isLogin) ...[
                              TextFormField(
                                key: const ValueKey('username'),
                                decoration: const InputDecoration(
                                  labelText: 'Username',
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                                validator: (val) => val == null || val.isEmpty 
                                  ? 'Inserisci un username' : null,
                                onSaved: (val) => username = val!,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                key: const ValueKey('name'),
                                decoration: const InputDecoration(
                                  labelText: 'Nome',
                                  prefixIcon: Icon(Icons.badge_outlined),
                                ),
                                validator: (val) => val == null || val.isEmpty 
                                  ? 'Inserisci il nome' : null,
                                onSaved: (val) => name = val!,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                key: const ValueKey('surname'),
                                decoration: const InputDecoration(
                                  labelText: 'Cognome',
                                  prefixIcon: Icon(Icons.badge_outlined),
                                ),
                                validator: (val) => val == null || val.isEmpty 
                                  ? 'Inserisci il cognome' : null,
                                onSaved: (val) => surname = val!,
                              ),
                              const SizedBox(height: 16),
                            ],
                            
                            TextFormField(
                              key: const ValueKey('email'),
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: (val) => val == null || !val.contains('@')
                                  ? "Inserisci un'email valida"
                                  : null,
                              onSaved: (val) => email = val!,
                            ),
                            const SizedBox(height: 16),
                            
                            TextFormField(
                              key: const ValueKey('password'),
                              decoration: const InputDecoration(
                                labelText: 'Password',
                                prefixIcon: Icon(Icons.lock_outline),
                              ),
                              obscureText: true,
                              validator: (val) => val != null && val.length < 6
                                  ? 'Password troppo corta (min 6 caratteri)'
                                  : null,
                              onSaved: (val) => password = val!,
                            ),
                            
                            // Link "Password dimenticata" solo per il login
                            if (isLogin) ...[
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: isLoading ? null : _resetPassword,
                                  child: Text(
                                    'Password dimenticata?',
                                    style: TextStyle(
                                      color: const Color(0xFF8B5CF6),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                            
                            const SizedBox(height: 32),
                            
                            // Pulsante principale
                            ElevatedButton(
                              onPressed: isLoading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF8B5CF6),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: isLoading 
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    isLogin ? 'Accedi' : 'Registrati',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                            ),
                            const SizedBox(height: 16),
                            
                            TextButton(
                              onPressed: isLoading ? null : () {
                                if (mounted) setState(() => isLogin = !isLogin);
                              },
                              child: Text(
                                isLogin
                                    ? 'Non hai un account? Registrati'
                                    : 'Hai già un account? Accedi',
                                style: TextStyle(
                                  color: const Color(0xFF8B5CF6),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Divider
                            Row(
                              children: [
                                Expanded(child: Divider(color: Colors.grey.shade300)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Text(
                                    'oppure',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Expanded(child: Divider(color: Colors.grey.shade300)),
                              ],
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Pulsante Google migliorato
                            Container(
                              width: double.infinity,
                              height: 56,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: isLoading ? null : _signInWithGoogle,
                                  borderRadius: BorderRadius.circular(12),
                                  hoverColor: const Color(0xFF4285F4).withOpacity(0.05),
                                  splashColor: const Color(0xFF4285F4).withOpacity(0.1),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        if (isLoading)
                                          Container(
                                            height: 24,
                                            width: 24,
                                            margin: const EdgeInsets.only(right: 12),
                                            child: const CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                Color(0xFF4285F4),
                                              ),
                                            ),
                                          )
                                        else
                                          Container(
                                            height: 24,
                                            width: 24,
                                            margin: const EdgeInsets.only(right: 12),
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Image.network(
                                              'https://developers.google.com/identity/images/g-logo.png',
                                              height: 24,
                                              width: 24,
                                              errorBuilder: (context, error, stackTrace) {
                                                // Fallback icon se l'immagine non carica
                                                return Container(
                                                  decoration: BoxDecoration(
                                                    gradient: const LinearGradient(
                                                      colors: [
                                                        Color(0xFF4285F4),
                                                        Color(0xFF34A853),
                                                        Color(0xFFFBBC05),
                                                        Color(0xFFEA4335),
                                                      ],
                                                    ),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: const Center(
                                                    child: Text(
                                                      'G',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        Text(
                                          isLoading ? 'Connessione in corso...' : 'Accedi con Google',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF1F2937),
                                            letterSpacing: 0.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
