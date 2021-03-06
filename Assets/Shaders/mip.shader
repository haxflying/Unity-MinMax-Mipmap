﻿Shader "Hidden/mip"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	}
	SubShader
	{
		// No culling or depth
		Cull Off ZWrite Off ZTest Always

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
			};

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				return o;
			}
			
			sampler2D _MainTex;
			int _miplvl;

			float3 hash3(float2 p)
			{
				float3 q = float3(dot(p, float2(127.1, 311.7)),
								dot(p, float2(269.5, 183.3)),
								dot(p, float2(419.2, 371.9)));
				return frac(sin(q)*43758.5453);
			}

			fixed4 frag (v2f i) : SV_Target
			{
				
				return fixed4(hash3(_miplvl),1);
			}
			ENDCG
		}
	}
}
