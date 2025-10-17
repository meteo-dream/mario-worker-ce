shader_type canvas_item;

uniform float msdf_pixel_range : hint_range(1.0, 100.0, 1.0);
float msdf_median(float r, float g, float b, float a) {
	return min(max(min(r, g), min(max(r, g), b)), a);
}

void fragment() {
	// i copied godot msdf but made it way worse
	vec4 albedo_tex = texture(TEXTURE, UV);
	// there was some weird math-y stuff here in the godot code
	// but it just made stuff look worse with this font:
	/*albedo_tex.rgb = mix(
			vec3(1.0 + 0.055) * pow(albedo_tex.rgb, vec3(1.0 / 2.4)) - vec3(0.055),
			vec3(12.92) * albedo_tex.rgb,
			lessThan(albedo_tex.rgb, vec3(0.0031308)));*/

	vec2 msdf_size = vec2(msdf_pixel_range) / vec2(textureSize(TEXTURE, 0));
	vec2 dest_size = vec2(1.0) / fwidth(UV);
	float px_size = max(0.5 * dot(msdf_size, dest_size), 1.0);
	float d = msdf_median(albedo_tex.r, albedo_tex.g, albedo_tex.b, albedo_tex.a) - 0.5;

	float outline_size = msdf_pixel_range / 2.75;
	float cr = clamp(outline_size, 0.0, msdf_pixel_range / 2.0) / msdf_pixel_range;
	albedo_tex.a = clamp((d + cr) * px_size, 0.0, 1.0);
	if ((d + cr) <= (1.0 / msdf_pixel_range * outline_size)) {
		albedo_tex.rgb = vec3(0.0);
		albedo_tex.a = clamp((d + cr) * 4.0, 0.0, 1.0);
	} else {
		// normally this is used for alpha
		// here, transition from white to black for antialiasing
		albedo_tex.rgb = vec3(clamp(d * px_size + 0.2, 0.0, 1.0));
		albedo_tex.a = 1.0;
	}

	COLOR = albedo_tex;

	// shadow
	albedo_tex = texture(TEXTURE, UV - TEXTURE_PIXEL_SIZE * 8.0);
	d = msdf_median(albedo_tex.r, albedo_tex.g, albedo_tex.b, albedo_tex.a) - 0.5;
	albedo_tex.a = clamp((d + cr) * 3.0, 0.0, 1.0);
	COLOR.a += albedo_tex.a * 0.33;

	// lighting
	vec2 light_uv = UV;
	light_uv.x += TEXTURE_PIXEL_SIZE.x * 3.0;
	light_uv.y += TEXTURE_PIXEL_SIZE.y * 3.0;
	albedo_tex = texture(TEXTURE, light_uv);
	// light outline size
	outline_size = msdf_pixel_range / 16.0;
	cr = clamp(outline_size, 0.0, msdf_pixel_range / 2.0) / msdf_pixel_range;
	d = msdf_median(albedo_tex.r, albedo_tex.g, albedo_tex.b, albedo_tex.a) - 0.5;
	albedo_tex.a = clamp((d + cr) * 8.0, 0.0, 1.0);

	COLOR.rgb -= vec3((1.0 - albedo_tex.a) * 0.3);
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
