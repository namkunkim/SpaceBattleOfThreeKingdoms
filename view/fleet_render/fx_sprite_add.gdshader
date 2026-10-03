shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, skip_vertex_transform, shadows_disabled;

#include "res://view/fleet_render/fx_sprite.gdshaderinc"

void fragment() {
	vec4 s = sprite(UV);
	ALBEDO = s.rgb * s.a;
	ALPHA = 1.0;
}
