Shader "Timewarp"
{
    Properties
    {
        _MainTex(               "Texture",              2D)     = "white" {}
        _ColorTex(              "Texture",              2D)     = "white" {}
        _DepthTex(              "_DepthTex",            2D)     = "white" {}
        _Color(                 "Tint",                 Color)  = (1, 1, 1, 1)

        _NearClip(              "_NearClip",            Float) = 0
        _FarClip(               "_FarClip",             Float) = 0

        _CameraPos(             "_CameraPos",           Vector) = (0, 0, 0, 1)
        _CameraForward(         "_CameraForward",       Vector) = (0, 0, 0, 1)
        _TopLeft(               "_TopLeft",             Vector) = (0, 0, 0, 1)
        _TopRight(              "_TopRight",            Vector) = (0, 0, 0, 1)
        _BottomLeft(            "_BottomLeft",          Vector) = (0, 0, 0, 1)
        _BottomRight(           "_BottomRight",         Vector) = (0, 0, 0, 1)

        _FrozenCameraPos(       "_FrozenCameraPos",     Vector) = (0, 0, 0, 1)
        _FrozenCameraForward(   "_FrozenCameraForward", Vector) = (0, 0, 0, 1)
        _FrozenTopLeft(         "_FrozenTopLeft",       Vector) = (0, 0, 0, 1)
        _FrozenTopRight(        "_FrozenTopRight",      Vector) = (0, 0, 0, 1)
        _FrozenBottomLeft(      "_FrozenBottomLeft",    Vector) = (0, 0, 0, 1)
        _FrozenBottomRight(     "_FrozenBottomRight",   Vector) = (0, 0, 0, 1)
        _StretchBorders("_StretchBorders", Float) = 0
        _ReprojectMovement("_ReprojectMovement", Float) = 0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100


        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            float4x4 _FrozenWorldToCameraMatrix;
            float4x4 _FrozenProjectionMatrix;
            float4x4 _WorldToCameraMatrix;
            float4x4 _ProjectionMatrix;

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _DepthTex;
            sampler2D _ColorTex;

            float3 _CameraPos;
            float3 _CameraForward;
            float3 _TopLeft;
            float3 _TopRight;
            float3 _BottomLeft;
            float3 _BottomRight;

            float3 _FrozenCameraPos;
            float3 _FrozenCameraForward;
            float3 _FrozenTopLeft;
            float3 _FrozenTopRight;
            float3 _FrozenBottomLeft;
            float3 _FrozenBottomRight;

            sampler2D _CameraDepthTexture;
            float _NearClip;
            float _FarClip;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float4 screenPosition : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.screenPosition = ComputeScreenPos(o.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            float3 GetWorldPos(float3 CameraVector, float3 CameraForward, float3 CameraPos, float2 uv)
            {
                float d = dot(CameraForward, CameraVector);
                float SceneDistance = LinearEyeDepth(tex2D(_DepthTex, uv).r) / d;
                float3 worldPos = CameraPos + CameraVector * SceneDistance;
                return worldPos;
            }
            float InverseLerp(float3 a, float3 b, float3 value)
            {
                float3 AB = b - a;
                float3 AV = value - a;
                return dot(AV, AB) / dot(AB, AB);
            }

            float2 reproject(float3 input)
            {
                float a = InverseLerp(_FrozenTopLeft, _FrozenTopRight, input);
                float b = InverseLerp(_FrozenBottomLeft, _FrozenTopLeft, input);
                float2 result = float2(a, b);
                return result;
            }

            float2 WorldToScreenPos(float3 pos, float4x4 CameraProjection, float4x4 WorldToCamera, float3 CameraPosition)
            {
                float nearPlane = _NearClip;
                float farPlane = _FarClip;
                float textureWidth = _ScreenParams.x;
                float textureHeight = _ScreenParams.y;
                float3 SamplePos = pos;


                SamplePos = normalize(SamplePos - CameraPosition) * (nearPlane + (farPlane - nearPlane)) + CameraPosition;
                float2 uv = 0;
                float3 toCam = mul(WorldToCamera, SamplePos);
                float camPosZ = toCam.z;
                float height = 2 * camPosZ / CameraProjection._m11;
                float width = textureWidth / textureHeight * height;
                uv.x = (toCam.x + width / 2) / width;
                uv.y = (toCam.y + height / 2) / height;
                return 1.0f - uv;
            }
            float _StretchBorders;
            float _ReprojectMovement;
            float4 frag(v2f i) : SV_Target
            {
                float2 uv =  i.screenPosition.xy / i.screenPosition.w;

                float3 CameraVector = lerp(lerp(_TopLeft, _TopRight, uv.x), lerp(_BottomLeft, _BottomRight, uv.x),  1.0f - uv.y);

                float3 CameraVectorFrozen = lerp(lerp(_FrozenTopLeft, _FrozenTopRight, uv.x), lerp(_FrozenBottomLeft,  _FrozenBottomRight, uv.x),  1.0f - uv.y);

                float3 Start = _CameraPos;
                float3 CurrentPos = Start;
                float3 End = _CameraPos + CameraVector * 10.0f;
                bool occluded = false;
                bool missed = false;

                

                float2 uv3 = WorldToScreenPos(_FrozenCameraPos + CameraVector, _FrozenProjectionMatrix, _FrozenWorldToCameraMatrix, _FrozenCameraPos);

                if (_ReprojectMovement > 0.5)
                {
                    // raymarch through the frozen cameras depth buffer, there are three possible resutls
                    // 1. surface hit
                    // 2. miss (hit skybox or something)
                    // 3. occluded (went behind something without hitting it.
                    float steps = 100;
                    float DistanceFromWorldToPos;
                    [loop]
                    for (int i = 0; i < steps; i++)
                    {
                        float StepSize = 30.0f / steps;
                        CurrentPos += (CameraVector * StepSize);

                        float2 uv4 = WorldToScreenPos(CurrentPos, _FrozenProjectionMatrix, _FrozenWorldToCameraMatrix, _FrozenCameraPos);
                        float3 tracedPos = GetWorldPos(normalize(CurrentPos - _FrozenCameraPos), _FrozenCameraForward, _FrozenCameraPos, uv4);

                        float DistanceToCurrentPos = distance(_FrozenCameraPos, CurrentPos);
                        float DistanceToWorld = distance(_FrozenCameraPos, tracedPos);

                        DistanceFromWorldToPos = DistanceToCurrentPos - DistanceToWorld;
                        if (DistanceFromWorldToPos > StepSize)
                        {
                            occluded = true;
                        }
                        if (DistanceFromWorldToPos > 0)
                        {
                            break;
                        }
                        if (i == (steps-1))
                        {
                            missed = true;
                        }
                    }
                    uv3 = WorldToScreenPos(CurrentPos, _FrozenProjectionMatrix, _FrozenWorldToCameraMatrix, _FrozenCameraPos);
                }

                float3 MainTex = tex2D(_ColorTex, uv3).rgb;

                if ((uv3.x < 0 || uv3.y < 0 || uv3.x > 1 || uv3.y > 1) && _StretchBorders < 0.5)
                {
                    MainTex = float3(0, 0, 0);
                }

                // If the pixel was occluded, pick a "nearby" pixel to use intead.
                // Try returning black of occluded and you will see what it means.
                if (occluded)
                {
                    float2 OffsetUVLeft     = uv3 + float2(1, 0)  * 0.01f;
                    float2 OffsetUVRight    = uv3 + float2(0, 1)  * 0.01f;
                    float2 OffsetUVTop      = uv3 + float2(-1, 0) * 0.01f;
                    float2 OffsetUVDown     = uv3 + float2(0, -1) * 0.01f;
                    
                    float3 MainTexLeft      = tex2D(_ColorTex, OffsetUVLeft ).rgb;
                    float3 MainTexRight     = tex2D(_ColorTex, OffsetUVRight).rgb;
                    float3 MainTexTop       = tex2D(_ColorTex, OffsetUVTop  ).rgb;
                    float3 MainTexDown      = tex2D(_ColorTex, OffsetUVDown ).rgb;
                
                    float Depth             = LinearEyeDepth(tex2D(_DepthTex, uv3).r);
                    float DepthLeft         = LinearEyeDepth(tex2D(_DepthTex, OffsetUVLeft ).r);
                    float DepthRight        = LinearEyeDepth(tex2D(_DepthTex, OffsetUVRight).r);
                    float DepthTop          = LinearEyeDepth(tex2D(_DepthTex, OffsetUVTop  ).r);
                    float DepthDown         = LinearEyeDepth(tex2D(_DepthTex, OffsetUVDown ).r);

                    // Find the furthest away one of these five samples
                    float FurthestDepth = max(max(max(max(Depth, DepthLeft), DepthRight), DepthTop), DepthDown);
                    if (FurthestDepth == DepthLeft)
                        MainTex = MainTexLeft;
                    if (FurthestDepth == DepthRight)
                        MainTex = MainTexRight;
                    if (FurthestDepth == DepthTop)
                        MainTex = MainTexTop;
                    if (FurthestDepth == DepthDown)
                        MainTex = MainTexDown;
                }

                //if (dot(_FrozenCameraForward, CameraVector) < 0)
                //{
                //    MainTex = float3(0, 0, 0);
                //}

                return float4(MainTex, 0);
            }
            ENDCG
        }
    }
}