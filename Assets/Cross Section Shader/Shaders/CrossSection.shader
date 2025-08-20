Shader "CrossSection"{

    Properties {
        [Header(Colors)] [Space(7)]
        _MainColor ("Main Color", Color) = (0.7, 0.7, 0.7, 1.0)
        _CrossSectionColor1 ("Cross Section Color 1", Color) = (0.7, 0.2, 0.3, 1.0)
        _CrossSectionColor2 ("Cross Section Color 2", Color) = (0.4, 0.1, 0.2, 1.0)
        _EdgeColor ("Edge Color", Color) = (1.0, 1.0, 1.0, 1.0)

        [Header(Cross Section Settings)][Space(7)]
        _EdgeWidth ("Edge Width", Range(0,10)) = 0.02
        _LinesWidth ("Cross Section Lines Width", Float) = 50.0
        [MaterialToggle] _FlipSide("Flip Cut Side", Float) = 0

        [Header(Material Settings)][Space(7)]
        _MainTex("Albedo (RGB)", 2D) = "white" {}
        _Glossiness("Smoothness", Range(0,1)) = 0.5
        _Metallic("Metallic", Range(0,1)) = 0.0
    }

    SubShader {
        Tags { "RenderType" = "Opaque" "ForceNoShadowCasting" = "True" }

        // Main Geometry Pass (Standard Light Model)
        CGPROGRAM 
        #pragma surface surf Standard noshadow
        #pragma target 3.0

        sampler2D _MainTex;
        float4 _MainColor, _CrossSectionColor1, _CrossSectionColor2, _EdgeColor;
        float _FlipSide;
        float _EdgeWidth;
        float _Glossiness;
        float _Metallic;
        float4x4 _PlaneMatrix;

        struct Input {
            float3 worldPos;
            float2 uv_MainTex;
        };

        void surf (Input i, inout SurfaceOutputStandard o) {
            float3 planeNormal = _PlaneMatrix[2].xyz;
            float3 planePos = float3(-_PlaneMatrix[0][3], -_PlaneMatrix[1][3], -_PlaneMatrix[2][3]);
            float dist = dot(planeNormal, (i.worldPos - planePos));
            bool needCut = (_FlipSide == 1) ? (dist > 0.0) : (dist < 0.0);
            clip(needCut - 0.5);

            // edge near cut
            float edge = saturate(1.0 - pow(abs(dist), 0.5) - (1.0 - _EdgeWidth));

            fixed4 c = tex2D(_MainTex, i.uv_MainTex) * _MainColor;
            o.Albedo = c.rgb * (1.0 - edge) + _EdgeColor * edge;
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
        }
        ENDCG

        // Pass To Find Cross Section Mask Using Stencil Buffer 1
        Pass {

            Stencil {
                Ref 1
                Comp Always
                Pass IncrSat
            }

            ColorMask 0  // No color output
            Cull Front
            ZTest Off
            ZWrite Off

            CGPROGRAM
            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            float4 _MainColor;
            float _FlipSide;
            float4x4 _PlaneMatrix;

            struct appdata {
                float4 vertex : POSITION;
            };

            struct v2f {
                float3 worldPos  : TEXCOORD1;
                float4 vertex    : SV_POSITION;
            };
            

            v2f vert (appdata v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target {
                float3 planeNormal = _PlaneMatrix[2].xyz;
                float3 planePos = float3(-_PlaneMatrix[0][3], -_PlaneMatrix[1][3], -_PlaneMatrix[2][3]);
                float dist = dot(planeNormal, (i.worldPos - planePos));
                bool needCut = (_FlipSide == 1) ? (dist > 0.0) : (dist < 0.0);
                clip(needCut - 0.5);

                return float4(0.0, 0.0, 0.0, 1.0);
            }

            ENDCG
        }

        // Pass To Find Cross Section Mask Using Stencil Buffer 2
        Pass {

            Stencil {
                Ref 1
                Comp Always
                Pass DecrSat
            }

            ColorMask 0  // No color output
            Cull Back
            ZTest Off
            ZWrite Off

            CGPROGRAM
            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            float4 _MainColor;
            float _FlipSide;
            float4x4 _PlaneMatrix;

            struct appdata {
                float4 vertex : POSITION;
            };

            struct v2f {
                float3 worldPos  : TEXCOORD1;
                float4 vertex    : SV_POSITION;
            };


            v2f vert (appdata v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target {
                float3 planeNormal = _PlaneMatrix[2].xyz;
                float3 planePos = float3(-_PlaneMatrix[0][3], -_PlaneMatrix[1][3], -_PlaneMatrix[2][3]);
                float dist = dot(planeNormal, (i.worldPos - planePos));
                bool needCut = (_FlipSide == 1) ? (dist > 0.0) : (dist < 0.0);
                clip(needCut - 0.5);

                return float4(0.0, 0.0, 0.0, 1.0);
            }

            ENDCG
        }

        // Edge Pass
        Pass{

            Stencil {
                Ref 1 
                Comp LEqual
            }

            Cull Front
            ZTest On
            ZWrite On

            CGPROGRAM
            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            float4 _MainColor, _CrossSectionColor1, _CrossSectionColor2;
            float _LinesWidth;
            float4x4 _PlaneMatrix;

            struct appdata {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f {
                float3 worldPos  : TEXCOORD0;
                float3 normal    : TEXCOORD1;
                float4 screenPos : TEXCOORD2;
                UNITY_FOG_COORDS(3)
                float4 vertex    : SV_POSITION;
            };

            v2f vert (appdata v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.normal = UnityObjectToWorldNormal(v.normal);
                o.screenPos = ComputeScreenPos(o.vertex);
                UNITY_TRANSFER_FOG(o, o.vertex);
                return o;
            }

            fixed4 frag (v2f i, half facing : VFACE, out float outputDepth : SV_Depth) : SV_Target {
                i.normal = normalize(i.normal);

                // Plane params
                float3 planeNormal = _PlaneMatrix[2].xyz;
                float3 planePos = float3(-_PlaneMatrix[0][3], -_PlaneMatrix[1][3], -_PlaneMatrix[2][3]);

                // Edge mask
                float dist = dot(planeNormal, (i.worldPos - planePos));

                // Depth
                float fragDepth = i.screenPos.z / i.screenPos.w;
                outputDepth = fragDepth;

                // Ray plane intersection
                float3 rayDir = normalize(_WorldSpaceCameraPos - i.worldPos);
                float3 rayOrigin = _WorldSpaceCameraPos;

                float denominator = dot(planeNormal, rayDir);
                float t = dot(planePos - rayOrigin, planeNormal) / denominator;
                float3 intersectionPoint = rayOrigin + t * rayDir;
                float4 clipPos = UnityWorldToClipPos(intersectionPoint);
                outputDepth = clipPos.z / clipPos.w;

                // Lines
                float2 planeUV = mul(_PlaneMatrix, float4(intersectionPoint.xyz, 1.0)).xy;
                float wave = step(sin(planeUV.y * _LinesWidth), 0.0);

                // Color
                float3 col = _CrossSectionColor1 * wave + _CrossSectionColor2 * (1.0 - wave);
                UNITY_APPLY_FOG(i.fogCoord, col);

                return float4(col, 1.0);
            }

            ENDCG
        }
    }
}
