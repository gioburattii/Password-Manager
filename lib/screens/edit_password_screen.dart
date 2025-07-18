import 'package:flutter/material.dart';
import '../models/password_entry.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class EditPasswordScreen extends StatefulWidget {
  final PasswordEntry entry;

  const EditPasswordScreen({
    super.key,
    required this.entry,
  });

  @override
  State<EditPasswordScreen> createState() => _EditPasswordScreenState();
}

class _EditPasswordScreenState extends State<EditPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late TextEditingController _notesController;
  
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.entry.title);
    _usernameController = TextEditingController(text: widget.entry.username);
    _passwordController = TextEditingController(text: widget.entry.password);
    _notesController = TextEditingController(text: widget.entry.notes ?? '');
    
    _titleController.addListener(() {
      if (mounted) {
        setState(() {}); // Aggiorna l'anteprima icona
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Sistema icone identico alla home e add screen
  IconData _getIconForService(String title) {
    final serviceName = title.toLowerCase().trim();
    
    const serviceIcons = {
      // Social Media
      'facebook': Icons.facebook,
      'instagram': Icons.camera_alt,
      'twitter': Icons.pets,
      'linkedin': Icons.work,
      'youtube': Icons.play_circle_filled,
      'tiktok': Icons.music_note,
      'snapchat': Icons.flash_on,
      'whatsapp': Icons.chat,
      'telegram': Icons.send,
      'discord': Icons.gamepad,
      
      // Email & Comunicazione
      'gmail': Icons.email,
      'outlook': Icons.mail_outline,
      'yahoo': Icons.alternate_email,
      'protonmail': Icons.security,
      'skype': Icons.video_call,
      'zoom': Icons.videocam,
      
      // Tech & Cloud
      'google': Icons.search,
      'microsoft': Icons.window,
      'apple': Icons.phone_iphone,
      'icloud': Icons.cloud,
      'dropbox': Icons.cloud_upload,
      'github': Icons.code,
      'gitlab': Icons.developer_mode,
      'amazon': Icons.shopping_cart,
      'aws': Icons.cloud_queue,
      
      // Streaming & Entertainment
      'netflix': Icons.play_arrow,
      'spotify': Icons.music_note,
      'amazon prime': Icons.movie,
      'disney+': Icons.castle,
      'hbo': Icons.tv,
      'twitch': Icons.live_tv,
      'steam': Icons.sports_esports,
      
      // Finance & Banking
      'paypal': Icons.payment,
      'stripe': Icons.credit_card,
      'revolut': Icons.account_balance_wallet,
      'banca intesa': Icons.account_balance,
      'unicredit': Icons.euro,
      'poste italiane': Icons.local_post_office,
      
      // Utilities
      'tim': Icons.phone,
      'vodafone': Icons.signal_cellular_4_bar,
      'tre': Icons.network_cell,
      'enel': Icons.electrical_services,
      'eni': Icons.local_gas_station,
      'trenitalia': Icons.train,
      
      // Work & Productivity
      'slack': Icons.chat_bubble,
      'notion': Icons.note,
      'trello': Icons.dashboard,
      'figma': Icons.design_services,
      'adobe': Icons.photo_filter,
      'canva': Icons.palette,
    };
    
    if (serviceIcons.containsKey(serviceName)) {
      return serviceIcons[serviceName]!;
    }
    
    for (final entry in serviceIcons.entries) {
      if (serviceName.contains(entry.key)) {
        return entry.value;
      }
    }
    
    if (serviceName.contains('mail') || serviceName.contains('email')) {
      return Icons.email;
    } else if (serviceName.contains('bank') || serviceName.contains('banca') || serviceName.contains('pay')) {
      return Icons.account_balance;
    } else if (serviceName.contains('music') || serviceName.contains('audio')) {
      return Icons.music_note;
    } else if (serviceName.contains('video') || serviceName.contains('stream')) {
      return Icons.play_circle_filled;
    } else if (serviceName.contains('game') || serviceName.contains('gioco')) {
      return Icons.sports_esports;
    } else if (serviceName.contains('shop') || serviceName.contains('store')) {
      return Icons.shopping_cart;
    }
    
    return Icons.lock;
  }

  Color _getColorForService(String title) {
    final serviceName = title.toLowerCase().trim();
    
    const serviceColors = {
      'facebook': Color(0xFF1877F2),
      'instagram': Color(0xFFE4405F),
      'twitter': Color(0xFF1DA1F2),
      'linkedin': Color(0xFF0A66C2),
      'youtube': Color(0xFFFF0000),
      'gmail': Color(0xFFEA4335),
      'whatsapp': Color(0xFF25D366),
      'spotify': Color(0xFF1DB954),
      'netflix': Color(0xFFE50914),
      'paypal': Color(0xFF003087),
      'amazon': Color(0xFFFF9900),
      'google': Color(0xFF4285F4),
      'microsoft': Color(0xFF00A1F1),
      'apple': Color(0xFF007AFF),
      'github': Color(0xFF333333),
      'steam': Color(0xFF171A21),
    };
    
    if (serviceColors.containsKey(serviceName)) {
      return serviceColors[serviceName]!;
    }
    
    if (serviceName.contains('mail') || serviceName.contains('email')) {
      return const Color(0xFFEA4335);
    } else if (serviceName.contains('bank') || serviceName.contains('banca')) {
      return const Color(0xFF2E7D32);
    } else if (serviceName.contains('music')) {
      return const Color(0xFF1DB954);
    } else if (serviceName.contains('video') || serviceName.contains('stream')) {
      return const Color(0xFFE50914);
    }
    
    return const Color(0xFFEC4899); // Rosa chiaro
  }

  String _generateSecurePassword() {
    const characters = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#\$%^&*()_+-=[]{}|;:,.<>?';
    final random = Random.secure();
    final password = List.generate(16, (index) => characters[random.nextInt(characters.length)]).join();
    
    final chars = password.split('')..shuffle(random);
    return chars.join();
  }

  @override
  Widget build(BuildContext context) {
    final currentIcon = _getIconForService(_titleController.text);
    final currentColor = _getColorForService(_titleController.text);
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Modifica Password',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFFEC4899), // Rosa chiaro
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: Color(0xFFEC4899), // Rosa chiaro
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!_isLoading)
            Container(
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF059669), Color(0xFF047857)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextButton(
                onPressed: _updatePassword,
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Aggiorna',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF059669)),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Aggiornando password...',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header con icona e info
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            currentColor.withOpacity(0.1),
                            currentColor.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: currentColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Icona del servizio
                          Hero(
                            tag: 'icon_${widget.entry.id}',
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: currentColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: currentColor.withOpacity(0.4),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: currentColor.withOpacity(0.3),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Icon(
                                currentIcon,
                                size: 40,
                                color: currentColor,
                              ),
                            ),
                          ),
                          
                          const SizedBox(width: 20),
                          
                          // Info password
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Modifica',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: currentColor.withOpacity(0.8),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _titleController.text.isEmpty 
                                      ? 'Password Entry' 
                                      : _titleController.text,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: currentColor.withOpacity(0.9),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.schedule_rounded,
                                      size: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Creato il ${widget.entry.createdAt.day}/${widget.entry.createdAt.month}/${widget.entry.createdAt.year}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Messaggio educativo
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.amber.shade200,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_rounded,
                            color: Colors.amber.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'L\'icona si aggiorna automaticamente quando modifichi il nome del servizio',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.amber.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Campo titolo
                    const Text(
                      'Nome del servizio',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFEC4899), // Rosa chiaro
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          hintText: 'es. Instagram, Gmail, Netflix...',
                          prefixIcon: Icon(
                            Icons.apps_rounded,
                            color: currentColor,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Inserisci il nome del servizio';
                          }
                          return null;
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Campo username
                    const Text(
                      'Username/Email',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFEC4899), // Rosa chiaro
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextFormField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          hintText: 'Il tuo username o email',
                          prefixIcon: const Icon(
                            Icons.person_rounded,
                            color: Color(0xFFEC4899), // Rosa chiaro
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Inserisci username o email';
                          }
                          return null;
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Campo password con generatore
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Password',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFEC4899), // Rosa chiaro
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            final newPassword = _generateSecurePassword();
                            _passwordController.text = newPassword;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Row(
                                  children: [
                                    Icon(Icons.auto_fix_high_rounded, color: Colors.white),
                                    SizedBox(width: 12),
                                    Text('Nuova password sicura generata!'),
                                  ],
                                ),
                                backgroundColor: Colors.green,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                behavior: SnackBarBehavior.floating,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text(
                            'Rigenera',
                            style: TextStyle(fontSize: 14),
                          ),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF059669),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: 'Password sicura',
                          prefixIcon: const Icon(
                            Icons.lock_rounded,
                            color: Color(0xFFEC4899), // Rosa chiaro
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              color: const Color(0xFFEC4899), // Rosa chiaro
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Inserisci una password';
                          }
                          if (value.length < 6) {
                            return 'La password deve essere di almeno 6 caratteri';
                          }
                          return null;
                        },
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Campo note
                    const Text(
                      'Note (opzionale)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFEC4899), // Rosa chiaro
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextFormField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Aggiungi note o promemoria...',
                          prefixIcon: const Icon(
                            Icons.note_rounded,
                            color: Color(0xFFEC4899), // Rosa chiaro
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Card informazioni di sicurezza
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.purple.shade50,
                            Color(0xFFFCE7F3), // Rosa chiaro molto chiaro
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.purple.shade200,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.shield_rounded,
                                color: Colors.purple.shade600,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Sicurezza Account',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple.shade800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildSecurityInfo('🔄', 'Aggiorna regolarmente le password'),
                          _buildSecurityInfo('🔒', 'Usa l\'autenticazione a due fattori'),
                          _buildSecurityInfo('📱', 'Monitora accessi sospetti'),
                          _buildSecurityInfo('🚫', 'Non condividere mai le password'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSecurityInfo(String emoji, String info) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              info,
              style: TextStyle(
                fontSize: 14,
                color: Colors.purple.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updatePassword() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Utente non autenticato');
      }

      final updatedEntry = PasswordEntry(
        id: widget.entry.id,
        title: _titleController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        createdAt: widget.entry.createdAt,
        updatedAt: DateTime.now(),
        imageUrl: null, // Non usiamo più le immagini
      );

      print('Updating password in Firestore: ${updatedEntry.title}');

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('passwords')
          .doc(widget.entry.id)
          .update(updatedEntry.toMap());

      print('Password updated successfully in Firestore');

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('Error updating password: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Errore nell\'aggiornamento: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
} 