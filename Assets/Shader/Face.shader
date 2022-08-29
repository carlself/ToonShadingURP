Shader "ToonShading/Face"
{
    Properties
    {
        _BaseMap ("BaseMap", 2D) = "white" {}

        _FaceShadowMap("FaceShadowMap", 2D) = "white" {}
        _FaceShadowStrength("FaceShadowStrength", Range(0, 1)) = 0.5
        _FaceShadowMax("FaceShadowMax", Range(0, 1)) = 0.5

        _OutlineWidth("Outline Width", Range(0,10)) = 0.4
        _OutlineColor("Outline Color", Color) = (0, 0, 0, 1)
        _RimWidth("Rim Width", float) = 0.2
        _RimSmoothness("Rim Smoothness", float) = 0.1
        _RimColor("Rim Color", Color) = (1,1,1,1)
        _RimIntensity("Rim Intensity", Range(0, 1)) = 1
    }

    SubShader
    {
        Tags{"RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" }
        Pass
        {
            Name "Toon"
            Tags {"LightMode" = "UniversalForward"}

            ZWrite On
            ZTest LEqual
            Cull Back

            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex Vert
            #pragma fragment Frag
            #define _FACE 1
            #include "./Toon.hlsl"
            ENDHLSL
        }

        Pass
        {
            Name "ToonOutline"

            Cull Front

            HLSLPROGRAM
            #pragma target 3.5
            #pragma shader_feature_local _CONST_LINE_WIDTH_ON
            #pragma vertex VertOutline
            #pragma fragment FragOutline
            #include "./Toon.hlsl"
            ENDHLSL
        }
    }
}