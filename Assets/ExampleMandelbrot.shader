Shader "Custom/ExampleMandelbrot" {
	Properties {
		//_Color ("Color", Color) = (1,1,1,1)
		//_MainTex ("Albedo (RGB)", 2D) = "white" {}
		_Glossiness ("Smoothness", Range(0,1)) = 0.5
		_Metallic ("Metallic", Range(0,1)) = 0.0
	}
		SubShader{
			Pass
			{
		//Tags{ "RenderType" = "Opaque" }
		//LOD 200

		CGPROGRAM

		uniform float4 GLOBALmask_xyOffset;		// ignore z and w in this float4
		uniform float4 GLOBALmask_zoom;
		uniform float4 GLOBALmask_maxIterations = float4(2000.0f,0,0,0);

		#pragma vertex vert
		#pragma fragment frag

		// Physically based Standard lighting model, and enable shadows on all light types
		//#pragma surface surf Standard fullforwardshadows

		// Use shader model 3.0 target, to get nicer looking lighting
		#pragma target 4.0
		//pragma only_renderers d3d11_9x

//pragma only_renderers d3d11

#include "extPrecision.cginc"

#define _MaxIterations 500
//#define _MaxIterations 2000
#define _IterationsModulus 2000
		float mandelbrot(float2 c, float mi)
		{
			float2 z = 0;
			float2 zNext;
			int i;
			for (i = 0; i < mi; i++)
			{
				// f(z) = z^2 + c
				zNext.x = z.x * z.x - z.y * z.y + c.x;
				zNext.y = 2 * z.x * z.y + c.y;
				z = zNext;

				// Bounded?
				if (distance(z, float2(0, 0)) > 2)
					//break;
					return i / float(mi);
			}

			return 0;
			//return i / float(mi);
		}

		// double functions needed:
		//
		// float2 split(float a) {
		//
		// float2 df64_mult(float2 a, float2 b) {
		// float2 df64_add(float2 a, float2 b) {
		//
		//  probably not needed: float2 df64_addSLOW(float2 a, float2 b) {
		//	probably not needed: float2 df64_diffSLOW(float2 a, float2 b) {
		//
		// float2 df64_diff(float2 a, float2 b) {
		//
		// float2 df64_div(float2 B, float2 A) {

		
		float3 mandelbrotRGB_double(float4 c, float mi)
		{
			const float2 dbl2 = split(2.0f);

			float2 cx = float2(c.x, c.y);
			float2 cy = float2(c.z, c.w);

			//float2 z = 0;
			float2 zx = split(0.0f);
			float2 zy = split(0.0f);

			//float2 zNext;
			float2 DBL_zNextx;
			float2 DBL_zNexty;

			for (int j = 0; j < mi; j++)
			{
				// f(z) = z^2 + c
				//zNext.x = z.x * z.x - z.y * z.y + c.x;
				//zNext.y = 2 * z.x * z.y + c.y;
				//z = zNext;

				// use double library above
				//zNext.x = z.x * z.x - z.y * z.y + c.x;
				float2 DBLzx = df64_mult(zx, zx);			// z.x * z.x
				float2 DBLzy = df64_mult(zy, zy);			// z.y * z.y
				DBL_zNextx = df64_diff(DBLzx, DBLzy);		// z.x * z.x - z.y * z.y
				DBL_zNextx = df64_add(DBL_zNextx, cx);		// z.x * z.x - z.y * z.y + c.x

				//zNext.y = 2 * z.x * z.y + c.y;
				float2 DBLzxy = df64_mult(zx, zy);			//     z.x * z.y
				DBLzxy = df64_mult(DBLzxy, dbl2);			// 2 * z.x * z.y
				DBL_zNexty = df64_add(DBLzxy, cy);

				//z = zNext;
				zx = DBL_zNextx;
				zy = DBL_zNexty;

				float2 z = float2(zx.x, zy.x);				// This assumes the x component of the doubles contain the float32 equivalent of the double.

				// Bounded?
				if (distance(z, float2(0, 0)) > 2) {

					// return a pretty color
					int i = j % _IterationsModulus;

					if (i < _IterationsModulus / 20) {
						float grey = i / (_IterationsModulus / 20.0f);
						return float3(grey, grey, grey);						// tiny is grey
					} else 
					if (i <= (_IterationsModulus / 3) ) {
						return float3(i / (_IterationsModulus /3.0f),0.0f,0.0f);			// small are red
					}
					//else if (i > (_IterationsModulus * 2 ) / 3) {
					//	return float3(0.0f, (i/3) / (_IterationsModulus /3.0f), 0.0f);	// big are blue
					else if (i >(mi * 2) / 3) {
						return float3(1.0f, 1.0f, 1.0f);			// big are white!
					}
					else {
						return float3(0.0f, 0.0f, i / float(_IterationsModulus));			// medium are green
					}
				}
			}
	
			return float3(0,0,0);												// fails are black
		}

		float3 mandelbrotRGB(float2 c, float mi)
		{
			float2 z = 0;
			float2 zNext;

			for (int j = 0; j < mi; j++)
			{
				//f(z) = z^2 + c
				zNext.x = z.x * z.x - z.y * z.y + c.x;
				zNext.y = 2 * z.x * z.y + c.y;
				z = zNext;

															// Bounded?
				if (distance(z, float2(0, 0)) > 2) {

					// return a pretty color
					int i = j % _IterationsModulus;

					if (i < _IterationsModulus / 20) {
						float grey = i / (_IterationsModulus / 20.0f);
						return float3(grey, grey, grey);						// tiny is grey
					}
					else
						if (i <= (_IterationsModulus / 3)) {
							return float3(i / (_IterationsModulus / 3.0f), 0.0f, 0.0f);			// small are red
						}
						else if (i >(_IterationsModulus * 2) / 3) {
							return float3(0.0f, (i / 3) / (_IterationsModulus / 3.0f), 0.0f);	// big are blue
						}
						else {
							return float3(0.0f, 0.0f, i / float(_IterationsModulus));			// medium are green
						}
				}
			}

			return float3(0, 0, 0);												// fails are black
		}

		struct v2f {
			float2 uv : TEXCOORD0;
			float4 pos : SV_POSITION;
		};

		v2f vert(
			float4 vertex : POSITION, // vertex position input
			float2 uv : TEXCOORD0 // first texture coordinate input
			)
		{
			v2f o;
			o.pos = UnityObjectToClipPos(vertex);
			o.uv = uv;
			return o;
		}
		
		float2 magnify(float2 xy, float2 origin, float zoom)
		{
//			float2 outxy = float2( (xy + origin ) / zoom + origin*zoom/4 );		// divide by zoom to make the range of x and y smaller!
			float2 outxy = float2((xy + origin) / zoom );		// divide by zoom to make the range of x and y smaller!
			return(outxy);
		}

		//double transx(double x, double x_min, double x_max) {
		//	return x / (m / (x_max − x_min)) + x_min;
		//}
		// source: https://www.kth.se/social/files/5504b42ff276543e4aa5f5a1/An_introduction_to_the_Mandelbrot_Set.pdf page 7
		//
		float2 trans_x(float2 dblx, float2 dblxmin, float2 dblxmax, float2 width)
		{
			float2 delta_x = df64_diff(dblxmax, dblxmin);		// x_max − x_min
			float2 m_x = df64_div(width, delta_x);				// m / (x_max − x_min)
			float2 something = df64_div(dblx, m_x);				// x / (m / (x_max − x_min))
			float2 dblOutx = df64_add(something, dblxmin);		// x / (m / (x_max − x_min)) + x_min;
			return (dblOutx);
		}

		//double transy(double y, double y_min, double y_max) {
		//	return y_max − y / (n / (y_max − y_min));
		//}
		// source: https://www.kth.se/social/files/5504b42ff276543e4aa5f5a1/An_introduction_to_the_Mandelbrot_Set.pdf page 7
		//
		float2 trans_y(float2 dbly, float2 dblymin, float2 dblymax, float2 height)
		{
			float2 delta_y = df64_diff(dblymax, dblymin);		// y_max − y_min
			float2 n_y = df64_div(height, delta_y);				// n / (y_max − y_min)
			float2 something = df64_div(dbly, n_y);				// y / (n / (y_max − y_min))
			float2 dblOuty = df64_diff(dblymax, something);		// y_max − y / (n / (y_max − y_min))
			return (dblOuty);
		}

		float4 magnify_double(float2 xy, float2 origin, float zoom)
		{
			// BEGIN GARBAGE
			/*
			float2 dblx = split(xy.x);
			float2 dbly = split(xy.y);
			float2 dblOriginx = split(origin.x);
			float2 dblOriginy = split(origin.y);

			//float2 outxy = float2((xy + origin) / zoom);		// divide by zoom to make the range of x and y smaller!
			float2 dblOutx = df64_add(dblx, dblOriginx);
			float2 dblOuty = df64_add(dbly, dblOriginy);
			dblOutx = df64_div(dblOutx, zoom);
			dblOuty = df64_div(dblOuty, zoom);
			*/
			// END GARBAGE

			float x = xy.x + origin.x;
			float y = xy.y + origin.y;

			float2 half_widthORheight = df64_div(1.0f, zoom*2);		// 1.0f is the uv range (from 0 to 1).
			float2 dblx_min = df64_diff(x, half_widthORheight);
			float2 dblx_max = df64_add(x, half_widthORheight);
			float2 dbly_min = df64_diff(y, half_widthORheight);
			float2 dbly_max = df64_add(y, half_widthORheight);

			float2 dblOutx = trans_x(x, dblx_min, dblx_max, df64_div(1.0f, zoom));// 1.0f / zoom);
			float2 dblOuty = trans_y(y, dbly_min, dbly_max, df64_div(1.0f, zoom));// 1.0f / zoom);
			return(float4(dblOutx.x,dblOutx.y,dblOuty.x,dblOuty.y));
		}

		fixed4 frag(v2f i) : SV_Target
		{
			// get rid of offset in next line: float2 fxy = magnify(i.uv.xy, GLOBALmask_xyOffset.xy+float2(-0.7,-0.5), max(GLOBALmask_zoom.x, 0.3) );
			float2 normUV = i.uv.xy + float2(-0.5f,-0.5f) + GLOBALmask_xyOffset.xy;
			//float2 fxy = magnify(i.uv.xy, GLOBALmask_xyOffset.xy, max(GLOBALmask_zoom.x, 0.3));
//			float2 fxy = magnify(normUV, float2(0.0f,0.0f), max(GLOBALmask_zoom.x, 0.3));
			float4 dblxy = magnify_double(normUV, float2(0.0f, 0.0f), max(GLOBALmask_zoom.x, 0.3));
			float mi = (GLOBALmask_maxIterations.x == 0) ? _MaxIterations : GLOBALmask_maxIterations.x;
			float3 c = mandelbrotRGB_double(dblxy, mi);
			if ( (i.uv.x > 0.49f && i.uv.x < 0.51f) && (i.uv.y > 0.49f && i.uv.y < 0.51f) ) {
			//if ((normUV.x > -0.015f && normUV.x < 0.015f) && (normUV.y > -0.015f && normUV.y < 0.015f)) {
					c = float3(i.uv.x/5, i.uv.y/5, c.b);
			}
			return fixed4(c.rgb, 0);
		}
	ENDCG
	}

	}
}
