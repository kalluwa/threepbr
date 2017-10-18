varying vec2 vUV;
varying vec3 v_worldpos;
varying vec3 v_normal;
void main()
{
    vUV = uv;
    vec4 worldpos_v4 = modelViewMatrix * vec4(position,1.0);
    v_worldpos = worldpos_v4.xyz;
    
    v_normal = normal;
    gl_Position  = projectionMatrix * worldpos_v4;
}


