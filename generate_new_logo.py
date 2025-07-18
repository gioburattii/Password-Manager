#!/usr/bin/env python3
"""
Script per generare il nuovo logo dell'app Password Manager
con scudo bianco su sfondo gradiente viola-fuchsia-blu
"""

from PIL import Image, ImageDraw, ImageFont
import os

def create_logo(size, output_path):
    """Crea il logo con scudo bianco su sfondo gradiente"""
    
    # Crea un'immagine con sfondo trasparente
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Calcola le dimensioni del gradiente
    gradient_width = size
    gradient_height = size
    
    # Crea il gradiente viola-fuchsia-blu
    for y in range(gradient_height):
        # Calcola il colore per questa riga
        ratio = y / gradient_height
        
        # Gradiente da viola (top) a fuchsia (middle) a blu (bottom)
        if ratio < 0.5:
            # Prima metà: viola a fuchsia
            r = int(139 + (236 - 139) * (ratio * 2))  # 139 -> 236
            g = int(92 + (72 - 92) * (ratio * 2))     # 92 -> 72
            b = int(246 + (153 - 246) * (ratio * 2))  # 246 -> 153
        else:
            # Seconda metà: fuchsia a blu
            r = int(236 + (59 - 236) * ((ratio - 0.5) * 2))  # 236 -> 59
            g = int(72 + (130 - 72) * ((ratio - 0.5) * 2))   # 72 -> 130
            b = int(153 + (246 - 153) * ((ratio - 0.5) * 2)) # 153 -> 246
        
        # Disegna la riga del gradiente
        draw.line([(0, y), (gradient_width, y)], fill=(r, g, b, 255))
    
    # Calcola le dimensioni dello scudo
    shield_size = int(size * 0.6)
    shield_x = (size - shield_size) // 2
    shield_y = (size - shield_size) // 2
    
    # Disegna lo scudo bianco
    shield_points = [
        (shield_x + shield_size // 2, shield_y),  # Punta superiore
        (shield_x + shield_size, shield_y + shield_size // 3),  # Angolo superiore destro
        (shield_x + shield_size * 3 // 4, shield_y + shield_size * 2 // 3),  # Curva destra
        (shield_x + shield_size // 2, shield_y + shield_size),  # Punta inferiore
        (shield_x + shield_size // 4, shield_y + shield_size * 2 // 3),  # Curva sinistra
        (shield_x, shield_y + shield_size // 3),  # Angolo superiore sinistro
    ]
    
    # Disegna lo scudo con bordo sottile
    draw.polygon(shield_points, fill=(255, 255, 255, 255), outline=(255, 255, 255, 200))
    
    # Aggiungi le linee interne dello scudo per dare profondità
    line_width = max(1, shield_size // 40)
    
    # Linea orizzontale centrale
    center_y = shield_y + shield_size // 2
    draw.line([
        (shield_x + shield_size // 4, center_y),
        (shield_x + shield_size * 3 // 4, center_y)
    ], fill=(240, 240, 240, 255), width=line_width)
    
    # Linea verticale centrale
    center_x = shield_x + shield_size // 2
    draw.line([
        (center_x, shield_y + shield_size // 3),
        (center_x, shield_y + shield_size * 2 // 3)
    ], fill=(240, 240, 240, 255), width=line_width)
    
    # Salva l'immagine
    img.save(output_path, 'PNG')
    print(f"Logo generato: {output_path}")

def main():
    """Genera tutti i formati di logo necessari"""
    
    # Crea la cartella assets se non esiste
    os.makedirs('assets', exist_ok=True)
    
    # Dimensioni per web
    web_sizes = [16, 32, 48, 64, 128, 192, 256, 512]
    for size in web_sizes:
        output_path = f'assets/logo_{size}x{size}.png'
        create_logo(size, output_path)
    
    # Dimensioni per Android
    android_sizes = {
        'mipmap-hdpi': 72,
        'mipmap-mdpi': 48,
        'mipmap-xhdpi': 96,
        'mipmap-xxhdpi': 144,
        'mipmap-xxxhdpi': 192
    }
    
    for folder, size in android_sizes.items():
        os.makedirs(f'android/app/src/main/res/{folder}', exist_ok=True)
        output_path = f'android/app/src/main/res/{folder}/ic_launcher.png'
        create_logo(size, output_path)
    
    # Dimensioni per iOS
    ios_sizes = {
        'Icon-App-20x20@1x': 20,
        'Icon-App-20x20@2x': 40,
        'Icon-App-20x20@3x': 60,
        'Icon-App-29x29@1x': 29,
        'Icon-App-29x29@2x': 58,
        'Icon-App-29x29@3x': 87,
        'Icon-App-40x40@1x': 40,
        'Icon-App-40x40@2x': 80,
        'Icon-App-40x40@3x': 120,
        'Icon-App-60x60@1x': 60,
        'Icon-App-60x60@2x': 120,
        'Icon-App-60x60@3x': 180,
        'Icon-App-76x76@1x': 76,
        'Icon-App-76x76@2x': 152,
        'Icon-App-83.5x83.5@2x': 167,
        'Icon-App-1024x1024@1x': 1024
    }
    
    for name, size in ios_sizes.items():
        output_path = f'ios/Runner/Assets.xcassets/AppIcon.appiconset/{name}.png'
        create_logo(size, output_path)
    
    # Dimensioni per macOS
    macos_sizes = {
        'app_icon_16': 16,
        'app_icon_32': 32,
        'app_icon_64': 64,
        'app_icon_128': 128,
        'app_icon_256': 256,
        'app_icon_512': 512,
        'app_icon_1024': 1024
    }
    
    for name, size in macos_sizes.items():
        output_path = f'macos/Runner/Assets.xcassets/AppIcon.appiconset/{name}.png'
        create_logo(size, output_path)
    
    print("✅ Tutti i loghi sono stati generati con successo!")
    print("🎨 Logo: Scudo bianco su sfondo gradiente viola-fuchsia-blu")
    print("📱 Formati: Web, Android, iOS, macOS")

if __name__ == "__main__":
    main() 