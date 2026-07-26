import json
import os
import random

def generate_map():
    width = 50
    height = 50
    
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

    # Start room
    carve_rect(20, 40, 10, 8)
    # Hallway
    carve_rect(24, 30, 2, 10)
    # Middle Room
    carve_rect(15, 20, 20, 10)
    # Boss Hallway
    carve_rect(24, 10, 2, 10)
    # Boss Room
    carve_rect(15, 2, 20, 8)

    objects = [
        {
            "id": 1,
            "name": "sector7_transition",
            "type": "trigger",
            "x": 24 * 16,
            "y": 45 * 16,
            "width": 32,
            "height": 32,
            "properties": {
                "dialogue_id": "arc1:substation_exit"
            }
        },
        {
            "id": 2,
            "name": "boss_trigger",
            "type": "trigger",
            "x": 20 * 16,
            "y": 5 * 16,
            "width": 160,
            "height": 16,
            "properties": {
                "dialogue_id": "arc1:ch5_foreign_ozone_1",
                "run_once": True,
                "quest_step": 5
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
    
    output_path = os.path.join(os.path.dirname(__file__), "data", "maps", "substation_07.json")
    with open(output_path, "w") as f:
        json.dump(map_json, f, indent=4)
        
    print(f"Generated {output_path}")

if __name__ == '__main__':
    generate_map()
