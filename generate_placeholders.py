import os
import wave
import struct
import math
from PIL import Image, ImageDraw

# Improved 16x16 pixel art patterns for Primordium City
# 0=transparent, 1=primary, 2=secondary, 3=skin/detail, 4=dark outline, 5=highlight, 6=accent

# ============================================================
# CHARACTERS — Each has a distinct silhouette and color palette
# ============================================================

# Elias — Former Archive Enforcer, blue coat, short hair
elias_idle = [
    "0000044444000000",
    "0000433334000000",
    "0004333333400000",
    "0004333333400000",
    "0004340040340000",
    "0004333333400000",
    "0000433334000000",
    "0000441144000000",
    "0004411114400000",
    "0044112211440000",
    "0041111111140000",
    "0041111111140000",
    "0004111111400000",
    "0000422240000000",
    "0000420024000000",
    "0000440004400000",
]

elias_walk1 = [
    "0000044444000000",
    "0000433334000000",
    "0004333333400000",
    "0004333333400000",
    "0004340040340000",
    "0004333333400000",
    "0000433334000000",
    "0000441144000000",
    "0004411114400000",
    "0044112211440000",
    "0041111111140000",
    "0041111111140000",
    "0004111111400000",
    "0000422240000000",
    "0000040024000000",
    "0000440000400000",
]

# Vesper — Rogue data-weaver, purple robes, long hair
vesper_idle = [
    "0000044444000000",
    "0004433334400000",
    "0004333333400000",
    "0043333333340000",
    "0043340040334000",
    "0043333333340000",
    "0004333333400000",
    "0004441144400000",
    "0044111111440000",
    "0041115511140000",
    "0041111111140000",
    "0041111111140000",
    "0004111111400000",
    "0004411114400000",
    "0000420024000000",
    "0000440004400000",
]

# Lyra — Glitch construct, golden/white, ethereal
lyra_idle = [
    "0005044444050000",
    "0000433334000000",
    "0004333333400000",
    "0004333333400000",
    "0004340040340000",
    "0004333553400000",
    "0000433334000000",
    "0055441144550000",
    "0054111111450000",
    "0041115511140000",
    "0041111111140000",
    "0051111111150000",
    "0004111111400000",
    "0000411114000000",
    "0000420024000000",
    "0000550005500000",
]

# ============================================================
# ENEMIES — Distinct mechanical/drone designs
# ============================================================

# Drone Sweeper — Small hovering drone with scanner eye
drone_sweeper = [
    "0000000000000000",
    "0000044444000000",
    "0004411111400000",
    "0041166611140000",
    "0041166611140000",
    "0041166611140000",
    "0004411111400000",
    "0000444444000000",
    "0000414414000000",
    "0044444444440000",
    "0411111111114000",
    "0044444444440000",
    "0000414414000000",
    "0000044444000000",
    "0000055550000000",
    "0000000000000000",
]

# Boss Sweeper Captain — Larger menacing drone
boss_drone = [
    "0044444444444400",
    "0411666666611400",
    "4116666666661140",
    "4116611661166114",
    "4116666666661140",
    "0411111111111400",
    "0044444444444000",
    "0004441144440000",
    "0044111111144000",
    "4411111111111440",
    "4111111111111140",
    "4411111111111440",
    "0044111111144000",
    "0004411114440000",
    "0000055555000000",
    "0000000000000000",
]

# NPC — Generic citizen, gray tones
npc_citizen = [
    "0000044444000000",
    "0000411114000000",
    "0004133314000000",
    "0004133314000000",
    "0004130031400000",
    "0004133314000000",
    "0000433334000000",
    "0000441144000000",
    "0004411114400000",
    "0044111111440000",
    "0041111111140000",
    "0041111111140000",
    "0004111111400000",
    "0000422240000000",
    "0000420024000000",
    "0000440004400000",
]

# ============================================================
# ENVIRONMENT TILES
# ============================================================

# Metal floor tile — cyberpunk grid pattern
floor_metal = [
    "2222222222222222",
    "2111211111112112",
    "2111211111112112",
    "2111211111112112",
    "2111211111112112",
    "2222222222222222",
    "2111111211111112",
    "2111111211111112",
    "2111111211111112",
    "2111111211111112",
    "2222222222222222",
    "2111211111112112",
    "2111211111112112",
    "2111211111112112",
    "2111211111112112",
    "2222222222222222",
]

