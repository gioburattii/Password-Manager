import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:password_manager/models/password_entry.dart';
import 'package:password_manager/screens/add_password_screen.dart';
import 'package:password_manager/screens/edit_password_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final List<PasswordEntry> _entries = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  
  String _searchQuery = '';
  bool _obscureText = true;
  String _username = '';
  String? _currentUserId;
  late AnimationController _logoController;

  @override
  void initState() {
    super.initState();
    
    _logoController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
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

  @override
  void dispose() {
    _logoController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
    final prefs = await SharedPreferences.getInstance();
      final savedUsername = prefs.getString('username') ?? '';
      
      if (savedUsername.isEmpty) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          final displayName = user.displayName ?? user.email?.split('@')[0] ?? 'Utente';
          await prefs.setString('username', displayName);
          await prefs.setString('email', user.email ?? '');
          print('User data saved: $displayName');
          setState(() {
            _username = displayName;
          });
          
          // Salva anche nel documento Firestore
          await _firestore.collection('users').doc(user.uid).set({
            'username': displayName,
            'email': user.email,
            'lastLogin': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          print('User document created/updated in Firestore');
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

  void _loadPasswordsFromFirestore() {
    if (_currentUserId == null) return;
    
    try {
      print('Loading passwords from Firestore for user: $_currentUserId');
      
      _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('passwords')
          .orderBy('title')
          .snapshots()
          .listen((querySnapshot) {
        try {
          final List<PasswordEntry> loadedEntries = [];
          for (var doc in querySnapshot.docs) {
            try {
              final data = doc.data();
              final entry = PasswordEntry(
                id: doc.id,
                title: data['title'] ?? '',
                username: data['username'] ?? '',
                password: data['password'] ?? '',
                notes: data['notes'] ?? '',
                createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
                imageUrl: null, // Non usiamo più le immagini
              );
              loadedEntries.add(entry);
            } catch (e) {
              print('Error parsing password entry: $e');
            }
          }
          
    setState(() {
            _entries.clear();
            _entries.addAll(loadedEntries);
    });
          
          print('Loaded ${loadedEntries.length} passwords from Firestore');
          
        } catch (e) {
          print('Error processing password entries: $e');
        }
      }, onError: (e) {
        print('Error listening to password changes: $e');
      });
    } catch (e) {
      print('Error setting up passwords listener: $e');
    }
  }

  // Sistema icone uniforme super efficiente
  IconData _getIconForService(String title) {
    final serviceName = title.toLowerCase().trim();
    
    // Mappa statica per performance migliori (O(1) lookup)
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
    
    // Ricerca diretta
    if (serviceIcons.containsKey(serviceName)) {
      return serviceIcons[serviceName]!;
  }

    // Ricerca per contenimento di parole chiave
    for (final entry in serviceIcons.entries) {
      if (serviceName.contains(entry.key)) {
        return entry.value;
      }
    }
    
    // Fallback per categoria
    if (serviceName.contains('mail') || serviceName.contains('email')) {
      return Icons.email;
    } else if (serviceName.contains('bank') || serviceName.contains('banca')) {
      return Icons.account_balance;
    } else if (serviceName.contains('music')) {
      return Icons.music_note;
    } else if (serviceName.contains('video') || serviceName.contains('stream')) {
      return Icons.play_circle_filled;
    } else if (serviceName.contains('game') || serviceName.contains('gioco')) {
      return Icons.sports_esports;
    } else if (serviceName.contains('shop') || serviceName.contains('store')) {
      return Icons.shopping_cart;
    }
    
    // Icona di default
    return Icons.lock;
  }

  Color _getColorForService(String title) {
    final serviceName = title.toLowerCase().trim();
    
    // Mappa colori brand per servizi specifici
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
    
    // Colori per categoria
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

  List<PasswordEntry> get _filteredEntries {
    if (_searchQuery.isEmpty) {
      return _entries;
    }
    return _entries.where((entry) =>
        entry.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        entry.username.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        (entry.notes?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false)
    ).toList();
  }

  String _getPasswordStrength(String password) {
    // Password sotto i 6 caratteri non dovrebbero esistere (validazione form)
    if (password.length < 6) return 'Debole';
    
    // Controlla la complessità della password
    bool hasUpper = password.contains(RegExp(r'[A-Z]'));
    bool hasLower = password.contains(RegExp(r'[a-z]'));
    bool hasDigits = password.contains(RegExp(r'[0-9]'));
    bool hasSpecial = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    
    int complexityScore = 0;
    if (hasUpper) complexityScore++;
    if (hasLower) complexityScore++;
    if (hasDigits) complexityScore++;
    if (hasSpecial) complexityScore++;
    
    // Password forti: 12+ caratteri con complessità completa
    if (password.length >= 12 && complexityScore >= 4) {
      return 'Forte';
    }
    
    // Password medie: 9+ caratteri con buona complessità O 6-8 caratteri con complessità completa
    if ((password.length >= 9 && complexityScore >= 3) || 
        (password.length >= 6 && complexityScore >= 4)) {
      return 'Media';
    }
    
    // Password deboli: tutto il resto (6-8 caratteri con poca complessità)
    return 'Debole';
  }

  Color _getStrengthColor(String strength) {
    switch (strength) {
      case 'Forte': return Colors.green;
      case 'Media': return Colors.orange;
      case 'Debole': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          // Header moderno con gradiente
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF8B5CF6), // Viola principale
                    Color(0xFFEC4899), // Fuchsia
                    Color(0xFF3B82F6), // Blu
                  ],
                ),
              ),
              child: FlexibleSpaceBar(
                background: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header top row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ciao, $_username! 👋',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_entries.length} password salvate',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            // Action buttons
                            Row(
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.analytics_rounded,
                                      color: Colors.white,
                                    ),
                                    onPressed: () => _showStatsDialog(),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: IconButton(
                                    icon: Icon(
                                      _obscureText ? Icons.visibility_off : Icons.visibility,
                                      color: Colors.white,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscureText = !_obscureText;
                                      });
                                    },
          ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.logout_rounded,
                                      color: Colors.white,
                                    ),
                                    onPressed: _logout,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Search bar
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: TextField(
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                            },
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Cerca password...',
                              hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                              prefixIcon: Container(
                                margin: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.search_rounded,
                                  color: Colors.white,
                                ),
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
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
          ),
          
          // Lista password con animazioni
          SliverToBoxAdapter(
            child: _filteredEntries.isEmpty
                ? _buildEmptyState()
                : AnimatedList(
                    key: _listKey,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(20),
                    initialItemCount: _filteredEntries.length,
                    itemBuilder: (context, index, animation) {
                      if (index >= _filteredEntries.length) return const SizedBox();
                      return _buildPasswordCard(_filteredEntries[index], animation);
                    },
                  ),
          ),
        ],
      ),
      
      // FAB con design moderno
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3B82F6).withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: _addPassword,
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text(
            'Aggiungi',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo animato
          AnimatedBuilder(
            animation: _logoController,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (_logoController.value * 0.1),
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color.lerp(const Color(0xFF1E293B), const Color(0xFF334155), _logoController.value)!,
                        Color.lerp(const Color(0xFF334155), const Color(0xFF3B82F6), _logoController.value)!,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                                                      color: const Color(0xFFEC4899).withOpacity(0.3), // Rosa chiaro
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.security_rounded,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
              );
            },
          ),
          
          const SizedBox(height: 30),
          
          Text(
            _searchQuery.isEmpty
                ? 'Nessuna password salvata'
                : 'Nessun risultato per "$_searchQuery"',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          
          const SizedBox(height: 12),
          
          Text(
            _searchQuery.isEmpty
                ? 'Inizia aggiungendo la tua prima password sicura'
                : 'Prova con un termine di ricerca diverso',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          
          if (_searchQuery.isEmpty) ...[
            const SizedBox(height: 30),
            
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                                            color: Color(0xFFFCE7F3), // Rosa chiaro molto chiaro
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                                              color: Color(0xFFF9A8D4), // Rosa chiaro
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.tips_and_updates_rounded,
                    color: Color(0xFFEC4899), // Rosa chiaro
                    size: 30,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Suggerimenti per password sicure',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFEC4899), // Rosa chiaro
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Usa almeno 12 caratteri\n• Combina lettere, numeri e simboli\n• Evita informazioni personali\n• Usa password uniche per ogni account',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFFEC4899), // Rosa chiaro
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF3B82F6).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _addPassword,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                label: const Text(
                  'Aggiungi prima password',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
            ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPasswordCard(PasswordEntry entry, Animation<double> animation) {
    final strength = _getPasswordStrength(entry.password);
    final strengthColor = _getStrengthColor(strength);
    final serviceIcon = _getIconForService(entry.title);
    final serviceColor = _getColorForService(entry.title);
    
    return SlideTransition(
      position: animation.drive(
        Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => _editPassword(entry),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header della card
                  Row(
                    children: [
                      // Icona del servizio con Hero animation
                      Hero(
                        tag: 'icon_${entry.id}',
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: serviceColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: serviceColor.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            serviceIcon,
                            color: serviceColor,
                            size: 24,
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // Titolo e username
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
                            if (entry.username.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                entry.username,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      
                      // Menu popup
                      PopupMenuButton(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'copy',
                            child: const Row(
                              children: [
                                Icon(Icons.copy_rounded, color: Color(0xFFEC4899)),
                                SizedBox(width: 12),
                                Text('Copia password'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'edit',
                            child: const Row(
                              children: [
                                Icon(Icons.edit_rounded, color: Color(0xFF059669)),
                                SizedBox(width: 12),
                                Text('Modifica'),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: const Row(
                              children: [
                                Icon(Icons.delete_rounded, color: Color(0xFFDC2626)),
                                SizedBox(width: 12),
                                Text('Elimina'),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (value) {
                          switch (value) {
                            case 'copy':
                              _copyPassword(entry.password);
                              break;
                            case 'edit':
                              _editPassword(entry);
                              break;
                            case 'delete':
                              _deletePassword(entry);
                              break;
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.more_vert_rounded,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Campo password con design moderno
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.grey.shade50,
                          Colors.grey.shade100,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey.shade200,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lock_rounded,
                          color: Colors.grey.shade500,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _obscureText ? '••••••••••••' : entry.password,
                            style: TextStyle(
                              fontSize: 16,
                              fontFamily: 'monospace',
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => _copyPassword(entry.password),
                          icon: Icon(
                            Icons.copy_rounded,
                            color: serviceColor,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Footer con info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Badge forza password
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: strengthColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: strengthColor.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.security_rounded,
                              color: strengthColor,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              strength,
                              style: TextStyle(
                                color: strengthColor,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Data creazione
                      Text(
                        'Creato il ${entry.createdAt.day}/${entry.createdAt.month}/${entry.createdAt.year}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showStatsDialog() {
    final strongPasswords = _entries.where((e) => _getPasswordStrength(e.password) == 'Forte').length;
    final mediumPasswords = _entries.where((e) => _getPasswordStrength(e.password) == 'Media').length;
    final weakPasswords = _entries.where((e) => _getPasswordStrength(e.password) == 'Debole').length;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.analytics_rounded, color: Colors.white),
            ),
            const SizedBox(width: 12),
            const Text('Statistiche Sicurezza'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildStatRow('Password totali', _entries.length.toString(), Icons.lock_rounded, const Color(0xFFEC4899)), // Rosa chiaro
            _buildStatRow('Password forti', strongPasswords.toString(), Icons.security_rounded, Colors.green),
            _buildStatRow('Password medie', mediumPasswords.toString(), Icons.warning_rounded, Colors.orange),
            _buildStatRow('Password deboli', weakPasswords.toString(), Icons.error_rounded, Colors.red),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Chiudi'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(label)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addPassword() async {
    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const AddPasswordScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: animation.drive(
              Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
                  .chain(CurveTween(curve: Curves.easeOutCubic)),
            ),
            child: child,
          );
        },
      ),
    );
    
    if (result == true) {
      // Password aggiunta con successo
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 12),
              Text('Password aggiunta con successo!'),
            ],
          ),
          backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _editPassword(PasswordEntry entry) async {
    final result = await Navigator.push(
            context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => EditPasswordScreen(entry: entry),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: animation.drive(
              Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
                  .chain(CurveTween(curve: Curves.easeOutCubic)),
            ),
            child: child,
          );
        },
      ),
    );
    
    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white),
              SizedBox(width: 12),
              Text('Password modificata con successo!'),
            ],
          ),
          backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

  Future<void> _deletePassword(PasswordEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.delete_rounded, color: Colors.red),
            ),
            const SizedBox(width: 12),
            const Text('Elimina Password'),
          ],
        ),
        content: Text('Sei sicuro di voler eliminare la password per "${entry.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla'),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Elimina',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
    
    if (confirmed == true && _currentUserId != null) {
      try {
        await _firestore
            .collection('users')
            .doc(_currentUserId)
            .collection('passwords')
            .doc(entry.id)
            .delete();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 12),
                Text('Password eliminata'),
              ],
            ),
            backgroundColor: Colors.red,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_rounded, color: Colors.white),
                const SizedBox(width: 12),
                Text('Errore: $e'),
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

  void _copyPassword(String password) {
    Clipboard.setData(ClipboardData(text: password));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.copy_rounded, color: Colors.white),
            SizedBox(width: 12),
            Text('Password copiata negli appunti'),
          ],
        ),
        backgroundColor: const Color(0xFFEC4899), // Rosa chiaro
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)], // Rosa chiaro + Viola
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.logout_rounded, color: Colors.white),
            ),
            const SizedBox(width: 12),
            const Text('Logout'),
          ],
        ),
        content: const Text('Sei sicuro di voler uscire?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annulla'),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEC4899), Color(0xFF8B5CF6)], // Rosa chiaro + Viola
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await FirebaseAuth.instance.signOut();
  }
}
}



