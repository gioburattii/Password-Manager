import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/password_entry.dart';
import '../services/image_service.dart';
import 'package:image_picker/image_picker.dart';


class AddPasswordScreen extends StatefulWidget {
  const AddPasswordScreen({super.key});

  @override
  State<AddPasswordScreen> createState() => _AddPasswordScreenState();
}

class _AddPasswordScreenState extends State<AddPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final ImageService _imageService = ImageService();
  
  XFile? _selectedImage;
  String? _imageUrl;
  bool _isUploading = false;
  double _uploadProgress = 0.0;

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
          final passwordId = const Uuid().v4();
          
          try {
            // Usa uploadImageWithRetry per maggiore affidabilità
            imageUrl = await _imageService.uploadImageWithRetry(
              _selectedImage!, 
              passwordId,
              onProgress: (progress) {
                setState(() {
                  _uploadProgress = progress;
                });
              },
            );
            
            if (imageUrl == null) {
              throw Exception('Errore durante il caricamento dell\'immagine');
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
        
        final newEntry = PasswordEntry(
          id: const Uuid().v4(),
          title: _titleController.text,
          username: _usernameController.text,
          password: _passwordController.text,
          notes: _notesController.text.isEmpty ? null : _notesController.text,
          imageUrl: imageUrl,
        );

        Navigator.pop(context, newEntry);
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
        _imageUrl = null; // Reset URL se si seleziona una nuova immagine
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
      appBar: AppBar(title: const Text('Aggiungi Password')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
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
                          'Tocca per scegliere un\'immagine personalizzata',
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
              const SizedBox(height: 24),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Titolo'),
                validator: (value) =>
                    value!.isEmpty ? 'Campo obbligatorio' : null,
                onChanged: (value) => setState(() {}), // Aggiorna l'emoji
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username / Email'),
                validator: (value) =>
                    value!.isEmpty ? 'Campo obbligatorio' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) =>
                    value!.isEmpty ? 'Campo obbligatorio' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(labelText: 'Note (opzionale)'),
                maxLines: 2,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isUploading ? null : _savePassword,
                child: _isUploading
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                              value: _selectedImage != null ? _uploadProgress : null,
                            ),
                          ),
                          if (_selectedImage != null && _uploadProgress > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                '${(_uploadProgress * 100).toInt()}%',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                        ],
                      )
                    : const Text('Salva'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
