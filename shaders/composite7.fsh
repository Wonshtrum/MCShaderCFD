#version 120

#include "config.glsl"


//////////////////////////////////////////////////////////////////////////////////////////
/* DRAWBUFFERS:012 */
//////////////////////////////////////////////////////////////////////////////////////////
void main() {

#ifdef TWO_DIMENSION
	//frag_out = vec4(texPos(bufPos(texcoord)), 0, 1);
	vec4 ext = cursor() ? vec4(1, 1, 0, 1)*10 : vec4(0, 0, 0, 0);
	frag_out = vec4(abs(texture2D(current_field, texcoord).www), 1);
	if (cursor()) frag_out = vec4(1, 0, 0.5, 1);
#else
	vec3 source = pointer(vec2(0.5));
	vec4 ext = vec4(0);
	if (source != vec3(0) && length(source-bufPos(texcoord))<5) {
		ext = vec4(0,1,0,0.1)*10;
	}
	frag_out = texture2D(out_field, texcoord);
	//frag_out += vec4(tracedColor(gbufferModelViewInverse[3].xyz + cameraPosition, texcoord), 1);
	frag_out += vec4(traced(gbufferModelViewInverse[3].xyz + cameraPosition, texcoord));
#endif
	
	frag_current = texture2D(current_field, texcoord) + DT*ext;
	frag_prev = frag_current;


}