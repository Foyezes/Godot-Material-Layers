#define SETUP_LAYER_FRAGMENT \
vec3    LAYER_BELOW_ALBEDO = vec3(0.8); \
vec3    LAYER_BELOW_NORMAL_MAP = vec3(0.5, 0.5, 1.0); \
float   LAYER_BELOW_ROUGHNESS = 1.0; \
float   LAYER_BELOW_HEIGHT = 0.5; \
float   LAYER_BELOW_AO = 1.0; \
float   LAYER_BELOW_METALLIC = 0.0; \
vec3    LAYER_BELOW_EMISSION = vec3(0.0); \
vec3    LAYER_BELOW_BENT_NORMAL = vec3(0.5, 0.5, 1.0); \
vec3    LAYER_BELOW_MESH_NORMAL_MAP = vec3(0.5, 0.5, 1.0); \
float   LAYER_BELOW_MESH_AO = 0.0; \
float   LAYER_BELOW_MESH_HEIGHT = 0.0; \
float   LAYER_BELOW_MESH_CURVATURE = 0.0; \
float   LAYER_BELOW_MESH_THICKNESS = 0.0; \
vec3    LAYER_CURRENT_ALBEDO = vec3(0.8); \
vec3    LAYER_CURRENT_NORMAL_MAP = vec3(0.5, 0.5, 1.0); \
float   LAYER_CURRENT_ROUGHNESS = 1.0; \
float   LAYER_CURRENT_HEIGHT = 0.5; \
float   LAYER_CURRENT_AO = 1.0; \
float   LAYER_CURRENT_METALLIC = 0.0; \
vec3    LAYER_CURRENT_EMISSION = vec3(0.0); \
vec3    LAYER_CURRENT_BENT_NORMAL = vec3(0.5, 0.5, 1.0); \
vec3    LAYER_CURRENT_MESH_NORMAL_MAP = vec3(0.5, 0.5, 1.0); \
float   LAYER_CURRENT_MESH_AO = 0.0; \
float   LAYER_CURRENT_MESH_HEIGHT = 0.0; \
float   LAYER_CURRENT_MESH_CURVATURE = 0.0; \
float   LAYER_CURRENT_MESH_THICKNESS = 0.0; \
vec3    LAYER_OUT_ALBEDO = vec3(0.8); \
vec3    LAYER_OUT_NORMAL_MAP = vec3(0.5, 0.5, 1.0); \
float   LAYER_OUT_ROUGHNESS = 1.0; \
float   LAYER_OUT_HEIGHT = 0.5; \
float   LAYER_OUT_AO = 1.0; \
float   LAYER_OUT_METALLIC = 0.0; \
vec3    LAYER_OUT_EMISSION = vec3(0.0); \
vec3    LAYER_OUT_BENT_NORMAL = vec3(0.5, 0.5, 1.0); \
vec3    LAYER_OUT_MESH_NORMAL_MAP = vec3(0.5, 0.5, 1.0); \
float   LAYER_OUT_MESH_AO = 0.0; \
float   LAYER_OUT_MESH_HEIGHT = 0.0; \
float   LAYER_OUT_MESH_CURVATURE = 0.0; \
float   LAYER_OUT_MESH_THICKNESS = 0.0; \
vec3    RESULT_ALBEDO = vec3(0.8); \
vec3    RESULT_NORMAL_MAP = vec3(0.5, 0.5, 1.0); \
float   RESULT_ROUGHNESS = 1.0; \
float   RESULT_HEIGHT = 0.5; \
float   RESULT_AO = 1.0; \
float   RESULT_METALLIC = 0.0; \
vec3    RESULT_EMISSION = vec3(0.0); \
vec4    LAYER_OUT_TEX_0; \
vec4    LAYER_OUT_TEX_1; \
vec4    LAYER_OUT_TEX_2; \
vec4    LAYER_OUT_TEX_3; \
vec4    LAYER_OUT_TEX_4; \
vec4    LAYER_OUT_TEX_5; \
vec4    LAYER_OUT_TEX_6; \
vec4    LAYER_OUT_TEX_7; \
vec4    LAYER_BELOW_TEX_0; \
vec4    LAYER_BELOW_TEX_1; \
vec4    LAYER_BELOW_TEX_2; \
vec4    LAYER_BELOW_TEX_3; \
vec4    LAYER_BELOW_TEX_4; \
vec4    LAYER_BELOW_TEX_5; \
vec4    LAYER_BELOW_TEX_6; \
vec4    LAYER_BELOW_TEX_7; \
float   LAYER_OUT_MASK_0; \
float   LAYER_OUT_MASK_1; \
float   LAYER_OUT_MASK_2; \
float   LAYER_OUT_MASK_3; \
float   LAYER_OUT_MASK_4; \
float   LAYER_OUT_MASK_5; \
float   LAYER_OUT_MASK_6; \
float   LAYER_OUT_MASK_7; \
float   LAYER_BELOW_MASK_0; \
float   LAYER_BELOW_MASK_1; \
float   LAYER_BELOW_MASK_2; \
float   LAYER_BELOW_MASK_3; \
float   LAYER_BELOW_MASK_4; \
float   LAYER_BELOW_MASK_5; \
float   LAYER_BELOW_MASK_6; \
float   LAYER_BELOW_MASK_7 \

