Shader "Hidden/mip_multiTex"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	}
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
	
	sampler2D _MainTex;
	float4 _MainTex_TexelSize;

	fixed4 frag_leaf (v2f i) : SV_Target
	{
		half c0 = tex2D(_MainTex, i.uv).r;
		half c1 = tex2D(_MainTex, i.uv + float2(_MainTex_TexelSize.x, 0)).r;
		return half4(max(c0, c1), min(c0, c1), 0, 1);
	}

	fixed4 frag_node (v2f i) : SV_Target
	{
		half2 c0 = tex2D(_MainTex, i.uv).rg;
		half2 c1 = tex2D(_MainTex, i.uv + float2(_MainTex_TexelSize.x, 0)).rg;
		return half4(max(c0.r, c1.r), min(c0.g, c1.g), 0, 1);
	}
	ENDCG

	SubShader
	{
		// No culling or depth
		Cull Off ZWrite Off ZTest Always

		Pass
		{
			Name "leaf"
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag_leaf
			
			#include "UnityCG.cginc"

			
			ENDCG
		}

		Pass
		{
			Name "node"
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag_node
			
			#include "UnityCG.cginc"

			
			ENDCG
		}
	}
}
