#version 120

#include "config.glsl"


//////////////////////////////////////////////////////////////////////////////////////////
/* DRAWBUFFERS:012 */
//////////////////////////////////////////////////////////////////////////////////////////
void main() {
	vec4 cell = texture2D(current_field, texcoord);
	vec3 pos = bufPos(texcoord)-DT*cell.xyz;
	pos = clamp(pos, vec3(0.5), vec3(N+0.5));
	frag_current = getFieldSmooth(current_field, pos);
	frag_current.z = cell.z;
	frag_current = cell;
}