#define SETUP_LAYER_VERTEX \
vec3    LAYER_OUT_VERTEX; \
vec3    LAYER_CURRENT_VERTEX; \
vec3    LAYER_BELOW_VERTEX; \
vec3    RESULT_VERTEX; \
float   LAYER_OUT_HEIGHT; \
float   LAYER_BELOW_HEIGHT; \
float   LAYER_CURRENT_HEIGHT; \
float   RESULT_HEIGHT \

struct vertexMaterial{
    vec3    layer_mat_vertex;
    float   layer_mat_height;
};

struct fragmentMaterial{
    vec3    layer_mat_albedo;
    vec3    layer_mat_normal_map;
    float   layer_mat_roughness;
    float   layer_mat_ao;
    float   layer_mat_height;
    float   layer_mat_metallic;
    vec3    layer_mat_emission;
    vec3    layer_mat_bent_normal;
    vec3    layer_mat_mesh_normal_map;
    float   layer_mat_mesh_ao;
    float   layer_mat_mesh_height;
    float   layer_mat_mesh_curvature;
    float   layer_mat_mesh_thickness;
};

struct layerData{
    vec4 mat_layer_tex_0;
    vec4 mat_layer_tex_1;
    vec4 mat_layer_tex_2;
    vec4 mat_layer_tex_3;
    vec4 mat_layer_tex_4;
    vec4 mat_layer_tex_5;
    vec4 mat_layer_tex_6;
    vec4 mat_layer_tex_7;

    float mat_layer_mask_0;
    float mat_layer_mask_1;
    float mat_layer_mask_2;
    float mat_layer_mask_3;
    float mat_layer_mask_4;
    float mat_layer_mask_5;
    float mat_layer_mask_6;
    float mat_layer_mask_7;
};

fragmentMaterial l_mixFragment(
    fragmentMaterial matA,
    fragmentMaterial matB, 
    float mask ){
    fragmentMaterial result;
    result.layer_mat_albedo = mix(matA.layer_mat_albedo, matB.layer_mat_albedo, mask);
    result.layer_mat_normal_map = mix(matA.layer_mat_normal_map, matB.layer_mat_normal_map, mask);
    result.layer_mat_bent_normal = mix(matA.layer_mat_bent_normal, matB.layer_mat_bent_normal, mask);
    result.layer_mat_roughness = mix(matA.layer_mat_roughness, matB.layer_mat_roughness, mask);
    result.layer_mat_ao = mix(matA.layer_mat_ao, matB.layer_mat_ao, mask);
    result.layer_mat_height = mix(matA.layer_mat_height, matB.layer_mat_height, mask);
    result.layer_mat_metallic = mix(matA.layer_mat_metallic, matB.layer_mat_metallic, mask);
    result.layer_mat_emission = mix(matA.layer_mat_emission, matB.layer_mat_emission, mask);
    result.layer_mat_mesh_normal_map = mix(matA.layer_mat_mesh_normal_map, matB.layer_mat_mesh_normal_map, mask);
    result.layer_mat_mesh_ao = mix(matA.layer_mat_mesh_ao, matB.layer_mat_mesh_ao, mask);
    result.layer_mat_mesh_height = mix(matA.layer_mat_mesh_height, matB.layer_mat_mesh_height, mask);
    result.layer_mat_mesh_curvature = mix(matA.layer_mat_mesh_curvature, matB.layer_mat_mesh_curvature, mask);
    result.layer_mat_mesh_thickness = mix(matA.layer_mat_mesh_thickness, matB.layer_mat_mesh_thickness, mask);
    
    return result;
}

