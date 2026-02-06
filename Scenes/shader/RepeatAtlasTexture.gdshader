//shader_type canvas_item;
//
//uniform vec2 repeat_amount = vec2(1.0, 1.0);

shader_type canvas_item;

uniform vec2 region_top_left; // e.g., (0.0, 0.0)
uniform vec2 region_size = vec2(16.0, 16.0);
uniform vec2 repeat_amount = vec2(1.0, 1.0);

void fragment() {
	vec2 full_sheet_size = vec2(textureSize(TEXTURE, 0));
	vec2 uv_min = region_top_left / full_sheet_size;
	vec2 uv_max = (region_top_left + region_size) / full_sheet_size;
	vec2 uv_range = uv_max - uv_min;
	
	vec2 looped_uv = fract(UV * repeat_amount);
	vec2 final_uv = uv_min + (looped_uv * uv_range);

	COLOR = texture(TEXTURE, final_uv);
}