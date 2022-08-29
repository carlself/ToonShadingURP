Shader "ToonShading/Hair"
{
    Properties
    {
        _BaseMap ("BaseMap", 2D) = "white" {}

        _ShiftNoiseMap("Shift Noise Map", 2D) = "white" {}
        _ShiftStrength ("ShiftStrength", Range(0, 1)) = 1
        _SpecularScale ("SpecularScale", Range(0, 1)) = 0.1
        _SpecularExponent("Specular Exponent", float)  = 10
        _SpecColor ("SpecColor", Color) = (1, 1,1,1)

        _OutlineWidth("Outline Width", Range(0,10)) = 0.4
        _OutlineColor("Outline Color", Color) = (0, 0, 0, 1)
        _RimWidth("Rim Width", float) = 0.2
        _RimSmoothness("Rim Smoothness", float) = 0.1
        _RimColor("Rim Color", Color) = (1,1,1,1)
        _RimIntensity("Rim Intensity", Range(0, 1)) = 1
        // _ShadowColor("Shadow Color", Color) = (0.5, 0.5, 0.5, 1)
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
            #define _HAIR 1
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