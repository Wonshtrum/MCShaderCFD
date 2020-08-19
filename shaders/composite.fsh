#version 120

#include "config.glsl"


//////////////////////////////////////////////////////////////////////////////////////////
/* DRAWBUFFERS:012 */
//////////////////////////////////////////////////////////////////////////////////////////
void main() {
	float h = 1.0/N;
	vec3 pos = bufPos(texcoord);
	frag_current = texture2D(current_field, texcoord);
	frag_prev = -0.5*vec4(
		getField(current_field, pos+vec3(1, 0, 0)).x - getField(current_field, pos-vec3(1, 0, 0)).x +
		getField(current_field, pos+vec3(0, 1, 0)).y - getField(current_field, pos-vec3(0, 1, 0)).y +
		getField(current_field, pos+vec3(0, 0, 1)).z - getField(current_field, pos-vec3(0, 0, 1)).z, 0, 0, 0);
	BOUNDS_div_p();
}