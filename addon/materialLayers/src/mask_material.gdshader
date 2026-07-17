shader_type spatial;

#include "res://addons/materialLayers/src/layer_lib.gdshaderinc"


void vertex() {
	SETUP_LAYER_VERTEX;



	// Vertex shader code goes here



	// Layer outputs - used in material layering
    RESULT_VERTEX = LAYER_CURRENT_VERTEX;
	RESULT_HEIGHT = LAYER_CURRENT_HEIGHT;
}

void fragment() {
	SETUP_LAYER_FRAGMENT;


	// Blending logic goes here

	float mask = 0.5;


	// Blend layer below and current layer and assign them to RESULT attribute
	RESULT_ALBEDO = mix(LAYER_BELOW_ALBEDO, LAYER_CURRENT_ALBEDO, mask);
    RESULT_ROUGHNESS = mix(LAYER_BELOW_ROUGHNESS, LAYER_CURRENT_ROUGHNESS, mask);
    RESULT_NORMAL_MAP = mix(LAYER_BELOW_NORMAL_MAP, LAYER_CURRENT_NORMAL_MAP, mask);
    RESULT_AO = LAYER_BELOW_AO * mix(1.0, LAYER_CURRENT_AO, mask);
	RESULT_HEIGHT = mix(LAYER_BELOW_HEIGHT, LAYER_CURRENT_HEIGHT, mask);
    RESULT_METALLIC = mix(LAYER_BELOW_METALLIC, LAYER_CURRENT_METALLIC, mask);
    RESULT_EMISSION = mix(LAYER_BELOW_EMISSION, LAYER_CURRENT_EMISSION, mask);

}