#define N				115
#define W				16
#define DT				0.2

//#define TWO_DIMENSION

#define origine			vec3(28, 8, 5)
#define scale			5

#define out_field 		colortex0
#define prev_field 		colortex1
#define current_field 	colortex2

#define frag_out 		gl_FragData[0]
#define frag_prev 		gl_FragData[1]
#define frag_current 	gl_FragData[2]

#define Field 			sampler2D

///////////////////////////////////////////////////////////////

/*
const int colortex1Format = RGBA32F;
const int colortex2Format = RGBA32F;
const int shadowMapResolution = 16;
const bool colortex1Clear = false;
const bool colortex2Clear = false;
*/

///////////////////////////////////////////////////////////////

uniform float viewWidth;
uniform float viewHeight;
uniform float frameTime;
uniform vec3 cameraPosition;

uniform mat4 gbufferModelViewInverse;
uniform mat4 gbufferProjectionInverse;

uniform Field out_field;
uniform Field prev_field;
uniform Field current_field;
uniform Field gdepthtex;

varying vec2 texcoord;

///////////////////////////////////////////////////////////////

vec2 bufSize = vec2(viewWidth, viewHeight);
vec2 pxlSize = 1/bufSize;

bool cursor() {
	float a = acos(gbufferModelViewInverse[0][0])/3.14159;
	float b = 2*acos(gbufferModelViewInverse[1][1])/3.14159;
	const float s = 0.002;
	return texcoord.s > a && texcoord.t > b && texcoord.s < a+s && texcoord.t < b+2*s;
}

vec3 bufPos(vec2 pos) {
	vec3 npos = vec3(0);
	npos.x = fract(pos.x*bufSize.x/N)*N;
	npos.y = fract(pos.y*bufSize.y/N)*N;
	npos.z = floor(pos.x*bufSize.x/N)+floor(pos.y*bufSize.y/N)*W;
	return npos;
}
vec2 texPos(vec3 pos) {
	pos = clamp(pos.xyz, vec3(0.5), vec3(N-0.5));
	pos.z = floor(pos.z);
	vec2 npos = pos.xy;
	npos.x += fract(pos.z/W)*W*N;
	npos.y += floor(pos.z/W)*N;
	return npos*pxlSize;
}

bool isBoundary(vec3 pos) {
	return pos.x < 1 || pos.y < 1 || pos.z < 1 || pos.x > N-1 || pos.y > N-1 || pos.z > N-1;
}

vec4 getField(Field field, vec3 pos) {
	if (isBoundary(pos)) return vec4(0);
	pos.z = floor(pos.z);
	return texture2D(field, texPos(pos));
}
vec4 getFieldSmooth(Field field, vec3 pos) {
	if (isBoundary(pos)) return vec4(0);
	return mix(texture2D(field, texPos(vec3(pos))), texture2D(field, texPos(vec3(pos+vec3(0,0,1)))), fract(pos.z));
}


vec4 diffuse(vec3 pos, Field u, Field u0, float diff, float dt) {
	vec4 a = dt*diff*vec4(0,0,0,0.1);
	//add bounds
	//return (getField(u0, pos) + a*(getField(u, pos-vec3(1, 0, 0)) + getField(u, pos+vec3(1, 0, 0)) + getField(u, pos-vec3(0, 1, 0)) + getField(u, pos+vec3(0, 1, 0))))/(1+4*a);
	return (getField(u0, pos) + a*(
		getField(u, pos-vec3(1, 0, 0)) + getField(u, pos+vec3(1, 0, 0)) +
		getField(u, pos-vec3(0, 1, 0)) + getField(u, pos+vec3(0, 1, 0)) +
		getField(u, pos-vec3(0, 0, 1)) + getField(u, pos+vec3(0, 0, 1))))/(1+6*a);
}

///////////////////////////////////////////////////////////////

vec3 getWorldSpacePosition(vec2 coord) {
	vec3 screenPos = vec3(coord, texture2D(gdepthtex, coord).r) * 2.0 - 1.0;
	vec4 tmp = gbufferProjectionInverse * vec4(screenPos, 1.0);
	vec3 viewPos = tmp.xyz / tmp.w;
	return mat3(gbufferModelViewInverse) * viewPos + gbufferModelViewInverse[3].xyz + cameraPosition;
}

vec3 pointer(vec2 coord) {
	vec3 pos = gbufferModelViewInverse[3].xyz + cameraPosition;
	vec3 ray = getWorldSpacePosition(coord).xyz-pos;
	float dist = length(ray);
	float p = 0;
	ray = normalize(ray);
	vec3 compensate = sign(sign(ray)+0.5);

	vec3 tmin = (origine-pos+scale*(1-(compensate+1)/2))/ray;
	vec3 tmax = (origine-pos+scale*(compensate+1)/2)/ray;
	if (tmin.x > tmax.y || tmin.y > tmax.x) {
		return vec3(0);
	}
	if (tmin.y > tmin.x) {
		tmin.x = tmin.y;
	}
	if (tmax.y < tmax.x) {
		tmax.x = tmax.y;
	}
	if (tmin.x > tmax.z || tmin.z > tmax.x) {
		return vec3(0);
	}	
	if (tmin.z > tmin.x) {
		tmin.x = tmin.z;
	}
	if (tmax.z < tmax.x) {
		tmax.x = tmax.z;
	}
	if (tmax.x > 0) {
		return (pos+tmax.x*ray-origine)*N/scale;
	}
	return vec3(0);
}

float voxel(vec3 pos) {
	return getField(current_field, floor(pos)+0.5).w*0.03;
}

