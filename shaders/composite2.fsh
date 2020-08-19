#version 120

#include "config.glsl"


//////////////////////////////////////////////////////////////////////////////////////////
/* DRAWBUFFERS:012 */
//////////////////////////////////////////////////////////////////////////////////////////
void main() {
	vec4 cell = texture2D(current_field, texcoord);
	vec3 pos = bufPos(texcoord)-DT*cell.xyz;
	frag_current = getFieldSmooth(current_field, pos);
	frag_current.w = cell.w;
}