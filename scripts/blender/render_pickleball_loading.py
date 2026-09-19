import bpy
import math
import os

# 1. RESET FACTORY SCENE
bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene

scene.render.fps = 30
scene.frame_start = 1
scene.frame_end = 90 # 3.0 seconds

scene.render.resolution_x = 512
scene.render.resolution_y = 512
scene.render.resolution_percentage = 100

# Transparent World background (Render with Alpha!)
scene.render.film_transparent = True

# 2. ISOMETRIC CAMERA
cam_data = bpy.data.cameras.new("IsoCam")
cam_data.type = 'ORTHO'
cam_data.ortho_scale = 3.8

cam_obj = bpy.data.objects.new("IsoCam", cam_data)
scene.collection.objects.link(cam_obj)
scene.camera = cam_obj

cam_obj.location = (6.0, -6.0, 5.0)
cam_obj.rotation_euler = (math.radians(54.736), 0.0, math.radians(45.0))

# 3. STUDIO LIGHTING
sun_data = bpy.data.lights.new("MainSun", type='SUN')
sun_data.energy = 3.5
sun_data.color = (1.0, 1.0, 1.0)
sun_obj = bpy.data.objects.new("MainSun", sun_data)
scene.collection.objects.link(sun_obj)
sun_obj.location = (5.0, -3.0, 7.0)
sun_obj.rotation_euler = (math.radians(45), math.radians(10), math.radians(35))

fill_data = bpy.data.lights.new("FillLight", type='POINT')
fill_data.energy = 40.0
fill_data.color = (0.85, 0.92, 1.0)
fill_obj = bpy.data.objects.new("FillLight", fill_data)
scene.collection.objects.link(fill_obj)
fill_obj.location = (-4.0, 4.0, 4.0)

# 4. MATERIALS EXACT HEX
def create_mat(name, rgba, roughness=0.2):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs['Base Color'].default_value = rgba
        bsdf.inputs['Roughness'].default_value = roughness
    return mat

# Web Brand: #1D8EF8
mat_court_blue = create_mat("SportOBlue", (0.012, 0.275, 0.941, 1.0), roughness=0.18)
# Deep Navy Base: #1E293B
mat_navy_base = create_mat("NavyBase", (0.02, 0.04, 0.08, 1.0), roughness=0.3)
# Crisp White Lines & Rim: #FFFFFF
mat_white = create_mat("WhiteMat", (1.0, 1.0, 1.0, 1.0), roughness=0.08)
# Ball Yellow: #FFEA00
mat_ball = create_mat("YellowBall", (1.0, 0.81, 0.0, 1.0), roughness=0.25)
# Net
mat_net = create_mat("DarkNet", (0.08, 0.08, 0.08, 1.0), roughness=0.5)

# 5. BASE PEDESTAL (Navy bottom block)
bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, -0.15))
base_cube = bpy.context.active_object
base_cube.name = "CourtBase"
base_cube.data.materials.append(mat_navy_base)

bev_base = base_cube.modifiers.new(name="Bevel", type='BEVEL')
bev_base.width = 0.08
bev_base.segments = 4

base_cube.scale = (2.8, 1.6, 0.25)
base_cube.keyframe_insert(data_path="scale", frame=1)
base_cube.keyframe_insert(data_path="scale", frame=35)
base_cube.scale = (1.6, 1.6, 0.25) # Shrink to Square
base_cube.keyframe_insert(data_path="scale", frame=65)
base_cube.keyframe_insert(data_path="scale", frame=90)

# 6. COURT BLUE SURFACE (Upper plane)
bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 0.01))
court_surface = bpy.context.active_object
court_surface.name = "CourtSurface"
court_surface.data.materials.append(mat_court_blue)

bev_surf = court_surface.modifiers.new(name="Bevel", type='BEVEL')
bev_surf.width = 0.05
bev_surf.segments = 4

court_surface.scale = (2.65, 1.45, 0.08)
court_surface.keyframe_insert(data_path="scale", frame=1)
court_surface.keyframe_insert(data_path="scale", frame=35)
court_surface.scale = (1.45, 1.45, 0.08)
court_surface.keyframe_insert(data_path="scale", frame=65)
court_surface.keyframe_insert(data_path="scale", frame=90)

# 7. WHITE BORDER LINE & CROSS LINE
# Outer border frame
bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 0.055))
border_line = bpy.context.active_object
border_line.name = "WhiteBorder"
border_line.data.materials.append(mat_white)
border_line.scale = (2.45, 1.25, 0.005)
border_line.keyframe_insert(data_path="scale", frame=1)
border_line.keyframe_insert(data_path="scale", frame=35)
border_line.scale = (1.25, 1.25, 0.005)
border_line.keyframe_insert(data_path="scale", frame=65)
border_line.keyframe_insert(data_path="scale", frame=90)

# We want the blue inner surface visible, so we slice or add inner blue tile
bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 0.06))
inner_blue = bpy.context.active_object
inner_blue.name = "InnerBlue"
inner_blue.data.materials.append(mat_court_blue)
inner_blue.scale = (2.35, 1.15, 0.006)
inner_blue.keyframe_insert(data_path="scale", frame=1)
inner_blue.keyframe_insert(data_path="scale", frame=35)
inner_blue.scale = (1.15, 1.15, 0.006)
inner_blue.keyframe_insert(data_path="scale", frame=65)
inner_blue.keyframe_insert(data_path="scale", frame=90)

