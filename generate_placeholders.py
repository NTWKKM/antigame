import os
import wave
import struct
import math
from PIL import Image, ImageDraw

# 16x16 ASCII pixel art patterns
# 0 = transparent, 1 = primary, 2 = secondary, 3 = skin/details, 4 = dark outline

elias_pattern = [
    "0000044444400000",
    "0000411111140000",
    "0004111331114000",
    "0041113333111400",
    "0041133443311400",
    "0041334444331400",
    "0041340440431400",
    "0041344444431400",
    "0004334334334000",
    "0004333333334000",
    "0000444444440000",
    "0004224444224000",
    "0004222442224000",
    "0004222442224000",
    "0000444004440000",
    "0000444004440000",
]

wall_pattern = [
    "4444444444444444",
    "4111111411111114",
    "4111111411111114",
    "4111111411111114",
    "4444444444444444",
    "1111411111111411",
    "1111411111111411",
    "1111411111111411",
    "4444444444444444",
    "4111111411111114",
    "4111111411111114",
    "4111111411111114",
    "4444444444444444",
    "1111411111111411",
    "1111411111111411",
    "1111411111111411",
]

floor_pattern = [
    "2222211111222221",
    "2222211111222221",
    "2212211111222221",
    "2222211111222221",
    "2222211111222221",
    "1111111111111111",
    "1111111111111111",
    "1111111111111111",
    "1111111111111111",
    "1111111111111111",
    "2222211111222221",
    "2222211121222221",
    "2222211111222221",
    "2222211111222221",
    "2222211111222221",
    "1111111111111111",
]

def draw_pattern(draw, x_off, y_off, pattern, colors):
    for y, row in enumerate(pattern):
        for x, char in enumerate(row):
            idx = int(char)
            if idx > 0 and idx in colors:
                draw.point((x_off + x, y_off + y), fill=colors[idx])

def generate_spritesheet(filepath):
    # 256x256 image (16x16 grid of 16x16 sprites)
    img = Image.new('RGBA', (256, 256), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Colors: {1: primary, 2: secondary, 3: skin, 4: outline}
    elias_colors = {1: (0, 100, 255), 2: (50, 50, 80), 3: (255, 200, 150), 4: (0, 0, 0)}
    vesper_colors = {1: (150, 0, 200), 2: (80, 20, 100), 3: (255, 180, 150), 4: (0, 0, 0)}
    lyra_colors = {1: (255, 200, 0), 2: (255, 255, 100), 3: (255, 255, 255), 4: (0, 0, 0)}
    enemy_colors = {1: (200, 0, 0), 2: (100, 0, 0), 3: (255, 0, 0), 4: (50, 0, 0)}
    wall_colors = {1: (80, 80, 80), 4: (40, 40, 40)}
    floor_colors = {1: (50, 50, 50), 2: (60, 60, 60)}

    # 1: Window icon (16x16)
    draw.rectangle([0, 0, 15, 15], fill=(255, 0, 255))
    
    # Player (index 2, col 2 -> x=16)
    draw_pattern(draw, 16 * 1, 0, elias_pattern, elias_colors)
    
    # Vesper (index 3, col 3 -> x=32)
    draw_pattern(draw, 16 * 2, 0, elias_pattern, vesper_colors)
    
    # Lyra (index 4, col 4 -> x=48)
    draw_pattern(draw, 16 * 3, 0, elias_pattern, lyra_colors)
    
    # Enemy (index 5, col 5 -> x=64)
    draw_pattern(draw, 16 * 4, 0, elias_pattern, enemy_colors)
    
    # Wall (index 17, row 2, col 1 -> x=0, y=16)
    draw_pattern(draw, 0, 16, wall_pattern, wall_colors)
    
    # Floor (index 18, row 2, col 2 -> x=16, y=16)
    draw_pattern(draw, 16 * 1, 16, floor_pattern, floor_colors)
    
    img.save(filepath)

def generate_wav(filepath, freq=440.0, duration=0.2, vol=0.5):
    sample_rate = 44100
    num_samples = int(duration * sample_rate)
    
    # ensure dir exists
    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    
    with wave.open(filepath, 'w') as w:
        w.setnchannels(1) # mono
        w.setsampwidth(2) # 2 bytes
        w.setframerate(sample_rate)
        
        for i in range(num_samples):
            env = 1.0 - (i / num_samples)
            value = int(vol * env * 32767.0 * math.sin(2.0 * math.pi * freq * (i / sample_rate)))
            data = struct.pack('<h', value)
            w.writeframesraw(data)

def generate_music_placeholder(filepath):
    generate_wav(filepath, freq=220.0, duration=1.0, vol=0.3)

if __name__ == '__main__':
    generate_spritesheet('sprites.png')
    generate_wav('sfx/hit.wav', freq=150.0, duration=0.1)
    generate_wav('sfx/jump.wav', freq=600.0, duration=0.15)
    generate_wav('sfx/select.wav', freq=800.0, duration=0.05)
    generate_music_placeholder('music/theme.wav')
    print("Enhanced pixel art assets generated.")
