# 💾 Flusso di Salvataggio - Password Manager

## 🔄 **Aggiunta Nuova Password**

### 1. **AddPasswordScreen → HomeScreen**
```dart
// In AddPasswordScreen._savePassword()
final newEntry = PasswordEntry(
  id: const Uuid().v4(),
  title: _titleController.text,
  username: _usernameController.text,
  password: _passwordController.text,
  notes: _notesController.text.isEmpty ? null : _notesController.text,
  imageUrl: imageUrl, // Se caricata immagine
);

Navigator.pop(context, newEntry); // Ritorna l'entry
```

### 2. **HomeScreen riceve e salva**
```dart
// In HomeScreen FloatingActionButton
final newEntry = await Navigator.push<PasswordEntry>(
  context,
  MaterialPageRoute(builder: (_) => const AddPasswordScreen()),
);
if (newEntry != null) {
  _addEntry(newEntry); // ✅ Chiama il salvataggio
}
```

### 3. **Salvataggio su Firestore**
```dart
void _addEntry(PasswordEntry entry) {
  setState(() {
    _entries.add(entry); // ✅ Aggiunge alla lista locale
  });
  _savePasswordToFirestore(entry); // ✅ Salva su Firestore
}

Future<void> _savePasswordToFirestore(PasswordEntry entry) async {
  await _firestore
      .collection('users')
      .doc(_currentUserId)
      .collection('passwords')
      .doc(entry.id)
      .set(entry.toJson()); // ✅ Salvataggio persistente
  
  _saveBackupToDrive(); // ✅ Backup su Google Drive
}
```

## 🔄 **Modifica Password Esistente**

### 1. **EditPasswordScreen → HomeScreen**
```dart
// In EditPasswordScreen._savePassword()
final updatedEntry = PasswordEntry(
  id: widget.entry.id, // ✅ Mantiene stesso ID
  title: _titleController.text,
  username: _usernameController.text,
  password: _passwordController.text,
  notes: _notesController.text.isEmpty ? null : _notesController.text,
  imageUrl: imageUrl,
);

Navigator.pop(context, updatedEntry); // Ritorna entry aggiornata
```

### 2. **HomeScreen aggiorna**
```dart
// In HomeScreen._editEntry()
final updatedEntry = await Navigator.push<PasswordEntry>(
  context,
  MaterialPageRoute(builder: (_) => EditPasswordScreen(entry: entry)),
);

if (updatedEntry != null) {
  _updateEntry(index, updatedEntry); // ✅ Chiama l'aggiornamento
}
```

### 3. **Aggiornamento su Firestore**
```dart
void _updateEntry(int index, PasswordEntry updatedEntry) {
  setState(() {
    _entries[index] = updatedEntry; // ✅ Aggiorna lista locale
  });
  _savePasswordToFirestore(updatedEntry); // ✅ Salva su Firestore (stesso doc ID)
}
```

## 🖼️ **Upload Immagini**

### 1. **Compressione Automatica**
- **Dimensioni**: 300x300px max
- **Qualità**: 70% (JPEG)
- **Limite**: 1MB massimo
- **Retry**: 3 tentativi automatici

### 2. **Salvataggio Firebase Storage**
```dart
Path: users/{userId}/password_images/{passwordId}_{timestamp}.jpg
Metadata: passwordId, uploadedAt, originalSize, compressedSize
Cache: max-age=31536000 (1 anno)
```

## 📱 **Caricamento Dati**

### 1. **All'avvio dell'app**
```dart
// In HomeScreen.initState()
_loadPasswordsFromFirestore(); // ✅ Carica da Firestore
_migrateDriveToFirestore(); // ✅ Migra da Drive se necessario
```

### 2. **Sincronizzazione**
- **Primario**: Firestore (tempo reale)
- **Backup**: Google Drive (fallback)
- **Locale**: Lista in memoria (_entries)

## ✅ **Verifiche di Funzionamento**

### Test da Effettuare:

1. **Aggiunta Password**
   - [ ] Compila form con tutti i campi
   - [ ] Carica immagine (opzionale)
   - [ ] Salva e verifica apparizione in lista
   - [ ] Ricarica app e verifica persistenza

2. **Modifica Password**
   - [ ] Clicca su password esistente
   - [ ] Modifica campi
   - [ ] Cambia immagine (opzionale)
   - [ ] Salva e verifica aggiornamento

3. **Upload Immagine**
   - [ ] Seleziona immagine grande (test compressione)
   - [ ] Verifica barra progresso
   - [ ] Controlla retry automatico se fallisce

4. **Sincronizzazione**
   - [ ] Aggiungi password su un device
   - [ ] Verifica su Firestore Console
   - [ ] Login su altro device/browser
   - [ ] Verifica password presenti

## 🔧 **Troubleshooting**

### Problemi Comuni:
- **Password non salvata**: Verifica autenticazione Firebase
- **Immagine non caricata**: Controlla dimensioni e connessione
- **Dati non sincronizzati**: Verifica regole Firestore Security

### Log da Controllare:
```
Saving password to Firestore: {title}
Password saved successfully to Firestore
Upload completed: {downloadUrl}
Loaded X passwords from Firestore
```

## 📊 **Stato Implementazione**

- ✅ **Aggiunta password**: Implementata e testata
- ✅ **Modifica password**: Implementata e testata  
- ✅ **Upload immagini**: Ottimizzata con progresso
- ✅ **Salvataggio Firestore**: Funzionante
- ✅ **Backup Google Drive**: Automatico
- ✅ **Compressione immagini**: Implementata
- ✅ **Retry automatico**: Configurato
- ✅ **UI feedback**: Barre progresso e messaggi errore 