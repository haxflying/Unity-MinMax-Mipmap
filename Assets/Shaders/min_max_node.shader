Shader "Hidden/min_max_node"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	}
	

	SubShader
	{
		CGINCLUDE
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

		Texture2D _MainTex;
		SamplerState sampler_MainTex;

		fixed4 frag_node (v2f i) : SV_Target
		{
			float4 r = _MainTex.GatherRed(sampler_MainTex, i.uv);
			float4 g = _MainTex.GatherGreen(sampler_MainTex, i.uv);

			float maxc = max(max(r.x, r.y), max(r.z,r.w));
			float minc = min(min(g.x, g.y), min(g.z, g.w));

			return half4(maxc, minc, 0, 0);
		}

		fixed4 frag_leaf (v2f i) : SV_Target
		{
			float4 c = _MainTex.GatherRed(sampler_MainTex, i.uv);

			float maxc = max(max(c.x, c.y), max(c.z,c.w));
			float minc = min(min(c.x, c.y), min(c.z, c.w));

			return half4(maxc, minc, 0, 0);
		}
		ENDCG
		// No culling or depth
		Cull Off ZWrite Off ZTest Always

		Pass
		{
			Name "leaf"
			CGPROGRAM
			#pragma target 4.5
			#pragma vertex vert
			#pragma fragment frag_leaf
			
			#include "UnityCG.cginc"


			ENDCG
		}

		Pass
		{
			Name "node"
			CGPROGRAM
			#pragma target 4.5
			#pragma vertex vert
			#pragma fragment frag_node			
			
			#include "UnityCG.cginc"


			ENDCG
		}
	}
}
