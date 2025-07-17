import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:password_manager/models/password_entry.dart';
import 'package:password_manager/screens/add_password_screen.dart';
import 'package:password_manager/screens/edit_password_screen.dart';
import 'package:password_manager/services/google_drive_service.dart';
import 'package:password_manager/services/image_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<PasswordEntry> _entries = [];
  final GoogleDriveService _driveService = GoogleDriveService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImageService _imageService = ImageService();
  String _searchQuery = '';
  bool _obscureText = true;
  String _username = '';
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    
    // Verifica che l'utente sia autenticato
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      print('HomeScreen initialized for user: ${user.email}');
      _currentUserId = user.uid;
      _loadUserData();
      _loadPasswordsFromFirestore();
    } else {
      print('No authenticated user found in HomeScreen');
    }
  }

  Future<void> _loadUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUsername = prefs.getString('username') ?? '';
      
      // Se non c'è username salvato, prova a prenderlo da Firebase
      if (savedUsername.isEmpty) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final displayName = user.displayName ?? user.email?.split('@')[0] ?? 'Utente';
          await prefs.setString('username', displayName);
          await prefs.setString('email', user.email ?? '');
          print('User data saved from Firebase: $displayName (${user.email})');
          setState(() {
            _username = displayName;
          });
        } else {
          setState(() {
            _username = 'Utente';
          });
        }
      } else {
        print('Loaded saved username: $savedUsername');
        setState(() {
          _username = savedUsername;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _username = 'Utente';
      });
    }
  }

  Future<void> _loadPasswordsFromFirestore() async {
    if (_currentUserId == null) return;
    
    try {
      print('Loading passwords from Firestore for user: $_currentUserId');
      
      final querySnapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('passwords')
          .orderBy('title')
          .get();

      final List<PasswordEntry> loadedEntries = [];
      for (var doc in querySnapshot.docs) {
        try {
          final data = doc.data();
          data['id'] = doc.id; // Assicurati che l'ID del documento sia incluso
          loadedEntries.add(PasswordEntry.fromJson(data));
        } catch (e) {
          print('Error parsing password entry: $e');
        }
      }

      setState(() {
        _entries.clear();
        _entries.addAll(loadedEntries);
      });
      
      print('Loaded ${_entries.length} passwords from Firestore');
      
      // Backup su Drive come fallback
      _saveBackupToDrive();
      
      // Se non ci sono password in Firestore, controlla se ce ne sono su Drive da migrare
      if (_entries.isEmpty) {
        await _migrateFromDriveToFirestore();
      }
      
    } catch (e) {
      print('Error loading passwords from Firestore: $e');
      // Fallback a Google Drive se Firestore fallisce
      _loadBackupFromDrive();
    }
  }

  Future<void> _savePasswordToFirestore(PasswordEntry entry) async {
    if (_currentUserId == null) return;
    
    try {
      print('Saving password to Firestore: ${entry.title}');
      
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('passwords')
          .doc(entry.id)
          .set(entry.toJson());
      
      print('Password saved successfully to Firestore');
      
      // Backup su Drive
      _saveBackupToDrive();
      
    } catch (e) {
      print('Error saving password to Firestore: $e');
      // Mostra errore all'utente
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore durante il salvataggio: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deletePasswordFromFirestore(String passwordId) async {
    if (_currentUserId == null) return;
    
    try {
      print('Deleting password from Firestore: $passwordId');
      
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('passwords')
          .doc(passwordId)
          .delete();
      
      print('Password deleted successfully from Firestore');
      
      // Backup su Drive
      _saveBackupToDrive();
      
    } catch (e) {
      print('Error deleting password from Firestore: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore durante l\'eliminazione: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadBackupFromDrive() async {
    final jsonString = await _driveService.downloadBackup('password_backup_$_username.json');
    if (jsonString != null) {
      final List<dynamic> jsonData = json.decode(jsonString);
      setState(() {
        _entries.clear();
        _entries.addAll(jsonData.map((e) => PasswordEntry.fromJson(e)));
      });
    }
  }

  Future<void> _saveBackupToDrive() async {
    final jsonString = json.encode(_entries.map((e) => e.toJson()).toList());
    await _driveService.uploadBackup('password_backup_$_username.json', jsonString);
  }

  Future<void> _migrateFromDriveToFirestore() async {
    if (_currentUserId == null) return;
    
    try {
      print('Attempting to migrate data from Google Drive to Firestore...');
      
      // Carica dal backup di Drive
      final jsonString = await _driveService.downloadBackup('password_backup_$_username.json');
      if (jsonString != null) {
        final List<dynamic> jsonData = json.decode(jsonString);
        final driveEntries = jsonData.map((e) => PasswordEntry.fromJson(e)).toList();
        
        if (driveEntries.isNotEmpty) {
          print('Found ${driveEntries.length} passwords in Google Drive backup');
          
          // Migra ogni password a Firestore
          for (var entry in driveEntries) {
            await _firestore
                .collection('users')
                .doc(_currentUserId)
                .collection('passwords')
                .doc(entry.id)
                .set(entry.toJson());
          }
          
          // Aggiorna la UI
          setState(() {
            _entries.clear();
            _entries.addAll(driveEntries);
          });
          
          print('Successfully migrated ${driveEntries.length} passwords to Firestore');
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Migrazione completata: ${driveEntries.length} password trasferite'),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 3),
              ),
            );
          }
        }
      }
    } catch (e) {
      print('Error during migration: $e');
    }
  }

  void _addEntry(PasswordEntry entry) {
    setState(() {
      _entries.add(entry);
    });
    // Salva su Firestore (che farà automaticamente il backup su Drive)
    _savePasswordToFirestore(entry);
  }

  void _updateEntry(int index, PasswordEntry updatedEntry) {
    setState(() {
      _entries[index] = updatedEntry;
    });
    // Aggiorna su Firestore (che farà automaticamente il backup su Drive)
    _savePasswordToFirestore(updatedEntry);
  }

  void _deleteEntry(int index) {
    final entryToDelete = _entries[index];
    setState(() {
      _entries.removeAt(index);
    });
    // Elimina da Firestore (che farà automaticamente il backup su Drive)
    _deletePasswordFromFirestore(entryToDelete.id);
  }

  Future<void> _editEntry(int index, PasswordEntry entry) async {
    final updatedEntry = await Navigator.push<PasswordEntry>(
      context,
      MaterialPageRoute(
        builder: (_) => EditPasswordScreen(entry: entry),
      ),
    );
    
    if (updatedEntry != null) {
      _updateEntry(index, updatedEntry);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password "${updatedEntry.title}" aggiornata'),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }

  Future<void> _confirmAndDeleteEntry(int index, String title) async {
    final shouldDelete = await _confirmDelete(title);
    if (shouldDelete == true) {
      _deleteEntry(index);
    }
  }

  Future<bool?> _confirmDelete(String title) async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning,
                color: Colors.orange.shade600,
                size: 28,
              ),
              const SizedBox(width: 12),
              const Text(
                'Conferma Eliminazione',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          content: Text(
            'Sei sicuro di voler eliminare la password per "$title"?\n\nQuesta azione non può essere annullata.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Annulla',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Elimina',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmAndLogout() async {
    // Mostra dialogo di conferma
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Conferma Logout'),
          content: const Text('Sei sicuro di voler uscire dall\'app?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Annulla'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      _logout();
    }
  }

  Future<void> _logout() async {
    try {
      print('Starting logout process...');
      
      // Pulisce SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      print('SharedPreferences cleared');
      
      // Logout da Google Drive
      await _driveService.signOut();
      print('Google Drive signed out');
      
      // Logout da Firebase (questo farà scattare authStateChanges)
      await FirebaseAuth.instance.signOut();
      print('Firebase signed out');
      
      // Non serve Navigator.push perché lo StreamBuilder gestirà il cambio automaticamente
    } catch (e) {
      print('Logout error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore durante il logout: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredEntries = _entries.where((entry) {
      final query = _searchQuery.toLowerCase();
      return entry.title.toLowerCase().contains(query) ||
          entry.username.toLowerCase().contains(query) ||
          (entry.notes?.toLowerCase().contains(query) ?? false);
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ciao, $_username! 👋',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1F2937),
              ),
            ),
            Text(
              _searchQuery.isEmpty 
                ? '${_entries.length} password salvate'
                : '${filteredEntries.length} di ${_entries.length} password',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _obscureText ? Icons.visibility_off : Icons.visibility,
              color: const Color(0xFF6366F1),
            ),
            onPressed: () => setState(() => _obscureText = !_obscureText),
            tooltip: _obscureText ? 'Mostra password' : 'Nascondi password',
          ),
          IconButton(
            icon: const Icon(
              Icons.logout,
              color: Color(0xFFEF4444),
            ),
            onPressed: _confirmAndLogout,
            tooltip: 'Logout',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Barra di ricerca
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Cerca password per titolo, username o note...',
                hintStyle: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.grey.shade400,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: Colors.grey.shade400,
                        ),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          // Contenuto principale
          Expanded(
            child: filteredEntries.isEmpty && _searchQuery.isNotEmpty
                ? _buildNoResultsState()
                : _entries.isEmpty
                ? _buildEmptyState()
                : _buildPasswordList(filteredEntries),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6366F1).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: () async {
            final newEntry = await Navigator.push<PasswordEntry>(
              context,
              MaterialPageRoute(builder: (_) => const AddPasswordScreen()),
            );
            if (newEntry != null) {
              _addEntry(newEntry);
            }
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(
            Icons.add,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.search_off,
              size: 64,
              color: Colors.orange,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Nessun risultato trovato',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Prova con parole chiave diverse o\ncontrolla l\'ortografia',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => setState(() => _searchQuery = ''),
            icon: const Icon(Icons.clear),
            label: const Text('Cancella ricerca'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.lock_outline,
              size: 80,
              color: Color(0xFF6366F1),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Nessuna password salvata',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Inizia aggiungendo la tua prima password',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () async {
              final newEntry = await Navigator.push<PasswordEntry>(
                context,
                MaterialPageRoute(builder: (_) => const AddPasswordScreen()),
              );
              if (newEntry != null) {
                _addEntry(newEntry);
              }
            },
            icon: const Icon(Icons.add),
            label: const Text('Aggiungi Password'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordList(List<PasswordEntry> filteredEntries) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredEntries.length,
      itemBuilder: (context, index) {
        final entry = filteredEntries[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Dismissible(
            key: Key(entry.id),
            direction: DismissDirection.endToStart,
            background: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete, color: Colors.white, size: 28),
                  SizedBox(height: 4),
                  Text(
                    'Elimina',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            confirmDismiss: (_) => _confirmDelete(entry.title),
            onDismissed: (_) => _deleteEntry(index),
            child: _buildPasswordCard(entry, index),
          ),
        );
      },
    );
  }

  Widget _buildPasswordCard(PasswordEntry entry, int index) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          // Copia password negli appunti
          Clipboard.setData(ClipboardData(text: entry.password));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Password copiata negli appunti'),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => _editEntry(index, entry),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: entry.imageUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                entry.imageUrl!,
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return _buildDefaultEntryIcon(entry.title);
                                },
                              ),
                            )
                          : _buildDefaultEntryIcon(entry.title),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          entry.username,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.edit,
                          color: Color(0xFF10B981),
                          size: 20,
                        ),
                        onPressed: () => _editEntry(index, entry),
                        tooltip: 'Modifica',
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.copy,
                          color: Color(0xFF6366F1),
                          size: 20,
                        ),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: entry.password));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Password copiata!'),
                              backgroundColor: const Color(0xFF10B981),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          );
                        },
                        tooltip: 'Copia password',
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: Color(0xFFEF4444),
                          size: 20,
                        ),
                        onPressed: () => _confirmAndDeleteEntry(index, entry.title),
                        tooltip: 'Elimina',
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.lock_outline,
                      size: 18,
                      color: Color(0xFF6B7280),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _obscureText ? '••••••••' : entry.password,
                        style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'monospace',
                          color: _obscureText ? Colors.grey.shade600 : const Color(0xFF1F2937),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (entry.notes != null && entry.notes!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.note_outlined,
                        size: 18,
                        color: Color(0xFF6366F1),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.notes!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF4B5563),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultEntryIcon(String title) {
    final emoji = _imageService.getEmojiForTitle(title);
    
    if (emoji != null) {
      return Center(
        child: Text(
          emoji,
          style: const TextStyle(fontSize: 24),
        ),
      );
    } else {
      return Icon(
        _getIconForTitle(title),
        color: Colors.white,
        size: 24,
      );
    }
  }

  IconData _getIconForTitle(String title) {
    final lowercaseTitle = title.toLowerCase();
    if (lowercaseTitle.contains('google') || lowercaseTitle.contains('gmail')) {
      return Icons.mail_outline;
    } else if (lowercaseTitle.contains('facebook')) {
      return Icons.people_outline;
    } else if (lowercaseTitle.contains('twitter') || lowercaseTitle.contains('x')) {
      return Icons.chat_bubble_outline;
    } else if (lowercaseTitle.contains('instagram')) {
      return Icons.camera_alt_outlined;
    } else if (lowercaseTitle.contains('linkedin')) {
      return Icons.work_outline;
    } else if (lowercaseTitle.contains('github')) {
      return Icons.code;
    } else if (lowercaseTitle.contains('bank') || lowercaseTitle.contains('banca')) {
      return Icons.account_balance;
    } else if (lowercaseTitle.contains('wifi') || lowercaseTitle.contains('router')) {
      return Icons.wifi;
    } else {
      return Icons.account_circle_outlined;
    }
  }
}


