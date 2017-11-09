// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "UI/Reflection"
{
	Properties
	{
		[PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" {}
		_WaveNoise("Noise", 2D) = "white" {}  //用于扭曲的噪声纹理
		_Offset("Vertex Offset", vector) = (0, 0, 0, 0)  //顶点偏移
		_Color ("Tint", Color) = (1,1,1,1)   
		_Distort("Distort", float) = 1.0    //扭曲强度
		_SampOffset ("SampleOffset", float) = 0.0   //噪声纹理采样偏移
		_Speed ("WaveSpeed", float) = 1.0   //水波速度
		_AlphaFadeIn ("AlphaFadeIn", float) = 0.0    //透明度淡入
		_AlphaFadeOut ("AlphaFadeOut", float) = 1.0   //透明度淡出
		_DistortFadeIn ("DistortFadeIn", float) = 1.0    //扭曲淡入
		_DistortFadeOut ("DistortFadeOut", float) = 1.0    //扭曲淡出
		_DistortFadeInStrength ("DistortFadeInStrength", float) = 1.0   //扭曲淡入时强度
		_DistortFadeOutStrength("DistortFadeOutStrength ", float) = 1.0   //扭曲淡出时强度
		
		_StencilComp ("Stencil Comparison", Float) = 8
		_Stencil ("Stencil ID", Float) = 0
		_StencilOp ("Stencil Operation", Float) = 0
		_StencilWriteMask ("Stencil Write Mask", Float) = 255
		_StencilReadMask ("Stencil Read Mask", Float) = 255

		_ColorMask ("Color Mask", Float) = 15

		[Toggle(UNITY_UI_ALPHACLIP)] _UseUIAlphaClip ("Use Alpha Clip", Float) = 0
	}

	SubShader
	{
		Tags
		{ 
			"Queue"="Transparent" 
			"IgnoreProjector"="True" 
			"RenderType"="Transparent" 
			"PreviewType"="Plane"
			"CanUseSpriteAtlas"="True"
		}
		
		Stencil
		{
			Ref [_Stencil]
			Comp [_StencilComp]
			Pass [_StencilOp] 
			ReadMask [_StencilReadMask]
			WriteMask [_StencilWriteMask]
		}

		Cull Off
		Lighting Off
		ZWrite Off
		ZTest [unity_GUIZTestMode]
		Blend SrcAlpha OneMinusSrcAlpha
		ColorMask [_ColorMask]

		Pass
		{
			Name "UIReflection"
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 2.0

			#include "UnityCG.cginc"
			#include "UnityUI.cginc"

			#pragma multi_compile __ UNITY_UI_ALPHACLIP
			
			struct appdata_t
			{
				float4 vertex   : POSITION;
				float4 color    : COLOR;
				float2 texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct v2f
			{
				float4 vertex   : SV_POSITION;
				fixed4 color    : COLOR;
				float2 texcoord  : TEXCOORD0;
				float4 worldPosition : TEXCOORD1;
				UNITY_VERTEX_OUTPUT_STEREO
			};
			
			fixed4 _Color;
			fixed4 _TextureSampleAdd;
			float4 _ClipRect;

			v2f vert(appdata_t IN)
			{
				v2f OUT;
				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);
				OUT.worldPosition = IN.vertex;
				OUT.vertex = UnityObjectToClipPos(OUT.worldPosition);

				OUT.texcoord = IN.texcoord;
				
				OUT.color = IN.color * _Color;
				return OUT;
			}

			sampler2D _MainTex;

			fixed4 frag(v2f IN) : SV_Target
			{
				half4 color = (tex2D(_MainTex, IN.texcoord) + _TextureSampleAdd) * IN.color;
				
				color.a *= UnityGet2DClipping(IN.worldPosition.xy, _ClipRect);
				
				#ifdef UNITY_UI_ALPHACLIP
				clip (color.a - 0.001);
				#endif

				return color;
			}
			ENDCG
		}
		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 2.0

			#include "UnityCG.cginc"
			#include "UnityUI.cginc"

			#pragma multi_compile __ UNITY_UI_ALPHACLIP

			struct appdata_t
			{
				float4 vertex   : POSITION;
				float4 color    : COLOR;
				float2 texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct v2f
			{
				float4 vertex   : SV_POSITION;
				fixed4 color : COLOR;
				float2 texcoord  : TEXCOORD0;
				float4 worldPosition : TEXCOORD1;
				UNITY_VERTEX_OUTPUT_STEREO
			};

			fixed4 _Color;
			fixed4 _TextureSampleAdd;
			float4 _ClipRect;

			float4 _Offset;
			half _Speed;
			half _Distort;
			half _SampOffset;
			float _AlphaFadeIn;
			float _AlphaFadeOut;
			half _DistortFadeIn;
			half _DistortFadeOut;
			fixed _DistortFadeInStrength;
			fixed _DistortFadeOutStrength;

			v2f vert(appdata_t IN)
			{
				v2f OUT;
				IN.vertex = IN.vertex - half4(_Offset.xyz, 0);
				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);
				OUT.worldPosition = IN.vertex;
				OUT.vertex = UnityObjectToClipPos(OUT.worldPosition);

				OUT.texcoord = IN.texcoord;

				OUT.color = IN.color * _Color;
				return OUT;
			}

			sampler2D _MainTex;
			sampler2D _WaveNoise;

			fixed4 frag(v2f IN) : SV_Target
			{
				fixed fadeD = saturate((_DistortFadeOut - IN.texcoord.y) / (_DistortFadeOut - _DistortFadeIn));
				fixed2 duv = (IN.texcoord - fixed2(0.5, 0)) * fixed2(lerp(_DistortFadeOutStrength, _DistortFadeInStrength, fadeD), 1) + fixed2(0.5, 0);

				fixed waveL = tex2D(_WaveNoise, duv + fixed2(_SampOffset, _Time.y * _Speed)).r;
				fixed waveR = tex2D(_WaveNoise, duv + fixed2(-_SampOffset, _Time.y * _Speed)).r;
				fixed waveU = tex2D(_WaveNoise, duv + fixed2(0, _Time.y * _Speed + _SampOffset)).r;
				fixed waveD = tex2D(_WaveNoise, duv + fixed2(0, _Time.y * _Speed - _SampOffset)).r;
				fixed2 uv = fixed2(IN.texcoord.x, 1 - IN.texcoord.y) + fixed2(waveL - waveR, waveU - waveD) * _Distort;

				half4 color = (tex2D(_MainTex, uv) + _TextureSampleAdd) * IN.color;

				fixed fadeA = saturate((_AlphaFadeOut - uv.y) / (_AlphaFadeOut - _AlphaFadeIn));

				color.a *= UnityGet2DClipping(IN.worldPosition.xy, _ClipRect)*fadeA;

#ifdef UNITY_UI_ALPHACLIP
				clip(color.a - 0.001);
#endif

				return color;
			}
			ENDCG
		}
	}
}
