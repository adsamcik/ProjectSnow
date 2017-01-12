Shader "Snow/Tessellation" {
	Properties{
		_Tess("Tessellation", Range(1,32)) = 4
		_MainTex("Base (RGB)", 2D) = "white" {}
		_DispTex("Displacement Texture", 2D) = "gray" {}
		_NormalMap("Normalmap", 2D) = "bump" {}
		_Displacement("Displacement", Range(0, 1.0)) = 0.3
		_DispOffset("Disp Offset", Range(0, 1)) = 0.5
		_Color("Color", color) = (1,1,1,0)
		_SpecPow("Metallic", Range(0, 1)) = 0.5
		_GlossPow("Smoothness", Range(0, 1)) = 0.5
		_Snow("Snow", 2D) = "white" {}
		_SnowNormal("Snow Normal (A)", 2D) = "bump" {}
		_Threshold("Threshold", Range(0.0,1.0)) = 0.3
		_KeepShape("Keep Shape", Range(0.0,1.0)) = 0.8
	}
		SubShader{
			Tags { "RenderType" = "Opaque" }
			LOD 300

			CGPROGRAM
			#pragma surface surf Standard addshadow fullforwardshadows vertex:disp tessellate:tessDistance
			#pragma target 5.0
			#include "Tessellation.cginc"

			struct appdata {
				float4 vertex : POSITION;
				float4 tangent : TANGENT;
				float3 normal : NORMAL;
				float2 texcoord : TEXCOORD0;
				float2 texcoord1 : TEXCOORD1;
				float2 texcoord2 : TEXCOORD2;
			};

			float _Tess;

			float4 tessDistance(appdata v0, appdata v1, appdata v2) {
				float minDist = 10.0;
				float maxDist = 25.0;
				return UnityDistanceBasedTess(v0.vertex, v1.vertex, v2.vertex, minDist, maxDist, _Tess);
			}

			sampler2D _DispTex;
			uniform float4 _DispTex_ST;
			float _Displacement;
			float _DispOffset;

			sampler2D _Snow;
			sampler2D _SnowNormal;
			float _Threshold;
			float _KeepShape;

			void disp(inout appdata v) {
				float d = tex2Dlod(_DispTex, float4(v.texcoord.xy * _DispTex_ST.xy + _DispTex_ST.zw,0,0)).r;
				if (d < _Threshold)
					d += (_Threshold - d) * _KeepShape;
				d = d *  _Displacement * 0.5 - 0.5 + _DispOffset;
				v.vertex.xyz += v.normal * d;
			}

			struct Input {
				float2 uv_MainTex;
				INTERNAL_DATA
			};

			sampler2D _MainTex;
			sampler2D _NormalMap;
			fixed4 _Color;
			float _SpecPow;
			float _GlossPow;

			#define snowTex tex2D(_Snow, IN.uv_MainTex)
			#define snowNormal tex2D(_SnowNormal, IN.uv_MainTex)

			void surf(Input IN, inout SurfaceOutputStandard o) {
				half4 c = tex2D(_MainTex, IN.uv_MainTex) * _Color;
				o.Albedo = c.rgb;
				o.Metallic = _SpecPow;
				o.Smoothness = _GlossPow;
				o.Normal = UnpackNormal(tex2D(_NormalMap, IN.uv_MainTex));

				float a = tex2D(_DispTex, IN.uv_MainTex).r;
				float diff = _Threshold * 1.1 - a;
				float3 worldNormal = WorldNormalVector(IN, float3(0, 1, 0));
				if (diff >= 0 && _Threshold != 0) {
					a += _Threshold / 2;
					a = a < 1 ? a : 1;
					/*if (wn.y == 0) {
						if (diff < -0.25)
							diff = -0.25;
						float lerpValue = (wn.y - 0.3) * 5 * (-diff * 4);
						o.Albedo = lerp(c.rgb, snowTex, lerpValue);
						o.Normal = lerp(o.Normal, snowNormal, lerpValue);
						o.Smoothness = 0;
					} else*/ if (diff > 0) {
						float lerpValue;
						if (_Threshold >= 0.75) {
							float val = 1 + (_Threshold - 0.75) * 4;
							lerpValue = (diff * 4)*val*val;
						} else
							lerpValue = diff * 4;
						if (lerpValue > 1)
							lerpValue = 1;
						o.Albedo = lerp(o.Albedo, snowTex, lerpValue);
						o.Normal = lerp(o.Normal, snowNormal, lerpValue);
						o.Smoothness = lerp(o.Smoothness, 0, lerpValue);
						o.Metallic = lerp(o.Metallic, 0, lerpValue);
					} else {
						o.Albedo = snowTex;
						o.Normal = snowNormal;
						o.Smoothness = 0;
						o.Metallic = 0;
					}
				}
			}
			ENDCG
		}
			FallBack "Diffuse"
}