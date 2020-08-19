#version 120

#include "config.glsl"


//////////////////////////////////////////////////////////////////////////////////////////
/* DRAWBUFFERS:012 */
//////////////////////////////////////////////////////////////////////////////////////////
void main() {
	float h = 1.0/N;
	vec3 pos = bufPos(texcoord);
	frag_current = texture2D(current_field, texcoord);
	frag_current.xyz -= 0.5*vec3(
		getField(prev_field, pos+vec3(1, 0, 0)).x - getField(prev_field, pos-vec3(1, 0, 0)).x,
		getField(prev_field, pos+vec3(0, 1, 0)).x - getField(prev_field, pos-vec3(0, 1, 0)).x,
		getField(prev_field, pos+vec3(0, 0, 1)).x - getField(prev_field, pos-vec3(0, 0, 1)).x)/h;
}