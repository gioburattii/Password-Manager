#!/usr/bin/env python3
"""
Script per generare il nuovo logo dell'app Password Manager
con sfondo sfumato viola-rosa e scudo bianco a scacchiera
"""

from PIL import Image, ImageDraw
import math

def create_gradient_background(width, height):
    """Crea uno sfondo con sfumatura da viola a rosa/magenta"""
    image = Image.new('RGB', (width, height))
    draw = ImageDraw.Draw(image)
    
    # Colori: viola a rosa/magenta
    violet = (139, 92, 246)    # #8B5CF6
    magenta = (236, 72, 153)   # #EC4899
    
    for x in range(width):
        # Calcola il colore per questa colonna (gradiente orizzontale)
        ratio = x / width
        r = int(violet[0] * (1 - ratio) + magenta[0] * ratio)
        g = int(violet[1] * (1 - ratio) + magenta[1] * ratio)
        b = int(violet[2] * (1 - ratio) + magenta[2] * ratio)
        
        # Disegna la linea verticale
        draw.line([(x, 0), (x, height)], fill=(r, g, b))
    
    return image

def create_rounded_square_mask(size, radius_ratio=0.15):
    """Crea una maschera per angoli arrotondati"""
    mask = Image.new('L', (size, size), 0)
    draw = ImageDraw.Draw(mask)
    
    radius = int(size * radius_ratio)
    draw.rounded_rectangle([0, 0, size-1, size-1], radius=radius, fill=255)
    
    return mask

def create_key_icon(size, color=(255, 255, 255)):
    """Crea un'icona di chiave semplice"""
    # Crea un'immagine trasparente per la chiave
    key = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(key)
    
    # Dimensioni della chiave
    key_size = int(size * 0.4)
    x_offset = (size - key_size) // 2
    y_offset = (size - key_size) // 2
    
    # Disegna la chiave
    # Anello della chiave
    ring_center_x = x_offset + key_size * 0.3
    ring_center_y = y_offset + key_size * 0.3
    ring_radius = key_size * 0.15
    draw.ellipse([
        ring_center_x - ring_radius,
        ring_center_y - ring_radius,
        ring_center_x + ring_radius,
        ring_center_y + ring_radius
    ], fill=color)
    
    # Asta della chiave
    shaft_width = key_size * 0.08
    shaft_length = key_size * 0.6
    shaft_x = ring_center_x + ring_radius - shaft_width // 2
    shaft_y = ring_center_y
    draw.rectangle([
        shaft_x, shaft_y,
        shaft_x + shaft_length, shaft_y + shaft_width
    ], fill=color)
    
    # Denti della chiave
    teeth_width = key_size * 0.12
    teeth_height = key_size * 0.08
    teeth_x = shaft_x + shaft_length - teeth_width
    teeth_y = shaft_y - teeth_height // 2
    draw.rectangle([
        teeth_x, teeth_y,
        teeth_x + teeth_width, teeth_y + teeth_height
    ], fill=color)
    
    return key