# Center dividing line (Image 2 cross lines)
bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 0.065))
cross1 = bpy.context.active_object
cross1.name = "Cross1"
cross1.data.materials.append(mat_white)
cross1.scale = (0.04, 1.15, 0.007)
cross1.keyframe_insert(data_path="scale", frame=1)
cross1.keyframe_insert(data_path="scale", frame=35)
cross1.scale = (0.04, 1.15, 0.007)
cross1.keyframe_insert(data_path="scale", frame=65)
cross1.keyframe_insert(data_path="scale", frame=90)

bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 0.065))
cross2 = bpy.context.active_object
cross2.name = "Cross2"
cross2.data.materials.append(mat_white)
cross2.scale = (1.15, 0.04, 0.007)

# 8. NET (Fades out when morphing to Image 2)
bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 0.18))
net = bpy.context.active_object
net.name = "Net"
net.data.materials.append(mat_net)
net.scale = (0.02, 1.45, 0.22)
net.keyframe_insert(data_path="scale", frame=1)
net.keyframe_insert(data_path="scale", frame=35)
net.scale = (0.001, 0.001, 0.001) # Shrink into zero
net.keyframe_insert(data_path="scale", frame=55)
net.keyframe_insert(data_path="scale", frame=90)

# 9. PICKLEBALL YELLOW BALL (With black holes)
bpy.ops.mesh.primitive_uv_sphere_add(radius=0.18, location=(-0.95, -0.4, 0.15))
ball = bpy.context.active_object
ball.name = "Pickleball"
ball.data.materials.append(mat_ball)
bpy.ops.object.shade_smooth()

# Flight Arc Keyframes:
# Frame 1-12: Upper Left (Image 1 starting point)
ball.location = (-0.95, -0.35, 0.15)
ball.keyframe_insert(data_path="location", frame=1)
ball.keyframe_insert(data_path="location", frame=12)

# Frame 32: Peak of arc (flying through air)
ball.location = (-0.45, -0.15, 0.85)
ball.keyframe_insert(data_path="location", frame=32)

# Frame 50: Landing in center of court
ball.location = (0.08, 0.04, 0.16)
ball.keyframe_insert(data_path="location", frame=50)

# Frame 68-90: Rest in exact center of Image 2 icon
ball.location = (0.0, 0.0, 0.16)
ball.keyframe_insert(data_path="location", frame=68)
ball.keyframe_insert(data_path="location", frame=90)

# 10. CURVED WHITE SWOOSH TRAIL (Curved 3D Ribbon like Image 2)
curve_data = bpy.data.curves.new('SwooshCurve', type='CURVE')
curve_data.dimensions = '3D'
curve_data.bevel_depth = 0.05
curve_data.bevel_resolution = 6

spline = curve_data.splines.new('BEZIER')
spline.bezier_points.add(2)

# Point 0: Origin behind ball
p0 = spline.bezier_points[0]
p0.co = (-0.85, -0.32, 0.12)
p0.handle_left = (-1.0, -0.38, 0.12)
p0.handle_right = (-0.6, -0.22, 0.45)

# Point 1: Crest of arc
p1 = spline.bezier_points[1]
p1.co = (-0.4, -0.15, 0.55)
p1.handle_left = (-0.6, -0.25, 0.55)
p1.handle_right = (-0.15, -0.05, 0.45)

# Point 2: Landing into ball (Image 2 swoosh)
p2 = spline.bezier_points[2]
p2.co = (0.0, 0.0, 0.15)
p2.handle_left = (-0.15, -0.05, 0.25)
p2.handle_right = (0.05, 0.05, 0.15)

swoosh_obj = bpy.data.objects.new('Swoosh', curve_data)
scene.collection.objects.link(swoosh_obj)
swoosh_obj.data.materials.append(mat_white)

# Animate swoosh growing along the arc
curve_data.bevel_factor_end = 0.0
curve_data.keyframe_insert(data_path="bevel_factor_end", frame=12)
curve_data.bevel_factor_end = 1.0
curve_data.keyframe_insert(data_path="bevel_factor_end", frame=50)

# 11. SHADOW (Soft dark oval beneath the ball in Image 2)
bpy.ops.mesh.primitive_plane_add(size=1.0, location=(0.04, -0.03, 0.068))
shadow = bpy.context.active_object
shadow.name = "BallShadow"
mat_shadow = create_mat("ShadowMat", (0.01, 0.03, 0.08, 0.5), roughness=0.6)
shadow.data.materials.append(mat_shadow)
shadow.scale = (0.16, 0.10, 1.0)

# 12. SAVE BLENDER FILE & RENDER FRAMES
blend_path = os.path.abspath(r"D:\Duancanhan\Project_QuanLyGiaiDau\HethongFrontEndApp_QLgiaidau\scripts\blender\pickleball_scene.blend")
bpy.ops.wm.save_as_mainfile(filepath=blend_path)
print(f"==> Saved Blender Project: {blend_path}")

output_pattern = os.path.abspath(r"D:\Duancanhan\Project_QuanLyGiaiDau\HethongFrontEndApp_QLgiaidau\assets\videos\render_frame_#####.png")
scene.render.filepath = output_pattern
scene.render.image_settings.file_format = 'PNG'
scene.render.image_settings.color_mode = 'RGBA' # Render Transparent PNGs!

print("==> V3 Script Ready for High Quality Render!")
