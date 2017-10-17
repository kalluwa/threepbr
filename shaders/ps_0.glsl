
uniform sampler2D t_basemap;
varying vec2 vUV;

void main()
{
    vec4 c_base = texture2D(t_basemap,vUV);
    gl_FragColor = c_base;
}


