import sys
sys.path.insert(0, "/home/ser9/.local/share/muse/skills/bundled/built-in--exact-minimal-literal-tests~v1/skills/blender/scripts")
import bpy_helpers as H
import bpy
from mathutils import Vector

FINAL = "--final" in sys.argv
GLB = "/home/ser9/Projects/kritikart/assets/cars/customizable_hypercar_model3.glb"
OUT = "/home/ser9/Projects/kritikart/assets/ui/key_art_player_car.png" if FINAL else "/tmp/kk_blender/preview.png"

H.reset_scene()

# --- import the game's actual car ---
bpy.ops.import_scene.gltf(filepath=GLB)
car_objs = [o for o in bpy.context.scene.objects if o.type in ("MESH", "EMPTY")]
meshes = [o for o in car_objs if o.type == "MESH"]
H.report()

# place car on ground (z=0 at lowest point)
mins, maxs = H.bbox(meshes)
for o in car_objs:
    o.location.z -= mins[2]
mins, maxs = H.bbox(meshes)
center = ((mins[0] + maxs[0]) / 2, (mins[1] + maxs[1]) / 2, 0)
print("CAR size:", tuple(round(maxs[i] - mins[i], 2) for i in range(3)))

# --- keep the game's textured material, add a clearcoat layer for premium gloss ---
for o in meshes:
    for m in o.data.materials:
        if m and m.use_nodes:
            for node in m.node_tree.nodes:
                if node.type == "BSDF_PRINCIPLED":
                    node.inputs["Coat Weight"].default_value = 1.0
                    node.inputs["Coat Roughness"].default_value = 0.12

# --- ground: dark wet asphalt disc ---
ground = H.add_cylinder("Ground", radius=120, depth=0.1, location=(center[0], center[1], -0.05),
                        mat=H.material_preset("WetAsphalt", "concrete", "#14181C", scale=6))
gmat = ground.data.materials[0]
H.add_noise_variation(gmat, scale=14, amount=0.25, roughness_amount=0.2)
for node in gmat.node_tree.nodes:
    if node.type == "BSDF_PRINCIPLED":
        node.inputs["Roughness"].default_value = 0.32

# distant coastal hills (dark silhouettes)
hill_mat = H.material("Hills", "#232B33", roughness=0.95, metallic=0.0)
for i, (hx, hy, hs) in enumerate([(-18, 26, 16), (4, 34, 22), (24, 28, 14)]):
    h = H.add_sphere(f"Hill{i}", radius=1, location=(hx, hy, -4), scale=(hs, hs * 0.7, hs * 0.38), mat=hill_mat)

# --- lighting: golden-hour sun + cool sky fill ---
H.sun_and_sky(elevation=9, azimuth=140)
key = H.add_light("AREA", "KeyLight", location=(center[0] - 6, center[1] - 7, 6),
                  target=(center[0], center[1], 0.6), energy=900, size=6)
rim = H.add_light("AREA", "RimLight", location=(center[0] + 7, center[1] + 6, 3.5),
                  target=(center[0], center[1], 0.6), energy=700, size=4)

# --- camera: front three-quarter hero shot (car front faces -X) ---
cam = H.add_camera("HeroCam", location=(center[0], center[1], 1.2), target=(center[0], center[1], 0.5), lens=55)
H.frame_objects(cam, meshes, azimuth=-125, elevation=8, margin=1.05)

H.world_color("#1C2836", strength=0.7)
H.set_render(engine="CYCLES", resolution=(1920, 1080) if FINAL else (960, 540),
             samples=96 if FINAL else 24, view_transform="AgX")
H.render_still(OUT)
if FINAL:
    H.save_blend("/home/ser9/Projects/kritikart/assets/ui/key_art_player_car.blend")
print("RENDERED:", OUT)
