shader_type canvas_item;
render_mode unshaded;

global uniform sampler2D color_texture;
global uniform int max_channels;
global uniform int current_editor_layer;
global uniform vec3 selection_color;

uniform int channel_id = 1;
uniform bool is_selected = false;
uniform int editor_layer = 0;


void fragment() {
	vec4 texture_color = texture(TEXTURE, UV);
	vec3 object_color = texture_color.rgb;
	
	if (is_selected) {
		object_color = texture_color.rgb * selection_color;
	} else {
		if(channel_id >= 0){
			object_color = texture_color.rgb * texture(color_texture, vec2((float(channel_id) + 0.5) / float(max_channels), 0.5)).rgb;
		}
	 }
	
	if(editor_layer == current_editor_layer || current_editor_layer < 0){
		COLOR = vec4(object_color, texture_color.a);
	} else {
		COLOR = vec4(object_color, texture_color.a * 0.4);
	}
}
