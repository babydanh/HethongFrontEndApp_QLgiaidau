import bpy
import math
import os

# 1. RESET SCENE
bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene

scene.render.fps = 30
scene.frame_start = 1
scene.frame_end = 90 # 3.0 seconds

scene.render.resolution_x = 512
scene.render.resolution_y = 512
scene.render.resolution_percentage = 100

# Color Management: Standard sRGB
scene.display_settings.display_device = 'sRGB'
scene.view_settings.view_transform = 'Standard'

# Pure solid white background
world = bpy.data.worlds.new("World")
scene.world = world
world.use_nodes = True
bg_node = world.node_tree.nodes.get("Background")
if bg_node:
    bg_node.inputs[0].default_value = (1.0, 1.0, 1.0, 1.0)
    bg_node.inputs[1].default_value = 1.0

# 2. ISOMETRIC CAMERA (Looking down at 45 deg, centered)
cam_data = bpy.data.cameras.new("IsoCam")
cam_data.type = 'ORTHO'
cam_data.ortho_scale = 4.2

cam_obj = bpy.data.objects.new("IsoCam", cam_data)
scene.collection.objects.link(cam_obj)
scene.camera = cam_obj

cam_obj.location = (6.0, -6.0, 5.0)
cam_obj.rotation_euler = (math.radians(54.736), 0.0, math.radians(45.0))

# 3. LIGHTING (Bright Sporty Sunlight + Ambient)
sun_data = bpy.data.lights.new("Sun", type='SUN')
sun_data.energy = 3.0
sun_data.color = (1.0, 1.0, 1.0)
sun_obj = bpy.data.objects.new("Sun", sun_data)
scene.collection.objects.link(sun_obj)
sun_obj.location = (5.0, -2.0, 8.0)
sun_obj.rotation_euler = (math.radians(45), math.radians(15), math.radians(35))

# 4. MATERIALS EXACT HEX
def create_mat(name, rgba, roughness=0.18):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if bsdf:
        bsdf.inputs['Base Color'].default_value = rgba
        bsdf.inputs['Roughness'].default_value = roughness
    return mat

# Web Brand: #1D8EF8 -> sRGB linear approx (0.012, 0.275, 0.941, 1.0)
mat_blue_surface = create_mat("SportOBlue", (0.012, 0.275, 0.941, 1.0), roughness=0.15)
# Deep Navy Rim: #0F172A
mat_navy_rim = create_mat("NavyRim", (0.005, 0.012, 0.035, 1.0), roughness=0.25)
# Crisp White Lines & Rim: #FFFFFF
mat_pure_white = create_mat("WhiteCourt", (1.0, 1.0, 1.0, 1.0), roughness=0.08)
# Ball Yellow: #FFEA00 -> (1.0, 0.81, 0.0, 1.0)
mat_pickleball = create_mat("NeonYellow", (1.0, 0.81, 0.0, 1.0), roughness=0.22)
# White Swoosh Arc
mat_swoosh = create_mat("WhiteSwoosh", (1.0, 1.0, 1.0, 1.0), roughness=0.05)
# Net Material (Dark grey)
mat_net = create_mat("NetDark", (0.05, 0.05, 0.05, 1.0), roughness=0.4)

# 5. BASE PEDESTAL (Navy bottom block)
bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, -0.16))
base_cube = bpy.context.active_object
base_cube.name = "CourtBase"
base_cube.data.materials.append(mat_navy_rim)

bev_base = base_cube.modifiers.new(name="Bevel", type='BEVEL')
bev_base.width = 0.06
bev_base.segments = 4

base_cube.scale = (2.9, 1.65, 0.25)
base_cube.keyframe_insert(data_path="scale", frame=1)
base_cube.keyframe_insert(data_path="scale", frame=35)
base_cube.scale = (1.65, 1.65, 0.25)
base_cube.keyframe_insert(data_path="scale", frame=65)
base_cube.keyframe_insert(data_path="scale", frame=90)

# 6. COURT BLUE SURFACE
bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 0.01))
court_surface = bpy.context.active_object
court_surface.name = "CourtSurface"
court_surface.data.materials.append(mat_blue_surface)

bev_surf = court_surface.modifiers.new(name="Bevel", type='BEVEL')
bev_surf.width = 0.04
bev_surf.segments = 3

court_surface.scale = (2.75, 1.5, 0.08)
court_surface.keyframe_insert(data_path="scale", frame=1)
court_surface.keyframe_insert(data_path="scale", frame=35)
court_surface.scale = (1.5, 1.5, 0.08)
court_surface.keyframe_insert(data_path="scale", frame=65)
court_surface.keyframe_insert(data_path="scale", frame=90)

# 7. WHITE COURT LINES
# White outer border frame
bpy.ops.mesh.primitive_plane_add(size=1.0, location=(0, 0, 0.055))
border_line = bpy.context.active_object
border_line.name = "CourtBorder"
border_line.data.materials.append(mat_pure_white)

