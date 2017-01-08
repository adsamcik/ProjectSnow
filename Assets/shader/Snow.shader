// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Custom/Snow" {

	Properties{
		_Color("Color", Color) = (1,1,1,1)
		_MainTex("Albedo (RGB)", 2D) = "white" {}
		_HeightMap("_HeightMap", 2D) = "height" {}
		_Snow("Snow", 2D) = "white" {}
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

			sampler2D _MainTex;
			sampler2D _HeightMap;
			sampler2D _Snow;

			float _Threshold;

			struct Input {
				float2 uv_MainTex;
				float2 uv_HeightMap;
				float2 uv_Snow;
			};

			fixed4 _Color;


			void surf(Input IN, inout SurfaceOutputStandard o) {
				//fixed4 c = tex2D(_MainTex, IN.uv_MainTex) + tex2D(_MainTex, IN.uv_MainTex) * _Color;
				//o.Albedo = c.rgb;
				float3 wn = WorldNormalVector(IN, o.Normal);
				fixed4 c = tex2D(_MainTex, IN.uv_MainTex);
				fixed4 h = tex2D(_HeightMap, IN.uv_HeightMap);
				fixed4 s = tex2D(_Snow, IN.uv_Snow);
				float a = h.r;
				float diff = 1 - _Threshold - a;
				if (diff >= 0 || wn.y < 0.3)
					o.Albedo = (half3)c;
				else {
					a += _Threshold / 2;
					a = a < 1 ? a : 1;
					if (wn.y < 0.5)
						o.Albedo = lerp(c, a, (wn.y - 0.3) * 5);
					else if (diff > -0.05)
						o.Albedo = lerp(c, a, -(diff*20));
					else
						o.Albedo = a;
				}
			}


			ENDCG
		}
			FallBack "Diffuse"
}
