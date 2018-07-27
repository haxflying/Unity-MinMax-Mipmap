Shader "Hidden/mip_sampler"
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

			sampler2D sm_mip_0, sm_mip_1, sm_mip_2, sm_mip_3, sm_mip_4,
			sm_mip_5, sm_mip_6, sm_mip_7, sm_mip_8, sm_mip_9;

			int _miplvl;

			fixed4 frag (v2f i) : SV_Target
			{
				fixed col = 0;
				if(_miplvl == 0)
					col = tex2D(sm_mip_0, i.uv);
				else if(_miplvl == 1)
					col = tex2D(sm_mip_1, i.uv);
				else if(_miplvl == 2)
					col = tex2D(sm_mip_2, i.uv);
				else if(_miplvl == 3)
					col = tex2D(sm_mip_3, i.uv);
				else if(_miplvl == 4)
					col = tex2D(sm_mip_4, i.uv);
				else if(_miplvl == 5)
					col = tex2D(sm_mip_5, i.uv);
				else if(_miplvl == 6)
					col = tex2D(sm_mip_6, i.uv);
				else if(_miplvl == 7)
					col = tex2D(sm_mip_7, i.uv);
				else if(_miplvl == 8)
					col = tex2D(sm_mip_8, i.uv);
				else if(_miplvl == 9)
					col = tex2D(sm_mip_9, i.uv);
				return col;
			}
			ENDCG
		}
	}
}