# Wall tile — industrial panel
wall_panel = [
    "4444444444444444",
    "4111111411111114",
    "4111511411111114",
    "4111111411111114",
    "4111111411151114",
    "4444444444444444",
    "4111111411111114",
    "4111111411111114",
    "4111111411111114",
    "4111111411111514",
    "4444444444444444",
    "4115111411111114",
    "4111111411111114",
    "4111111411111114",
    "4111111411151114",
    "4444444444444444",
]

# Neon accent wall — glowing strip
wall_neon = [
    "4444444444444444",
    "4111111111111114",
    "4111111111111114",
    "4666666666666664",
    "4555555555555554",
    "4666666666666664",
    "4111111111111114",
    "4111111111111114",
    "4111111111111114",
    "4111111111111114",
    "4666666666666664",
    "4555555555555554",
    "4666666666666664",
    "4111111111111114",
    "4111111111111114",
    "4444444444444444",
]

# Grate/vent floor
floor_grate = [
    "4141414141414141",
    "1414141414141414",
    "4141414141414141",
    "1212121212121212",
    "4141414141414141",
    "1414141414141414",
    "4141414141414141",
    "1212121212121212",
    "4141414141414141",
    "1414141414141414",
    "4141414141414141",
    "1212121212121212",
    "4141414141414141",
    "1414141414141414",
    "4141414141414141",
    "1212121212121212",
]

