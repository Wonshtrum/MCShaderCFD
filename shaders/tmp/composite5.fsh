#version 120

#include "config.glsl"


//////////////////////////////////////////////////////////////////////////////////////////
/* DRAWBUFFERS:012 */
//////////////////////////////////////////////////////////////////////////////////////////
void main() {
	vec4 cell = texture2D(current_field, texcoord);
	vec3 pos = bufPos(texcoord)-DT*cell.xyz;
	pos = clamp(pos, vec3(0.5), vec3(N+0.5));
	frag_current = cell;
	frag_current.w = getFieldSmooth(current_field, pos).w;
	frag_prev = texture2D(prev_field, texcoord);
	frag_current = cell;
}