vertexMaterial l_mixVertex(
    vertexMaterial matA,
    vertexMaterial matB, 
    float mask ){
    vertexMaterial result;
    result.layer_mat_vertex = mix(matA.layer_mat_vertex, matB.layer_mat_vertex, mask);
    result.layer_mat_height = mix(matA.layer_mat_height, matB.layer_mat_height, mask);

    return result;
}

float l_getChannel(vec4 tex, vec2 uv, int ch) {
	if (ch == 0) return tex.r;
	if (ch == 1) return tex.g;
	if (ch == 2) return tex.b;
	return tex.a;
}

vec3 l_normalCombine(vec3 n1, vec3 n2){
	return vec3(n1.rg + ((n2.rg - 0.5)), n1.z * n2.z);
}
// vec3 normalCombine(vec3 n1, vec3 n2, float mask){
//     vec2 blendedXY = n1.rg + (n2.rg - 0.5) * mask;
//     float blendedZ = mix(n1.z, n1.z * n2.z, mask);
//     return vec3(blendedXY, blendedZ);
// }
// vec3 normalStrength(vec3 normal_map_in, float normal_map_strength){
// 	vec3 normal = vec3(normal_map_in * 2.0 - 1.0);
// 	return vec3(normal.xy * normal_map_strength, normal.z) * 0.5 + 0.5;
// }
// vec3 normalInvert (vec3 normal_map){
//     return vec3(1.0 - normal_map.xy, normal_map.z);
// }
// vec3 worldNormalMap(vec3 normal_map, mat4 inv_view_matrix, vec3 tangent, vec3 binormal, vec3 normal){		
// 	normal_map = normal_map * 2.0 - 1.0;
//     vec3 tangentWS = (inv_view_matrix * vec4(tangent, 0.0)).xyz;
// 	vec3 binormalWS = vec3((inv_view_matrix * vec4(binormal, 0.0)).xyz);
// 	vec3 normalWS = vec3((inv_view_matrix * vec4(normal, 0.0)).xyz);
		
// 	mat4 TBN = mat4(vec4(tangentWS, 0.0), vec4(binormalWS, 0.0), vec4(normalWS, 0.0), vec4(0.0, 0.0, 0.0, 1.0));
// 	vec3 worldNormalMap = (TBN * vec4(normal_map, 1.0)).xyz;
//     return worldNormalMap * 0.5 + 0.5;
// }
// vec3 deriveZ(float x_in, float y_in){
//     vec2 normalXY = vec2(x_in * 2.0 - 1.0, y_in * 2.0 - 1.0);
// 	float z = sqrt(max(1.0 - dot(normalXY, normalXY), 0.0));
// 	vec3 normal = vec3(normalXY.x, normalXY.y, z);
// 	return normal * 0.5 + 0.5;
// }

// layerMaterial overlayMat(
//     layerMaterial matA,
//     layerMaterial matB, 
//     float mask ){
//     layerMaterial result;
//     result.layer_mat_albedo = mix(matA.layer_mat_albedo, matB.layer_mat_albedo, mask);
//     result.layer_mat_normal_map = normalCombine(matA.layer_mat_normal_map, matB.layer_mat_normal_map, mask);
//     result.layer_mat_roughness = mix(matA.layer_mat_roughness, matB.layer_mat_roughness, mask);
//     result.layer_mat_ao = matA.layer_mat_ao * mix(1.0, matB.layer_mat_ao, mask);
//     result.layer_mat_height = matA.layer_mat_height * mix(1.0, matB.layer_mat_height, mask);

//     result.layer_mat_metallic = mix(matA.layer_mat_metallic, matB.layer_mat_metallic, mask);
//     result.layerAlpha = mix(matA.layerAlpha, matB.layerAlpha, mask);
    
//     return result;
// }

