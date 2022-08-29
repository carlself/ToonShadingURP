Shader "ToonShading/Toon"
{
    Properties
    {
        _BaseMap ("BaseMap", 2D) = "white" {}
        _RampMap ("RampMap", 2D) = "white" {}

        // _SpecThreshold("SpecThreshold", Range(0,1)) = 0.5
        // _SpecSmoothness("SpeSmoothness", Range(0, 1)) = 0.01
        _Glossiness ("Glossiness", Float) = 0.1
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
            #pragma shader_feature_local _FACE_ON
            #pragma target 3.5
            #pragma vertex Vert
            #pragma fragment Frag
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