
uniform sampler2D t_basemap;
uniform sampler2D t_mrmap;
uniform sampler2D t_normalmap;
//env map
uniform samplerCube t_diffuse_cubemap;
uniform samplerCube t_specular_cubemap;
uniform sampler2D t_brdfLUT;

uniform vec3 v_campos;

varying vec2 vUV;
varying vec3 v_worldpos;
varying vec3 v_normal;

//const value
const float min_roughness = 0.04;
const float M_PI = 3.141592653589793;
const vec3 v_lightdir = vec3(0.3,-0.4,0.5);
const vec3 c_light = vec3(1.0,1.0,1.0);
//PBR
vec3 getNormal()
{
    // Retrieve the tangent space matrix
    vec3 pos_dx = dFdx(v_worldpos);
    vec3 pos_dy = dFdy(v_worldpos);
    vec3 tex_dx = dFdx(vec3(vUV, 0.0));
    vec3 tex_dy = dFdy(vec3(vUV, 0.0));
    vec3 t = (tex_dy.t * pos_dx - tex_dx.t * pos_dy) / (tex_dx.s * tex_dy.t - tex_dy.s * tex_dx.t);

    vec3 ng = normalize(v_normal);

    t = normalize(t - ng * dot(ng, t));
    vec3 b = normalize(cross(ng, t));
    mat3 tbn = mat3(t, b, ng);

    vec3 n = texture2D(t_normalmap, vUV).rgb;
    vec3 nn = normalize(v_normal);//normalize(tbn*(2.0 * n - 1.0));//*vec3(u_NormalScale, u_NormalScale, 1.0);
    return nn;

    
    //vec3 n = texture2D(t_normalmap, vUV).rgb;
    //n = normalize(2.0 * n - 1.0);
    //return n;
}

//封装输入
struct PBRInfo
{
    float NdotL;                  // cos angle between normal and light direction
    float NdotV;                  // cos angle between normal and view direction
    float NdotH;                  // cos angle between normal and half vector
    float LdotH;                  // cos angle between light direction and half vector
    float VdotH;                  // cos angle between view direction and half vector
    float perceptualRoughness;    // roughness value, as authored by the model creator (input to shader)
    float metalness;              // metallic value at the surface
    vec3 reflectance0;            // full reflectance color (normal incidence angle)
    vec3 reflectance90;           // reflectance color at grazing angle
    float alphaRoughness;         // roughness mapped to a more linear change in the roughness (proposed by [2])
    vec3 diffuseColor;            // color contribution from diffuse lighting
    vec3 specularColor;           // color contribution from specular lighting
};

vec3 specularReflection(PBRInfo pbrInputs)
{
    return pbrInputs.reflectance0 + (pbrInputs.reflectance90 - pbrInputs.reflectance0) * pow(clamp(1.0 - pbrInputs.VdotH, 0.0, 1.0), 5.0);
}
float geometricOcclusion(PBRInfo pbrInputs)
{
    float NdotL = pbrInputs.NdotL;
    float NdotV = pbrInputs.NdotV;
    float r = pbrInputs.alphaRoughness;

    float attenuationL = 2.0 * NdotL / (NdotL + sqrt(r * r + (1.0 - r * r) * (NdotL * NdotL)));
    float attenuationV = 2.0 * NdotV / (NdotV + sqrt(r * r + (1.0 - r * r) * (NdotV * NdotV)));
    return attenuationL * attenuationV;
}
float microfacetDistribution(PBRInfo pbrInputs)
{
    float roughnessSq = pbrInputs.alphaRoughness * pbrInputs.alphaRoughness;
    float f = (pbrInputs.NdotH * roughnessSq - pbrInputs.NdotH) * pbrInputs.NdotH + 1.0;
    return roughnessSq / (M_PI * f * f);
}
vec3 diffuse(PBRInfo pbrInputs)
{
    return pbrInputs.diffuseColor / M_PI;
}