// layerMaterial multiplyMat(
//     layerMaterial matA,
//     layerMaterial matB, 
//     float mask ){
//     layerMaterial result;
//     result.layer_mat_albedo = matA.layer_mat_albedo * matB.layer_mat_albedo * mask;
//     result.layer_mat_normal_map = matA.layer_mat_normal_map * matB.layer_mat_normal_map * mask;
//     result.layer_mat_roughness = matA.layer_mat_roughness * matB.layer_mat_roughness * mask;
//     result.layer_mat_ao = matA.layer_mat_ao * matB.layer_mat_ao * mask;
//     result.layer_mat_height = matA.layer_mat_height * matB.layer_mat_height * mask;
//     result.layer_mat_metallic = matA.layer_mat_metallic * matB.layer_mat_metallic * mask;
//     result.layerAlpha = matA.layerAlpha * matB.layerAlpha * mask;
    
//     return result;
// }

// layerMaterial addSubMat(
//     layerMaterial matA,
//     layerMaterial matB, 
//     float mask ){
//     layerMaterial result;
//     result.layer_mat_albedo = matB.layer_mat_albedo + (matA.layer_mat_albedo - .5) * 2.0 * mask;
//     result.layer_mat_normal_map = matB.layer_mat_normal_map + (matA.layer_mat_normal_map - .5) * 2.0 * mask;
//     result.layer_mat_roughness = matB.layer_mat_roughness + (matA.layer_mat_roughness - .5) * 2.0 * mask;
//     result.layer_mat_ao = matB.layer_mat_ao + (matA.layer_mat_ao - .5) * 2.0 * mask;
//     result.layer_mat_height = matB.layer_mat_height + (matA.layer_mat_height - .5) * 2.0 * mask;
//     result.layer_mat_metallic = matB.layer_mat_metallic + (matA.layer_mat_metallic - .5) * 2.0 * mask;
//     result.layerAlpha = matB.layerAlpha + (matA.layerAlpha - .5) * 2.0 * mask;
    
//     return result;
// }

// layerMaterial lightenMat(
//     layerMaterial matA,
//     layerMaterial matB, 
//     float mask ){
//     layerMaterial result;
//     result.layer_mat_albedo = mask * max(matA.layer_mat_albedo, matB.layer_mat_albedo) + (1.0 - mask) * matB.layer_mat_albedo;
//     result.layer_mat_normal_map = mask * max(matA.layer_mat_normal_map, matB.layer_mat_normal_map) + (1.0 - mask) * matB.layer_mat_normal_map;
//     result.layer_mat_roughness = mask * max(matA.layer_mat_roughness, matB.layer_mat_roughness) + (1.0 - mask) * matB.layer_mat_roughness;
//     result.layer_mat_ao = mask * max(matA.layer_mat_ao, matB.layer_mat_ao) + (1.0 - mask) * matB.layer_mat_ao;
//     result.layer_mat_height = mask * max(matA.layer_mat_height, matB.layer_mat_height) + (1.0 - mask) * matB.layer_mat_height;
//     result.layer_mat_metallic = mask * max(matA.layer_mat_metallic, matB.layer_mat_metallic) + (1.0 - mask) * matB.layer_mat_metallic;
//     result.layerAlpha = mask * max(matA.layerAlpha, matB.layerAlpha) + (1.0 - mask) * matB.layerAlpha;
    
//     return result;
// }

// layerMaterial darkenMat(
//     layerMaterial matA,
//     layerMaterial matB, 
//     float mask ){
//     layerMaterial result;
//     result.layer_mat_albedo = mask * min(matA.layer_mat_albedo, matB.layer_mat_albedo) + (1.0 - mask) * matB.layer_mat_albedo;
//     result.layer_mat_normal_map = mask * min(matA.layer_mat_normal_map, matB.layer_mat_normal_map) + (1.0 - mask) * matB.layer_mat_normal_map;
//     result.layer_mat_roughness = mask * min(matA.layer_mat_roughness, matB.layer_mat_roughness) + (1.0 - mask) * matB.layer_mat_roughness;
//     result.layer_mat_ao = mask * min(matA.layer_mat_ao, matB.layer_mat_ao) + (1.0 - mask) * matB.layer_mat_ao;
//     result.layer_mat_height = mask * min(matA.layer_mat_height, matB.layer_mat_height) + (1.0 - mask) * matB.layer_mat_height;
//     result.layer_mat_metallic = mask * min(matA.layer_mat_metallic, matB.layer_mat_metallic) + (1.0 - mask) * matB.layer_mat_metallic;
//     result.layerAlpha = mask * min(matA.layerAlpha, matB.layerAlpha) + (1.0 - mask) * matB.layerAlpha;
    
//     return result;
// }