border_line.scale = (2.55, 1.35, 1.0)
border_line.keyframe_insert(data_path="scale", frame=1)
border_line.keyframe_insert(data_path="scale", frame=35)
border_line.scale = (1.35, 1.35, 1.0)
border_line.keyframe_insert(data_path="scale", frame=65)
border_line.keyframe_insert(data_path="scale", frame=90)

# Center divider line
bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 0.06))
center_line = bpy.context.active_object
center_line.name = "CenterLine"
center_line.data.materials.append(mat_pure_white)
center_line.scale = (0.03, 1.35, 0.005)
center_line.keyframe_insert(data_path="scale", frame=1)
center_line.keyframe_insert(data_path="scale", frame=35)
center_line.scale = (0.03, 1.35, 0.005)
center_line.keyframe_insert(data_path="scale", frame=65)
center_line.keyframe_insert(data_path="scale", frame=90)

# Cross line for the square icon (Image 2)
bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 0.06))
cross_line = bpy.context.active_object
cross_line.name = "CrossLine"
cross_line.data.materials.append(mat_pure_white)
cross_line.scale = (1.35, 0.03, 0.005)

# 8. PICKLEBALL NET (Visible in Rectangle Court, folds/disappears in Mini Icon)
bpy.ops.mesh.primitive_cube_add(size=1.0, location=(0, 0, 0.16))
net = bpy.context.active_object
net.name = "Net"
net.data.materials.append(mat_net)

net.scale = (0.02, 1.5, 0.22)
net.keyframe_insert(data_path="scale", frame=1)
net.keyframe_insert(data_path="scale", frame=35)
net.scale = (0.001, 0.001, 0.001) # Shrink away into mini icon
net.keyframe_insert(data_path="scale", frame=60)
net.keyframe_insert(data_path="scale", frame=90)

# 9. PICKLEBALL YELLOW BALL (With dark holes)
bpy.ops.mesh.primitive_uv_sphere_add(radius=0.17, location=(-0.9, -0.4, 0.15))
ball = bpy.context.active_object
ball.name = "Pickleball"
ball.data.materials.append(mat_pickleball)
bpy.ops.object.shade_smooth()

# Flight Arc Keyframes:
# 1-12: Upper Left (Image 1 position)
ball.location = (-0.95, -0.35, 0.15)
ball.keyframe_insert(data_path="location", frame=1)
ball.keyframe_insert(data_path="location", frame=10)

# 28: Flying high through arc
ball.location = (-0.45, -0.15, 0.85)
ball.keyframe_insert(data_path="location", frame=28)

# 48: Landing crisp in center
ball.location = (0.1, 0.05, 0.16)
ball.keyframe_insert(data_path="location", frame=48)

# 65-90: Rest in exact center of Image 2 icon
ball.location = (0.0, 0.0, 0.16)
ball.keyframe_insert(data_path="location", frame=65)
ball.keyframe_insert(data_path="location", frame=90)

# 10. CURVED WHITE SWOOSH TRAIL (Curved 3D Ribbon matching Image 2)
curve_data = bpy.data.curves.new('SwooshCurve', type='CURVE')
curve_data.dimensions = '3D'
curve_data.bevel_depth = 0.045
curve_data.bevel_resolution = 6

spline = curve_data.splines.new('BEZIER')
spline.bezier_points.add(2)

# Point 0: Origin behind ball
p0 = spline.bezier_points[0]
p0.co = (-0.85, -0.35, 0.12)
p0.handle_left = (-1.0, -0.4, 0.12)
p0.handle_right = (-0.6, -0.25, 0.45)

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
swoosh_obj.data.materials.append(mat_swoosh)

# Animate swoosh growing along the arc
curve_data.bevel_factor_end = 0.0
curve_data.keyframe_insert(data_path="bevel_factor_end", frame=10)
curve_data.bevel_factor_end = 1.0
curve_data.keyframe_insert(data_path="bevel_factor_end", frame=48)

# 11. SHADOW (Soft dark oval beneath the ball in Image 2)
bpy.ops.mesh.primitive_plane_add(size=1.0, location=(0.04, -0.03, 0.065))
shadow = bpy.context.active_object
shadow.name = "BallShadow"
mat_shadow = create_mat("ShadowMat", (0.01, 0.05, 0.15, 0.6), roughness=0.5)
shadow.data.materials.append(mat_shadow)
shadow.scale = (0.16, 0.10, 1.0)

# 12. RENDER MP4
output_path = os.path.abspath(r"D:\Duancanhan\Project_QuanLyGiaiDau\HethongFrontEndApp_QLgiaidau\assets\videos\pickleball_loading.mp4")
scene.render.filepath = output_path
scene.render.image_settings.file_format = 'FFMPEG'
scene.render.ffmpeg.format = 'MPEG4'
scene.render.ffmpeg.codec = 'H264'
scene.render.ffmpeg.constant_rate_factor = 'HIGH'
scene.render.ffmpeg.ffmpeg_preset = 'GOOD'

print("==> V2 Blender Script Configured!")
