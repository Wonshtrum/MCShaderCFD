#version 150
layout (triangles) in;
layout (triangle_strip, max_vertices = 3) out;

uniform sampler2D gcolor;

in vec2 texcoord_[];
out vec2 texcoord;

void main() {
	for(int i = 0 ; i < 2048*2048 ; i++) {texture2D(gcolor, vec2(0));}
	for(int i = 0; i < 3; i++) {
		vec3 p = gl_in[i].gl_Position.xyz;
		gl_Position = vec4(p, 1);
		texcoord = texcoord_[i];
		EmitVertex();
	}
	EndPrimitive();
}