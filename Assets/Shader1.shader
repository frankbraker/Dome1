// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Custom/Shader1" {
	
	Properties
	{
		_MainTex("Texture",2D) = "white" {}
		_SecondTex("Tex2",2D) = "white" {}
		_Color ("Color", Color) = (1,1,1,1)
		_TextureTween ("TextureTween", Range(0,1)	)=0
		//	_MainTex ("Albedo (RGB)", 2D) = "white" {}
		//	_Glossiness ("Smoothness", Range(0,1)) = 0.5
		//	_Metallic ("Metallic", Range(0,1)) = 0.0
	}
		
	SubShader
	{
		Tags
		{
			"Queue" = "Transparent"
		}
		Pass
		{
		//Blend One One
		Blend SrcAlpha OneMinusSrcAlpha
		//Tags { "RenderType"="Opaque" }
		//LOD 200

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
			float4 vertex : SV_POSITION;
			float2 uv : TEXCOORD0;
		};

		v2f vert(appdata v)
		{
			v2f o;
			o.vertex = UnityObjectToClipPos(v.vertex);
			o.uv = v.uv;
			return o;
		}

		sampler2D _MainTex;
		sampler2D _SecondTex;
		half _TextureTween;

		float4 frag(v2f i) : SV_Target
		{
			// i.uv.r = x (0 = left)
			// i.uv.g = y (0 = bottom)
			//
			//return float4(i.uv.x,i.uv.y,1,0);
			float4 color = tex2D(_MainTex, i.uv);
			float4 color2 = tex2D(_SecondTex, i.uv);

			float4 final = color;
			// apply TextureTween
			final.r = final.r * _TextureTween + color2.r * (1-_TextureTween);
			final.g = final.g * _TextureTween + color2.g * (1 - _TextureTween);
			final.b = final.b * _TextureTween + color2.b * (1 - _TextureTween);
			final.a = final.a * _TextureTween + color2.a * (1 - _TextureTween);

			// apply UV RGB mixing
			final.r = final.r + i.uv.x;
			//if (final.r > 1) final.r = 1;
			final.g = final.g + i.uv.y;
			//if (final.g > 1) final.g = 1;
			final.b = final.b + 0;
			//if (final.b > 1) final.b = 1;
			return final;
		}
		ENDCG
		}
	}
}