vec3 getIBLContribution(PBRInfo pbrInputs, vec3 n, vec3 reflection)
{
    float mipCount = 9.0; // resolution of 512x512
    float lod = (pbrInputs.perceptualRoughness * mipCount);
    // retrieve a scale and bias to F0. See [1], Figure 3
    vec3 brdf = texture2D(t_brdfLUT, vec2(pbrInputs.NdotV, 1.0 - pbrInputs.perceptualRoughness)).rgb;
    vec3 diffuseLight = textureCube(t_diffuse_cubemap, n).rgb;
    vec3 specularLight = textureCube(t_specular_cubemap, reflection).rgb;
    //textureCubeLodEXT(t_specular_cubemap, reflection, lod).rgb;

    vec3 diffuse = diffuseLight * pbrInputs.diffuseColor;
    vec3 specular =  specularLight * (pbrInputs.specularColor * brdf.x + brdf.y);

    return diffuse + specular;
}

void main()
{
    /**
    * 1 metallic and roughness
    */
    //决定显示的两个因素就是[metallic&&roughness]
    //这个[一般]来自pixel（texel）
    float perceptualRoughness = 1.0;
    float metallic = 1.0;
    vec4 mrSample = texture2D(t_mrmap,vUV);
    perceptualRoughness = mrSample.g * perceptualRoughness;
    metallic = mrSample.b * metallic;

    perceptualRoughness = clamp(perceptualRoughness,min_roughness,1.0);
    metallic = clamp(metallic,0.0,1.0);

    float alpha_roughness = perceptualRoughness * perceptualRoughness;

    /**
    * 2 basecolor
    */
    vec4 c_base = texture2D(t_basemap,vUV);

    /**
    * 3 specularcolor
    */
    vec3 f0 = vec3(0.04);
    vec3 c_diffuse = c_base.rgb * (vec3(1.0) - f0);
    c_diffuse *= 1.0 - metallic;
    vec3 c_specular = mix(f0,c_base.rgb,metallic);

    //计算反射强度
    float reflectance = max(max(c_specular.r, c_specular.g), c_specular.b);

    float reflectance90 = clamp(reflectance * 25.0, 0.0, 1.0);
    vec3 specularEnvironmentR0 = c_specular.rgb;
    vec3 specularEnvironmentR90 = vec3(1.0, 1.0, 1.0) * reflectance90;

    vec3 n = getNormal();
    vec3 v = normalize(cameraPosition-v_worldpos.xyz);
    vec3 l = normalize(v_lightdir);
    vec3 h = normalize(l+v);
    vec3 reflection = -normalize(reflect(v,n));

    float NdotL = clamp(dot(n,l),0.001,1.0);
    float NdotV = abs(dot(n,v)) + 0.001;
    float NdotH = clamp(dot(n,h),0.0,1.0);
    float LdotH = clamp(dot(l,h),0.0,1.0);
    float VdotH = clamp(dot(v,h),0.0,1.0);


    PBRInfo pbrInputs = PBRInfo(
        NdotL,
        NdotV,
        NdotH,
        LdotH,
        VdotH,
        perceptualRoughness,
        metallic,
        specularEnvironmentR0,
        specularEnvironmentR90,
        alpha_roughness,
        c_diffuse,
        c_specular
    );

    // Calculate the shading terms for the microfacet specular shading model
    vec3 F = specularReflection(pbrInputs);
    float G = geometricOcclusion(pbrInputs);
    float D = microfacetDistribution(pbrInputs);

    // Calculation of analytical lighting contribution
    vec3 diffuseContrib = (1.0 - F) * diffuse(pbrInputs);
    vec3 specContrib = F * G * D / (4.0 * NdotL * NdotV);
    vec3 color = NdotL * c_light * (diffuseContrib + specContrib);

    /**
    * 4 IBL light
    */
    color += getIBLContribution(pbrInputs, n, reflection);

    //vec3 vn = v_normal*2.0+1.0;
    gl_FragColor = vec4(color,1.0);
}


