shader_type canvas_item;
render_mode unshaded;

instance uniform float flash_intensity : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	vec3 flash_col = tex_color.rgb + (vec3(flash_intensity) * tex_color.a);
	COLOR = vec4(flash_col, tex_color.a);
}
