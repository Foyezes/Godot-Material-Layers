[<img target="newtab" src="https://github.com/user-attachments/assets/89491dd0-aa9b-42ca-b2a0-c58ab701ddf4">](https://store.godotengine.org)

Material Layers is a Godot plugin that lets you blend materials using a layer based system.
--- GIF ---
Unlike traditional materials where you have to blend desired materials in a single shader, Material Layers allows you to easily blend multiple materials in the inspector. This workflow drastically reduces time required to blend multiple materials, allowing for a more iterative and easy to use experience.

## Why Material Layers
Material Layers lets you create what would otherwise be an overly complicated material, using smaller and reusable materials. This creates a more manageable system with reduced complexity, more control and flexibility.

## How does it work
Material Layers introduces 4 new resources.
- <img align="absmiddle" width="20" height="20" alt="layerStack_32x32" src="https://github.com/user-attachments/assets/0c440670-5882-49cd-b9ae-36310021d41e" /> **`LayerStack`**: Contains MaterialLayer resource and generates final material.
- <img align="absmiddle" width="20" height="20" alt="materialLayer_32x32" src="https://github.com/user-attachments/assets/197ea74f-c1fe-47ee-9e57-f16dc21e5966" />**`MaterialLayer`**: Contains SurfaceMaterial & mask texture or MaskMaterial.
- <img align="absmiddle" width="20" height="20" alt="surfaceMaterial_32x32" src="https://github.com/user-attachments/assets/cf61462d-f4e5-4abe-bd60-c375aa19f184" />**`SurfaceMaterial`**: Material that's blended using mask texture or `MaskMaterial`. Contains a `.gdshader` template with new layer specific inputs & outputs. You write your own material, then output them using the new output tokens.
- <img align="absmiddle" width="20" height="20" alt="maskMaterial_32x32" src="https://github.com/user-attachments/assets/5253218e-fb3f-4aca-ae5e-ff152722733d" />**`MaskMaterial`**: Material used to blend `SurfaceMaterial`s. You write your own blending logic such as height blending, vertex colors or sample textures. You control how each material attribute is blended.

## Quick Start
### <img align="absmiddle" width="20" height="20" alt="surfaceMaterial_32x32" src="https://github.com/user-attachments/assets/cf61462d-f4e5-4abe-bd60-c375aa19f184" /> Writing SurfaceMaterials
Create a new `SurfaceMaterial`, you can create it from the file system dock, a material slot or inside a `MaterialLayer`. `SurfaceMaterial` functions the same as a ShaderMaterial, the only difference is it contains a `.gdshader` template for writing Material Layer shaders. You write material shaders in gdshader as usual. But instead of writing to `ALBEDO`, `ROUGHNESS` etc. you write to layer-specific outputs such as `LAYER_OUT_ALBEDO`, `LAYER_OUT_ROUGHNESS`. [See all tokens](#new-tokens)

```gdshader

#include "res://addons/materialLayers/src/layer_lib.gdshaderinc" // Essential for Material Layering

void fragment() {

	SETUP_LAYER_FRAGMENT; // Sets up Material Layering

	//-------------------------------------

    vec2 uv = getUV(UVSelect, UV, UV2, custom0, custom1, custom2);
    uv *= UVScale;
    uv = uvManip(uv, vec2(UVScale), UVRot, pivot, UVOffset);

	vec4 norm_ao_height = texture(normAOHeight, uv);
    vec3 albedo = texture(albedoGradient, vec2(norm_ao_height.a, 0.5)).rgb;

	float roughness = histRange(1.0 - norm_ao_height.a, roughnessRange, roughnessPos);
    roughness = mix(roughness, 1.0 - roughness, float(invertRoughness));
    roughness = saturate(roughness);
	
    vec3 normal = deriveZ(norm_ao_height.r, norm_ao_height.g);
	float ao = norm_ao_height.b;
	float height = norm_ao_height.a;

	albedo *= tint;
	albedo = albedo * (albedoBrightness + 1.0);
	albedo = (albedo - 0.5) * max(albedoContrast + 1.0, 0.0) + 0.5;
	albedo = clamp(albedo, 0.0, 1.0);

	normal = normalStrength(normal, normalIntensity);

	ao += aoLevel;
	ao = clamp(ao, 0.0, 1.0);

	//------------ Outputs Layer Attributes --------------

	LAYER_OUT_ALBEDO = albedo;
	LAYER_OUT_ROUGHNESS = roughness;
	LAYER_OUT_NORMAL_MAP = normal;
	LAYER_OUT_AO = ao;
	LAYER_OUT_HEIGHT = height;

	//------------ Default Material Outputs --------------

	ALBEDO = albedo;
	ROUGHNESS = roughness;
	NORMAL_MAP = normal;
	AO = ao;

}
```

Keep in mind, you can still write to the default `ALBEDO`, `ROUGHNESS` and use it as a standalone material. It's also needed to generate preview thumbnails.

### <img align="absmiddle" width="20" height="20" alt="maskMaterial_32x32" src="https://github.com/user-attachments/assets/5253218e-fb3f-4aca-ae5e-ff152722733d" /> Writing MaskMaterials

`MaskMaterial` lets you blend materials using your own logic in `.gdshader`. You can control how each material attribute is blended, use height blending, vertex colors, position and normal based etc. You are free to do whatever you want, because it's essentially `gdshader` with some new tokens.

```gdshader
#include "res://addons/materialLayers/src/layer_lib.gdshaderinc" // Essential for Material Layering

void fragment() {
    
    SETUP_LAYER_FRAGMENT; // Sets up Material Layering

    //-------------------------------------

    float vertex_color = getChannel(COLOR, vertexColor);

    float mask = heightBlend(
        mix(1.0 - LAYER_BELOW_HEIGHT,
        LAYER_BELOW_HEIGHT, float(invertHeight)),
        LAYER_CURRENT_HEIGHT, heightOffset,
        heightContrast, vertex_color);

    //------------ Blend the Layer Below and the Current Layer --------------

    RESULT_ALBEDO = mix(LAYER_BELOW_ALBEDO, LAYER_CURRENT_ALBEDO, mask);
    RESULT_ROUGHNESS = mix(LAYER_BELOW_ROUGHNESS, LAYER_CURRENT_ROUGHNESS, mask);
    RESULT_NORMAL_MAP = normalCombine(LAYER_BELOW_NORMAL_MAP, LAYER_CURRENT_NORMAL_MAP, mask);
    RESULT_AO = LAYER_BELOW_AO * mix(1.0, LAYER_CURRENT_AO, mask);
    RESULT_HEIGHT = LAYER_BELOW_HEIGHT;
    RESULT_METALLIC = mix(LAYER_BELOW_METALLIC, LAYER_CURRENT_METALLIC, mask);

}
```

Both `SurfaceMaterial` and `MaskMaterial` must have the `#include` at the top, and `SETUP_LAYER_FRAGMENT` at the top of fragment shader and `SETUP_LAYER_VERTEX` at the top of vertex shader.

### Blending Two SurfaceMaterials
Create a new `LayerStack` from the material slot.

<img align="top" width="440" height="auto" alt="layerStack1" src="https://github.com/user-attachments/assets/30d55c98-9597-46c8-a87e-d4d5cf1832ee" />
<img align="top" width="440" height="auto" alt="layerStack2" src="https://github.com/user-attachments/assets/0757b1dc-a8ac-4d2b-b2a8-a0251a681e3a" />


Assign a `SurfaceMaterial` to the `Base Layer` slot.

<img align="top" width="440" height="auto" alt="baseLayer" src="https://github.com/user-attachments/assets/b625859e-e289-4d18-bc72-63dc7db9d982" />
<img width="1920" height="988" alt="baseLayerMat" src="https://github.com/user-attachments/assets/fca57913-492a-4a3c-95f0-25de59d7036d" />

Then create a new `Material Layer` and assign a different `SurfaceMaterial` to the Surface Material slot.

<img align="top" width="440" height="auto" alt="materialLayer1" src="https://github.com/user-attachments/assets/65c9481b-5040-4b8b-8a58-e3ccc5db117e" />
<img align="top" width="440" height="auto" alt="materialLayer2" src="https://github.com/user-attachments/assets/5384e47a-187a-493d-a6ab-05332d81234a" />

You can either use a mask texture or a `MaskMaterial`.
 
<img width="1668" height="auto" alt="textureMask" src="https://github.com/user-attachments/assets/909b0351-abd8-4288-997a-fa24555d8525" />
<img width="1920" height="986" alt="maskMaterial" src="https://github.com/user-attachments/assets/f1f03290-d2c0-4feb-b360-3858488fd7f7" />

### New Tokens
This plugin introduces some new Macros and Tokens used for Material Layering.
#### SurfaceMaterial Tokens
Surface Map Tokens

| `LAYER_OUT`                    | `LAYER_BELOW`                     |
| ------------------------------ | --------------------------------- |
| Outputs the layer's attributes | Gets the layer below's attributes |
| `LAYER_OUT_ALBEDO`             | `LAYER_BELOW_ALBEDO`              |
| `LAYER_OUT_NORMAL_MAP`         | `LAYER_BELOW_NORMAL_MAP`          |
| `LAYER_OUT_ROUGHNESS`          | `LAYER_BELOW_ROUGHNESS`           |
| `LAYER_OUT_HEIGHT`             | `LAYER_BELOW_HEIGHT`              |
| `LAYER_OUT_AO`                 | `LAYER_BELOW_AO`                  |
| `LAYER_OUT_METALLIC`           | `LAYER_BELOW_METALLIC`            |
| `LAYER_OUT_EMISSION`           | `LAYER_BELOW_EMISSION`            |

Mesh Map Tokens

| `LAYER_OUT_BENT_NORMAL`     | `LAYER_BELOW_BENT_NORMAL`     |
| --------------------------- | ----------------------------- |
| `LAYER_OUT_MESH_NORMAL_MAP` | `LAYER_BELOW_MESH_NORMAL_MAP` |
| `LAYER_OUT_MESH_AO`         | `LAYER_BELOW_MESH_AO`         |
| `LAYER_OUT_MESH_HEIGHT`     | `LAYER_BELOW_MESH_HEIGHT`     |
| `LAYER_OUT_MESH_CURVATURE`  | `LAYER_BELOW_MESH_CURVATURE`  |
| `LAYER_OUT_MESH_THICKNESS`  | `LAYER_BELOW_MESH_THICKNESS`  |


#### MaskMaterial Tokens
Surface Map Tokens

| `LAYER_CURRENT`                     | `LAYER_BELOW`                     | `RESULT`                   |
| ----------------------------------- | --------------------------------- | -------------------------- |
| Gets the current layer's attributes | Gets the layer below's attributes | Outputs the blended result |
| `LAYER_CURRENT_ALBEDO`              | `LAYER_BELOW_ALBEDO`              | `RESULT_ALBEDO`            |
| `LAYER_CURRENT_NORMAL_MAP`          | `LAYER_BELOW_NORMAL_MAP`          | `RESULT_NORMAL_MAP`        |
| `LAYER_CURRENT_ROUGHNESS`           | `LAYER_BELOW_ROUGHNESS`           | `RESULT_ROUGHNESS`         |
| `LAYER_CURRENT_HEIGHT`              | `LAYER_BELOW_HEIGHT`              | `RESULT_HEIGHT`            |
| `LAYER_CURRENT_AO`                  | `LAYER_BELOW_AO`                  | `RESULT_AO`                |
| `LAYER_CURRENT_METALLIC`            | `LAYER_BELOW_METALLIC`            | `RESULT_METALLIC`          |
| `LAYER_CURRENT_EMISSION`            | `LAYER_BELOW_EMISSION`            | `RESULT_EMISSION`          |
|                                     |                                   |                            |
#### Texture and Mask Tokens
You can assign textures to the TEX tokens and masks to the MASK tokens.
These are meant to be used for passing arbitrary texture data such as noise and masks.

| Output textures   | Get below layer's texture | Output masks       | Get below layer's masks  |
| ----------------- | ------------------------- | ------------------ | ------------------------ |
| `LAYER_OUT_TEX_0` | `LAYER_BELOW_TEX_0`       | `LAYER_OUT_MASK_0` | `LAYER_BELOW_MASK_0`     |
| `LAYER_OUT_TEX_1` | `LAYER_BELOW_TEX_1`       | `LAYER_OUT_MASK_1` | `LAYER_BELOW_MASK_1` |
| `LAYER_OUT_TEX_2` | `LAYER_BELOW_TEX_2`       | `LAYER_OUT_MASK_2` | `LAYER_BELOW_MASK_2` |
| `LAYER_OUT_TEX_3` | `LAYER_BELOW_TEX_3`       | `LAYER_OUT_MASK_3` | `LAYER_BELOW_MASK_3` |
| `LAYER_OUT_TEX_4`  | `LAYER_BELOW_TEX_4`       | `LAYER_OUT_MASK_4` | `LAYER_BELOW_MASK_4` |
| `LAYER_OUT_TEX_5`  | `LAYER_BELOW_TEX_5`       | `LAYER_OUT_MASK_5` | `LAYER_BELOW_MASK_5` |
| `LAYER_OUT_TEX_6` | `LAYER_BELOW_TEX_6`       | `LAYER_OUT_MASK_6` | `LAYER_BELOW_MASK_6` |
| `LAYER_OUT_TEX_7` | `LAYER_BELOW_TEX_7`       | `LAYER_OUT_MASK_7` | `LAYER_BELOW_MASK_7`> |

