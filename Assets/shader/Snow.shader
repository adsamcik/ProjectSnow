Shader "Snow/Standard" {

	Properties{
		_Color("Color", Color) = (1,1,1,1)
		_MainTex("Albedo", 2D) = "white" {}

		_Metallic("Metalic", Range(0.0,1.0)) = 0
		_Glossiness("Smoothness", Range(0.0,1.0)) = 0
		_BumpMap("Normal Map", 2D) = "bump" {}
		_ParallaxMap("Height Map", 2D) = "height" {}
		_SnowTex("Snow", 2D) = "white" {}
		_SnowBumpMap("SnowNormal", 2D) = "bump" {}
		_Threshold("Threshold", Range(0.0,1.0)) = 0.3
		_LowerThreshold("Lower threshold", Range(0.0,1.0)) = 0
		_UpperThreshold("Upper threshold", Range(0.0,1.0)) = 1
	}
		SubShader{
			Tags { "RenderType" = "Opaque" }
			LOD 200

			CGPROGRAM
			#include "UnityPBSLighting.cginc"
			// Physically based Standard lighting model, and enable shadows on all light types
			#pragma surface surf Standard fullforwardshadows

			// Use shader model 3.0 target, to get nicer looking lighting
			#pragma target 3.0

			#define snowTex tex2D(_SnowTex, IN.uv_MainTex)
			#define snowNormal UnpackNormal(tex2D(_SnowBumpMap, IN.uv_MainTex))

			sampler2D _MainTex;
			sampler2D _BumpMap;
			sampler2D _ParallaxMap;
			sampler2D _SnowTex;
			sampler2D _SnowBumpMap;

			fixed4 _Color;

			float _Threshold, _LowerThreshold, _UpperThreshold;
			float _Glossiness;
			float _Metallic;
			float _Cutoff;

			struct Input {
				float2 uv_MainTex;
				float3 worldNormal;
				INTERNAL_DATA
			};

			float3 normalize(float3 v) {
				return rsqrt(dot(v, v))*v;
			}


			void surf(Input IN, inout SurfaceOutputStandard o) {
				half3 c = tex2D(_MainTex, IN.uv_MainTex) * _Color;
				half3 h = tex2D(_ParallaxMap, IN.uv_MainTex);
				o.Normal = UnpackNormal(tex2D(_BumpMap, IN.uv_MainTex));
				o.Smoothness = _Glossiness;
				o.Metallic = _Metallic;
				o.Albedo = c.rgb;
				float3 wn = normalize(WorldNormalVector(IN, float3(0, 0, 1)));
				float thld = _LowerThreshold + _Threshold * (_UpperThreshold - _LowerThreshold);
				float diff = thld - h.r;
				if (diff >= 0 && thld != 0 && wn.y >= 0.1) {
					if (wn.y <= 0.6) {
						diff = diff - (1-((wn.y - 0.1) * 2));
						if (diff < 0)
							return;
					}
					diff *= 4;

					if (diff > 0 && diff < 1) {
						float lerpValue;
						if (thld >= 0.75) {
							float val = 1 + (thld - 0.75) * 4;
							lerpValue = diff*val*val;
						} else
							lerpValue = diff;

						if (lerpValue > 1)
							lerpValue = 1;
						o.Albedo = lerp(c.rgb, snowTex, lerpValue);
						o.Normal = lerp(o.Normal.rgb, snowNormal.rgb, lerpValue);
						//o.Normal = snowNormal.rgb;
						o.Smoothness = lerp(o.Smoothness, 1, lerpValue);
						o.Metallic = lerp(o.Metallic, 0, lerpValue);
					} else {
						o.Albedo = snowTex;
						o.Normal = snowNormal.rgb;
						o.Smoothness = 1;
						o.Metallic = 0;
					}
				}
			}


			ENDCG
		}
			FallBack "Diffuse"
}
