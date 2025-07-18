#!/usr/bin/env python3
"""
Script per generare le icone macOS con le dimensioni corrette
"""

import os
from PIL import Image, ImageDraw, ImageFont

def create_gradient_icon(size):
    """Crea un'icona con gradiente e simbolo del lucchetto"""
    
    # Crea un'immagine con sfondo trasparente
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
    """Genera le icone macOS con le dimensioni corrette"""
    
    print("🖥️ Generazione icone macOS...")
    
    # Dimensioni macOS con scale factors
    macos_icons = [
        (16, 1, "app_icon_16.png"),      # 16x16
        (16, 2, "app_icon_32.png"),      # 32x32
        (32, 1, "app_icon_32.png"),      # 32x32
        (32, 2, "app_icon_64.png"),      # 64x64
        (128, 1, "app_icon_128.png"),    # 128x128
        (128, 2, "app_icon_256.png"),    # 256x256
        (256, 1, "app_icon_256.png"),    # 256x256
        (256, 2, "app_icon_512.png"),    # 512x512
        (512, 1, "app_icon_512.png"),    # 512x512
        (512, 2, "app_icon_1024.png"),   # 1024x1024
    ]
    
    # Crea directory se non esiste
    os.makedirs('macos/Runner/Assets.xcassets/AppIcon.appiconset', exist_ok=True)
    
    # Genera le icone
    for base_size, scale, filename in macos_icons:
        actual_size = int(base_size * scale)
        icon = create_gradient_icon(actual_size)
        icon.save(f'macos/Runner/Assets.xcassets/AppIcon.appiconset/{filename}')
        print(f"  ✅ {filename} ({actual_size}x{actual_size})")
    
    print("\n🎉 Icone macOS generate con successo!")

if __name__ == "__main__":
    main() 