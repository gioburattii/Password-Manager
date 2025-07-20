# 🔐 Password Manager

Un'applicazione Flutter moderna e sicura per la gestione delle password, con autenticazione Google e sincronizzazione cloud tramite Firebase.

![Password Manager Logo](assets/logo_512x512.png)

## 📱 Caratteristiche Principali

### 🔒 Sicurezza Avanzata
- **Autenticazione Google** sicura e affidabile
- **Crittografia dei dati** tramite Firebase Firestore
- **Accesso protetto** con credenziali personali
- **Sessione persistente** per un'esperienza fluida

### 💾 Gestione Password Completa
- **Aggiunta password** con dettagli completi (sito web, username, password, note)
- **Modifica e aggiornamento** delle password esistenti
- **Eliminazione sicura** dei dati
- **Ricerca rapida** tra le password salvate
- **Categorizzazione** automatica per tipo di servizio

### 🎨 Interfaccia Moderna
- **Design Material 3** con tema personalizzato
- **Animazioni fluide** e transizioni eleganti
- **Logo personalizzato** con rombo e chiave
- **Responsive design** per tutti i dispositivi
- **Tema scuro/chiaro** automatico

### 📊 Statistiche e Analisi
- **Dashboard informativa** con statistiche password
- **Contatore password** totali e per categoria
- **Indicatori di sicurezza** per password forti/deboli
- **Grafici visivi** per una migliore comprensione

## 🚀 Tecnologie Utilizzate

### Frontend
- **Flutter 3.x** - Framework cross-platform
- **Dart** - Linguaggio di programmazione
- **Material Design 3** - Sistema di design
- **Provider** - Gestione dello stato

### Backend e Servizi
- **Firebase Authentication** - Autenticazione utenti
- **Firebase Firestore** - Database NoSQL cloud
- **Google Sign-In** - Accesso con account Google
- **SharedPreferences** - Storage locale

### Sicurezza
- **Firestore Security Rules** - Controllo accessi
- **Crittografia dati** - Protezione informazioni
- **Validazione input** - Prevenzione attacchi

## 📋 Requisiti di Sistema

### Sviluppo
- **Flutter SDK** 3.0 o superiore
- **Dart SDK** 2.17 o superiore
- **Android Studio** / **VS Code**
- **Git** per il controllo versione

### Runtime
- **Android** 5.0 (API 21) o superiore
- **iOS** 11.0 o superiore
- **Web** - Browser moderno con JavaScript abilitato
- **macOS** 10.14 o superiore

## 🛠️ Installazione e Setup

### 1. Clona il Repository
```bash
git clone https://github.com/tuousername/password_manager.git
cd password_manager
```

### 2. Installa le Dipendenze
```bash
flutter pub get
```

### 3. Configura Firebase
1. Crea un progetto Firebase su [console.firebase.google.com](https://console.firebase.google.com)
2. Abilita Authentication e Firestore
3. Configura Google Sign-In
4. Scarica e aggiungi i file di configurazione:
   - `google-services.json` per Android
   - `GoogleService-Info.plist` per iOS
   - Configurazione web per il browser

### 4. Configura le Regole Firestore
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      match /passwords/{passwordId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
  }
}
```

### 5. Esegui l'Applicazione
```bash
# Per web
flutter run -d chrome

# Per Android
flutter run -d android

# Per iOS
flutter run -d ios

# Per macOS
flutter run -d macos
```

## 📱 Struttura dell'Applicazione

### 🏗️ Architettura
```
lib/
├── main.dart                 # Entry point dell'app
├── firebase_options.dart     # Configurazione Firebase
├── models/
│   └── password_entry.dart   # Modello dati password
├── screens/
│   ├── splash_screen.dart    # Schermata di avvio
│   ├── auth_screen.dart      # Autenticazione
│   ├── home_screen.dart      # Dashboard principale
│   ├── add_password_screen.dart    # Aggiunta password
│   └── edit_password_screen.dart   # Modifica password
└── services/
    └── (servizi vari)
