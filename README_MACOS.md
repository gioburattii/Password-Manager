# Password Manager - macOS

## 🍎 Esecuzione su macOS

Questa app Flutter è stata configurata per funzionare su macOS oltre che su web, Android e iOS.

### Prerequisiti

1. **Flutter SDK** (versione 3.32.6 o superiore)
2. **Xcode** (versione 16.4 o superiore)
3. **CocoaPods** (installato automaticamente con Xcode)

### Verifica dell'installazione

```bash
flutter doctor
```

Assicurati che tutti i componenti siano configurati correttamente.

### Esecuzione dell'app

#### Prima volta
```bash
# Abilita il supporto per macOS
flutter config --enable-macos-desktop

# Installa le dipendenze
flutter pub get

# Installa le dipendenze CocoaPods
cd macos && pod install && cd ..

# Esegui l'app
flutter run -d macos
```

#### Esecuzioni successive
```bash
flutter run -d macos
```

### Funzionalità disponibili su macOS

✅ **Autenticazione Google** - Login con account Google  
✅ **Firebase Firestore** - Sincronizzazione dati cloud  
✅ **Gestione password** - Aggiunta, modifica, eliminazione  
✅ **Ricerca password** - Ricerca in tempo reale  
✅ **Interfaccia nativa** - Design ottimizzato per macOS  
✅ **Sicurezza** - Crittografia e protezione dati  

### Risoluzione problemi

#### Errore di compilazione
Se incontri errori di compilazione:

```bash
# Pulisci la cache
flutter clean

# Reinstalla le dipendenze
flutter pub get

# Reinstalla CocoaPods
cd macos && pod install && cd ..

# Riprova
flutter run -d macos
```

#### Problemi con Google Sign-In
L'app usa Google Sign-In per l'autenticazione. Assicurati che:
- Il progetto Firebase sia configurato correttamente
- Le credenziali OAuth siano valide
- L'app sia registrata nel progetto Firebase

#### Problemi di rete
L'app richiede una connessione internet per:
- Autenticazione Google
- Sincronizzazione con Firebase
- Backup su Google Drive

### Build per distribuzione

Per creare un'app distributibile:

```bash
flutter build macos
```

L'app compilata si troverà in `build/macos/Build/Products/Release/`

### Note tecniche

- **Versione minima macOS**: 10.13 (High Sierra)
- **Architetture supportate**: ARM64 (Apple Silicon) e x86_64 (Intel)
- **Dipendenze principali**: Firebase, Google Sign-In, Flutter
- **Lingua**: Italiano (interfaccia localizzata)

### Supporto

Per problemi specifici su macOS, controlla:
1. I log di Xcode
2. La console di macOS
3. I log di Flutter (`flutter logs`)

---

**Password Manager** - Gestore di password sicuro e moderno per macOS 🛡️ 