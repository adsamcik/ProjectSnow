Shader "Snow/Terrain" {
	Properties{
		_Threshold("Threshold", Range(0.0,1.0)) = 0.3
		_SnowTex("Snow", 2D) = "white" {}
		_SnowBumpMap("Snow Normal", 2D) = "bump" {}
		// set by terrain engine
		[HideInInspector] _Control("Control (RGBA)", 2D) = "red" {}
		[HideInInspector] _Splat3("Layer 3 (A)", 2D) = "white" {}
		[HideInInspector] _Splat2("Layer 2 (B)", 2D) = "white" {}
		[HideInInspector] _Splat1("Layer 1 (G)", 2D) = "white" {}
		[HideInInspector] _Splat0("Layer 0 (R)", 2D) = "white" {}
		[HideInInspector] _Normal3("Normal 3 (A)", 2D) = "bump" {}
		[HideInInspector] _Normal2("Normal 2 (B)", 2D) = "bump" {}
		[HideInInspector] _Normal1("Normal 1 (G)", 2D) = "bump" {}
		[HideInInspector] _Normal0("Normal 0 (R)", 2D) = "bump" {}
		[HideInInspector][Gamma] _Metallic0("Metallic 0", Range(0.0, 1.0)) = 0.0
		[HideInInspector][Gamma] _Metallic1("Metallic 1", Range(0.0, 1.0)) = 0.0
		[HideInInspector][Gamma] _Metallic2("Metallic 2", Range(0.0, 1.0)) = 0.0
		[HideInInspector][Gamma] _Metallic3("Metallic 3", Range(0.0, 1.0)) = 0.0
		[HideInInspector] _Smoothness0("Smoothness 0", Range(0.0, 1.0)) = 1.0
		[HideInInspector] _Smoothness1("Smoothness 1", Range(0.0, 1.0)) = 1.0
		[HideInInspector] _Smoothness2("Smoothness 2", Range(0.0, 1.0)) = 1.0
		[HideInInspector] _Smoothness3("Smoothness 3", Range(0.0, 1.0)) = 1.0

			// used in fallback on old cards & base map
		[HideInInspector] _MainTex("BaseMap (RGB)", 2D) = "white" {}
		[HideInInspector] _Color("Main Color", Color) = (1,1,1,1)
	}

		SubShader{
		Tags{
		"Queue" = "Geometry-100"
		"RenderType" = "Opaque"
	}

		CGPROGRAM
#pragma surface surf Standard vertex:SplatmapVert finalcolor:SplatmapFinalColor finalgbuffer:SplatmapFinalGBuffer fullforwardshadows

#pragma multi_compile_fog
#pragma target 3.0
			// needs more than 8 texcoords
		#pragma exclude_renderers gles
		#include "UnityPBSLighting.cginc"

		#pragma multi_compile __ _TERRAIN_NORMAL_MAP

		#define TERRAIN_STANDARD_SHADER
		#define TERRAIN_SURFACE_OUTPUT SurfaceOutputStandard
		#include "SnowTerrainSplatmap.cginc"


			half _Metallic0;
			half _Metallic1;
			half _Metallic2;
			half _Metallic3;

			half _Smoothness0;
			half _Smoothness1;
			half _Smoothness2;
			half _Smoothness3;

			float _Threshold;

			sampler2D _SnowTex;
			sampler2D _SnowBumpMap;

#define snowTex tex2D(_SnowTex, IN.uv_Splat0)
#define snowNormal UnpackNormal(tex2D(_SnowBumpMap, IN.uv_Splat0))

			void surf(Input IN, inout SurfaceOutputStandard o) {
				half4 splat_control;
				half weight;
				fixed4 mixedDiffuse;
				half4 defaultSmoothness = half4(_Smoothness0, _Smoothness1, _Smoothness2, _Smoothness3);
				SplatmapMix(IN, defaultSmoothness, splat_control, weight, mixedDiffuse, o.Normal);
				o.Albedo = mixedDiffuse.rgb;
				o.Alpha = weight;
				o.Metallic = dot(splat_control, half4(_Metallic0, _Metallic1, _Metallic2, _Metallic3));
				float3 wn = normalize(WorldNormalVector(IN, float3(0, 0, 1)));
				float diff = _Threshold - mixedDiffuse.r;
				if (diff >= 0 && _Threshold != 0 && wn.y >= 0.1) {
					if (wn.y <= 0.6) {
						diff = diff - (1 - ((wn.y - 0.1) * 2));
						if (diff < 0)
							return;
					}
					diff *= 4;

					if (diff > 0 && diff < 1) {
						float lerpValue;
						if (_Threshold >= 0.75) {
							float val = 1 + (_Threshold - 0.75) * 4;
							lerpValue = diff*val*val;
						} else
							lerpValue = diff;

						if (lerpValue > 1)
							lerpValue = 1;
						o.Albedo = lerp(o.Albedo.rgb, snowTex.rgb, lerpValue);
						o.Normal = lerp(o.Normal.rgb, snowNormal.rgb, lerpValue);
						//o.Normal = snowNormal.rgb;
						o.Smoothness = lerp(o.Smoothness, 1, lerpValue);
						o.Metallic = lerp(o.Metallic, 0, lerpValue);
					} else {
						o.Albedo = snowTex.rgb;
						o.Normal = snowNormal.rgb;
						o.Smoothness = 1;
						o.Metallic = 0;
					}
				}

			}

			ENDCG
		}

			Dependency "AddPassShader" = "Hidden/TerrainEngine/Splatmap/Standard-AddPass"
			Dependency "BaseMapShader" = "Hidden/TerrainEngine/Splatmap/Standard-Base"

			Fallback "Nature/Terrain/Diffuse"
}
