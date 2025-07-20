#!/usr/bin/env python3
"""
Script per generare le icone iOS con le dimensioni corrette
"""

import os
from PIL import Image, ImageDraw, ImageFont

def create_gradient_icon(size):
    """Crea un'icona con gradiente e logo con chiave"""
    
    # Carica il logo con la chiave più grande
    try:
        # Prova a caricare il logo 512x512 e ridimensionarlo
        logo_path = 'assets/logo_512x512.png'
        if os.path.exists(logo_path):
            logo = Image.open(logo_path).convert('RGBA')
            logo = logo.resize((size, size), Image.Resampling.LANCZOS)
            return logo
        else:
            print(f"⚠️ Logo non trovato: {logo_path}")
    except Exception as e:
        print(f"⚠️ Errore nel caricare il logo: {e}")
    
    # Fallback: crea un'icona con gradiente e simbolo del lucchetto
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Colori del gradiente (viola, rosa, blu)
    colors = [
        (139, 92, 246, 255),  # Viola #8B5CF6
        (236, 72, 153, 255),  # Rosa #EC4899
        (59, 130, 246, 255),  # Blu #3B82F6
    ]
    
    # Crea il gradiente
    for y in range(size):
        # Calcola la posizione nel gradiente (0-1)
        pos = y / size
        
        # Interpola tra i colori
        if pos <= 0.5:
            # Prima metà: viola a rosa
            t = pos * 2
            r = int(colors[0][0] * (1-t) + colors[1][0] * t)
            g = int(colors[0][1] * (1-t) + colors[1][1] * t)
            b = int(colors[0][2] * (1-t) + colors[1][2] * t)
        else:
            # Seconda metà: rosa a blu
            t = (pos - 0.5) * 2
            r = int(colors[1][0] * (1-t) + colors[2][0] * t)
            g = int(colors[1][1] * (1-t) + colors[2][1] * t)
            b = int(colors[1][2] * (1-t) + colors[2][2] * t)
        
        # Disegna la linea orizzontale
        draw.line([(0, y), (size, y)], fill=(r, g, b, 255))
    
    # Aggiungi bordi arrotondati
    radius = int(size * 0.2)
    mask = Image.new('L', (size, size), 0)
    mask_draw = ImageDraw.Draw(mask)
    
    # Disegna un rettangolo con bordi arrotondati
    mask_draw.rounded_rectangle([0, 0, size-1, size-1], radius=radius, fill=255)
    
    # Applica la maschera
    result = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    result.paste(img, (0, 0))
    result.putalpha(mask)
    
    # Aggiungi il simbolo del lucchetto
    try:
        # Prova a usare un font di sistema
        font_size = int(size * 0.4)
        font = ImageFont.truetype("/System/Library/Fonts/Apple Color Emoji.ttc", font_size)
    except:
        try:
            font = ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf", font_size)
        except:
            # Fallback a font di default
            font = ImageFont.load_default()
    
    # Simbolo del lucchetto (emoji o testo)
    lock_symbol = "🔒"
    
    # Calcola la posizione centrale
    bbox = draw.textbbox((0, 0), lock_symbol, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]
    
    x = (size - text_width) // 2
    y = (size - text_height) // 2
    
    # Disegna il simbolo con ombra
    shadow_offset = int(size * 0.02)
    draw.text((x + shadow_offset, y + shadow_offset), lock_symbol, 
              font=font, fill=(0, 0, 0, 100))
    draw.text((x, y), lock_symbol, font=font, fill=(255, 255, 255, 255))
    
    return result

def main():
    """Genera le icone iOS con le dimensioni corrette"""
    
    print("🍎 Generazione icone iOS...")
    
    # Dimensioni iOS con scale factors
    ios_icons = [
        # iPhone
        (20, 2, "Icon-App-20x20@2x.png"),      # 40x40
        (20, 3, "Icon-App-20x20@3x.png"),      # 60x60
        (29, 2, "Icon-App-29x29@2x.png"),      # 58x58
        (29, 3, "Icon-App-29x29@3x.png"),      # 87x87
        (40, 2, "Icon-App-40x40@2x.png"),      # 80x80
        (40, 3, "Icon-App-40x40@3x.png"),      # 120x120
        (60, 2, "Icon-App-60x60@2x.png"),      # 120x120
        (60, 3, "Icon-App-60x60@3x.png"),      # 180x180
        
        # iPad
        (20, 1, "Icon-App-20x20@1x.png"),      # 20x20
        (20, 2, "Icon-App-20x20@2x.png"),      # 40x40
        (29, 1, "Icon-App-29x29@1x.png"),      # 29x29
        (29, 2, "Icon-App-29x29@2x.png"),      # 58x58
        (40, 1, "Icon-App-40x40@1x.png"),      # 40x40
        (40, 2, "Icon-App-40x40@2x.png"),      # 80x80
        (76, 1, "Icon-App-76x76@1x.png"),      # 76x76
        (76, 2, "Icon-App-76x76@2x.png"),      # 152x152
        (83.5, 2, "Icon-App-83.5x83.5@2x.png"), # 167x167
        
        # App Store
        (1024, 1, "Icon-App-1024x1024@1x.png"), # 1024x1024
    ]
    
    # Crea directory se non esiste
    os.makedirs('ios/Runner/Assets.xcassets/AppIcon.appiconset', exist_ok=True)
    
    # Genera le icone
    for base_size, scale, filename in ios_icons:
        actual_size = int(base_size * scale)
        icon = create_gradient_icon(actual_size)
        icon.save(f'ios/Runner/Assets.xcassets/AppIcon.appiconset/{filename}')
        print(f"  ✅ {filename} ({actual_size}x{actual_size})")
    
    print("\n🎉 Icone iOS generate con successo!")

if __name__ == "__main__":
    main() 