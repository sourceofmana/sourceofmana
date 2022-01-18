shader_type canvas_item;

uniform float LUMINANCE_WEIGHT = 1.0;
uniform float EQUAL_COLOR_TOLERANCE = 0.05;
uniform float STEEP_DIRECTION_THRESHOLD = 2.0;
uniform float DOMINANT_DIRECTION_THRESHOLD = 3.5;

varying vec4 t[8];

void vertex() {
	vec2 source_wh = vec2(1.0 / TEXTURE_PIXEL_SIZE.x, 1.0 / TEXTURE_PIXEL_SIZE.y);
	vec4 source_size = vec4(source_wh, 1.0 / source_wh);
	
	vec2 ps = vec2(source_size.z, source_size.w);
	float dx = ps.x;
	float dy = ps.y;
	t[1] = UV.xxxy + vec4(-dx, 0.0, dx, -2.0 * dy); // A1 B1 C1
	t[2] = UV.xxxy + vec4(-dx, 0.0, dx, -dy);    //  A  B  C
	t[3] = UV.xxxy + vec4(-dx, 0.0, dx, 0.0);    //  D  E  F
	t[4] = UV.xxxy + vec4(-dx, 0.0, dx, dy);     //  G  H  I
	t[5] = UV.xxxy + vec4(-dx, 0.0, dx, 2.0 * dy); // G5 H5 I5
	t[6] = UV.xyyy + vec4(-2.0 * dx, -dy, 0.0, dy);  // A0 D0 G0
	t[7] = UV.xyyy + vec4(2.0 * dx, -dy, 0.0, dy);  // C4 F4 I4
}

const float  one_sixth = 1.0 / 6.0;
const float  two_sixth = 2.0 / 6.0;
const float four_sixth = 4.0 / 6.0;
const float five_sixth = 5.0 / 6.0;

float reduce(vec3 color) {
	return dot(color, vec3(65536.0, 256.0, 1.0));
}

float DistYCbCr(vec3 pixA, vec3 pixB) {
	const vec3 w = vec3(0.2627, 0.6780, 0.0593);
	const float scaleB = 0.5 / (1.0 - w.b);
	const float scaleR = 0.5 / (1.0 - w.r);
	vec3 diff = pixA - pixB;
	float Y = dot(diff, w);
	float Cb = scaleB * (diff.b - Y);
	float Cr = scaleR * (diff.r - Y);
	return sqrt(((LUMINANCE_WEIGHT * Y) * (LUMINANCE_WEIGHT * Y)) + (Cb * Cb) + (Cr * Cr));
}

bool IsPixEqual(vec3 pixA, vec3 pixB) {
	return (DistYCbCr(pixA, pixB) < EQUAL_COLOR_TOLERANCE);
}

ivec4 notEqual(ivec4 a, ivec4 b) {
	return ivec4(
		int(a[0] != b[0]),
		int(a[1] != b[1]),
		int(a[2] != b[2]),
		int(a[3] != b[3])
	);
}

const int BLEND_NONE = 0;
const int BLEND_NORMAL = 1;
const int BLEND_DOMINANT = 2;

bool IsBlendingNeeded(ivec4 blend) {
	return any(notEqual(blend, ivec4(BLEND_NONE, BLEND_NONE, BLEND_NONE, BLEND_NONE))) || blend.a != 0;
}

