varying vec2 vUV;
varying vec4 v_worldpos;

void main()
{
    vUV = uv;
    v_worldpos = modelViewMatrix * vec4(position,1.0);
    gl_Position  = projectionMatrix * v_worldpos;
}


