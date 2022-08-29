#ifndef UNIVERSAL_TOON
#define UNIVERSAL_TOON

#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

CBUFFER_START(UnityPerMaterial)
    half4 _BaseMap_ST;
    half _Glossiness;
    half _SpecSmoothness;
    half3 _SpecColor;
    half _SpecularExponent;
    half _FaceShadowStrength;
    half _FaceShadowMax;
    half _ShiftStrength;

    half _SpecularScale;

    half _OutlineWidth;
    half4 _OutlineColor;

    half _RimWidth;
    half _RimSmoothness;
    half4 _RimColor;
    half _RimIntensity;
CBUFFER_END
TEXTURE2D(_BaseMap); SAMPLER(sampler_BaseMap);
TEXTURE2D(_RampMap); SAMPLER(sampler_RampMap);
TEXTURE2D(_FaceShadowMap); SAMPLER(sampler_FaceShadowMap);
TEXTURE2D(_ShiftNoiseMap); SAMPLER(sampler_ShiftNoiseMap);

struct Attributes
{
    float4 positionOS : POSITION;
    float2 texcoord : TEXCOORD;
    float4 normalOS : NORMAL;
    float4 tangentOS : TANGENT;
};

struct Varyings 
{
    float4 positionCS : SV_POSITION;
    float2 uv : TEXCOORD0;
    float3 positionWS : TEXCOORD1;
    // float3 viewDirWS : TEXCOORD1;
    float3 normalWS : TEXCOORD2;
    float3 bitangentWS : TEXCOORD3;
};

Varyings Vert(Attributes IN)
{
    Varyings OUT;
    VertexPositionInputs vertexInput = GetVertexPositionInputs(IN.positionOS.xyz);
    VertexNormalInputs normalInput = GetVertexNormalInputs(IN.normalOS.xyz, IN.tangentOS);
    OUT.positionCS = vertexInput.positionCS;
    // OUT.viewDirWS = GetWorldSpaceNormalizeViewDir(vertexInput.positionWS);
    OUT.positionWS = vertexInput.positionWS;
    OUT.normalWS = normalInput.normalWS;
    OUT.bitangentWS = normalInput.bitangentWS;
    OUT.uv = TRANSFORM_TEX(IN.texcoord, _BaseMap);

    return OUT;
}

half StrandSpecular(half3 bitangent, half3 halfVector, half exponent)
{
    half tdh = dot(bitangent, halfVector);
    half sinTdh = sqrt(1.0 - tdh * tdh);
    half dirAtten = smoothstep(-1.0, 0.0, tdh);
    return dirAtten * pow(sinTdh, exponent) ;
}

half4 Frag(Varyings IN) : SV_TARGET
{
    half3 viewDir = normalize(_WorldSpaceCameraPos.xyz - IN.positionWS);
    half3 normalWS = normalize(IN.normalWS);
    half3 lightDir = normalize(_MainLightPosition.xyz);
    half ndl = dot(normalWS, lightDir);
    half diff = saturate(ndl * 0.5 + 0.5);

    #if _FACE
        half3 diffuse = _MainLightColor;
        half4 leftFaceTex = SAMPLE_TEXTURE2D(_FaceShadowMap, sampler_FaceShadowMap, IN.uv);
        half4 rightFaceTex = SAMPLE_TEXTURE2D(_FaceShadowMap, sampler_FaceShadowMap, float2(1.0-IN.uv.x, IN.uv.y));
        half2 left = normalize(TransformObjectToWorldDir(float3(1, 0, 0)).xz);
        half2 front = normalize(TransformObjectToWorldDir(float3(0, 0, 1)).xz);
        half2 lightHDir = normalize(_MainLightPosition.xz);
        float angle = 1 - clamp(0, 1, dot(front, lightHDir) * 0.5 + 0.5);
        float texDirect = dot(lightDir, left) > 0 ? rightFaceTex.r : leftFaceTex.r;
        half isShadow = step(texDirect, angle);
        half bias = smoothstep(0, _FaceShadowMax, abs(angle - texDirect));
        if(angle > 0.99 || isShadow == 1)
             diffuse = lerp(_MainLightColor, _MainLightColor * (1-_FaceShadowStrength), bias);
    #else
        half3 rampTex = SAMPLE_TEXTURE2D(_RampMap, sampler_RampMap, float2(diff, 0));
        half3 diffuse = _MainLightColor.rgb * rampTex;
    #endif


    half3 h = normalize(lightDir + viewDir);
    #if _HAIR
        half shift= SAMPLE_TEXTURE2D(_ShiftNoiseMap, sampler_ShiftNoiseMap, IN.uv).r;
        half3 bitangent = normalize(IN.bitangentWS + shift * 0.5 * _ShiftStrength * normalWS);

        half spec = StrandSpecular(bitangent, h, _SpecularExponent);
        half3 specular =  spec * _SpecColor  * _MainLightColor.rgb * _SpecularScale;
    #elif _FACE 
        half3 specular = half3(0, 0, 0);
    #else
        half ndh = saturate(dot(normalWS, h));
        half spec = pow(ndh,  _Glossiness * 128);
        spec = smoothstep(0, 0.01, spec) * step(0.0001, _Glossiness);
        half3 specular = spec * _SpecColor * _MainLightColor.rgb;
    #endif

    half3 rimColor = 0;
    half rim = 1.0 - saturate(dot(viewDir, normalWS));
    rim = smoothstep(1 - _RimWidth, 1, rim);
    rim = smoothstep(0, _RimSmoothness, rim);
    rimColor =  _RimColor.rgb * _RimIntensity * rim;

    half4 mainTex = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv);
    half3 color = (diffuse + specular + rimColor) * mainTex.rgb;
    return half4(color.rgb, 1.0);
}


Varyings VertOutline(Attributes IN)
{
    Varyings OUT = (Varyings)0;

    float4 scaledScreenParams = GetScaledScreenParams();
    float scaleX = abs(scaledScreenParams.x / scaledScreenParams.y);
    VertexPositionInputs vertexInput = GetVertexPositionInputs(IN.positionOS.xyz);
    VertexNormalInputs normalInput = GetVertexNormalInputs(IN.normalOS.xyz);
    float3 normalCS = TransformWorldToHClipDir(normalInput.normalWS);
    float2 extendDis = normalize(normalCS.xy) * (_OutlineWidth * 0.01);
    extendDis.x /= scaleX;
    OUT.positionCS = vertexInput.positionCS;
    OUT.positionCS.xy += extendDis * OUT.positionCS.w;

    return OUT;
}

half4 FragOutline(Varyings IN) : SV_TARGET
{
    return half4(_OutlineColor.rgb, 1.0);
}
#endif