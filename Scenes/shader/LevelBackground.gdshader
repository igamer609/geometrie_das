shader_type canvas_item;

global uniform sampler2D color_texture;
global uniform int max_channels;

void fragment() {
	vec4 channel_color = texture(color_texture, vec2(0.5 / float(max_channels), 0.5));
	vec4 initial_color = texture(TEXTURE, UV);
	COLOR =  initial_color * channel_color;
}
