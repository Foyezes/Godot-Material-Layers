shader_type spatial;

#include "res://addons/layerForge/src/layer_lib.gdshaderinc"


void vertex() {
	SETUP_LAYER_VERTEX;



	// Vertex shader code goes here



	LAYER_OUT_HEIGHT = 0.5;
	LAYER_OUT_VERTEX = VERTEX;

	
}

void fragment() {
	SETUP_LAYER_FRAGMENT;
	

	
	// Fragment shader code goes here



	// Layer outputs - used in material layering

	LAYER_OUT_ALBEDO = vec3(0.75);
	LAYER_OUT_ROUGHNESS = 1.0;
	LAYER_OUT_NORMAL_MAP = vec3(0.5, 0.5, 1.0);
	LAYER_OUT_AO = 1.0;
	LAYER_OUT_HEIGHT = 0.5;
	LAYER_OUT_METALLIC = 0.0;
	LAYER_OUT_EMISSION = vec3(0.0);

	// Outputs for material preview and thumbnail generation
	// Not used in material layering

	ALBEDO = LAYER_OUT_ALBEDO;
	ROUGHNESS = LAYER_OUT_ROUGHNESS;
	NORMAL_MAP = LAYER_OUT_NORMAL_MAP;
	AO = LAYER_OUT_AO;
	METALLIC = LAYER_OUT_METALLIC;
	EMISSION = LAYER_OUT_EMISSION;
}