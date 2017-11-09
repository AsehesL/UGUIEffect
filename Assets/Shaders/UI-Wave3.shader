// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "UI/Wave3"
{
	Properties
	{
		[PerRendererData] _MainTex ("Sprite Texture", 2D) = "white" {}
		_Color("Tint", Color) = (1,1,1,1)
		_Height("Wave Height", float) = 0
		_Speed("Wave Speed", float) = 0
		_Range("Wave Range", float) = 0
		_FillAmount("FillAmount", range(0,1)) = 0
		_Lerp("LerpRange", float) = 1
		[KeywordEnum(Up, Bottom, Left, Right)] _Dir("Direction", float) = 0

		_EdgeColor("Edge Color", 2D) = "white" {}
		_EdgeWidth("EdgeWidth", float) = 0
		_EdgePower("EdgePower", float) = 0
		
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
			Name "Default"
		CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 2.0

			#include "UnityCG.cginc"
			#include "UnityUI.cginc"

			#pragma multi_compile __ UNITY_UI_ALPHACLIP
			#pragma shader_feature _DIR_UP _DIR_BOTTOM _DIR_LEFT _DIR_RIGHT

			fixed _Speed;
			half _FillAmount;
			fixed _Range;
			fixed _Height;

			half _Lerp;

			sampler2D _EdgeColor;
			fixed _EdgeWidth;
			fixed _EdgePower;
			
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

#if _DIR_UP
				half y = _FillAmount + _Height * sin(IN.texcoord.x * _Range + _Time.y * _Speed);
				float disalpha = saturate((y - IN.texcoord.y) / _Lerp);
				float lerpE = pow(1 - saturate((y - IN.texcoord.y) / _EdgeWidth), _EdgePower);
#elif _DIR_BOTTOM
				half y = _FillAmount + _Height * sin(IN.texcoord.x * _Range + _Time.y * _Speed);
				float disalpha = saturate((IN.texcoord.y - y) / _Lerp);
				float lerpE = pow(1 - saturate((IN.texcoord.y - y) / _EdgeWidth), _EdgePower);
#elif _DIR_LEFT
				half x = _FillAmount + _Height * sin(IN.texcoord.y * _Range + _Time.y * _Speed);
				float disalpha = saturate((x - IN.texcoord.x) / _Lerp);
				float lerpE = pow(1 - saturate((x - IN.texcoord.x) / _EdgeWidth), _EdgePower);
#else
				half x = _FillAmount + _Height * sin(IN.texcoord.y * _Range + _Time.y * _Speed);
				float disalpha = saturate((IN.texcoord.x - x) / _Lerp);
				float lerpE = pow(1 - saturate((IN.texcoord.x - x) / _EdgeWidth), _EdgePower);
#endif

				float3 emission = tex2D(_EdgeColor, float2(lerpE, 0)).rgb;
				
				color.a *= UnityGet2DClipping(IN.worldPosition.xy, _ClipRect)*disalpha;

				color.rgb += emission.rgb * lerpE;
				
				#ifdef UNITY_UI_ALPHACLIP
				clip (color.a - 0.001);
				#endif

				return color;
			}
		ENDCG
		}
	}
}