void fragment() {
	vec2 source_wh = vec2(1.0 / TEXTURE_PIXEL_SIZE.x, 1.0 / TEXTURE_PIXEL_SIZE.y);
	vec4 source_size = vec4(source_wh, 1.0 / source_wh);
	
	vec2 f = fract(UV * source_size.xy);
	vec3 src[25];
	src[21] = texture(TEXTURE, t[1].xw).rgb;
	src[22] = texture(TEXTURE, t[1].yw).rgb;
	src[23] = texture(TEXTURE, t[1].zw).rgb;
	src[6] = texture(TEXTURE, t[2].xw).rgb;
	src[7] = texture(TEXTURE, t[2].yw).rgb;
	src[8] = texture(TEXTURE, t[2].zw).rgb;
	src[5] = texture(TEXTURE, t[3].xw).rgb;
	src[0] = texture(TEXTURE, t[3].yw).rgb;
	src[1] = texture(TEXTURE, t[3].zw).rgb;
	src[4] = texture(TEXTURE, t[4].xw).rgb;
	src[3] = texture(TEXTURE, t[4].yw).rgb;
	src[2] = texture(TEXTURE, t[4].zw).rgb;
	src[15] = texture(TEXTURE, t[5].xw).rgb;
	src[14] = texture(TEXTURE, t[5].yw).rgb;
	src[13] = texture(TEXTURE, t[5].zw).rgb;
	src[19] = texture(TEXTURE, t[6].xy).rgb;
	src[18] = texture(TEXTURE, t[6].xz).rgb;
	src[17] = texture(TEXTURE, t[6].xw).rgb;
	src[9] = texture(TEXTURE, t[7].xy).rgb;
	src[10] = texture(TEXTURE, t[7].xz).rgb;
	src[11] = texture(TEXTURE, t[7].xw).rgb;
	
	float v[9];
	v[0] = reduce(src[0]);
	v[1] = reduce(src[1]);
	v[2] = reduce(src[2]);
	v[3] = reduce(src[3]);
	v[4] = reduce(src[4]);
	v[5] = reduce(src[5]);
	v[6] = reduce(src[6]);
	v[7] = reduce(src[7]);
	v[8] = reduce(src[8]);
	
	ivec4 blendResult = ivec4(BLEND_NONE, BLEND_NONE, BLEND_NONE, BLEND_NONE);

	if (((v[0] == v[1] && v[3] == v[2]) || (v[0] == v[3] && v[1] == v[2])) == false)
	{
		float dist_03_01 = DistYCbCr(src[4], src[0]) + DistYCbCr(src[0], src[8]) + DistYCbCr(src[14], src[2]) + DistYCbCr(src[2], src[10]) + (4.0 * DistYCbCr(src[3], src[1]));
		float dist_00_02 = DistYCbCr(src[5], src[3]) + DistYCbCr(src[3], src[13]) + DistYCbCr(src[7], src[1]) + DistYCbCr(src[1], src[11]) + (4.0 * DistYCbCr(src[0], src[2]));
		bool dominantGradient = (DOMINANT_DIRECTION_THRESHOLD * dist_03_01) < dist_00_02;
		blendResult[2] = ((dist_03_01 < dist_00_02) && (v[0] != v[1]) && (v[0] != v[3])) ? ((dominantGradient) ? BLEND_DOMINANT : BLEND_NORMAL) : BLEND_NONE;
	}

	if (((v[5] == v[0] && v[4] == v[3]) || (v[5] == v[4] && v[0] == v[3])) == false)
	{
		float dist_04_00 = DistYCbCr(src[17], src[5]) + DistYCbCr(src[5], src[7]) + DistYCbCr(src[15], src[3]) + DistYCbCr(src[3], src[1]) + (4.0 * DistYCbCr(src[4], src[0]));
		float dist_05_03 = DistYCbCr(src[18], src[4]) + DistYCbCr(src[4], src[14]) + DistYCbCr(src[6], src[0]) + DistYCbCr(src[0], src[2]) + (4.0 * DistYCbCr(src[5], src[3]));
		bool dominantGradient = (DOMINANT_DIRECTION_THRESHOLD * dist_05_03) < dist_04_00;
		blendResult[3] = ((dist_04_00 > dist_05_03) && (v[0] != v[5]) && (v[0] != v[3])) ? ((dominantGradient) ? BLEND_DOMINANT : BLEND_NORMAL) : BLEND_NONE;
	}

	if (((v[7] == v[8] && v[0] == v[1]) || (v[7] == v[0] && v[8] == v[1])) == false)
	{
		float dist_00_08 = DistYCbCr(src[5], src[7]) + DistYCbCr(src[7], src[23]) + DistYCbCr(src[3], src[1]) + DistYCbCr(src[1], src[9]) + (4.0 * DistYCbCr(src[0], src[8]));
		float dist_07_01 = DistYCbCr(src[6], src[0]) + DistYCbCr(src[0], src[2]) + DistYCbCr(src[22], src[8]) + DistYCbCr(src[8], src[10]) + (4.0 * DistYCbCr(src[7], src[1]));
		bool dominantGradient = (DOMINANT_DIRECTION_THRESHOLD * dist_07_01) < dist_00_08;
		blendResult[1] = ((dist_00_08 > dist_07_01) && (v[0] != v[7]) && (v[0] != v[1])) ? ((dominantGradient) ? BLEND_DOMINANT : BLEND_NORMAL) : BLEND_NONE;
	}

	if (((v[6] == v[7] && v[5] == v[0]) || (v[6] == v[5] && v[7] == v[0])) == false)
	{
		float dist_05_07 = DistYCbCr(src[18], src[6]) + DistYCbCr(src[6], src[22]) + DistYCbCr(src[4], src[0]) + DistYCbCr(src[0], src[8]) + (4.0 * DistYCbCr(src[5], src[7]));
		float dist_06_00 = DistYCbCr(src[19], src[5]) + DistYCbCr(src[5], src[3]) + DistYCbCr(src[21], src[7]) + DistYCbCr(src[7], src[1]) + (4.0 * DistYCbCr(src[6], src[0]));
		bool dominantGradient = (DOMINANT_DIRECTION_THRESHOLD * dist_05_07) < dist_06_00;
		blendResult[0] = ((dist_05_07 < dist_06_00) && (v[0] != v[5]) && (v[0] != v[7])) ? ((dominantGradient) ? BLEND_DOMINANT : BLEND_NORMAL) : BLEND_NONE;
	}
	
	vec3 dst[16];
	dst[0] = src[0];
	dst[1] = src[0];
	dst[2] = src[0];
	dst[3] = src[0];
	dst[4] = src[0];
	dst[5] = src[0];
	dst[6] = src[0];
	dst[7] = src[0];
	dst[8] = src[0];
	dst[9] = src[0];
	dst[10] = src[0];
	dst[11] = src[0];
	dst[12] = src[0];
	dst[13] = src[0];
	dst[14] = src[0];
	dst[15] = src[0];
	
	if (IsBlendingNeeded(blendResult) == true) {
		float dist_01_04 = DistYCbCr(src[1], src[4]);
		float dist_03_08 = DistYCbCr(src[3], src[8]);
		bool haveShallowLine = (STEEP_DIRECTION_THRESHOLD * dist_01_04 <= dist_03_08) && (v[0] != v[4]) && (v[5] != v[4]);
		bool haveSteepLine = (STEEP_DIRECTION_THRESHOLD * dist_03_08 <= dist_01_04) && (v[0] != v[8]) && (v[7] != v[8]);
		bool needBlend = (blendResult[2] != BLEND_NONE);
		bool doLineBlend = (blendResult[2] >= BLEND_DOMINANT ||
			((blendResult[1] != BLEND_NONE && !IsPixEqual(src[0], src[4])) ||
			(blendResult[3] != BLEND_NONE && !IsPixEqual(src[0], src[8])) ||
				(IsPixEqual(src[4], src[3]) && IsPixEqual(src[3], src[2]) && IsPixEqual(src[2], src[1]) && IsPixEqual(src[1], src[8]) && IsPixEqual(src[0], src[2]) == false)) == false);

		vec3 blendPix = (DistYCbCr(src[0], src[1]) <= DistYCbCr(src[0], src[3])) ? src[1] : src[3];
		dst[2] = mix(dst[2], blendPix, (needBlend && doLineBlend) ? ((haveShallowLine) ? ((haveSteepLine) ? 1.0 / 3.0 : 0.25) : ((haveSteepLine) ? 0.25 : 0.00)) : 0.00);
		dst[9] = mix(dst[9], blendPix, (needBlend && doLineBlend && haveSteepLine) ? 0.25 : 0.00);
		dst[10] = mix(dst[10], blendPix, (needBlend && doLineBlend && haveSteepLine) ? 0.75 : 0.00);
		dst[11] = mix(dst[11], blendPix, (needBlend) ? ((doLineBlend) ? ((haveSteepLine) ? 1.00 : ((haveShallowLine) ? 0.75 : 0.50)) : 0.08677704501) : 0.00);
		dst[12] = mix(dst[12], blendPix, (needBlend) ? ((doLineBlend) ? 1.00 : 0.6848532563) : 0.00);
		dst[13] = mix(dst[13], blendPix, (needBlend) ? ((doLineBlend) ? ((haveShallowLine) ? 1.00 : ((haveSteepLine) ? 0.75 : 0.50)) : 0.08677704501) : 0.00);
		dst[14] = mix(dst[14], blendPix, (needBlend && doLineBlend && haveShallowLine) ? 0.75 : 0.00);
		dst[15] = mix(dst[15], blendPix, (needBlend && doLineBlend && haveShallowLine) ? 0.25 : 0.00);

		dist_01_04 = DistYCbCr(src[7], src[2]);
		dist_03_08 = DistYCbCr(src[1], src[6]);
		haveShallowLine = (STEEP_DIRECTION_THRESHOLD * dist_01_04 <= dist_03_08) && (v[0] != v[2]) && (v[3] != v[2]);
		haveSteepLine = (STEEP_DIRECTION_THRESHOLD * dist_03_08 <= dist_01_04) && (v[0] != v[6]) && (v[5] != v[6]);
		needBlend = (blendResult[1] != BLEND_NONE);
		doLineBlend = (blendResult[1] >= BLEND_DOMINANT ||
			!((blendResult[0] != BLEND_NONE && !IsPixEqual(src[0], src[2])) ||
			(blendResult[2] != BLEND_NONE && !IsPixEqual(src[0], src[6])) ||
				(IsPixEqual(src[2], src[1]) && IsPixEqual(src[1], src[8]) && IsPixEqual(src[8], src[7]) && IsPixEqual(src[7], src[6]) && !IsPixEqual(src[0], src[8]))));

		blendPix = (DistYCbCr(src[0], src[7]) <= DistYCbCr(src[0], src[1])) ? src[7] : src[1];
		dst[1] = mix(dst[1], blendPix, (needBlend && doLineBlend) ? ((haveShallowLine) ? ((haveSteepLine) ? 1.0 / 3.0 : 0.25) : ((haveSteepLine) ? 0.25 : 0.00)) : 0.00);
		dst[6] = mix(dst[6], blendPix, (needBlend && doLineBlend && haveSteepLine) ? 0.25 : 0.00);
		dst[7] = mix(dst[7], blendPix, (needBlend && doLineBlend && haveSteepLine) ? 0.75 : 0.00);
		dst[8] = mix(dst[8], blendPix, (needBlend) ? ((doLineBlend) ? ((haveSteepLine) ? 1.00 : ((haveShallowLine) ? 0.75 : 0.50)) : 0.08677704501) : 0.00);
		dst[9] = mix(dst[9], blendPix, (needBlend) ? ((doLineBlend) ? 1.00 : 0.6848532563) : 0.00);
		dst[10] = mix(dst[10], blendPix, (needBlend) ? ((doLineBlend) ? ((haveShallowLine) ? 1.00 : ((haveSteepLine) ? 0.75 : 0.50)) : 0.08677704501) : 0.00);
		dst[11] = mix(dst[11], blendPix, (needBlend && doLineBlend && haveShallowLine) ? 0.75 : 0.00);
		dst[12] = mix(dst[12], blendPix, (needBlend && doLineBlend && haveShallowLine) ? 0.25 : 0.00);

		dist_01_04 = DistYCbCr(src[5], src[8]);
		dist_03_08 = DistYCbCr(src[7], src[4]);
		haveShallowLine = (STEEP_DIRECTION_THRESHOLD * dist_01_04 <= dist_03_08) && (v[0] != v[8]) && (v[1] != v[8]);
		haveSteepLine = (STEEP_DIRECTION_THRESHOLD * dist_03_08 <= dist_01_04) && (v[0] != v[4]) && (v[3] != v[4]);
		needBlend = (blendResult[0] != BLEND_NONE);
		doLineBlend = (blendResult[0] >= BLEND_DOMINANT ||
			!((blendResult[3] != BLEND_NONE && !IsPixEqual(src[0], src[8])) ||
			(blendResult[1] != BLEND_NONE && !IsPixEqual(src[0], src[4])) ||
				(IsPixEqual(src[8], src[7]) && IsPixEqual(src[7], src[6]) && IsPixEqual(src[6], src[5]) && IsPixEqual(src[5], src[4]) && !IsPixEqual(src[0], src[6]))));

		blendPix = (DistYCbCr(src[0], src[5]) <= DistYCbCr(src[0], src[7])) ? src[5] : src[7];
		dst[0] = mix(dst[0], blendPix, (needBlend && doLineBlend) ? ((haveShallowLine) ? ((haveSteepLine) ? 1.0 / 3.0 : 0.25) : ((haveSteepLine) ? 0.25 : 0.00)) : 0.00);
		dst[15] = mix(dst[15], blendPix, (needBlend && doLineBlend && haveSteepLine) ? 0.25 : 0.00);
		dst[4] = mix(dst[4], blendPix, (needBlend && doLineBlend && haveSteepLine) ? 0.75 : 0.00);
		dst[5] = mix(dst[5], blendPix, (needBlend) ? ((doLineBlend) ? ((haveSteepLine) ? 1.00 : ((haveShallowLine) ? 0.75 : 0.50)) : 0.08677704501) : 0.00);
		dst[6] = mix(dst[6], blendPix, (needBlend) ? ((doLineBlend) ? 1.00 : 0.6848532563) : 0.00);
		dst[7] = mix(dst[7], blendPix, (needBlend) ? ((doLineBlend) ? ((haveShallowLine) ? 1.00 : ((haveSteepLine) ? 0.75 : 0.50)) : 0.08677704501) : 0.00);
		dst[8] = mix(dst[8], blendPix, (needBlend && doLineBlend && haveShallowLine) ? 0.75 : 0.00);
		dst[9] = mix(dst[9], blendPix, (needBlend && doLineBlend && haveShallowLine) ? 0.25 : 0.00);


		dist_01_04 = DistYCbCr(src[3], src[6]);
		dist_03_08 = DistYCbCr(src[5], src[2]);
		haveShallowLine = (STEEP_DIRECTION_THRESHOLD * dist_01_04 <= dist_03_08) && (v[0] != v[6]) && (v[7] != v[6]);
		haveSteepLine = (STEEP_DIRECTION_THRESHOLD * dist_03_08 <= dist_01_04) && (v[0] != v[2]) && (v[1] != v[2]);
		needBlend = (blendResult[3] != BLEND_NONE);
		doLineBlend = (blendResult[3] >= BLEND_DOMINANT ||
			!((blendResult[2] != BLEND_NONE && !IsPixEqual(src[0], src[6])) ||
			(blendResult[0] != BLEND_NONE && !IsPixEqual(src[0], src[2])) ||
				(IsPixEqual(src[6], src[5]) && IsPixEqual(src[5], src[4]) && IsPixEqual(src[4], src[3]) && IsPixEqual(src[3], src[2]) && !IsPixEqual(src[0], src[4]))));

		blendPix = (DistYCbCr(src[0], src[3]) <= DistYCbCr(src[0], src[5])) ? src[3] : src[5];
		dst[3] = mix(dst[3], blendPix, (needBlend && doLineBlend) ? ((haveShallowLine) ? ((haveSteepLine) ? 1.0 / 3.0 : 0.25) : ((haveSteepLine) ? 0.25 : 0.00)) : 0.00);
		dst[12] = mix(dst[12], blendPix, (needBlend && doLineBlend && haveSteepLine) ? 0.25 : 0.00);
		dst[13] = mix(dst[13], blendPix, (needBlend && doLineBlend && haveSteepLine) ? 0.75 : 0.00);
		dst[14] = mix(dst[14], blendPix, (needBlend) ? ((doLineBlend) ? ((haveSteepLine) ? 1.00 : ((haveShallowLine) ? 0.75 : 0.50)) : 0.08677704501) : 0.00);
		dst[15] = mix(dst[15], blendPix, (needBlend) ? ((doLineBlend) ? 1.00 : 0.6848532563) : 0.00);
		dst[4] = mix(dst[4], blendPix, (needBlend) ? ((doLineBlend) ? ((haveShallowLine) ? 1.00 : ((haveSteepLine) ? 0.75 : 0.50)) : 0.08677704501) : 0.00);
		dst[5] = mix(dst[5], blendPix, (needBlend && doLineBlend && haveShallowLine) ? 0.75 : 0.00);
		dst[6] = mix(dst[6], blendPix, (needBlend && doLineBlend && haveShallowLine) ? 0.25 : 0.00);
	}

	vec3 res = mix(mix(mix(mix(dst[6], dst[7], step(0.25, f.x)), mix(dst[8], dst[9], step(0.75, f.x)), step(0.50, f.x)),
		mix(mix(dst[5], dst[0], step(0.25, f.x)), mix(dst[1], dst[10], step(0.75, f.x)), step(0.50, f.x)), step(0.25, f.y)),
		mix(mix(mix(dst[4], dst[3], step(0.25, f.x)), mix(dst[2], dst[11], step(0.75, f.x)), step(0.50, f.x)),
			mix(mix(dst[15], dst[14], step(0.25, f.x)), mix(dst[13], dst[12], step(0.75, f.x)), step(0.50, f.x)), step(0.75, f.y)),
		step(0.50, f.y));
	
	COLOR = vec4(res.rgb, texture(TEXTURE, UV).a);
}
