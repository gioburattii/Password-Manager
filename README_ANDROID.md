# Password Manager - Installazione Android

## 📱 App Android Pronta per l'Installazione

L'app Password Manager è ora configurata per funzionare su dispositivi Android!

### 🎯 Caratteristiche dell'App Android

- ✅ **Icona aggiornata** con la chiave più grande nel diamante
- ✅ **Autenticazione Google** integrata
- ✅ **Firebase Firestore** per il salvataggio sicuro delle password
- ✅ **Interfaccia moderna** e responsive
- ✅ **Compatibilità** con Android 6.0 (API 23) e versioni successive

### 📦 File APK Disponibili

Sono stati generati due file APK:

1. **`app-debug.apk`** (201MB) - Versione di debug per test
2. **`app-release.apk`** (51MB) - Versione release ottimizzata per l'installazione

### 🔧 Come Installare l'App su Android

#### Metodo 1: Installazione Diretta (Raccomandato)

1. **Copia il file APK** sul tuo dispositivo Android:
   - `build/app/outputs/flutter-apk/app-release.apk`

2. **Abilita l'installazione da fonti sconosciute**:
   - Vai su **Impostazioni > Sicurezza**
   - Abilita **"Origini sconosciute"** o **"Installa app sconosciute"**

3. **Installa l'app**:
   - Apri il file APK dal file manager
   - Tocca **"Installa"**
   - Conferma l'installazione

#### Metodo 2: Installazione via ADB (per sviluppatori)

```bash
# Connessione USB con debug abilitato
adb install build/app/outputs/flutter-apk/app-release.apk
```

#### Metodo 3: Installazione via Flutter

```bash
# Con dispositivo connesso via USB
flutter install -d <device-id>
```

### 🚀 Primo Avvio

1. **Apri l'app** "Password Manager" dal launcher
2. **Accedi con Google** per iniziare
3. **Inizia a salvare** le tue password in modo sicuro

### 🔒 Sicurezza

- L'app utilizza **Firebase Authentication** per l'accesso sicuro
- Le password sono salvate in **Firestore** con crittografia
- **Google Sign-In** per un accesso rapido e sicuro

### 📋 Requisiti di Sistema

- **Android 6.0** (API 23) o superiore
- **Connessione internet** per l'autenticazione e sincronizzazione
- **Account Google** per l'accesso

### 🛠️ Sviluppo

Per modificare e ricompilare l'app:

```bash
# Aggiorna le dipendenze
flutter pub get

# Compila per debug
flutter build apk --debug

# Compila per release
flutter build apk --release

# Installa su dispositivo connesso
flutter install
```

### 🎨 Personalizzazione Icone

Per aggiornare le icone Android:

```bash
# Genera nuove icone con la chiave aggiornata
python3 generate_android_icons.py

# Ricompila l'app
flutter build apk --release
```

### 📞 Supporto

Se riscontri problemi durante l'installazione:

1. Verifica che il dispositivo supporti Android 6.0+
2. Assicurati di aver abilitato l'installazione da fonti sconosciute
3. Controlla che ci sia spazio sufficiente per l'installazione
4. Verifica la connessione internet per l'autenticazione

---

**🎉 L'app è ora pronta per essere installata su qualsiasi dispositivo Android!** 