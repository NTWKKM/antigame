import json
import os

def generate_map():
    width = 40
    height = 30
    
    ground_data = []
    collision_data = []
    
    # Fill with walls (17) initially
    for y in range(height):
        for x in range(width):
            ground_data.append(17)
            collision_data.append(1) # 1 = solid
            
    # Carve out a path (floor = 18, collision = 0)
    def carve_rect(rx, ry, rw, rh):
        for y in range(ry, ry + rh):
            for x in range(rx, rx + rw):
                if 0 <= x < width and 0 <= y < height:
                    idx = y * width + x
                    ground_data[idx] = 18
                    collision_data[idx] = 0
                    
    # Main street
    carve_rect(5, 12, 30, 6)
    # Side alleys
    carve_rect(10, 5, 4, 20)
    carve_rect(25, 5, 4, 20)
    
    # Define objects (NPCs and Triggers)
    objects = [
        {
            "id": 1,
            "name": "vesper",
            "type": "npc",
            "x": 26 * 16,
            "y": 6 * 16,
            "width": 16,
            "height": 16,
            "properties": {
                "sprite_id": 3,
                "dialogue_id": "vesper_dialogue:vesper_meet_1"
            }
        },
        {
            "id": 2,
            "name": "intro_trigger",
            "type": "trigger",
            "x": 6 * 16,
            "y": 14 * 16,
            "width": 32,
            "height": 32,
            "properties": {
                "dialogue_id": "arc1_intro:intro_scene_1",
                "run_once": True
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
    
    output_path = os.path.join(os.path.dirname(__file__), "data", "maps", "sector_4_streets.json")
    with open(output_path, "w") as f:
        json.dump(map_json, f, indent=4)
        
    print(f"Generated {output_path}")

if __name__ == '__main__':
    generate_map()
