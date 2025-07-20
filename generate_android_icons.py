#!/usr/bin/env python3
"""
Script per generare le icone Android con le dimensioni corrette
"""

import os
from PIL import Image, ImageDraw, ImageFont

def create_android_icon(size):
    """Crea un'icona Android con il logo aggiornato"""
    
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
    
    # Fallback: crea un'icona con gradiente
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
    
    return result

def main():
    """Genera le icone Android con le dimensioni corrette"""
    
    print("🤖 Generazione icone Android...")
    
    # Dimensioni Android mipmap
    android_icons = [
        # mdpi
        (48, "mipmap-mdpi/ic_launcher.png"),
        (48, "mipmap-mdpi/ic_launcher_foreground.png"),
        (48, "mipmap-mdpi/ic_launcher_background.png"),
        
        # hdpi
        (72, "mipmap-hdpi/ic_launcher.png"),
        (72, "mipmap-hdpi/ic_launcher_foreground.png"),
        (72, "mipmap-hdpi/ic_launcher_background.png"),
        
        # xhdpi
        (96, "mipmap-xhdpi/ic_launcher.png"),
        (96, "mipmap-xhdpi/ic_launcher_foreground.png"),
        (96, "mipmap-xhdpi/ic_launcher_background.png"),
        
        # xxhdpi
        (144, "mipmap-xxhdpi/ic_launcher.png"),
        (144, "mipmap-xxhdpi/ic_launcher_foreground.png"),
        (144, "mipmap-xxhdpi/ic_launcher_background.png"),
        
        # xxxhdpi
        (192, "mipmap-xxxhdpi/ic_launcher.png"),
        (192, "mipmap-xxxhdpi/ic_launcher_foreground.png"),
        (192, "mipmap-xxxhdpi/ic_launcher_background.png"),
    ]
    
    # Crea directory se non esistono
    for size, path in android_icons:
        os.makedirs(f'android/app/src/main/res/{os.path.dirname(path)}', exist_ok=True)
    
    # Genera le icone
    for size, path in android_icons:
        icon = create_android_icon(size)
        full_path = f'android/app/src/main/res/{path}'
        icon.save(full_path)
        print(f"  ✅ {path} ({size}x{size})")
    
    print("\n🎉 Icone Android generate con successo!")

if __name__ == "__main__":
    main() 