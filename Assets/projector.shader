Shader "Cg projector shader for adding light"
{
    Properties
    {
        _MainTex("_MainTex", 2D) = "white" {}
        _DepthTex("_DepthTex", 2D) = "white" {}
        _StretchBorders("_StretchBorders", Float) = 0
        _OffsetX("_OffsetX", Float) = 0
        _OffsetY("_OffsetY", Float) = 0
        _UnmodifiedCameraPosition("_UnmodifiedCameraPosition",     Vector) = (0, 0, 0, 1)
        _CameraPosition("_CameraPosition",                         Vector) = (0, 0, 0, 1)
    }
    SubShader
    {
        Pass 
        {
            Blend One One
            ZWrite Off
            CGPROGRAM

            #pragma vertex vert  
            #pragma fragment frag 

            uniform sampler2D _MainTex;
            uniform sampler2D _DepthTex;
            uniform sampler2D _CameraDepthTexture;
            uniform sampler2D _LastCameraDepthTexture;

            float _OffsetX;
            float _OffsetY;

            uniform float4x4 unity_Projector;

            struct vertexInput
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };
            struct vertexOutput
            {
                float4 pos : SV_POSITION;
                float4 posProj : TEXCOORD0;
                // position in projector space
            };

            vertexOutput vert(vertexInput input)
            {
                vertexOutput output;

                output.posProj = mul(unity_Projector, input.vertex);
                output.pos = UnityObjectToClipPos(input.vertex);
                return output;
            }

            float _StretchBorders;
            float4 frag(vertexOutput input) : COLOR
            {
                if (input.posProj.w > 0.0) // in front of projector?
                {
                    float2 uv = input.posProj.xy / input.posProj.w;
        
                    if ((uv.x < 0 || uv.y < 0 || uv.x > 1 || uv.y > 1) && _StretchBorders < 0.5)
                    {
                        return float4(0, 0, 0, 0);
                    }

                    float lastDepth = SAMPLE_DEPTH_TEXTURE(_DepthTex, uv);

                    float2 angle = -float2(_OffsetX, _OffsetY);
                    float newDepth = SAMPLE_DEPTH_TEXTURE(_DepthTex, uv + angle * lastDepth * 15.0f);

                    float4 MainTex = tex2D(_MainTex, uv);

                    //float3 DepthTex = tex2D(_DepthTex, uv).rgb;
                    //depth = frac(depth * 500);
                    return float4(MainTex.rgb, 0.0f);

                }
                else // behind projector
                {
                    return float4(0.0, 0.0, 0.0, 0.0);
                }
            }

        ENDCG
        }
    }
    Fallback "Projector/Light"
}