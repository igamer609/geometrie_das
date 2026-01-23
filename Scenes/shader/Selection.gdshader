shader_type canvas_item;
render_mode blend_mix;

instance uniform bool is_selected = false;

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);
	 if (is_selected) {
		vec3 multiply = tex_color.rgb * vec3(0.0, 0.9, 0.0);
		COLOR = vec4(multiply, tex_color.a);
	} else {
		 COLOR = tex_color;
	 }
}