// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Snow/Snow" {

	Properties{
		_Color("Color", Color) = (1,1,1,1)
		_MainTex("Albedo (RGB)", 2D) = "white" {}
		_MainTexNormal("Normal (A)", 2D) = "bump" {}
		_HeightMap("_HeightMap", 2D) = "height" {}
		_Snow("Snow", 2D) = "white" {}
		_SnowNormal("SnowNormal (A)", 2D) = "bump" {}
		_Threshold("Threshold", Range(0.0,1.0)) = 0.3
	}
		SubShader{
			Tags { "RenderType" = "Opaque" }
			LOD 200

			CGPROGRAM
			// Physically based Standard lighting model, and enable shadows on all light types
			#pragma surface surf Standard fullforwardshadows

			// Use shader model 3.0 target, to get nicer looking lighting
			#pragma target 3.0

			#define snowTex tex2D(_Snow, IN.uv_MainTex)
			#define snowNormal tex2D(_SnowNormal, IN.uv_MainTex)

			sampler2D _MainTex;
			sampler2D _MainTexNormal;
			sampler2D _HeightMap;
			sampler2D _Snow;
			sampler2D _SnowNormal;

			fixed4 _Color;

			float _Threshold;

			struct Input {
				float2 uv_MainTex;
				INTERNAL_DATA
			};


			void surf(Input IN, inout SurfaceOutputStandard o) {
				//fixed4 c = tex2D(_MainTex, IN.uv_MainTex) + tex2D(_MainTex, IN.uv_MainTex) * _Color;
				//o.Albedo = c.rgb;
				fixed4 c = tex2D(_MainTex, IN.uv_MainTex) * _Color;
				fixed4 h = tex2D(_HeightMap, IN.uv_MainTex);
				o.Smoothness = c.a;
				o.Normal = tex2D(_MainTexNormal, IN.uv_MainTex);
				float3 wn = WorldNormalVector(IN, o.Normal);
				float a = h.r;
				float diff = _Threshold * 1.1 - a;
				float3 worldNormal = WorldNormalVector(IN, float3(0, 1, 0));
				if (diff >= 0 && _Threshold != 0) {
					a += _Threshold / 2;
					a = a < 1 ? a : 1;
					if (wn.y > 0.5) {
						if (diff < -0.25)
							diff = -0.25;
						float lerpValue = (wn.y - 0.3) * 5 * (-diff * 4);
						o.Albedo = lerp(c.rgb, snowTex, lerpValue);
						o.Normal = lerp(o.Normal, snowNormal, lerpValue);
						o.Smoothness = 0;
					} else if (diff > 0) {
						float lerpValue;
						if (_Threshold >= 0.75) {
							float val = 1 + (_Threshold - 0.75) * 4;
							lerpValue = (diff * 4)*val*val;
						} else
							lerpValue = diff * 4;
						if (lerpValue > 1)
							lerpValue = 1;
						o.Albedo = lerp(c.rgb, snowTex, lerpValue);
						o.Normal = lerp(o.Normal, snowNormal, lerpValue);
						o.Smoothness = lerp(o.Smoothness, 0, lerpValue);
						o.Metallic = lerp(o.Metallic, 0, lerpValue);
					} else {
						o.Albedo = snowTex;
						o.Normal = snowNormal;
						o.Smoothness = 0;
						o.Metallic = 0;
					}
				} else {
					o.Albedo = c.rgb;
				}
			}


			ENDCG
		}
			FallBack "Diffuse"
}