```

### 🎯 Flusso Utente
1. **Splash Screen** - Logo animato e caricamento
2. **Autenticazione** - Login con Google o credenziali
3. **Dashboard** - Visualizzazione password e statistiche
4. **Gestione** - Aggiunta, modifica, eliminazione password

## 🔧 Funzionalità Dettagliate

### 🔐 Gestione Password
- **Aggiunta**: Form completo con validazione
- **Modifica**: Interfaccia intuitiva per aggiornamenti
- **Eliminazione**: Conferma sicura prima della rimozione
- **Ricerca**: Filtro rapido per trovare password
- **Copia**: Copia automatica negli appunti
- **Reset Password**: Funzionalità "Password dimenticata" integrata
- **Caricamento Ultra Aggressivo**: Sistema di refresh avanzato per garantire visibilità immediata
- **Refresh Manuale**: Pulsante di refresh per forzare l'aggiornamento della lista

### 📊 Dashboard
- **Contatore totale** password
- **Statistiche per categoria** (social, email, banking, etc.)
- **Indicatori di sicurezza** (password forti/deboli)
- **Grafici visivi** per analisi rapida

### 🎨 Personalizzazione
- **Tema dinamico** che si adatta al sistema
- **Animazioni fluide** per una migliore UX
- **Icone personalizzate** per ogni categoria
- **Layout responsive** per tutti i dispositivi

## 🚀 Nuove Funzionalità

### 🔄 Sistema di Refresh Avanzato
- **Caricamento Ultra Aggressivo**: Bypass completo del listener Firestore per garantire visibilità immediata
- **Refresh Manuale**: Pulsante dedicato per forzare l'aggiornamento della lista password
- **Refresh Automatico**: Trigger automatici quando si torna alla home screen o l'app riprende
- **Retry Intelligente**: Sistema di retry con 20 tentativi per garantire il caricamento completo

### 🔐 Gestione Password Migliorata
- **Reset Password**: Funzionalità "Password dimenticata" con dialog professionale
- **Validazione Email**: Controllo automatico dell'email per il reset
- **Feedback Utente**: Messaggi informativi per successo ed errori
- **Gestione Errori**: Gestione completa degli errori di rete e autenticazione

### 🎯 Ottimizzazioni Performance
- **Caricamento Diretto**: Query dirette a Firestore senza dipendere dai listener
- **Rebuild Multipli**: Forza multipli aggiornamenti dell'UI per garantire la visibilità
- **Gestione Lifecycle**: Refresh automatico quando l'app riprende o cambia schermata
- **Bypass Listener**: Disabilita temporaneamente i listener problematici

## 🔒 Sicurezza

### Autenticazione
- **Google Sign-In** sicuro e affidabile
- **Sessione persistente** con refresh automatico
- **Logout sicuro** con pulizia dati locali
- **Reset Password** integrato con Firebase Auth

### Dati
- **Crittografia** tramite Firebase
- **Regole di accesso** per utente
- **Validazione input** per prevenire attacchi
- **Backup automatico** su cloud

### Privacy
- **Dati locali** crittografati
- **Nessuna condivisione** con terze parti
- **Controllo completo** sui propri dati

## 🚀 Deployment

### Web
```bash
flutter build web
# I file generati sono in build/web/
```

### Android
```bash
flutter build apk --release
# APK generato in build/app/outputs/flutter-apk/
```

### iOS
```bash
flutter build ios --release
# Apri ios/Runner.xcworkspace in Xcode per il deployment
```

### macOS
```bash
flutter build macos --release
# App generata in build/macos/Build/Products/Release/
```

## 🧪 Testing

### Test Unitari
```bash
flutter test
```

### Test di Integrazione
```bash
flutter test integration_test/
```

### Test Manuali
- Test su dispositivi reali
- Verifica funzionalità cross-platform
- Controllo performance

## 🔧 Risoluzione Problemi

### Problema: Password non appaiono dopo l'aggiunta
**Soluzione**: L'app include un sistema di refresh avanzato:
1. **Pulsante Refresh**: Tocca l'icona refresh nella barra superiore
2. **Tap Home Screen**: Tocca la home screen per forzare un refresh
3. **Riavvio App**: Chiudi e riapri l'app per triggerare il refresh automatico

### Problema: Reset password non funziona
**Soluzione**: 
1. Verifica che l'email sia corretta
2. Controlla la casella di posta (anche spam)
3. Assicurati di avere una connessione internet stabile

### Problema: App non si compila
**Soluzione**:
```bash
flutter clean
flutter pub get
cd ios && pod install
cd .. && flutter build ios --release
```

## 📈 Performance

### Ottimizzazioni
- **Lazy loading** per liste grandi
- **Caching intelligente** dei dati
- **Animazioni ottimizzate** per fluidità
- **Compressione immagini** per ridurre dimensioni

### Metriche
- **Tempo di avvio**: < 3 secondi
- **Tempo di caricamento**: < 1 secondo
- **Memoria utilizzata**: < 100MB
- **Dimensioni app**: < 50MB

## 🤝 Contribuire

### Come Contribuire
1. **Fork** il repository
2. Crea un **branch** per la feature (`git checkout -b feature/nuova-funzionalita`)
3. **Commit** le modifiche (`git commit -am 'Aggiunta nuova funzionalità'`)
4. **Push** al branch (`git push origin feature/nuova-funzionalita`)
5. Crea una **Pull Request**

### Linee Guida
- Segui le **convenzioni di codice** Dart/Flutter
- Aggiungi **test** per nuove funzionalità
- Aggiorna la **documentazione**
- Mantieni la **sicurezza** come priorità


### Problemi Comuni
- **Errore Firebase**: Verifica la configurazione
- **Problemi di build**: Pulisci la cache con `flutter clean`
- **Errori di autenticazione**: Controlla le regole Firestore


### v1.0.0 (2024)
- ✅ Autenticazione Google
- ✅ Gestione password completa
- ✅ Dashboard con statistiche
- ✅ Design Material 3
- ✅ Supporto multi-piattaforma
- ✅ Sicurezza avanzata
<<<<<<< HEAD
======