shader_type canvas_item;
render_mode unshaded;

global uniform sampler2D color_texture;
global uniform int max_channels;
global uniform int current_editor_layer;
instance uniform vec3 selection_color = vec3(0.0, 0.9, 0.0);
instance uniform bool is_selected = false;
instance uniform int editor_layer = 0;
instance uniform int channel_id = 1;
instance uniform float flash_intensity : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 texture_color = texture(TEXTURE, UV);
	vec3 object_color = texture_color.rgb;
	
	if (is_selected) {
		object_color = texture_color.rgb * selection_color;
	} else {
		object_color = texture_color.rgb * texture(color_texture, vec2((float(channel_id) + 0.5) / float(max_channels), 0.5)).rgb;
	
		if(flash_intensity > 0.001){
			object_color = object_color.rgb + (vec3(flash_intensity) * texture_color.a);
		}
	 }
	
	if(editor_layer == current_editor_layer){
		COLOR = vec4(object_color, texture_color.a);
	} else {
		COLOR = vec4(object_color, texture_color.a * 0.4);
	}
}
