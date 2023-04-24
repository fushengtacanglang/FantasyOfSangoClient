// Upgrade NOTE: replaced tex2D unity_Lightmap with UNITY_SAMPLE_TEX2D

// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "Raygeas/Suntail_Surfaceterrain"
{
	Properties
	{
		[SingleLineTexture][Header(Maps)][Space(10)][MainTexture]_Albedo01("Albedo01", 2D) = "white" {}
		[SingleLineTexture][Header(Maps)][Space(10)][MainTexture]_Albedo("Albedo", 2D) = "white" {}
		[SingleLineTexture][Header(Maps)][Space(10)][MainTexture]_split("split", 2D) = "white" {}
		[SingleLineTexture][Header(Maps)][Space(10)][MainTexture]_Albedo02("Albedo02", 2D) = "white" {}
		[Normal][SingleLineTexture]_Normal03("Normal03", 2D) = "bump" {}
		[Normal][SingleLineTexture]_Normal("Normal", 2D) = "bump" {}
		[Normal][SingleLineTexture]_Normal02("Normal02", 2D) = "bump" {}
		[SingleLineTexture]_MetallicSmoothness("Metallic/Smoothness", 2D) = "white" {}
		[HDR][SingleLineTexture]_Emission("Emission", 2D) = "white" {}
		_Tiling("Tiling", Float) = 1
		[Header(Settings)][Space(5)]_Color1("Color", Color) = (1,1,1,0)
		[Header(Settings)][Space(5)]_Color2("Color", Color) = (1,1,1,0)
		[Header(Settings)][Space(5)]_Color("Color", Color) = (1,1,1,0)
		[HDR]_EmissionColor("Emission", Color) = (0,0,0,1)
		_NormalScale("Normal", Float) = 1
		_Metallic("Metallic", Range( 0 , 1)) = 0
		_SurfaceSmoothness("Smoothness", Range( 0 , 1)) = 0
		_shadowcolor("shadowcolor", Color) = (0.3679245,0.3679245,0.3679245,1)
		_Occ("Occ", Range( 0 , 1)) = 0
		_LM_Power("LM_Power", Range( 0 , 15)) = 0
		[HideInInspector] _texcoord2( "", 2D ) = "white" {}
		[HideInInspector] _texcoord( "", 2D ) = "white" {}
		[HideInInspector] __dirty( "", Int ) = 1
	}

	SubShader
	{
		Tags{ "RenderType" = "Opaque"  "Queue" = "Geometry+0" }
		Cull Back
		CGINCLUDE
		#include "UnityPBSLighting.cginc"
		#include "UnityCG.cginc"
		#include "UnityStandardUtils.cginc"
		#include "UnityShaderVariables.cginc"
		#include "Lighting.cginc"
		#pragma target 3.0
		#ifdef UNITY_PASS_SHADOWCASTER
			#undef INTERNAL_DATA
			#undef WorldReflectionVector
			#undef WorldNormalVector
			#define INTERNAL_DATA half3 internalSurfaceTtoW0; half3 internalSurfaceTtoW1; half3 internalSurfaceTtoW2;
			#define WorldReflectionVector(data,normal) reflect (data.worldRefl, half3(dot(data.internalSurfaceTtoW0,normal), dot(data.internalSurfaceTtoW1,normal), dot(data.internalSurfaceTtoW2,normal)))
			#define WorldNormalVector(data,normal) half3(dot(data.internalSurfaceTtoW0,normal), dot(data.internalSurfaceTtoW1,normal), dot(data.internalSurfaceTtoW2,normal))
		#endif
		struct Input
		{
			float2 uv_texcoord;
			float2 uv2_texcoord2;
			float3 worldNormal;
			INTERNAL_DATA
			float3 worldPos;
		};

		struct SurfaceOutputCustomLightingCustom
		{
			half3 Albedo;
			half3 Normal;
			half3 Emission;
			half Metallic;
			half Smoothness;
			half Occlusion;
			half Alpha;
			Input SurfInput;
			UnityGIInput GIData;
		};

		uniform sampler2D _Emission;
		uniform float _Tiling;
		uniform float4 _EmissionColor;
		uniform float4 _shadowcolor;
		uniform float _LM_Power;
		uniform sampler2D _Normal02;
		uniform float _NormalScale;
		uniform sampler2D _split;
		uniform float4 _split_ST;
		uniform sampler2D _Normal;
		uniform sampler2D _Normal03;
		uniform sampler2D _Albedo;
		uniform float _SurfaceSmoothness;
		uniform float _Metallic;
		uniform sampler2D _MetallicSmoothness;
		uniform sampler2D _Albedo01;
		uniform float4 _Color1;
		uniform float4 _Color;
		uniform sampler2D _Albedo02;
		uniform float4 _Color2;
		uniform float _Occ;


		float4 shadowmaskcatch301( float2 LM_uv )
		{
			float4 finalColor = UNITY_SAMPLE_TEX2D( unity_ShadowMask, LM_uv );
			return finalColor;
		}


		float3 DisneyDiffuse374( float nv, float nl, float lh, float perceptualRoughness )
		{
			float3 rawDiffColor = DisneyDiffuse(nv,nl,lh,perceptualRoughness);
			return  rawDiffColor;
			 
		}


		half OneMinusReflectivityFromMetallic307( half metallic )
		{
			 half oneMinusDielectricSpec = unity_ColorSpaceDielectricSpec.a;
			 return oneMinusDielectricSpec - metallic * oneMinusDielectricSpec;
		}


		float GGX309( float3 nh, float roughness )
		{
			//1.2.直接光镜面反射部分
			// 1.2.1 D项（GGX）
			float D = GGXTerm( nh, roughness);
			 
			return D;
		}


		float SmithJointGGXVisibilityTerm311( float nl, float nv, float roughness )
		{
			// 1.2.2 G项 几何函数，遮蔽变暗一些
			// 直接光照和间接光照时的k都在逼近二分之一，只不过直接光照时这个值最小为八分之一而不是0。这是为了保证在表面绝对光滑时
			// 也会吸收一部分光线，毕竟完全不吸收光线的物体在现实中不存在
							
			float G=SmithJointGGXVisibilityTerm(nl,nv,roughness);
			return G;
		}


		float F0353( float3 Albedo, float _Metallic )
		{
			float3 F0 = lerp(unity_ColorSpaceDielectricSpec.rgb, Albedo, _Metallic);
			 
			return F0;
		}


		float FresnelTerm312( float3 F0, float lh )
		{
			float3 F=FresnelTerm(F0,lh);
			 
			return F;
		}


		float3 reflectVec426( float3 viewDir, float3 normal )
		{
			float3 reflectVec = reflect(-(viewDir), normal);
			return reflectVec;
		}


		float mip429( float mip_roughness )
		{
			half mip = mip_roughness * UNITY_SPECCUBE_LOD_STEPS;
			return mip;
		}


		float rgbm430( float3 reflectVec, half mip )
		{
			half4 rgbm = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, reflectVec, mip);
			return rgbm;
		}


		half3 iblSpecular434( half4 rgbm )
		{
			half3 iblSpecular = DecodeHDR(rgbm, unity_SpecCube0_HDR);
			return iblSpecular;
		}


		float oneMinusReflectivity455( float _Metallic )
		{
			float oneMinusReflectivity = unity_ColorSpaceDielectricSpec.a-unity_ColorSpaceDielectricSpec.a*_Metallic;
			return oneMinusReflectivity;
		}


		float3 iblSpecularResult462( float surfaceReduction, half3 iblSpecular, float3 F0, half grazingTerm, float nv )
		{
			float3 iblSpecularResult = surfaceReduction*iblSpecular*FresnelLerp(F0,grazingTerm,nv);
			return iblSpecularResult;
		}


		inline half4 LightingStandardCustomLighting( inout SurfaceOutputCustomLightingCustom s, half3 viewDir, UnityGI gi )
		{
			UnityGIInput data = s.GIData;
			Input i = s.SurfInput;
			half4 c = 0;
			float2 temp_cast_0 = (_Tiling).xx;
			float2 uv_TexCoord250 = i.uv_texcoord * temp_cast_0;
			float2 Tiling252 = uv_TexCoord250;
			float4 Emission259 = ( tex2D( _Emission, Tiling252 ) * _EmissionColor );
			float2 temp_output_278_0 = ( ( i.uv2_texcoord2 * (unity_LightmapST).xy ) + (unity_LightmapST).zw );
			float2 LM_uv301 = temp_output_278_0;
			float4 localshadowmaskcatch301 = shadowmaskcatch301( LM_uv301 );
			float temp_output_399_0 = (localshadowmaskcatch301).x;
			float clampResult439 = clamp( exp2( temp_output_399_0 ) , 0.0 , 1.0 );
			float4 temp_cast_1 = (clampResult439).xxxx;
			float4 lerpResult406 = lerp( _shadowcolor , temp_cast_1 , temp_output_399_0);
			float4 shadowmask497 = lerpResult406;
			float3 temp_output_489_0 = (UNITY_SAMPLE_TEX2D( unity_Lightmap, temp_output_278_0 )).rgb;
			float3 decodeLightMap440 = DecodeLightmap(float4( temp_output_489_0 , 0.0 ));
			float3 LMPower490 = ( decodeLightMap440 * _LM_Power );
			float2 uv_split = i.uv_texcoord * _split_ST.xy + _split_ST.zw;
			float4 tex2DNode520 = tex2D( _split, uv_split );
			float3 Normal75 = (WorldNormalVector( i , ( ( UnpackScaleNormal( tex2D( _Normal02, Tiling252 ), _NormalScale ) * tex2DNode520.a ) + ( UnpackScaleNormal( tex2D( _Normal, Tiling252 ), _NormalScale ) * tex2DNode520.g ) + ( UnpackScaleNormal( tex2D( _Normal03, Tiling252 ), _NormalScale ) * tex2DNode520.r ) ) ));
			float3 ase_worldPos = i.worldPos;
			float3 ase_worldViewDir = normalize( UnityWorldSpaceViewDir( ase_worldPos ) );
			float3 viewDir334 = ase_worldViewDir;
			float dotResult331 = dot( Normal75 , viewDir334 );
			float nv322 = max( saturate( dotResult331 ) , 1E-07 );
			float nv374 = nv322;
			#if defined(LIGHTMAP_ON) && UNITY_VERSION < 560 //aseld
			float3 ase_worldlightDir = 0;
			#else //aseld
			float3 ase_worldlightDir = normalize( UnityWorldSpaceLightDir( ase_worldPos ) );
			#endif //aseld
			float3 LightDir326 = ase_worldlightDir;
			float dotResult328 = dot( Normal75 , LightDir326 );
			float nl320 = max( saturate( dotResult328 ) , 1E-07 );
			float nl374 = nl320;
			float3 normalizeResult314 = normalize( ( ase_worldlightDir + ase_worldViewDir ) );
			float3 halfVector317 = normalizeResult314;
			float dotResult340 = dot( LightDir326 , halfVector317 );
			float lh323 = max( saturate( dotResult340 ) , 1E-07 );
			float lh374 = lh323;
			float4 tex2DNode2 = tex2D( _Albedo, Tiling252 );
			float AlbedoSmoothness267 = tex2DNode2.a;
			float Smoothness263 = ( AlbedoSmoothness267 * _SurfaceSmoothness );
			float perceptualRoughness374 = Smoothness263;
			float3 localDisneyDiffuse374 = DisneyDiffuse374( nv374 , nl374 , lh374 , perceptualRoughness374 );
			#if defined(LIGHTMAP_ON) && ( UNITY_VERSION < 560 || ( defined(LIGHTMAP_SHADOW_MIXING) && !defined(SHADOWS_SHADOWMASK) && defined(SHADOWS_SCREEN) ) )//aselc
			float4 ase_lightColor = 0;
			#else //aselc
			float4 ase_lightColor = _LightColor0;
			#endif //aselc
			float4 rawDiffColor381 = ( float4( ( localDisneyDiffuse374 * nl320 ) , 0.0 ) * ase_lightColor );
			float Metallic262 = ( _Metallic * tex2D( _MetallicSmoothness, Tiling252 ).r );
			half metallic307 = Metallic262;
			half localOneMinusReflectivityFromMetallic307 = OneMinusReflectivityFromMetallic307( metallic307 );
			float4 Albedo19 = ( ( ( tex2D( _Albedo01, Tiling252 ) * _Color1 ) * tex2DNode520.a ) + ( ( _Color * tex2DNode2 ) * tex2DNode520.g ) + ( ( tex2D( _Albedo02, Tiling252 ) * _Color2 ) * tex2DNode520.r ) );
			float4 kd366 = ( localOneMinusReflectivityFromMetallic307 * Albedo19 );
			float4 diffColor385 = ( rawDiffColor381 * kd366 );
			float dotResult343 = dot( Normal75 , halfVector317 );
			float nh324 = max( saturate( dotResult343 ) , 1E-07 );
			float3 temp_cast_5 = (nh324).xxx;
			float3 nh309 = temp_cast_5;
			float roughness309 = Smoothness263;
			float localGGX309 = GGX309( nh309 , roughness309 );
			float D355 = localGGX309;
			float nl311 = nl320;
			float nv311 = nv322;
			float roughness311 = Smoothness263;
			float localSmithJointGGXVisibilityTerm311 = SmithJointGGXVisibilityTerm311( nl311 , nv311 , roughness311 );
			float G356 = localSmithJointGGXVisibilityTerm311;
			float3 Albedo353 = Albedo19.rgb;
			float _Metallic353 = Metallic262;
			float localF0353 = F0353( Albedo353 , _Metallic353 );
			float3 temp_cast_7 = (localF0353).xxx;
			float3 F0312 = temp_cast_7;
			float lh312 = lh323;
			float localFresnelTerm312 = FresnelTerm312( F0312 , lh312 );
			float F357 = localFresnelTerm312;
			float specular360 = ( ( D355 * G356 ) * F357 );
			float4 specularcolor365 = ( ( nl320 * ( specular360 * ase_lightColor ) ) * UNITY_PI );
			float surfaceReduction462 = ( 1.0 / ( ( Smoothness263 * Smoothness263 ) + 1.0 ) );
			float3 viewDir426 = viewDir334;
			float3 normal426 = Normal75;
			float3 localreflectVec426 = reflectVec426( viewDir426 , normal426 );
			float3 reflectVec430 = localreflectVec426;
			float mip_roughness429 = ( Smoothness263 * ( 1.7 - ( Smoothness263 * 0.7 ) ) );
			float localmip429 = mip429( mip_roughness429 );
			float mip430 = localmip429;
			float localrgbm430 = rgbm430( reflectVec430 , mip430 );
			half4 temp_cast_8 = (localrgbm430).xxxx;
			half4 rgbm434 = temp_cast_8;
			half3 localiblSpecular434 = iblSpecular434( rgbm434 );
			float3 iblSpecular462 = localiblSpecular434;
			float3 F0462 = float3(1,0.5,0.4);
			float _Metallic455 = Metallic262;
			float localoneMinusReflectivity455 = oneMinusReflectivity455( _Metallic455 );
			float grazingTerm462 = saturate( ( Smoothness263 + ( 1.0 - localoneMinusReflectivity455 ) ) );
			float nv462 = nv322;
			float3 localiblSpecularResult462 = iblSpecularResult462( surfaceReduction462 , iblSpecular462 , F0462 , grazingTerm462 , nv462 );
			float4 blendOpSrc509 = float4( LMPower490 , 0.0 );
			float4 blendOpDest509 = ( ( diffColor385 + specularcolor365 ) + float4( ( ( localiblSpecularResult462 + localiblSpecularResult462 ) * _Occ ) , 0.0 ) );
			float grayscale515 = Luminance(temp_output_489_0);
			float4 lerpBlendMode509 = lerp(blendOpDest509,( blendOpSrc509 * blendOpDest509 ),grayscale515);
			c.rgb = ( Emission259 + ( shadowmask497 * ( saturate( lerpBlendMode509 )) ) ).rgb;
			c.a = 1;
			return c;
		}

		inline void LightingStandardCustomLighting_GI( inout SurfaceOutputCustomLightingCustom s, UnityGIInput data, inout UnityGI gi )
		{
			s.GIData = data;
		}

		void surf( Input i , inout SurfaceOutputCustomLightingCustom o )
		{
			o.SurfInput = i;
			o.Normal = float3(0,0,1);
		}

		ENDCG
		CGPROGRAM
		#pragma surface surf StandardCustomLighting keepalpha fullforwardshadows nolightmap  nodynlightmap nodirlightmap 

		ENDCG
		Pass
		{
			Name "ShadowCaster"
			Tags{ "LightMode" = "ShadowCaster" }
			ZWrite On
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma target 3.0
			#pragma multi_compile_shadowcaster
			#pragma multi_compile UNITY_PASS_SHADOWCASTER
			#pragma skip_variants FOG_LINEAR FOG_EXP FOG_EXP2
			#include "HLSLSupport.cginc"
			#if ( SHADER_API_D3D11 || SHADER_API_GLCORE || SHADER_API_GLES || SHADER_API_GLES3 || SHADER_API_METAL || SHADER_API_VULKAN )
				#define CAN_SKIP_VPOS
			#endif
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "UnityPBSLighting.cginc"
			struct v2f
			{
				V2F_SHADOW_CASTER;
				float4 customPack1 : TEXCOORD1;
				float4 tSpace0 : TEXCOORD2;
				float4 tSpace1 : TEXCOORD3;
				float4 tSpace2 : TEXCOORD4;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};
			v2f vert( appdata_full v )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID( v );
				UNITY_INITIALIZE_OUTPUT( v2f, o );
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( o );
				UNITY_TRANSFER_INSTANCE_ID( v, o );
				Input customInputData;
				float3 worldPos = mul( unity_ObjectToWorld, v.vertex ).xyz;
				half3 worldNormal = UnityObjectToWorldNormal( v.normal );
				half3 worldTangent = UnityObjectToWorldDir( v.tangent.xyz );
				half tangentSign = v.tangent.w * unity_WorldTransformParams.w;
				half3 worldBinormal = cross( worldNormal, worldTangent ) * tangentSign;
				o.tSpace0 = float4( worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x );
				o.tSpace1 = float4( worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y );
				o.tSpace2 = float4( worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z );
				o.customPack1.xy = customInputData.uv_texcoord;
				o.customPack1.xy = v.texcoord;
				o.customPack1.zw = customInputData.uv2_texcoord2;
				o.customPack1.zw = v.texcoord1;
				TRANSFER_SHADOW_CASTER_NORMALOFFSET( o )
				return o;
			}
			half4 frag( v2f IN
			#if !defined( CAN_SKIP_VPOS )
			, UNITY_VPOS_TYPE vpos : VPOS
			#endif
			) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				Input surfIN;
				UNITY_INITIALIZE_OUTPUT( Input, surfIN );
				surfIN.uv_texcoord = IN.customPack1.xy;
				surfIN.uv2_texcoord2 = IN.customPack1.zw;
				float3 worldPos = float3( IN.tSpace0.w, IN.tSpace1.w, IN.tSpace2.w );
				half3 worldViewDir = normalize( UnityWorldSpaceViewDir( worldPos ) );
				surfIN.worldPos = worldPos;
				surfIN.worldNormal = float3( IN.tSpace0.z, IN.tSpace1.z, IN.tSpace2.z );
				surfIN.internalSurfaceTtoW0 = IN.tSpace0.xyz;
				surfIN.internalSurfaceTtoW1 = IN.tSpace1.xyz;
				surfIN.internalSurfaceTtoW2 = IN.tSpace2.xyz;
				SurfaceOutputCustomLightingCustom o;
				UNITY_INITIALIZE_OUTPUT( SurfaceOutputCustomLightingCustom, o )
				surf( surfIN, o );
				#if defined( CAN_SKIP_VPOS )
				float2 vpos = IN.pos;
				#endif
				SHADOW_CASTER_FRAGMENT( IN )
			}
			ENDCG
		}
	}
	Fallback "Diffuse"
	CustomEditor "ASEMaterialInspector"
}
/*ASEBEGIN
Version=18912
200;294;1361;1043;6082.573;1678.24;2.471366;True;False
Node;AmplifyShaderEditor.CommentaryNode;254;-1612.259,-526.3455;Inherit;False;708.7898;344.8789;;3;252;250;248;Tiling;1,1,1,1;0;0
Node;AmplifyShaderEditor.RangedFloatNode;248;-1554.065,-371.4539;Inherit;False;Property;_Tiling;Tiling;10;0;Create;True;0;0;0;False;0;False;1;17;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;250;-1381.065,-388.4539;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.CommentaryNode;80;-2633.932,-516.5142;Inherit;False;947.0427;336.418;;4;75;256;6;396;Normal;0.6251274,0.49,0.7,1;0;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;252;-1120.067,-393.4539;Inherit;False;Tiling;-1;True;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.CommentaryNode;41;-4241.314,-517.7137;Inherit;False;1542.87;499.541;;8;255;19;267;3;1;2;537;175;Albedo01;0.5180138,0.6980392,0.4901961,1;0;0
Node;AmplifyShaderEditor.GetLocalVarNode;256;-2715.573,-439.384;Inherit;False;252;Tiling;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;175;-2921.297,-342.2237;Inherit;False;Property;_NormalScale;Normal;15;0;Create;False;0;1;Option1;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;318;-4088.348,1274.715;Inherit;False;914.7493;417.463;Comment;7;316;315;313;314;317;326;334;HalfVector;1,1,1,1;0;0
Node;AmplifyShaderEditor.SamplerNode;520;-5091.165,-818.7103;Inherit;True;Property;_split;split;2;1;[SingleLineTexture];Create;True;0;0;0;False;3;Header(Maps);Space(10);MainTexture;False;-1;None;8c3b275570c58ce4ebd8da9141e33d83;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;6;-2470.611,-425.3531;Inherit;True;Property;_Normal;Normal;6;2;[Normal];[SingleLineTexture];Create;True;0;0;0;False;0;False;-1;0d4fabb0258efd6459f6f3b864ce58ca;None;True;0;True;bump;Auto;True;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;543;-2678.32,-1055.35;Inherit;True;Property;_Normal02;Normal02;7;2;[Normal];[SingleLineTexture];Create;True;0;0;0;False;0;False;-1;0d4fabb0258efd6459f6f3b864ce58ca;None;True;0;True;bump;Auto;True;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;548;-2687.385,-1413.982;Inherit;True;Property;_Normal03;Normal03;5;2;[Normal];[SingleLineTexture];Create;True;0;0;0;False;0;False;-1;0d4fabb0258efd6459f6f3b864ce58ca;None;True;0;True;bump;Auto;True;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ViewDirInputsCoordNode;316;-3994.399,1507.578;Inherit;False;World;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.WorldSpaceLightDirHlpNode;313;-4034.348,1315.715;Inherit;True;False;1;0;FLOAT;0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;546;-2315.624,-1078.396;Inherit;True;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;549;-2322.656,-1395.902;Inherit;True;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;545;-2267.015,-819.1045;Inherit;True;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode;547;-1945.498,-909.2351;Inherit;True;3;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;255;-4219.541,-185.5925;Inherit;False;252;Tiling;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;315;-3725.399,1392.578;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SamplerNode;529;-4061.809,-1669.304;Inherit;True;Property;_Albedo02;Albedo02;3;1;[SingleLineTexture];Create;True;0;0;0;False;3;Header(Maps);Space(10);MainTexture;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;521;-4011.347,-1130.565;Inherit;True;Property;_Albedo01;Albedo01;0;1;[SingleLineTexture];Create;True;0;0;0;False;3;Header(Maps);Space(10);MainTexture;False;-1;None;d3d12a5c44f10ef49bce5c0cddb59bf8;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.NormalizeNode;314;-3573.399,1390.578;Inherit;False;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.WorldNormalVector;396;-2116.58,-445.8222;Inherit;True;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.ColorNode;531;-3951.025,-1330.953;Inherit;False;Property;_Color2;Color;12;0;Create;False;0;0;0;False;2;Header(Settings);Space(5);False;1,1,1,0;1,1,1,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;523;-3956.973,-898.2962;Inherit;False;Property;_Color1;Color;11;0;Create;False;0;0;0;False;2;Header(Settings);Space(5);False;1,1,1,0;1,1,1,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;2;-3943.279,-234.7192;Inherit;True;Property;_Albedo;Albedo;1;1;[SingleLineTexture];Create;True;0;0;0;False;3;Header(Maps);Space(10);MainTexture;False;-1;None;2b47f2696e9ccfa4cac3f18a1e969cfe;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;1;-3946.086,-468.061;Inherit;False;Property;_Color;Color;13;0;Create;False;0;0;0;False;2;Header(Settings);Space(5);False;1,1,1,0;1,1,1,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;541;-3707.982,-1455.54;Inherit;True;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;538;-3626.615,-1024.22;Inherit;True;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;334;-3731.428,1511.887;Inherit;False;viewDir;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;3;-3637.215,-464.7193;Inherit;True;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;75;-1874.751,-417.3694;Inherit;False;Normal;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;317;-3397.399,1389.578;Float;False;halfVector;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;326;-3735.328,1311.589;Float;False;LightDir;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;339;-4520.688,2089.853;Inherit;False;317;halfVector;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;539;-3348.269,-770.3505;Inherit;True;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;327;-4557.696,1838.109;Inherit;False;326;LightDir;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;335;-4513.688,1951.853;Inherit;False;334;viewDir;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;325;-4523.919,1698.779;Inherit;False;75;Normal;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;542;-3387.135,-1357.855;Inherit;True;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;537;-3358.588,-526.7886;Inherit;True;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.CommentaryNode;79;-4077.257,83.87437;Inherit;False;1376.693;541.9077;;9;242;262;241;54;268;239;257;263;240;Metallic/Smoothness;0.8,0.7843137,0.5607843,1;0;0
Node;AmplifyShaderEditor.DotProductOpNode;331;-4337.601,1924.536;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;267;-3017.612,-149.7058;Inherit;False;AlbedoSmoothness;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DotProductOpNode;343;-4250.065,2349.594;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;540;-3051.54,-794.5698;Inherit;True;3;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.DotProductOpNode;328;-4335.696,1680.109;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;257;-4042.854,296.9248;Inherit;False;252;Tiling;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;242;-3410.059,222.8964;Inherit;False;Property;_Metallic;Metallic;16;0;Create;True;0;0;0;False;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;332;-4143.599,1932.536;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;329;-4135.695,1774.109;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;345;-4097.063,2349.594;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;54;-3471.912,625.6462;Inherit;False;Property;_SurfaceSmoothness;Smoothness;17;0;Create;False;0;0;0;False;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;268;-3755.368,479.2715;Inherit;False;267;AlbedoSmoothness;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;19;-2880.679,-430.6133;Inherit;False;Albedo;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.DotProductOpNode;340;-4252.065,2232.594;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;239;-3718.599,270.9095;Inherit;True;Property;_MetallicSmoothness;Metallic/Smoothness;8;1;[SingleLineTexture];Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;347;-1624.663,1560.821;Inherit;False;19;Albedo;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.SaturateNode;342;-4099.063,2232.594;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;241;-3075.658,277.2964;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;240;-3075.657,413.2965;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMaxOpNode;333;-3968.472,1933.311;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;1E-07;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMaxOpNode;344;-3921.936,2350.37;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;1E-07;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMaxOpNode;330;-3960.569,1774.884;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;1E-07;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;372;-1429.492,1986.862;Inherit;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;322;-3774.016,1921.251;Float;False;nv;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;262;-2907.48,272.5011;Inherit;False;Metallic;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMaxOpNode;341;-3923.936,2233.37;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;1E-07;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;320;-3783.321,1770.508;Float;False;nl;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;263;-2907.48,408.5011;Inherit;False;Smoothness;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;324;-3734.016,2339.251;Float;False;nh;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;373;-1417.492,2003.862;Inherit;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;346;-1625.043,1456.341;Inherit;False;262;Metallic;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;351;-1587.543,2008.241;Inherit;False;322;nv;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;348;-1606.043,1659.341;Inherit;False;324;nh;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;349;-1618.043,1730.341;Inherit;False;263;Smoothness;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;350;-1602.043,1816.341;Inherit;False;320;nl;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;323;-3740.016,2210.251;Float;False;lh;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;368;-1457.243,1541.376;Inherit;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.CustomExpressionNode;309;-1187.599,1688.946;Float;False;//1.2.直接光镜面反射部分$// 1.2.1 D项（GGX）$$float D = GGXTerm( nh, roughness)@$ $return D@$;1;Create;2;True;nh;FLOAT3;0,0,0;In;;Float;False;True;roughness;FLOAT;0;In;;Float;False;GGX;True;False;0;;False;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;352;-1596.043,2121.341;Inherit;False;323;lh;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;418;-1836.675,2941.516;Inherit;False;803;467;Comment;6;414;415;416;417;412;413;mip_roughness;1,1,1,1;0;0
Node;AmplifyShaderEditor.CustomExpressionNode;311;-1192.047,1809.625;Float;False;// 1.2.2 G项 几何函数，遮蔽变暗一些$// 直接光照和间接光照时的k都在逼近二分之一，只不过直接光照时这个值最小为八分之一而不是0。这是为了保证在表面绝对光滑时$// 也会吸收一部分光线，毕竟完全不吸收光线的物体在现实中不存在$				$float G=SmithJointGGXVisibilityTerm(nl,nv,roughness)@$$return G@$;1;Create;3;True;nl;FLOAT;0;In;;Float;False;True;nv;FLOAT;0;In;;Float;False;True;roughness;FLOAT;0;In;;Float;False;SmithJointGGXVisibilityTerm;True;False;0;;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CustomExpressionNode;353;-1203.84,1984.141;Float;False;$float3 F0 = lerp(unity_ColorSpaceDielectricSpec.rgb, Albedo, _Metallic)@$ $return F0@$;1;Create;2;True;Albedo;FLOAT3;0,0,0;In;;Float;False;True;_Metallic;FLOAT;0;In;;Float;False;F0;True;False;0;;False;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CustomExpressionNode;312;-962.6308,2104.546;Float;False;$float3 F=FresnelTerm(F0,lh)@$ $return F@$;1;Create;2;True;F0;FLOAT3;0,0,0;In;;Float;False;True;lh;FLOAT;0;In;;Float;False;FresnelTerm;True;False;0;;False;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;412;-1786.675,2991.516;Inherit;False;263;Smoothness;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;355;-949.5454,1693.524;Inherit;False;D;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;416;-1713.675,3292.516;Inherit;False;Constant;_Float1;Float 1;12;0;Create;True;0;0;0;False;0;False;0.7;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;356;-931.8345,1803.746;Inherit;False;G;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;409;-1676.486,2655.245;Inherit;False;585.4827;234.2949;Comment;4;411;410;407;408;iblDiffuseResult;1,1,1,1;0;0
Node;AmplifyShaderEditor.WireNode;369;-1433.243,1533.376;Inherit;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;414;-1520.675,3066.516;Inherit;False;Constant;_Float0;Float 0;12;0;Create;True;0;0;0;False;0;False;1.7;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;417;-1510.675,3162.516;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;460;-982.8423,2994.963;Inherit;False;892.2344;257.9934;Comment;5;456;455;458;457;459;grazingTerm;1,1,1,1;0;0
Node;AmplifyShaderEditor.WireNode;376;-1384.826,2340.852;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;357;-784.8345,2098.746;Inherit;False;F;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;371;-997.2429,1533.376;Inherit;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.Vector4Node;273;-1458.359,1098.022;Float;False;Global;unity_LightmapST;unity_LightmapST;2;0;Fetch;True;0;0;0;False;0;False;0,0,0,0;0.1403194,0.1403194,0.6850034,0.4100685;0;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;408;-1626.486,2705.245;Inherit;False;75;Normal;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;358;-574.395,1818.933;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;370;-975.2429,1542.376;Inherit;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.CustomExpressionNode;307;-1242.039,1460.371;Half;False; half oneMinusDielectricSpec = unity_ColorSpaceDielectricSpec.a@$$ return oneMinusDielectricSpec - metallic * oneMinusDielectricSpec@$;1;Create;1;True;metallic;FLOAT;0;In;;Half;False;OneMinusReflectivityFromMetallic;True;False;0;;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;415;-1358.675,3130.516;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;276;-1473.116,919.1523;Inherit;False;1;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;456;-996.8423,3144.957;Inherit;False;262;Metallic;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;476;-737.5315,2283.111;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;454;-1020.199,2779.458;Inherit;False;689.0343;201.324;Comment;4;450;451;452;453;surfaceReduction;1,1,1,1;0;0
Node;AmplifyShaderEditor.CustomExpressionNode;374;-1258.855,2214.025;Float;False;float3 rawDiffColor = DisneyDiffuse(nv,nl,lh,perceptualRoughness)@$$return  rawDiffColor@$ ;3;Create;4;True;nv;FLOAT;0;In;;Float;False;True;nl;FLOAT;0;In;;Float;False;True;lh;FLOAT;0;In;;Float;False;True;perceptualRoughness;FLOAT;0;In;;Float;False;DisneyDiffuse;True;False;0;;False;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;359;-388.395,1899.933;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;431;-1454.421,2569.511;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SwizzleNode;274;-1177.359,1107.022;Inherit;False;FLOAT2;0;1;2;3;1;0;FLOAT4;0,0,0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.WireNode;377;-1367.826,2352.852;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;375;-879.8264,2308.852;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SwizzleNode;277;-1177.359,1219.022;Inherit;False;FLOAT2;2;3;2;3;1;0;FLOAT4;0,0,0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.WireNode;432;-1437.421,2555.511;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.LightColorNode;391;-831.8237,1951.307;Inherit;False;0;3;COLOR;0;FLOAT3;1;FLOAT;2
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;367;-901.3398,1518.629;Inherit;False;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.CustomExpressionNode;455;-806.6277,3145.01;Float;False;float oneMinusReflectivity = unity_ColorSpaceDielectricSpec.a-unity_ColorSpaceDielectricSpec.a*_Metallic@$$return oneMinusReflectivity@;1;Create;1;True;_Metallic;FLOAT;0;In;;Float;False;oneMinusReflectivity;True;False;0;;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;275;-1017.358,963.0222;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;413;-1195.675,3003.516;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;450;-970.1989,2829.458;Inherit;False;263;Smoothness;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;427;-1406.848,2474.52;Inherit;False;334;viewDir;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.WireNode;477;-680.4897,2313.914;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;360;-222.395,1899.933;Inherit;False;specular;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;361;-30.39502,1966.933;Inherit;False;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;278;-794.3588,1140.022;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.WireNode;478;-569.8269,2423.435;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;378;-636.5491,2235.539;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;458;-545.608,3138.963;Inherit;False;2;0;FLOAT;1;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;451;-768.1646,2845.782;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CustomExpressionNode;426;-1044.848,2477.52;Float;False;float3 reflectVec = reflect(-(viewDir), normal)@$$return reflectVec@;3;Create;2;True;viewDir;FLOAT3;0,0,0;In;;Float;False;True;normal;FLOAT3;0,0,0;In;;Float;False;reflectVec;True;False;0;;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.CustomExpressionNode;429;-1058.223,2610.011;Float;False;half mip = mip_roughness * UNITY_SPECCUBE_LOD_STEPS@$$return mip@;1;Create;1;True;mip_roughness;FLOAT;0;In;;Float;False;mip;True;False;0;;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;366;-742.3398,1515.629;Inherit;False;kd;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.CustomExpressionNode;430;-785.7814,2472.516;Float;False;half4 rgbm = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, reflectVec, mip)@$$return rgbm@;1;Create;2;True;reflectVec;FLOAT3;0,0,0;In;;Float;False;True;mip;FLOAT;0;In;;Half;False;rgbm;True;False;0;;False;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;383;-467.0884,2360.462;Inherit;False;366;kd;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.CustomExpressionNode;301;-659.6064,1246.621;Float;False;float4 finalColor = UNITY_SAMPLE_TEX2D( unity_ShadowMask, LM_uv )@$$return finalColor@$;4;Create;1;True;LM_uv;FLOAT2;0,0;In;;Float;False;shadowmaskcatch;True;False;0;;False;1;0;FLOAT2;0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleAddOpNode;457;-390.608,3044.963;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;381;-482.5486,2251.539;Inherit;False;rawDiffColor;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.PiNode;364;3.60498,2133.933;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;480;-446.6136,2428;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TexturePropertyNode;282;-835.6768,794.3215;Float;True;Global;unity_Lightmap;unity_Lightmap;4;0;Fetch;True;0;0;0;False;0;False;None;None;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;393;74.39685,1838.104;Inherit;False;2;2;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;452;-624.1646,2834.782;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SwizzleNode;399;-447.1008,1414.873;Inherit;False;FLOAT;0;1;2;3;1;0;FLOAT4;0,0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;299;-563.5401,787.9695;Inherit;True;Property;_TextureSample1;Texture Sample 1;14;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector3Node;475;-295.1434,2672.92;Inherit;False;Constant;_Vector0;Vector 0;14;0;Create;True;0;0;0;False;0;False;1,0.5,0.4;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.CommentaryNode;472;14.12035,2580.465;Inherit;False;723.929;384.4053;结束间接光部分;4;462;468;471;469;indirectResult;1,1,1,1;0;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;453;-483.1646,2838.782;Inherit;False;2;0;FLOAT;1;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;384;-269.0884,2261.462;Inherit;True;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SaturateNode;459;-232.2079,3047.763;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CustomExpressionNode;434;-524.0492,2464.223;Half;False;half3 iblSpecular = DecodeHDR(rgbm, unity_SpecCube0_HDR)@$$return iblSpecular@;3;Create;1;True;rgbm;FLOAT4;0,0,0,0;In;;Half;False;iblSpecular;True;False;0;;False;1;0;FLOAT4;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.WireNode;479;-337.0916,2449.676;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;363;215.605,2069.933;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.CommentaryNode;260;-2623.188,-91.06023;Inherit;False;1060.835;556.2388;;5;259;258;244;245;243;Emission;1,1,1,1;0;0
Node;AmplifyShaderEditor.SwizzleNode;489;-207.4321,771.4084;Inherit;False;FLOAT3;0;1;2;3;1;0;COLOR;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;385;-45.82352,2251.481;Inherit;False;diffColor;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;365;369.9692,2071.427;Inherit;False;specularcolor;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.WireNode;518;-239.5244,1429.172;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;389;-484.0092,1516.264;Inherit;False;624.6179;268.0212;直接光部分结束;3;388;387;386;directLightResult;1,1,1,1;0;0
Node;AmplifyShaderEditor.CustomExpressionNode;462;66.12035,2633.443;Float;False;float3 iblSpecularResult = surfaceReduction*iblSpecular*FresnelLerp(F0,grazingTerm,nv)@$$return iblSpecularResult@;3;Create;5;True;surfaceReduction;FLOAT;0;In;;Float;False;True;iblSpecular;FLOAT3;0,0,0;In;;Half;False;True;F0;FLOAT3;0,0,0;In;;Float;False;True;grazingTerm;FLOAT;0;In;;Half;False;True;nv;FLOAT;0;In;;Float;False;iblSpecularResult;True;False;0;;False;5;0;FLOAT;0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.WireNode;512;1.194946,980.1479;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;517;20.67188,886.4532;Inherit;False;Property;_LM_Power;LM_Power;20;0;Create;True;0;0;0;False;0;False;0;0;0;15;0;1;FLOAT;0
Node;AmplifyShaderEditor.Exp2OpNode;438;-340.4529,1332.606;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;442;-238.4773,1257.981;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;258;-2562.067,39.39619;Inherit;False;252;Tiling;1;0;OBJECT;;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;468;387.0493,2639.465;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;471;272.6127,2848.87;Inherit;False;Property;_Occ;Occ;19;0;Create;True;0;0;0;False;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;386;-439.9076,1556.264;Inherit;False;385;diffColor;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.DecodeLightmapHlpNode;440;13.64099,768.1995;Inherit;False;2;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;387;-434.0095,1652.285;Inherit;False;365;specularcolor;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.WireNode;443;-224.4773,1234.981;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ClampOpNode;439;-208.4529,1330.606;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;513;64.19495,991.1479;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ColorNode;403;-461.6924,1072.342;Inherit;False;Property;_shadowcolor;shadowcolor;18;0;Create;True;0;0;0;False;0;False;0.3679245,0.3679245,0.3679245,1;0.5647059,0.8,0.8509804,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SamplerNode;243;-2360.212,15.76204;Inherit;True;Property;_Emission;Emission;9;2;[HDR];[SingleLineTexture];Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;516;230.6719,830.4532;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;469;557.0493,2634.465;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ColorNode;245;-2268.63,240.7933;Inherit;False;Property;_EmissionColor;Emission;14;1;[HDR];Create;False;0;0;0;False;0;False;0,0,0,1;0,0,0,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleAddOpNode;388;-168.392,1630.838;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;473;655.8121,1659.871;Inherit;True;2;2;0;COLOR;0,0,0,0;False;1;FLOAT3;0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;244;-1987.73,134.0931;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;490;374.2849,768.7299;Float;False;LMPower;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.TFHCGrayscale;515;198.1949,958.1479;Inherit;False;0;1;0;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;406;14.09876,1157.613;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;259;-1807.939,130.5096;Inherit;False;Emission;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;497;430.927,1154.916;Inherit;False;shadowmask;-1;True;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.BlendOpsNode;509;870.4608,785.4233;Inherit;False;Multiply;True;3;0;FLOAT3;0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;1;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;502;1045.806,1155.794;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.GetLocalVarNode;485;1074.928,763.5231;Inherit;False;259;Emission;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.SaturateNode;338;-4117.063,2072.595;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CustomExpressionNode;447;-653.1927,1382.983;Float;False;float4 finalColor = UNITY_SAMPLE_TEX2D(unity_LightmapInd, LM_uv )@$$return finalColor@$;4;Create;1;True;LM_uv;FLOAT2;0,0;In;;Float;False; DIRLIGHTMAPcatch;True;False;0;;False;1;0;FLOAT2;0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;321;-3770.016,2069.251;Float;False;vh;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMaxOpNode;337;-3941.936,2073.37;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;1E-07;False;1;FLOAT;0
Node;AmplifyShaderEditor.CustomExpressionNode;407;-1418.552,2709.1;Half;False;$half3 iblDiffuse = ShadeSH9(float4(normal,1))@$ $return iblDiffuse@$;3;Create;1;True;normal;FLOAT4;0,0,0,0;In;;Float;False;ShadeSH9;True;False;0;;False;1;0;FLOAT4;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.DotProductOpNode;336;-4270.065,2072.595;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;411;-1242.352,2772.441;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.CustomExpressionNode;308;-1273.328,1566.131;Half;False;specColor = lerp (unity_ColorSpaceDielectricSpec.rgb, albedo, metallic)@$   $oneMinusReflectivity = OneMinusReflectivityFromMetallic(metallic)@$ $return albedo * oneMinusReflectivity@$;1;Create;4;True;albedo;FLOAT3;0,0,0;In;;Half;False;True;metallic;FLOAT;0;In;;Half;False;True;specColor;FLOAT3;0,0,0;Out;;Half;False;True;oneMinusReflectivity;FLOAT;0;Out;;Half;False;DiffuseAndSpecularFromMetallic;True;False;0;;False;4;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;3;FLOAT;0;FLOAT3;3;FLOAT;4
Node;AmplifyShaderEditor.GetLocalVarNode;410;-1416.352,2793.441;Inherit;False;366;kd;1;0;OBJECT;;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;483;1251.064,773.7815;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.StandardSurfaceOutputNode;519;1500.115,523.0618;Float;False;True;-1;2;ASEMaterialInspector;0;0;CustomLighting;Raygeas/Suntail_Surfaceterrain;False;False;False;False;False;False;True;True;True;False;False;False;False;False;False;False;False;False;False;False;False;Back;0;False;-1;0;False;-1;False;0;False;-1;0;False;-1;False;0;Opaque;0.5;True;True;0;False;Opaque;;Geometry;All;18;all;True;True;True;True;0;False;-1;False;0;False;-1;255;False;-1;255;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;-1;False;2;15;10;25;False;0.5;True;0;0;False;-1;0;False;-1;0;0;False;-1;0;False;-1;0;False;-1;0;False;-1;0;False;0;0,0,0,0;VertexOffset;True;False;Cylindrical;False;Relative;0;;-1;-1;-1;-1;0;False;0;0;False;-1;-1;0;False;-1;0;0;0;False;0.1;False;-1;0;False;-1;False;15;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT3;0,0,0;False;4;FLOAT;0;False;6;FLOAT3;0,0,0;False;7;FLOAT3;0,0,0;False;8;FLOAT;0;False;9;FLOAT;0;False;10;FLOAT;0;False;13;FLOAT3;0,0,0;False;11;FLOAT3;0,0,0;False;12;FLOAT3;0,0,0;False;14;FLOAT4;0,0,0,0;False;15;FLOAT3;0,0,0;False;0
WireConnection;250;0;248;0
WireConnection;252;0;250;0
WireConnection;6;1;256;0
WireConnection;6;5;175;0
WireConnection;543;1;256;0
WireConnection;543;5;175;0
WireConnection;548;1;256;0
WireConnection;548;5;175;0
WireConnection;546;0;543;0
WireConnection;546;1;520;4
WireConnection;549;0;548;0
WireConnection;549;1;520;1
WireConnection;545;0;6;0
WireConnection;545;1;520;2
WireConnection;547;0;546;0
WireConnection;547;1;545;0
WireConnection;547;2;549;0
WireConnection;315;0;313;0
WireConnection;315;1;316;0
WireConnection;529;1;255;0
WireConnection;521;1;255;0
WireConnection;314;0;315;0
WireConnection;396;0;547;0
WireConnection;2;1;255;0
WireConnection;541;0;529;0
WireConnection;541;1;531;0
WireConnection;538;0;521;0
WireConnection;538;1;523;0
WireConnection;334;0;316;0
WireConnection;3;0;1;0
WireConnection;3;1;2;0
WireConnection;75;0;396;0
WireConnection;317;0;314;0
WireConnection;326;0;313;0
WireConnection;539;0;538;0
WireConnection;539;1;520;4
WireConnection;542;0;541;0
WireConnection;542;1;520;1
WireConnection;537;0;3;0
WireConnection;537;1;520;2
WireConnection;331;0;325;0
WireConnection;331;1;335;0
WireConnection;267;0;2;4
WireConnection;343;0;325;0
WireConnection;343;1;339;0
WireConnection;540;0;539;0
WireConnection;540;1;537;0
WireConnection;540;2;542;0
WireConnection;328;0;325;0
WireConnection;328;1;327;0
WireConnection;332;0;331;0
WireConnection;329;0;328;0
WireConnection;345;0;343;0
WireConnection;19;0;540;0
WireConnection;340;0;327;0
WireConnection;340;1;339;0
WireConnection;239;1;257;0
WireConnection;342;0;340;0
WireConnection;241;0;242;0
WireConnection;241;1;239;1
WireConnection;240;0;268;0
WireConnection;240;1;54;0
WireConnection;333;0;332;0
WireConnection;344;0;345;0
WireConnection;330;0;329;0
WireConnection;372;0;347;0
WireConnection;322;0;333;0
WireConnection;262;0;241;0
WireConnection;341;0;342;0
WireConnection;320;0;330;0
WireConnection;263;0;240;0
WireConnection;324;0;344;0
WireConnection;373;0;372;0
WireConnection;323;0;341;0
WireConnection;368;0;347;0
WireConnection;309;0;348;0
WireConnection;309;1;349;0
WireConnection;311;0;350;0
WireConnection;311;1;351;0
WireConnection;311;2;349;0
WireConnection;353;0;373;0
WireConnection;353;1;346;0
WireConnection;312;0;353;0
WireConnection;312;1;352;0
WireConnection;355;0;309;0
WireConnection;356;0;311;0
WireConnection;369;0;368;0
WireConnection;417;0;412;0
WireConnection;417;1;416;0
WireConnection;376;0;350;0
WireConnection;357;0;312;0
WireConnection;371;0;369;0
WireConnection;358;0;355;0
WireConnection;358;1;356;0
WireConnection;370;0;371;0
WireConnection;307;0;346;0
WireConnection;415;0;414;0
WireConnection;415;1;417;0
WireConnection;476;0;351;0
WireConnection;374;0;351;0
WireConnection;374;1;350;0
WireConnection;374;2;352;0
WireConnection;374;3;349;0
WireConnection;359;0;358;0
WireConnection;359;1;357;0
WireConnection;431;0;408;0
WireConnection;274;0;273;0
WireConnection;377;0;376;0
WireConnection;375;0;374;0
WireConnection;375;1;377;0
WireConnection;277;0;273;0
WireConnection;432;0;431;0
WireConnection;367;0;307;0
WireConnection;367;1;370;0
WireConnection;455;0;456;0
WireConnection;275;0;276;0
WireConnection;275;1;274;0
WireConnection;413;0;412;0
WireConnection;413;1;415;0
WireConnection;477;0;476;0
WireConnection;360;0;359;0
WireConnection;361;0;360;0
WireConnection;361;1;391;0
WireConnection;278;0;275;0
WireConnection;278;1;277;0
WireConnection;478;0;477;0
WireConnection;378;0;375;0
WireConnection;378;1;391;0
WireConnection;458;1;455;0
WireConnection;451;0;450;0
WireConnection;451;1;450;0
WireConnection;426;0;427;0
WireConnection;426;1;432;0
WireConnection;429;0;413;0
WireConnection;366;0;367;0
WireConnection;430;0;426;0
WireConnection;430;1;429;0
WireConnection;301;0;278;0
WireConnection;457;0;450;0
WireConnection;457;1;458;0
WireConnection;381;0;378;0
WireConnection;480;0;478;0
WireConnection;393;0;350;0
WireConnection;393;1;361;0
WireConnection;452;0;451;0
WireConnection;399;0;301;0
WireConnection;299;0;282;0
WireConnection;299;1;278;0
WireConnection;453;1;452;0
WireConnection;384;0;381;0
WireConnection;384;1;383;0
WireConnection;459;0;457;0
WireConnection;434;0;430;0
WireConnection;479;0;480;0
WireConnection;363;0;393;0
WireConnection;363;1;364;0
WireConnection;489;0;299;0
WireConnection;385;0;384;0
WireConnection;365;0;363;0
WireConnection;518;0;399;0
WireConnection;462;0;453;0
WireConnection;462;1;434;0
WireConnection;462;2;475;0
WireConnection;462;3;459;0
WireConnection;462;4;479;0
WireConnection;512;0;489;0
WireConnection;438;0;399;0
WireConnection;442;0;518;0
WireConnection;468;0;462;0
WireConnection;468;1;462;0
WireConnection;440;0;489;0
WireConnection;443;0;442;0
WireConnection;439;0;438;0
WireConnection;513;0;512;0
WireConnection;243;1;258;0
WireConnection;516;0;440;0
WireConnection;516;1;517;0
WireConnection;469;0;468;0
WireConnection;469;1;471;0
WireConnection;388;0;386;0
WireConnection;388;1;387;0
WireConnection;473;0;388;0
WireConnection;473;1;469;0
WireConnection;244;0;243;0
WireConnection;244;1;245;0
WireConnection;490;0;516;0
WireConnection;515;0;513;0
WireConnection;406;0;403;0
WireConnection;406;1;439;0
WireConnection;406;2;443;0
WireConnection;259;0;244;0
WireConnection;497;0;406;0
WireConnection;509;0;490;0
WireConnection;509;1;473;0
WireConnection;509;2;515;0
WireConnection;502;0;497;0
WireConnection;502;1;509;0
WireConnection;338;0;336;0
WireConnection;447;0;278;0
WireConnection;321;0;337;0
WireConnection;337;0;338;0
WireConnection;407;0;408;0
WireConnection;336;0;335;0
WireConnection;336;1;339;0
WireConnection;411;0;407;0
WireConnection;411;1;410;0
WireConnection;308;0;347;0
WireConnection;308;1;346;0
WireConnection;483;0;485;0
WireConnection;483;1;502;0
WireConnection;519;13;483;0
ASEEND*/
//CHKSM=4360D78206050AFA2565585DC8D04124B66E90EC