shader_type canvas_item;

// 0.0 = intact, 1.0 = fully burned away.
uniform float progress : hint_range(0.0, 1.0) = 0.0;

// Colors of the burning edge band.
uniform vec3 ember_inner : source_color = vec3(1.0, 0.95, 0.35);
uniform vec3 ember_outer : source_color = vec3(1.0, 0.35, 0.05);

// Width of the glowing burn-edge band, in noise-space units.
uniform float edge_width : hint_range(0.0, 0.4) = 0.12;

// Bottom-up bias: 0 = uniform burn, 1 = burns from bottom to top.
uniform float vertical_bias : hint_range(0.0, 1.0) = 0.45;


// Cheap procedural noise — good enough for a dissolve mask and avoids
// shipping an extra texture asset.
float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash(i);
	float b = hash(i + vec2(1.0, 0.0));
	float c = hash(i + vec2(0.0, 1.0));
	float d = hash(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
	float v = 0.0;
	float amp = 0.5;
	for (int i = 0; i < 4; i++) {
		v += amp * value_noise(p);
		p *= 2.0;
		amp *= 0.5;
	}
	return v;
}

void fragment() {
	vec4 base = texture(TEXTURE, UV);

	// Burn from bottom up: bias the dissolve mask so lower pixels disappear sooner.
	float n = fbm(UV * 6.0);
	float mask = mix(n, n - (1.0 - UV.y), vertical_bias);
	mask = clamp(mask, 0.0, 1.0);

	// Threshold sweeps from -edge_width to 1+edge_width so the band fully exits.
	float threshold = mix(-edge_width, 1.0 + edge_width, progress);

	// Above threshold: discarded (already burned).
	// Inside band [threshold, threshold+edge_width]: glowing ember edge.
	// Below threshold+edge_width: intact.
	if (mask < threshold) {
		discard;
	}

	float band = smoothstep(threshold, threshold + edge_width, mask);
	vec3 ember = mix(ember_inner, ember_outer, smoothstep(0.0, 1.0, 1.0 - band));
	vec3 rgb = mix(ember, base.rgb, band);
	float alpha = base.a * mix(1.0, base.a, band);
	// Boost ember brightness so it reads even on the dark card stock.
	if (band < 1.0) {
		alpha = max(alpha, 0.9 * (1.0 - band));
	}

	COLOR = vec4(rgb, alpha);
}