# Crate / interactable object
crate = [
    "4444444444444444",
    "4222222222222224",
    "4211111111111124",
    "4211111111111124",
    "4211114441111124",
    "4211144444111124",
    "4211444144411124",
    "4211444144411124",
    "4211444144411124",
    "4211444144411124",
    "4211144444111124",
    "4211114441111124",
    "4211111111111124",
    "4211111111111124",
    "4222222222222224",
    "4444444444444444",
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
    
    # Color palettes for each character/element
    # {1: primary, 2: secondary, 3: skin, 4: outline, 5: highlight, 6: accent}
    
    elias_colors = {
        1: (41, 60, 120),    # Dark blue coat
        2: (30, 40, 70),     # Darker blue pants
        3: (230, 190, 155),  # Skin
        4: (15, 15, 25),     # Near-black outline
        5: (70, 120, 200),   # Blue highlight
        6: (100, 180, 255),  # Bright blue accent
    }
    
    vesper_colors = {
        1: (100, 40, 140),   # Purple robes
        2: (60, 25, 90),     # Dark purple
        3: (225, 185, 155),  # Skin
        4: (15, 10, 25),     # Dark outline
        5: (150, 80, 200),   # Purple highlight
        6: (180, 120, 230),  # Light purple accent
    }
    
    lyra_colors = {
        1: (220, 180, 50),   # Gold body
        2: (180, 140, 30),   # Darker gold
        3: (255, 255, 230),  # White/ethereal skin
        4: (80, 60, 15),     # Dark gold outline
        5: (255, 240, 150),  # Bright gold highlight
        6: (255, 200, 80),   # Gold accent
    }
    
    drone_colors = {
        1: (140, 30, 30),    # Dark red body
        2: (80, 20, 20),     # Darker red
        3: (200, 60, 60),    # Red detail
        4: (30, 10, 10),     # Near-black outline
        5: (220, 100, 100),  # Red highlight
        6: (255, 60, 60),    # Bright red scanner eye
    }
    
    boss_colors = {
        1: (160, 40, 40),    # Red body
        2: (100, 25, 25),    # Dark red
        3: (200, 70, 70),    # Detail
        4: (25, 8, 8),       # Outline
        5: (230, 110, 110),  # Highlight
        6: (255, 40, 40),    # Scanner glow
    }
    
    npc_colors = {
        1: (90, 90, 100),    # Gray clothes
        2: (60, 60, 70),     # Darker gray
        3: (215, 180, 150),  # Skin
        4: (20, 20, 25),     # Outline
        5: (120, 120, 140),  # Highlight
        6: (100, 200, 180),  # Teal accent
    }
    
    wall_colors = {
        1: (55, 55, 65),     # Medium gray panels
        2: (45, 45, 55),     # Slightly different gray
        4: (25, 25, 35),     # Dark outlines/seams
        5: (80, 85, 95),     # Highlight spots
    }
    
    floor_colors = {
        1: (40, 40, 50),     # Dark floor
        2: (48, 48, 58),     # Slightly lighter grid
        4: (25, 25, 35),     # Grid lines
    }
    
    neon_wall_colors = {
        1: (50, 50, 60),     # Wall body
        4: (25, 25, 35),     # Outline
        5: (100, 255, 200),  # Bright neon glow
        6: (60, 200, 150),   # Neon base
    }
    
    grate_colors = {
        1: (50, 50, 55),     # Grate bars
        2: (15, 15, 20),     # Gaps (deep dark)
        4: (35, 35, 40),     # Bar edges
    }
    
    crate_colors = {
        1: (100, 80, 50),    # Wood/metal body
        2: (70, 55, 35),     # Darker trim
        4: (30, 20, 10),     # Outline
    }
    
    # ROW 0 (y=0): Characters and enemies
    # Sprite 0: Window icon placeholder
    draw.rectangle([0, 0, 15, 15], fill=(180, 40, 40))
    draw.rectangle([3, 3, 12, 12], fill=(40, 40, 60))
    draw.rectangle([5, 5, 10, 10], fill=(255, 60, 60))
    
    # Sprite 1: Elias idle (index 1)
    draw_pattern(draw, 16 * 1, 0, elias_idle, elias_colors)
    # Sprite 2: Elias walk frame (index 2)  
    draw_pattern(draw, 16 * 2, 0, elias_walk1, elias_colors)
    # Sprite 3: Vesper idle (index 3)
    draw_pattern(draw, 16 * 3, 0, vesper_idle, vesper_colors)
    # Sprite 4: Lyra idle (index 4)
    draw_pattern(draw, 16 * 4, 0, lyra_idle, lyra_colors)
    # Sprite 5: Drone Sweeper (index 5)
    draw_pattern(draw, 16 * 5, 0, drone_sweeper, drone_colors)
    # Sprite 6: Boss Drone (index 6)
    draw_pattern(draw, 16 * 6, 0, boss_drone, boss_colors)
    # Sprite 7: NPC Citizen (index 7)
    draw_pattern(draw, 16 * 7, 0, npc_citizen, npc_colors)
    
    # ROW 1 (y=16): Environment tiles
    # Sprite 16: Metal floor (index 16)
    draw_pattern(draw, 0, 16, floor_metal, floor_colors)
    # Sprite 17: Wall panel (index 17)
    draw_pattern(draw, 16 * 1, 16, wall_panel, wall_colors)
    # Sprite 18: Neon wall (index 18)
    draw_pattern(draw, 16 * 2, 16, wall_neon, neon_wall_colors)
    # Sprite 19: Floor grate (index 19)
    draw_pattern(draw, 16 * 3, 16, floor_grate, grate_colors)
    # Sprite 20: Crate (index 20)
    draw_pattern(draw, 16 * 4, 16, crate, crate_colors)
    
    # ROW 2 (y=32): Additional walk frames and effects
    # Sprite 32: Elias facing right (flipped via engine spr_ex)
    draw_pattern(draw, 0, 32, elias_idle, elias_colors)
    # Sprite 33: Vesper walk
    draw_pattern(draw, 16 * 1, 32, vesper_idle, vesper_colors)
    # Sprite 34: Lyra walk  
    draw_pattern(draw, 16 * 2, 32, lyra_idle, lyra_colors)
    
    # Sprite 35: Drone Nullifier (recolor of sweeper with blue eye)
    nullifier_colors = dict(drone_colors)
    nullifier_colors[6] = (60, 60, 255)  # Blue scanner eye
    nullifier_colors[1] = (40, 40, 130)  # Blue body
    nullifier_colors[3] = (60, 60, 180)
    draw_pattern(draw, 16 * 3, 32, drone_sweeper, nullifier_colors)
    
    img.save(filepath)
    print(f"  Spritesheet saved: {filepath}")

def generate_wav(filepath, freq=440.0, duration=0.2, vol=0.5):
    sample_rate = 44100
    num_samples = int(duration * sample_rate)
    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    with wave.open(filepath, 'w') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(sample_rate)
        for i in range(num_samples):
            env = 1.0 - (i / num_samples)
            value = int(vol * env * 32767.0 * math.sin(2.0 * math.pi * freq * (i / sample_rate)))
            data = struct.pack('<h', value)
            w.writeframesraw(data)

def generate_glitch_wav(filepath, duration=0.25, vol=0.5):
    sample_rate = 44100
    num_samples = int(duration * sample_rate)
    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    with wave.open(filepath, 'w') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(sample_rate)
        for i in range(num_samples):
            t = i / sample_rate
            freq = 120.0 + (math.sin(t * 150.0) * 300.0) + ((i % 17) * 40.0)
            env = 1.0 - (i / num_samples)
            value = int(vol * env * 32767.0 * math.sin(2.0 * math.pi * freq * t))
            data = struct.pack('<h', value)
            w.writeframesraw(data)

def generate_battle_music(filepath):
    """Generate a more interesting battle loop with bass + melody."""
    sample_rate = 44100
    duration = 4.0  # 4-second loop
    num_samples = int(duration * sample_rate)
    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    
    # Simple bass + melody pattern
    bass_notes = [110, 110, 130.81, 110, 146.83, 146.83, 130.81, 110]  # A2, A2, C3, A2, D3, D3, C3, A2
    melody_notes = [440, 523.25, 659.25, 523.25, 587.33, 659.25, 523.25, 440]  # A4, C5, E5...
    beat_len = duration / len(bass_notes)
    
    with wave.open(filepath, 'w') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(sample_rate)
        for i in range(num_samples):
            t = i / sample_rate
            beat = int(t / beat_len) % len(bass_notes)
            beat_t = (t % beat_len) / beat_len
            
            # Bass (square wave, volume envelope)
            bass_freq = bass_notes[beat]
            bass_env = max(0, 1.0 - beat_t * 1.5) * 0.3
            bass = bass_env * (1.0 if math.sin(2 * math.pi * bass_freq * t) > 0 else -1.0)
            
            # Melody (triangle wave, lighter)
            mel_freq = melody_notes[beat]
            mel_env = max(0, 1.0 - beat_t * 2.0) * 0.15
            mel_phase = (mel_freq * t) % 1.0
            mel = mel_env * (4.0 * abs(mel_phase - 0.5) - 1.0)
            
            # Hi-hat (noise on every other beat)
            hat_env = max(0, 1.0 - beat_t * 8.0) * 0.08
            hat = hat_env * (((i * 1103515245 + 12345) % 32768) / 16384.0 - 1.0) if beat % 2 == 0 else 0
            
            value = int((bass + mel + hat) * 32767)
            value = max(-32768, min(32767, value))
            w.writeframesraw(struct.pack('<h', value))

def generate_exploration_music(filepath):
    """Generate ambient exploration music."""
    sample_rate = 44100
    duration = 8.0  # 8-second loop
    num_samples = int(duration * sample_rate)
    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    
    # Ambient pad with slow chord changes
    chord_notes = [
        [220, 277.18, 329.63],  # Am
        [196, 246.94, 293.66],  # Gm  
        [174.61, 220, 261.63],  # F
        [196, 246.94, 293.66],  # Gm
    ]
    chord_len = duration / len(chord_notes)
    
    with wave.open(filepath, 'w') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(sample_rate)
        for i in range(num_samples):
            t = i / sample_rate
            chord_idx = int(t / chord_len) % len(chord_notes)
            notes = chord_notes[chord_idx]
            
            # Soft pad (sine waves with slow vibrato)
            val = 0
            for note in notes:
                vibrato = math.sin(t * 4) * 1.5
                val += math.sin(2 * math.pi * (note + vibrato) * t) * 0.12
            
            # Subtle pulse
            pulse = math.sin(t * 0.5) * 0.05 + 0.95
            val *= pulse
            
            value = int(val * 32767)
            value = max(-32768, min(32767, value))
            w.writeframesraw(struct.pack('<h', value))

if __name__ == '__main__':
    print("Generating Primordium City assets...")
    
    # Sprites
    generate_spritesheet('sprites.png')
    
    # SFX
    generate_wav('sfx/hit.wav', freq=150.0, duration=0.1)
    generate_wav('sfx/jump.wav', freq=600.0, duration=0.15)
    generate_wav('sfx/select.wav', freq=800.0, duration=0.05)
    generate_glitch_wav('sfx/glitch.wav', duration=0.25)
    
    # Music
    generate_exploration_music('music/theme.wav')
    generate_battle_music('music/battle.wav')
    
    print("All assets generated successfully!")
