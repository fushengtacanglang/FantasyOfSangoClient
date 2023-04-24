Shader "Custom/myPBR"
{
	Properties
	{
		_Tint("Tint",Color)=(1,1,1,1)
		_MainTex ("Texture", 2D) = "white" {}
		//������Ҫ����gama�����򼴱���linear�ռ�����Ⱦ��unityҲ�����һ��������������
		[Gamma]_Metallic("Metallic",Range(0,1))=0
		_MetallicGlossMap("Metallic", 2D) = "white" {}
		_Smoothness("Smoothness(Metallic.a)",Range(0,1))=0.5
		_BumpMap("Normal Map", 2D) = "bump" {}
		_Parallax ("Height Scale", Range (0.00, 0.08)) = 0.0
        _ParallaxMap ("Height Map", 2D) = "black" {}
		_OcclusionMap("Occlusion", 2D) = "white" {}

	}
	SubShader
	{
		Pass
		{
		Tags{"LightMode"="ForwardBase"}
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			//����lightmap֧��
			#pragma multi_compile LIGHTMAP_OFF LIGHTMAP_ON
			#include "UnityStandardBRDF.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float3 normal:NORMAL;
				float2 uv : TEXCOORD0;
				float2 uv1:TEXCOORD1;
				fixed4 tangent : TANGENT;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				#ifndef LIGHTMAP_OFF 
				half2 uv1:TEXCOORD1;
				#endif
				float4 vertex : SV_POSITION;
				float3 normal:TEXCOORD2;
				float3 worldPos:TEXCOORD3;
				float4 tangent:TEXCOORD4;
				float3x3 tangentToWorld : TEXCOORD5; 
				float3 viewDir:COLOR1;
            	float3x3 tangentMatrix: TEXCOORD8; 
				float3 objectspaceViewdir:COLOR2;
			};

			sampler2D _MainTex;
			float4 _Tint;
			float _Metallic;
			float _Smoothness;
			float4 _MainTex_ST;
			sampler2D _MetallicGlossMap;
			sampler2D _BumpMap;
			sampler2D _OcclusionMap;
			float _Parallax;
			sampler2D _ParallaxMap;

inline half OneMinusReflectivityFromMetallic(half metallic)
{
    // We'll need oneMinusReflectivity, so
    //   1-reflectivity = 1-lerp(dielectricSpec, 1, metallic) = lerp(1-dielectricSpec, 0, metallic)
    // store (1-dielectricSpec) in unity_ColorSpaceDielectricSpec.a, then
    //   1-reflectivity = lerp(alpha, 0, metallic) = alpha + metallic*(0 - alpha) =
    //                  = alpha - metallic * alpha
    half oneMinusDielectricSpec = unity_ColorSpaceDielectricSpec.a;
    return oneMinusDielectricSpec - metallic * oneMinusDielectricSpec;
}

inline half3 DiffuseAndSpecularFromMetallic (half3 albedo, half metallic, out half3 specColor, out half oneMinusReflectivity)
{
    specColor = lerp (unity_ColorSpaceDielectricSpec.rgb, albedo, metallic);
    oneMinusReflectivity = OneMinusReflectivityFromMetallic(metallic);
    return albedo * oneMinusReflectivity;
}
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.normal = UnityObjectToWorldNormal(v.normal);
				o.normal = normalize(o.normal);
				o.tangent=v.tangent;
				float3 normalWorld = UnityObjectToWorldNormal(v.normal);
				float4 tangentWorld = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
				// ������ֵĸ����ţ�������Ҫsignȡ��(flip the sign)
				half sign = tangentWorld.w * unity_WorldTransformParams.w;
				half3 binormal = cross(normalWorld, tangentWorld) * sign;
				float3x3 tangentToWorld = half3x3(tangentWorld.xyz, binormal, normalWorld);
				o.tangentToWorld=tangentToWorld;
				o.viewDir=normalize(UnityWorldSpaceViewDir(o.worldPos));
				//Parallax viewDir need to changed from ObjectSpace to Tangent
				fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(o.worldPos));
                fixed3 objectspaceViewdir= mul(unity_WorldToObject, worldViewDir);
				o.objectspaceViewdir =normalize(objectspaceViewdir);
                float3 objectSpaceBinormal = normalize(cross(v.normal,v.tangent.xyz) * v.tangent.w);
                float3x3 tangentMatrix = float3x3(v.tangent.xyz, objectSpaceBinormal, v.normal);
				o.tangentMatrix = tangentMatrix;
				#ifndef LIGHTMAP_OFF
				o.uv1 = v.uv1.xy*unity_LightmapST.xy + unity_LightmapST.zw;
				#endif
				return o;
			}
			fixed4 frag (v2f i) : SV_Target
			{
				#ifndef LIGHTMAP_OFF
				fixed3 lm = DecodeLightmap(UNITY_SAMPLE_TEX2D(unity_Lightmap,i.uv1));
				float3 albedo = _Tint*tex2D(_MainTex,i.uv);
				float3 finalRes = albedo * lm;
				return float4( finalRes,1);
				#endif
				half height = tex2D(_ParallaxMap, i.uv).g;
                float3 tangentspaceViewDir =normalize( mul(i.tangentMatrix, i.objectspaceViewdir));
                i.uv += ParallaxOffset(height,_Parallax,tangentspaceViewDir);

				_Metallic=tex2D(_MetallicGlossMap,i.uv).r*_Metallic;
				_Smoothness=tex2D(_MetallicGlossMap,i.uv).a*_Smoothness;
				float occlusion=tex2D(_OcclusionMap,i.uv).r;
				float3 normal = normalize(i.normal);//û�м�normalize�����������仹��ȡ�Ķ��㷨�ߣ�û�н��в�ֵ
	//	#ifdef _NORMALMAP
				half3 tangent1 = i.tangentToWorld[0].xyz;
				half3 binormal1 = i.tangentToWorld[1].xyz;
				half3 normal1 = i.tangentToWorld[2].xyz;
				float3 normalTangent =UnpackNormal(tex2D(_BumpMap,i.uv));
				//return float4(1,0,0,1);
	//			normal= normalize(float3(dot(i.TtoW0.xyz, normalTangent), dot(i.TtoW1.xyz, normalTangent), dot(i.TtoW2.xyz, normalTangent)));//����任
				normal=normalize((float3)(tangent1 * normalTangent.x + binormal1 * normalTangent.y + normal1 * normalTangent.z));
	 // #endif
				float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
				//float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
		//		float3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
				float3 viewDir=i.viewDir;
				float3 lightColor = _LightColor0.rgb;
				float3 halfVector = normalize(lightDir + viewDir);
				//roughness���
				float perceptualRoughness = 1 - _Smoothness;
				float roughness = perceptualRoughness * perceptualRoughness;
				roughness=max(roughness,0.002);//����smoothnessΪ1��ҲҪ�е�߹���
				float squareRoughness = roughness * roughness;
				float nl = max(saturate(dot(normal , lightDir ) ) , 0.0000001);//��ֹ��0
				float nv = max(saturate(dot(normal, viewDir)), 0.0000001);
				float vh = max(saturate(dot(viewDir, halfVector)), 0.0000001);
				float lh = max(saturate(dot(lightDir, halfVector)), 0.0000001);
				float nh = max(saturate(dot(normal, halfVector)), 0.0000001);
			
				//1.1ֱ�ӹ������䲿��.�����ع��ա�û�г��ԦУ�����Ϊ���Ե�̫����
				float3 Albedo = _Tint*tex2D(_MainTex,i.uv);
				float3 rawDiffColor = DisneyDiffuse(nv,nl,lh,perceptualRoughness)*nl*lightColor;
				
				//1.2.ֱ�ӹ⾵�淴�䲿��
				// 1.2.1 D�GGX��
				float D=GGXTerm(nh,roughness);
				// 1.2.2 G�� ���κ������ڱα䰵һЩ
				//      ֱ�ӹ��պͼ�ӹ���ʱ��k���ڱƽ�����֮һ��ֻ����ֱ�ӹ���ʱ���ֵ��СΪ�˷�֮һ������0������Ϊ�˱�֤�ڱ�����Թ⻬ʱ
				//      Ҳ������һ���ֹ��ߣ��Ͼ���ȫ�����չ��ߵ���������ʵ�в�����
				float G=SmithJointGGXVisibilityTerm(nl,nv,roughness);
				//1.2.3 F�� ���������� ��������ǿ��Ե����ǿ
				float3 F0 = lerp(unity_ColorSpaceDielectricSpec.rgb, Albedo, _Metallic);
				float3 F=FresnelTerm(F0,lh);
				//������ϵ��kd
				float3 kd = OneMinusReflectivityFromMetallic(_Metallic);
				kd*=Albedo;
			
				float3 specular = D * G * F ;
				float3 specColor = specular * lightColor*nl*UNITY_PI;//ֱ�ӹ⾵�淴�䲿�֡����淴���ϵ������F��������֮ǰ�ٳ����ˣ�����Ϊ�˱�֤������;��淴��ı��������ﻹ�ó�һ����
				float3 diffColor = kd * rawDiffColor;//ֱ�ӹ������䲿�֡�
				float3 directLightResult = diffColor + specColor;
				//���ˣ�ֱ�ӹⲿ�ֽ���

				//2.��ʼ��ӹⲿ��
				//	2.1��ӹ�������
				half3 iblDiffuse = ShadeSH9(float4(normal,1));
				float3 iblDiffuseResult = iblDiffuse*kd;//�˼�ӹ�������ϵ��
				//	2.2��ӹ⾵�淴��
				float mip_roughness = perceptualRoughness * (1.7 - 0.7*perceptualRoughness );
				float3 reflectVec = reflect(-viewDir, normal);
				half mip = mip_roughness * UNITY_SPECCUBE_LOD_STEPS;//�ó�mip�㼶��Ĭ��UNITY_SPECCUBE_LOD_STEPS=6��������UnityStandardConfig.cginc��
				half4 rgbm = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, reflectVec, mip);//���߷���ķ���������ȥȡ����ͬʱ����mip�㼶
				half3 iblSpecular = DecodeHDR(rgbm, unity_SpecCube0_HDR);//ʹ��DecodeHDR����ɫ��HDR�����½��롣���Կ�����������rgbm��һ��4ͨ����ֵ��
				half surfaceReduction=1.0/(roughness*roughness+1.0);
				float oneMinusReflectivity = unity_ColorSpaceDielectricSpec.a-unity_ColorSpaceDielectricSpec.a*_Metallic;	//grazingTermѹ���ǽ����ı�Ե�쳣����
				half grazingTerm=saturate(_Smoothness+(1-oneMinusReflectivity));
				float3 iblSpecularResult = surfaceReduction*iblSpecular*FresnelLerp(F0,grazingTerm,nv);
				float3 indirectResult = (iblDiffuseResult + iblSpecularResult)*occlusion;
				//���ˣ�������ӹⲿ��
				
				
				//���ռӺ�
				float3 finalResult = directLightResult + indirectResult;
				return float4(finalResult,1);
			}
			ENDCG
		}
	}
	FallBack"Diffuse"
}