def create_diamond_with_key(size, gradient_colors):
    """Crea un rombo con chiave al centro con colori del gradiente"""
    # Crea un'immagine trasparente per il logo
    diamond = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(diamond)
    
    # Dimensioni del rombo
    diamond_size = int(size * 0.7)
    x_offset = (size - diamond_size) // 2
    y_offset = (size - diamond_size) // 2
    
    # Punti del rombo (diamante)
    diamond_points = [
        # Punta superiore
        (x_offset + diamond_size // 2, y_offset),
        # Punta destra
        (x_offset + diamond_size, y_offset + diamond_size // 2),
        # Punta inferiore
        (x_offset + diamond_size // 2, y_offset + diamond_size),
        # Punta sinistra
        (x_offset, y_offset + diamond_size // 2),
    ]
    
    # Disegna il rombo bianco
    draw.polygon(diamond_points, fill=(255, 255, 255))
    
    # Crea la chiave con colori del gradiente
    key_size = int(size * 0.3)
    key_x_offset = (size - key_size) // 2
    key_y_offset = (size - key_size) // 2
    
    # Crea un'immagine temporanea per la chiave
    temp_key = Image.new('RGBA', (key_size, key_size), (0, 0, 0, 0))
    temp_draw = ImageDraw.Draw(temp_key)
    
    # Disegna la chiave con gradiente
    key_actual_size = int(key_size * 0.4)
    key_actual_x_offset = (key_size - key_actual_size) // 2
    key_actual_y_offset = (key_size - key_actual_size) // 2
    
    # Anello della chiave
    ring_center_x = key_actual_x_offset + key_actual_size * 0.3
    ring_center_y = key_actual_y_offset + key_actual_size * 0.3
    ring_radius = key_actual_size * 0.15
    
    # Disegna l'anello con gradiente
    for i in range(int(ring_radius * 2)):
        for j in range(int(ring_radius * 2)):
            x = ring_center_x - ring_radius + i
            y = ring_center_y - ring_radius + j
            if (x - ring_center_x) ** 2 + (y - ring_center_y) ** 2 <= ring_radius ** 2:
                # Calcola il colore del gradiente per questo punto
                ratio = (i + j) / (ring_radius * 4)
                r = int(gradient_colors[0][0] * (1 - ratio) + gradient_colors[1][0] * ratio)
                g = int(gradient_colors[0][1] * (1 - ratio) + gradient_colors[1][1] * ratio)
                b = int(gradient_colors[0][2] * (1 - ratio) + gradient_colors[1][2] * ratio)
                temp_draw.point((x, y), fill=(r, g, b, 255))
    
    # Asta della chiave
    shaft_width = key_actual_size * 0.08
    shaft_length = key_actual_size * 0.6
    shaft_x = ring_center_x + ring_radius - shaft_width // 2
    shaft_y = ring_center_y
    
    # Disegna l'asta con gradiente
    for i in range(int(shaft_length)):
        ratio = i / shaft_length
        r = int(gradient_colors[0][0] * (1 - ratio) + gradient_colors[1][0] * ratio)
        g = int(gradient_colors[0][1] * (1 - ratio) + gradient_colors[1][1] * ratio)
        b = int(gradient_colors[0][2] * (1 - ratio) + gradient_colors[1][2] * ratio)
        temp_draw.rectangle([
            shaft_x + i, shaft_y,
            shaft_x + i + 1, shaft_y + shaft_width
        ], fill=(r, g, b, 255))
    
    # Denti della chiave
    teeth_width = key_actual_size * 0.12
    teeth_height = key_actual_size * 0.08
    teeth_x = shaft_x + shaft_length - teeth_width
    teeth_y = shaft_y - teeth_height // 2
    temp_draw.rectangle([
        teeth_x, teeth_y,
        teeth_x + teeth_width, teeth_y + teeth_height
    ], fill=gradient_colors[1])
    
    # Incolla la chiave nel rombo
    diamond.paste(temp_key, (key_x_offset, key_y_offset), temp_key)
    
    return diamond

def create_app_logo(size=512):
    """Crea il logo completo dell'app con rombo e chiave"""
    # Crea lo sfondo con sfumatura
    background = create_gradient_background(size, size)
    
    # Colori del gradiente
    violet = (139, 92, 246)    # #8B5CF6
    magenta = (236, 72, 153)   # #EC4899
    
    # Crea il rombo con chiave
    diamond_with_key = create_diamond_with_key(size, [violet, magenta])
    
    # Combina sfondo e rombo con chiave
    result = background.copy()
    result.paste(diamond_with_key, (0, 0), diamond_with_key)
    
    # Applica la maschera per angoli arrotondati
    mask = create_rounded_square_mask(size, 0.15)
    
    # Crea un'immagine finale con trasparenza
    final_image = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    final_image.paste(result, (0, 0))
    final_image.putalpha(mask)
    
    return final_image

def main():
    """Genera il logo in diverse dimensioni"""
    sizes = [16, 32, 48, 64, 128, 192, 256, 512]
    
    for size in sizes:
        print(f"Generando logo {size}x{size}...")
        logo = create_app_logo(size)
        
        # Salva con angoli arrotondati
        filename = f"assets/logo_{size}x{size}.png"
        logo.save(filename, "PNG")
        print(f"Logo salvato come {filename}")

if __name__ == "__main__":
    main() 