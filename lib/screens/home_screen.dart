import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
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

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  final List<PasswordEntry> _entries = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  
  String _searchQuery = '';
  bool _obscureText = true;
  String _username = '';
  String? _currentUserId;
  late AnimationController _logoController;
  Timer? _healthCheckTimer;
  bool _isAppActive = true;

    @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    _logoController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      print('HomeScreen initialized for user: ${user.email}');
      _currentUserId = user.uid;
      _loadUserData();
      _checkNewRegistration();
    } else {
      print('No authenticated user found in HomeScreen');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed && _currentUserId != null) {
      print('App resumed, forcing ULTRA AGGRESSIVE refresh...');
      _isAppActive = true;
      
      // Disabilita temporaneamente il listener
      _passwordsSubscription?.cancel();
      
      // Usa il caricamento ultra aggressivo
      _loadPasswordsUltraAggressive();
      
      // Riabilita il listener dopo un momento
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted && _currentUserId != null) {
          _loadPasswordsFromFirestore();
        }
      });
    } else if (state == AppLifecycleState.paused) {
      _isAppActive = false;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Forza un refresh quando torniamo alla home screen
    if (_currentUserId != null) {
      print('didChangeDependencies: forcing ULTRA AGGRESSIVE refresh...');
      
      // Disabilita temporaneamente il listener
      _passwordsSubscription?.cancel();
      
      // Usa il caricamento ultra aggressivo
      _loadPasswordsUltraAggressive();
      
      // Riabilita il listener dopo un momento
      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted && _currentUserId != null) {
          _loadPasswordsFromFirestore();
        }
      });
    }
  }



  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _logoController.dispose();
    _passwordsSubscription?.cancel();
    _healthCheckTimer?.cancel();
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

  // Metodo per gestire la nuova registrazione
  Future<void> _checkNewRegistration() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isNewRegistration = prefs.getBool('is_new_registration') ?? false;
      
      if (isNewRegistration) {
        print('New registration detected, using ULTRA aggressive loading...');
        
        // Rimuovi il flag
        await prefs.remove('is_new_registration');
        
        // SOLUZIONE RADICALE: Disabilita completamente il listener
        _passwordsSubscription?.cancel();
        
        // Caricamento ultra aggressivo con retry infinito
        await _loadPasswordsUltraAggressive();
        
        // Dopo un momento, attiva il listener normale
        Future.delayed(const Duration(milliseconds: 2000), () {
          if (mounted && _currentUserId != null) {
            _loadPasswordsFromFirestore();
          }
        });
      } else {
        // Utente esistente, usa il metodo normale
        print('Existing user, using normal loading...');
        _loadPasswordsFromFirestore();
      }
    } catch (e) {
      print('Error checking new registration: $e');
      // Fallback al metodo normale
      _loadPasswordsFromFirestore();
    }
  }

  StreamSubscription<QuerySnapshot>? _passwordsSubscription;

    void _loadPasswordsFromFirestore() {
    if (_currentUserId == null) return;
    
    try {
      print('Loading passwords from Firestore for user: $_currentUserId');
      
      // Cancella il listener precedente se esiste
      _passwordsSubscription?.cancel();
      
      // Test diretto per debug
      _testDirectQuery();
      
      // Crea un nuovo listener con gestione errori migliorata
      _passwordsSubscription = _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('passwords')
          .orderBy('title')
          .snapshots()
          .listen((querySnapshot) {
        try {
          print('Received Firestore update with ${querySnapshot.docs.length} documents');
          final List<PasswordEntry> loadedEntries = [];
          for (var doc in querySnapshot.docs) {
            try {
              final data = doc.data();
              print('Found password document: ${doc.id} - ${data['title']}');
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
          
          if (mounted) {
            setState(() {
              _entries.clear();
              _entries.addAll(loadedEntries);
            });
            print('Updated UI with ${loadedEntries.length} passwords from Firestore');
          }
          
        } catch (e) {
          print('Error processing password entries: $e');
          // Fallback immediato in caso di errore
          _loadPasswordsOnce();
        }
      }, onError: (e) {
        print('Error listening to password changes: $e');
        // Fallback: prova a caricare una volta sola
        _loadPasswordsOnce();
        
        // Retry automatico dopo 3 secondi
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted && _currentUserId != null) {
            print('Retrying Firestore listener...');
            _loadPasswordsFromFirestore();
          }
        });
      });
    } catch (e) {
      print('Error setting up passwords listener: $e');
      // Fallback: prova a caricare una volta sola
      _loadPasswordsOnce();
    }
    
    // Avvia il health check per monitorare il listener
    _startHealthCheck();
  }

    // Metodo di fallback per caricare le password una volta sola
  Future<void> _loadPasswordsOnce() async {
    if (_currentUserId == null) {
      print('Cannot load passwords: no user ID');
      return;
    }
    
    try {
      print('Trying to load passwords once for user: $_currentUserId');
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
          print('Found password document (once): ${doc.id} - ${data['title']}');
          final entry = PasswordEntry(
            id: doc.id,
            title: data['title'] ?? '',
            username: data['username'] ?? '',
            password: data['password'] ?? '',
            notes: data['notes'] ?? '',
            createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            imageUrl: null,
          );
          loadedEntries.add(entry);
        } catch (e) {
          print('Error parsing password entry (once): $e');
        }
      }
      
      if (mounted) {
        setState(() {
          _entries.clear();
          _entries.addAll(loadedEntries);
        });
        print('Updated UI with ${loadedEntries.length} passwords (once)');
        
        // Forza un rebuild dell'UI
        if (mounted) {
          setState(() {});
        }
      } else {
        print('Widget not mounted, skipping UI update');
      }
      
    } catch (e) {
      print('Error loading passwords once: $e');
      // Prova a ricaricare il listener in caso di errore
      if (mounted) {
        _loadPasswordsFromFirestore();
      }
    }
  }

  // Metodo ULTRA aggressivo per caricare le password
  Future<void> _loadPasswordsUltraAggressive() async {
    if (_currentUserId == null) {
      print('Cannot load passwords: no user ID');
      return;
    }
    
    print('ULTRA AGGRESSIVE loading started for user: $_currentUserId');
    
    // SOLUZIONE RADICALE: Caricamento diretto senza retry
    try {
      print('Loading passwords directly from Firestore...');
      
      // Query diretta senza orderBy per evitare problemi di indici
      final querySnapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('passwords')
          .get();
      
      final List<PasswordEntry> loadedEntries = [];
      for (var doc in querySnapshot.docs) {
        try {
          final data = doc.data();
          print('Found password: ${doc.id} - ${data['title']}');
          final entry = PasswordEntry(
            id: doc.id,
            title: data['title'] ?? '',
            username: data['username'] ?? '',
            password: data['password'] ?? '',
            notes: data['notes'] ?? '',
            createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            imageUrl: null,
          );
          loadedEntries.add(entry);
        } catch (e) {
          print('Error parsing password: $e');
        }
      }
      
      // Ordina manualmente
      loadedEntries.sort((a, b) => a.title.compareTo(b.title));
      
      print('Loaded ${loadedEntries.length} passwords total');
      
      if (mounted) {
        // Forza un aggiornamento completo
        setState(() {
          _entries.clear();
          _entries.addAll(loadedEntries);
        });
        
        print('UI updated with ${_entries.length} passwords');
        
        // Forza multipli rebuild per sicurezza
        for (int i = 0; i < 10; i++) {
          Future.delayed(Duration(milliseconds: i * 50), () {
            if (mounted) {
              setState(() {});
              print('Forced rebuild ${i + 1}/10');
            }
          });
        }
      }
      
    } catch (e) {
      print('Error loading passwords: $e');
      
      // Se fallisce, prova a ricaricare il listener
      if (mounted) {
        _loadPasswordsFromFirestore();
      }
    }
  }

  // Metodo per verificare la salute del listener
  void _startHealthCheck() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted && _currentUserId != null) {
        print('Health check: verifying Firestore connection...');
        _testDirectQuery();
      } else {
        timer.cancel();
      }
    });
  }

  // Metodo per forzare un refresh completo
  Future<void> _forceRefresh() async {
    print('Forcing complete refresh...');
    
    // Cancella tutto
    _passwordsSubscription?.cancel();
    _healthCheckTimer?.cancel();
    
    // Aspetta un momento
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Ricarica il listener
    _loadPasswordsFromFirestore();
    
    // Aspetta e ricarica manualmente
    await Future.delayed(const Duration(milliseconds: 1000));
    await _loadPasswordsOnce();
    
    // Forza un rebuild dell'UI
    if (mounted) {
      setState(() {});
    }
    
    // Aspetta ancora e ricarica di nuovo
    await Future.delayed(const Duration(milliseconds: 500));
    await _loadPasswordsOnce();
    
    // Forza un altro rebuild
    if (mounted) {
      setState(() {});
    }
  }

  // Metodo per forzare un refresh COMPLETO dell'intera home screen
  Future<void> _forceCompleteRefresh() async {
    print('FORCING COMPLETE REFRESH OF ENTIRE HOME SCREEN...');
    
    // Cancella tutto
    _passwordsSubscription?.cancel();
    _healthCheckTimer?.cancel();
    
    // Pulisci la lista
    if (mounted) {
      setState(() {
        _entries.clear();
      });
    }
    
    // Aspetta un momento
    await Future.delayed(const Duration(milliseconds: 300));
    
    // Carica le password con metodo ultra aggressivo
    await _loadPasswordsUltraAggressive();
    
    // Aspetta e ricarica di nuovo
    await Future.delayed(const Duration(milliseconds: 500));
    await _loadPasswordsUltraAggressive();
    
    // Aspetta e ricarica ancora una volta
    await Future.delayed(const Duration(milliseconds: 500));
    await _loadPasswordsUltraAggressive();
    
    // Forza multipli rebuild dell'intera UI
    for (int i = 0; i < 20; i++) {
      Future.delayed(Duration(milliseconds: i * 25), () {
        if (mounted) {
          setState(() {});
          print('Complete refresh rebuild ${i + 1}/20');
        }
      });
    }
    
    // Riabilita il listener dopo un momento
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted && _currentUserId != null) {
        _loadPasswordsFromFirestore();
      }
    });
  }

  // Metodo di test per verificare direttamente il database
  Future<void> _testDirectQuery() async {
    try {
      print('Testing direct query...');
      final querySnapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('passwords')
          .get();
      
      print('Direct query found ${querySnapshot.docs.length} documents');
      for (var doc in querySnapshot.docs) {
        print('Document: ${doc.id} - ${doc.data()}');
      }
    } catch (e) {
      print('Direct query error: $e');
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
    // Ottieni le dimensioni dello schermo per layout responsive
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 600;
    final isSmallMobile = screenSize.width < 400;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: GestureDetector(
        onTap: () {
          // Forza un refresh quando l'utente tocca la home screen
          if (_currentUserId != null) {
            print('Home screen tapped, forcing COMPLETE REFRESH...');
            
            // Forza un refresh completo
            _forceCompleteRefresh();
          }
        },
        child: CustomScrollView(
        slivers: [
          // Header responsive con altezza adattiva
          SliverAppBar(
            expandedHeight: isMobile ? 140 : 200, // Ridotto per mobile
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
                    padding: EdgeInsets.all(isMobile ? 12 : 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header top row responsive
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Ciao, $_username! 👋',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: isMobile ? 18 : 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${_entries.length} password salvate',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: isMobile ? 12 : 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Action buttons responsive
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (!isSmallMobile) ...[
                                  _buildActionButton(
                                    icon: Icons.analytics_rounded,
                                    onPressed: () => _showStatsDialog(),
                                    isMobile: isMobile,
                                  ),
                                  SizedBox(width: isMobile ? 4 : 6),
                                ],
                                _buildActionButton(
                                  icon: Icons.refresh_rounded,
                                  onPressed: () {
                                    print('Manual refresh button pressed - FORCING COMPLETE REFRESH');
                                    
                                    // Cancella tutto
                                    _passwordsSubscription?.cancel();
                                    _healthCheckTimer?.cancel();
                                    
                                    // Forza un refresh completo
                                    _forceCompleteRefresh();
                                  },
                                  isMobile: isMobile,
                                ),
                                SizedBox(width: isMobile ? 4 : 6),
                                _buildActionButton(
                                  icon: _obscureText ? Icons.visibility_off : Icons.visibility,
                                  onPressed: () {
                                    setState(() {
                                      _obscureText = !_obscureText;
                                    });
                                  },
                                  isMobile: isMobile,
                                ),
                                SizedBox(width: isMobile ? 4 : 6),
                                _buildActionButton(
                                  icon: Icons.logout_rounded,
                                  onPressed: _logout,
                                  isMobile: isMobile,
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: isMobile ? 12 : 16),
                        // Search bar responsive
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(isMobile ? 12 : 16),
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
                            style: const TextStyle(color: Color(0xFFEC4899)), // Fucsia
                            decoration: InputDecoration(
                              hintText: 'Cerca password...',
                              hintStyle: TextStyle(color: Color(0xFFEC4899).withOpacity(0.7)), // Fucsia
                              prefixIcon: Container(
                                margin: EdgeInsets.all(isMobile ? 4 : 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(isMobile ? 6 : 8),
                                ),
                                child: Icon(
                                  Icons.search_rounded,
                                  color: Color(0xFFEC4899), // Fucsia
                                  size: isMobile ? 18 : 20,
                                ),
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 12 : 16,
                                vertical: isMobile ? 10 : 14,
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
          
          // Lista password con padding responsive
          SliverToBoxAdapter(
            child: _filteredEntries.isEmpty
                ? _buildEmptyState()
                : AnimatedList(
                    key: _listKey,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.all(isMobile ? 12 : 16),
                    initialItemCount: _filteredEntries.length,
                    itemBuilder: (context, index, animation) {
                      if (index >= _filteredEntries.length) return const SizedBox();
                      return _buildPasswordCard(_filteredEntries[index], animation);
                    },
                  ),
          ),
        ],
      ),
      ),
      
      // FAB responsive
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
          ),
          borderRadius: BorderRadius.circular(isMobile ? 14 : 18),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3B82F6).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: _addPassword,
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: Icon(
            Icons.add_rounded, 
            color: Colors.white,
            size: isMobile ? 18 : 20,
          ),
          label: Text(
            'Aggiungi',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: isMobile ? 13 : 15,
            ),
          ),
        ),
      ),
    );
  }

  // Widget helper per bottoni responsive
  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    required bool isMobile,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(isMobile ? 6 : 8),
      ),
      child: IconButton(
        icon: Icon(
          icon,
          color: Colors.white,
          size: isMobile ? 18 : 20,
        ),
        onPressed: onPressed,
        padding: EdgeInsets.all(isMobile ? 6 : 8),
        constraints: BoxConstraints(
          minWidth: isMobile ? 36 : 40,
          minHeight: isMobile ? 36 : 40,
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
    
    // Ottieni le dimensioni dello schermo per layout responsive
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 600;
    final isSmallMobile = screenSize.width < 400;
    
    return SlideTransition(
      position: animation.drive(
        Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
            .chain(CurveTween(curve: Curves.easeOutCubic)),
      ),
      child: Container(
        margin: EdgeInsets.only(bottom: isMobile ? 12 : 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
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
            borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
            onTap: () => _editPassword(entry),
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 16 : 20),
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
                          width: isMobile ? 40 : 48,
                          height: isMobile ? 40 : 48,
                          decoration: BoxDecoration(
                            color: serviceColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
                            border: Border.all(
                              color: serviceColor.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            serviceIcon,
                            color: serviceColor,
                            size: isMobile ? 20 : 24,
                          ),
                        ),
                      ),
                      
                      SizedBox(width: isMobile ? 12 : 16),
                      
                      // Titolo e username
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.title,
                              style: TextStyle(
                                fontSize: isMobile ? 16 : 18,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1F2937),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (entry.username.isNotEmpty) ...[
                              SizedBox(height: isMobile ? 3 : 4),
                              Text(
                                entry.username,
                                style: TextStyle(
                                  fontSize: isMobile ? 12 : 14,
                                  color: Colors.grey.shade600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      
                      // Menu popup
                      PopupMenuButton(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(isMobile ? 8 : 12),
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
                          padding: EdgeInsets.all(isMobile ? 6 : 8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(isMobile ? 6 : 8),
                          ),
                          child: Icon(
                            Icons.more_vert_rounded,
                            color: const Color(0xFF6B7280),
                            size: isMobile ? 18 : 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  SizedBox(height: isMobile ? 12 : 16),
                  
                  // Campo password con design moderno
                  Container(
                    padding: EdgeInsets.all(isMobile ? 12 : 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.grey.shade50,
                          Colors.grey.shade100,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
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
                          size: isMobile ? 18 : 20,
                        ),
                        SizedBox(width: isMobile ? 10 : 12),
                        Expanded(
                          child: Text(
                            _obscureText ? '••••••••••••' : entry.password,
                            style: TextStyle(
                              fontSize: isMobile ? 14 : 16,
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
                            size: isMobile ? 18 : 20,
                          ),
                          padding: EdgeInsets.all(isMobile ? 4 : 8),
                          constraints: BoxConstraints(
                            minWidth: isMobile ? 32 : 40,
                            minHeight: isMobile ? 32 : 40,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  SizedBox(height: isMobile ? 12 : 16),
                  
                  // Footer con info
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Badge forza password
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: isMobile ? 8 : 12, 
                          vertical: isMobile ? 4 : 6
                        ),
                        decoration: BoxDecoration(
                          color: strengthColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(isMobile ? 16 : 20),
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
                              size: isMobile ? 14 : 16,
                            ),
                            SizedBox(width: isMobile ? 4 : 6),
                            Text(
                              strength,
                              style: TextStyle(
                                color: strengthColor,
                                fontSize: isMobile ? 10 : 12,
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
                          fontSize: isMobile ? 10 : 12,
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
      // Password aggiunta con successo, ricarica la lista
      print('Password added successfully, using ULTRA AGGRESSIVE refresh...');
      
      // SOLUZIONE RADICALE: Bypass completo del listener
      _passwordsSubscription?.cancel();
      
      // Aspetta un momento per permettere a Firestore di sincronizzare
      await Future.delayed(const Duration(milliseconds: 200));
      
      // Usa il caricamento ultra aggressivo
      await _loadPasswordsUltraAggressive();
      
      // Riabilita il listener dopo il caricamento
      Future.delayed(const Duration(milliseconds: 1000), () {
        if (mounted && _currentUserId != null) {
          _loadPasswordsFromFirestore();
        }
      });
      
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
      // Password modificata con successo, ricarica la lista
      print('Password edited successfully, refreshing list...');
      
      // Aspetta un momento per permettere a Firestore di sincronizzare
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Prova prima il listener, poi il fallback
      await _loadPasswordsOnce();
      
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
        
        // Ricarica la lista dopo l'eliminazione
        print('Password deleted successfully, refreshing list...');
        
        // Aspetta un momento per permettere a Firestore di sincronizzare
        await Future.delayed(const Duration(milliseconds: 500));
        
        // Prova prima il listener, poi il fallback
        await _loadPasswordsOnce();
        
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



