import json
import os

def generate_map():
    width = 40
    height = 30
    
    ground_data = []
    collision_data = []
    
    # 17 = Wall, 18 = Floor (assuming these tiles exist)
    for y in range(height):
        for x in range(width):
            ground_data.append(17)
            collision_data.append(1) # solid
            
    def carve_rect(rx, ry, rw, rh):
        for y in range(ry, ry + rh):
            for x in range(rx, rx + rw):
                if 0 <= x < width and 0 <= y < height:
                    idx = y * width + x
                    ground_data[idx] = 18
                    collision_data[idx] = 0
                    
    # Carve main area for Sector 7 Glitch Zone
    carve_rect(5, 5, 30, 20)
    
    # Some obstacles in the middle
    carve_rect(15, 10, 5, 5)
    for y in range(10, 15):
        for x in range(15, 20):
            idx = y * width + x
            ground_data[idx] = 17
            collision_data[idx] = 1

    objects = [
        {
            "id": 1,
            "name": "vesper",
            "type": "npc",
            "x": 20 * 16,
            "y": 8 * 16,
            "width": 16,
            "height": 16,
            "properties": {
                "sprite_id": 3,
                "dialogue_id": "arc1:ch2_silence_hour_1"
            }
        },
        {
            "id": 2,
            "name": "intro_trigger",
            "type": "trigger",
            "x": 10 * 16,
            "y": 10 * 16,
            "width": 32,
            "height": 32,
            "properties": {
                "dialogue_id": "arc1:ch1_intro_1",
                "run_once": True,
                "quest_step": 1
            }
        },
        {
            "id": 3,
            "name": "ozone_trigger",
            "type": "trigger",
            "x": 25 * 16,
            "y": 20 * 16,
            "width": 48,
            "height": 48,
            "properties": {
                "dialogue_id": "arc1:ch5_foreign_ozone_1",
                "run_once": True,
                "quest_step": 5
            }
        },
        {
            "id": 4,
            "name": "substation_transition",
            "type": "trigger",
            "x": 30 * 16,
            "y": 15 * 16,
            "width": 32,
            "height": 32,
            "properties": {
                "dialogue_id": "arc1:ch5_transition"
            }
        }
    ]
    
    map_json = {
        "width": width,
        "height": height,
        "tilewidth": 16,
        "tileheight": 16,
        "layers": [
            {
                "name": "ground",
                "type": "tilelayer",
                "data": ground_data,
                "width": width,
                "height": height
            },
            {
                "name": "collisions",
                "type": "tilelayer",
                "data": collision_data,
                "width": width,
                "height": height
            },
            {
                "name": "objects",
                "type": "objectgroup",
                "objects": objects
            }
        ]
    }
    
    output_path = os.path.join(os.path.dirname(__file__), "data", "maps", "sector_7_slums.json")
    with open(output_path, "w") as f:
        json.dump(map_json, f, indent=4)
        
    print(f"Generated {output_path}")

if __name__ == '__main__':
    generate_map()
