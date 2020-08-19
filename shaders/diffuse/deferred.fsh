#version 120

#include "config.glsl"


//////////////////////////////////////////////////////////////////////////////////////////
/* DRAWBUFFERS:012 */
//////////////////////////////////////////////////////////////////////////////////////////
void main() {

	vec4 data = texture2D(current_field, texcoord);

	if (data.a == 0 && false) {
		frag_current = vec4(0, 0, abs(texcoord.s-0.5)+abs(texcoord.t-0.5) < 0.1 ? 1 : 0, 0);
		frag_prev = frag_current;
	} else {
		DIFFUSE();
	}

}