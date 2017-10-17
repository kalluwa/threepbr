varying vec2 vUV;

void main()
{
    vUV = uv;
    mat4 mvpMatrix = projectionMatrix * modelViewMatrix;
    gl_Position = mvpMatrix * vec4(position,1.0);
}