vec3 voxelColor(vec3 pos) {
	return abs(getField(current_field, floor(pos)+0.5).xyz)*0.03;
}

float traced(vec3 pos, vec2 coord, int steps = N*2) {
	vec3 ray = getWorldSpacePosition(coord).xyz-pos;
	float dist = length(ray);
	float p = 0;
	ray = normalize(ray);
	vec3 dxyz = max(abs(ray), vec3(0.0001));
	vec3 compensate = sign(sign(ray)+0.5);

	vec3 tmin = (origine-pos+scale*(1-(compensate+1)/2))/ray;
	vec3 tmax = (origine-pos+scale*(compensate+1)/2)/ray;
	if (tmin.x > tmax.y || tmin.y > tmax.x) {
		return 0;
	}
	if (tmin.y > tmin.x) {
		tmin.x = tmin.y;
	}
	if (tmax.y < tmax.x) {
		tmax.x = tmax.y;
	}
	if (tmin.x > tmax.z || tmin.z > tmax.x) {
		return 0;
	}	
	if (tmin.z > tmin.x) {
		tmin.x = tmin.z;
	}
	if (tmax.z < tmax.x) {
		tmax.x = tmax.z;
	}
	if (tmax.x < 0) {
		return 0;
	}
	vec3 opos = pos;
	if (tmin.x > 0) {
		pos += tmin.x*ray;
	}
	dist = min(dist-length(opos-pos), length(opos+tmax.x*ray-pos))*N/scale;
	pos = (pos-origine)*N/scale;

	vec3 tmp;
	vec3 delta;
	const float minDelta = 0.001;
	float fog = 0;
	for (int k = 0 ; k < steps ; k++) {
		delta = fract(pos*-compensate)/dxyz;
		if (delta.x <= delta.y && delta.x <= delta.z) { //dx
			fog += voxel(pos)*(delta.x+minDelta);
			pos += ray*(delta.x+minDelta);
			p += delta.x+minDelta;
		} else if (delta.y <= delta.x && delta.y <= delta.z) { //dy
			fog += voxel(pos)*(delta.y+minDelta);
			pos += ray*(delta.y+minDelta);
			p += delta.y+minDelta;
		} else { //dz
			fog += voxel(pos)*(delta.z+minDelta);
			pos += ray*(delta.z+minDelta);
			p += delta.z+minDelta;
		}
		if (p >= dist || fog >= 1) {
			return fog;
		}
	}
	return fog;
}


vec3 tracedColor(vec3 pos, vec2 coord, int steps = N*2) {
	vec3 ray = getWorldSpacePosition(coord).xyz-pos;
	float dist = length(ray);
	float p = 0;
	ray = normalize(ray);
	vec3 dxyz = max(abs(ray), vec3(0.0001));
	vec3 compensate = sign(sign(ray)+0.5);

	vec3 tmin = (origine-pos+scale*(1-(compensate+1)/2))/ray;
	vec3 tmax = (origine-pos+scale*(compensate+1)/2)/ray;
	if (tmin.x > tmax.y || tmin.y > tmax.x) {
		return vec3(0);
	}
	if (tmin.y > tmin.x) {
		tmin.x = tmin.y;
	}
	if (tmax.y < tmax.x) {
		tmax.x = tmax.y;
	}
	if (tmin.x > tmax.z || tmin.z > tmax.x) {
		return vec3(0);
	}	
	if (tmin.z > tmin.x) {
		tmin.x = tmin.z;
	}
	if (tmax.z < tmax.x) {
		tmax.x = tmax.z;
	}
	if (tmax.x < 0) {
		return vec3(0);
	}
	vec3 opos = pos;
	if (tmin.x > 0) {
		pos += tmin.x*ray;
	}
	dist = min(dist-length(opos-pos), length(opos+tmax.x*ray-pos))*N/scale;
	pos = (pos-origine)*N/scale;

	vec3 tmp;
	vec3 delta;
	const float minDelta = 0.001;
	vec3 fog = vec3(0);
	for (int k = 0 ; k < steps ; k++) {
		delta = fract(pos*-compensate)/dxyz;
		if (delta.x <= delta.y && delta.x <= delta.z) { //dx
			fog += voxelColor(pos)*(delta.x+minDelta);
			pos += ray*(delta.x+minDelta);
			p += delta.x+minDelta;
		} else if (delta.y <= delta.x && delta.y <= delta.z) { //dy
			fog += voxelColor(pos)*(delta.y+minDelta);
			pos += ray*(delta.y+minDelta);
			p += delta.y+minDelta;
		} else { //dz
			fog += voxelColor(pos)*(delta.z+minDelta);
			pos += ray*(delta.z+minDelta);
			p += delta.z+minDelta;
		}
		if (p >= dist) {
			return fog;
		}
	}
	return fog;
}

///////////////////////////////////////////////////////////////

#define DIFFUSE()\
	frag_current = diffuse(bufPos(texcoord), current_field, prev_field, 1, DT);\
	frag_prev = texture2D(prev_field, texcoord);

#define BOUNDS_div_p()
#define BOUNDS_v()	const vec3 directions[] = vec3[6](vec3(-1, 0, 0), vec3(1, 0, 0), vec3(0, -1, 0), vec3(0, 1, 0), vec3(0, 0, -1), vec3(0, 0, 1));\
	for (int i = 0 ; i < 4 ; i++) {\
		if (isBoundary(pos+directions[i]))\
			frag_current.xyz *= 1-abs(directions[i]);\
	}
#define	BOUNDS_dv()