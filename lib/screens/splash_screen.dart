import 'package:flutter/material.dart';
import 'dart:math';

class DiamondKeyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    // Disegna il rombo
    final path = Path();
    final width = size.width;
    final height = size.height;
    
    // Punti del rombo
    path.moveTo(width * 0.5, height * 0.1); // Punta superiore
    path.lineTo(width * 0.8, height * 0.5); // Punta destra
    path.lineTo(width * 0.5, height * 0.9); // Punta inferiore
    path.lineTo(width * 0.2, height * 0.5); // Punta sinistra
    path.close();
    
    // Disegna il rombo bianco
    canvas.drawPath(path, paint);
    
    // Disegna la chiave con gradiente
    _drawKey(canvas, size);
  }
  
  void _drawKey(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    
    // Dimensioni della chiave
    final keySize = width * 0.4;
    final keyX = (width - keySize) / 2;
    final keyY = (height - keySize) / 2;
    
    // Anello della chiave
    final ringCenterX = keyX + keySize * 0.3;
    final ringCenterY = keyY + keySize * 0.3;
    final ringRadius = keySize * 0.15;
    
    // Disegna l'anello con gradiente
    final ringPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFF8B5CF6), // Viola
          const Color(0xFFEC4899), // Rosa/Magenta
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(ringCenterX, ringCenterY),
        radius: ringRadius,
      ));
    
    canvas.drawCircle(
      Offset(ringCenterX, ringCenterY),
      ringRadius,
      ringPaint,
    );
    
    // Asta della chiave
    final shaftWidth = keySize * 0.08;
    final shaftLength = keySize * 0.6;
    final shaftX = ringCenterX + ringRadius - shaftWidth / 2;
    final shaftY = ringCenterY;
    
    // Disegna l'asta con gradiente lineare
    final shaftPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          const Color(0xFF8B5CF6), // Viola
          const Color(0xFFEC4899), // Rosa/Magenta
        ],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ).createShader(Rect.fromLTWH(shaftX, shaftY, shaftLength, shaftWidth));
    
    canvas.drawRect(
      Rect.fromLTWH(shaftX, shaftY, shaftLength, shaftWidth),
      shaftPaint,
    );
    
    // Denti della chiave
    final teethWidth = keySize * 0.12;
    final teethHeight = keySize * 0.08;
    final teethX = shaftX + shaftLength - teethWidth;
    final teethY = shaftY - teethHeight / 2;
    
    final teethPaint = Paint()
      ..color = const Color(0xFFEC4899); // Rosa/Magenta
    
    canvas.drawRect(
      Rect.fromLTWH(teethX, teethY, teethWidth, teethHeight),
      teethPaint,
    );
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  
  late Animation<double> _logoScale;
  late Animation<double> _logoRotation;
  late Animation<double> _textOpacity;
  late Animation<Offset> _textSlide;

  @override
  void initState() {
    super.initState();
    
    // Controller per logo (3 secondi)
    _logoController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    // Controller per testo (2 secondi)
    _textController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    // Animazioni logo
    _logoScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    
    _logoRotation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeInOut),
    );
    
    // Animazioni testo
    _textOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeIn),
    );
    
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic));
    
    // Sequenza animazioni
    _startAnimations();
  }

  void _startAnimations() async {
    // Logo animato
    await _logoController.forward();
    
    // Testo animato
    await _textController.forward();
    
    // Aspetta 2 secondi prima di navigare
    await Future.delayed(const Duration(seconds: 2));
    
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/auth');
    }
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.white,
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                
                // Logo animato
                AnimatedBuilder(
                  animation: _logoController,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _logoScale.value,
                      child: Transform.rotate(
                        angle: _logoRotation.value * 0.1,
                        child: Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF8B5CF6), // Viola
                                Color(0xFFEC4899), // Rosa/Magenta
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(35),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF8B5CF6).withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                              BoxShadow(
                                color: const Color(0xFFEC4899).withOpacity(0.2),
                                blurRadius: 30,
                                offset: const Offset(0, 15),
                              ),
                            ],
                          ),
                          child: CustomPaint(
                            size: const Size(70, 70),
                            painter: DiamondKeyPainter(),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 40),
                
                // Testo animato
                SlideTransition(
                  position: _textSlide,
                  child: FadeTransition(
                    opacity: _textOpacity,
                    child: Column(
                      children: [
                        Text(
                          'Password Manager',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w300,
                            color: const Color(0xFF8B5CF6),
                            letterSpacing: 2.0,
                            shadows: [
                              Shadow(
                                color: const Color(0xFF8B5CF6).withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Indicatore di caricamento
                        Container(
                          width: 40,
                          height: 40,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              const Color(0xFF8B5CF6).withOpacity(0.8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Caricamento...',
                          style: TextStyle(
                            fontSize: 16,
                            color: const Color(0xFF8B5CF6).withOpacity(0.8),
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
 