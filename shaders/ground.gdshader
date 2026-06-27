// NOTE: Shader automatically converted from Godot Engine 4.6.3.stable.mono's StandardMaterial3D.

shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform vec4 albedo : source_color;
uniform sampler2D texture_albedo : source_color, filter_nearest, repeat_enable;

uniform vec3 uv1_scale;
uniform vec3 uv1_offset;

global uniform vec3 player_pos;
global uniform float curvature;
render_mode world_vertex_coords;
void vertex() {
	UV = UV * uv1_scale.xy + uv1_offset.xy;
	float x = player_pos.x - VERTEX.x;
	float z = player_pos.z - VERTEX.z;
	VERTEX.y -= curvature * (z * z + x * x);
}

void fragment() {
	vec2 base_uv = UV;
	vec4 albedo_tex = texture(texture_albedo, base_uv);
	ALBEDO = albedo.rgb * albedo_tex.rgb;
}
