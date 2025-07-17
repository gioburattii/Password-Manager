import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../models/password_entry.dart';
import '../services/image_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';

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
  final ImageService _imageService = ImageService();
  
  bool _obscurePassword = true;
  XFile? _selectedImage;
  String? _imageUrl;
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    // Inizializza i controller con i dati esistenti
    _titleController = TextEditingController(text: widget.entry.title);
    _usernameController = TextEditingController(text: widget.entry.username);
    _passwordController = TextEditingController(text: widget.entry.password);
    _notesController = TextEditingController(text: widget.entry.notes ?? '');
    _imageUrl = widget.entry.imageUrl;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _savePassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
      });
      
      try {
        String? imageUrl = _imageUrl;
        
        // Se c'è un'immagine selezionata, caricala con progresso
        if (_selectedImage != null) {
          try {
            imageUrl = await _imageService.uploadImageWithRetry(
              _selectedImage!, 
              widget.entry.id,
              onProgress: (progress) {
                setState(() {
                  _uploadProgress = progress;
                });
              },
            );
            
            if (imageUrl == null) {
              throw Exception('Errore durante il caricamento dell\'immagine');
            }
            
            // Elimina la vecchia immagine se esiste
            if (_imageUrl != null && _imageUrl != imageUrl) {
              await _imageService.deleteImage(_imageUrl!);
            }
          } catch (e) {
            // Mostra errore specifico per l'upload immagine
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Errore caricamento immagine: ${e.toString()}'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
            setState(() => _isUploading = false);
            return;
          }
        }
        
        final updatedEntry = PasswordEntry(
          id: widget.entry.id, // Mantiene lo stesso ID
          title: _titleController.text,
          username: _usernameController.text,
          password: _passwordController.text,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          imageUrl: imageUrl,
        );

        Navigator.pop(context, updatedEntry);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Errore durante il salvataggio: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _pickImage() async {
    final image = await _imageService.pickImage();
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  Widget _buildImageSelector() {
    final emoji = _imageService.getEmojiForTitle(_titleController.text);
    
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: _selectedImage != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FutureBuilder<Uint8List>(
                  future: _selectedImage!.readAsBytes(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Image.memory(
                        snapshot.data!,
                        fit: BoxFit.cover,
                      );
                    } else {
                      return _buildDefaultIcon(emoji);
                    }
                  },
                ),
              )
            : _imageUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      _imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildDefaultIcon(emoji);
                      },
                    ),
                  )
                : _buildDefaultIcon(emoji),
      ),
    );
  }

  Widget _buildDefaultIcon(String? emoji) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: emoji != null
            ? Text(
                emoji,
                style: const TextStyle(fontSize: 32),
              )
            : const Icon(
                Icons.add_photo_alternate,
                color: Colors.white,
                size: 32,
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Modifica Password',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF6366F1)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
                        TextButton.icon(
                onPressed: _isUploading ? null : _savePassword,
                icon: _isUploading 
                    ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          value: _selectedImage != null ? _uploadProgress : null,
                        ),
                      )
                    : const Icon(Icons.save, color: Color(0xFF10B981)),
                label: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isUploading ? 'Salvando...' : 'Salva',
                      style: TextStyle(
                        color: _isUploading ? Colors.grey : Color(0xFF10B981),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_isUploading && _selectedImage != null && _uploadProgress > 0)
                      Text(
                        '${(_uploadProgress * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
              ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card principale con i campi
              Card(
                elevation: 8,
                shadowColor: Colors.black.withOpacity(0.1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Titolo
                      const Text(
                        'Informazioni',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Selettore immagine
                      Row(
                        children: [
                          _buildImageSelector(),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Icona Password',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1F2937),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Tocca per cambiare l\'immagine',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // Campo Titolo
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: 'Titolo *',
                          hintText: 'es. Gmail, Facebook, GitHub...',
                          prefixIcon: const Icon(
                            Icons.title,
                            color: Color(0xFF6366F1),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF6366F1),
                              width: 2,
                            ),
                          ),
                        ),
                        validator: (value) =>
                            value!.isEmpty ? 'Il titolo è obbligatorio' : null,
                        onChanged: (value) => setState(() {}), // Aggiorna l'emoji
                      ),
                      const SizedBox(height: 16),
                      
                      // Campo Username/Email
                      TextFormField(
                        controller: _usernameController,
                        decoration: InputDecoration(
                          labelText: 'Username / Email *',
                          hintText: 'es. nomeutente@gmail.com',
                          prefixIcon: const Icon(
                            Icons.person,
                            color: Color(0xFF6366F1),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF6366F1),
                              width: 2,
                            ),
                          ),
                        ),
                        validator: (value) =>
                            value!.isEmpty ? 'Username/Email è obbligatorio' : null,
                      ),
                      const SizedBox(height: 16),
                      
                      // Campo Password
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password *',
                          hintText: 'Inserisci una password sicura',
                          prefixIcon: const Icon(
                            Icons.lock,
                            color: Color(0xFF6366F1),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: Colors.grey.shade600,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF6366F1),
                              width: 2,
                            ),
                          ),
                        ),
                        validator: (value) =>
                            value!.isEmpty ? 'La password è obbligatoria' : null,
                      ),
                      const SizedBox(height: 16),
                      
                      // Campo Note
                      TextFormField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Note (opzionale)',
                          hintText: 'Aggiungi informazioni aggiuntive...',
                          prefixIcon: const Icon(
                            Icons.notes,
                            color: Color(0xFF6366F1),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF6366F1),
                              width: 2,
                            ),
                          ),
                          alignLabelWithHint: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Pulsante Salva principale
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _savePassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    elevation: 8,
                    shadowColor: const Color(0xFF10B981).withOpacity(0.3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.save, size: 24),
                  label: const Text(
                    'Salva Modifiche',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Pulsante Annulla
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade400),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: Icon(Icons.cancel, color: Colors.grey.shade600),
                  label: Text(
                    'Annulla',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 