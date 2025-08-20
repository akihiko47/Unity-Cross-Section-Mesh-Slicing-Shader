Shader "Custom/Skybox" {

    Properties {
        _Color1 ("Color 1", Color) = (1.0, 1.0, 1.0, 1.0)
        _Color2 ("Color 2", Color) = (0.0, 0.0, 0.0, 1.0)
    }

    SubShader {
        Tags { "RenderType"="Opaque" }

        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            float4 _Color1, _Color2;

            struct appdata {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v2f vert (appdata v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            float4 frag (v2f i) : SV_Target{
                float3 col = 0.0;
                
                col += lerp(_Color1, _Color2, smoothstep(-0.7, 0.8, i.uv.y));

                return float4(col, 1.0);
            }
            ENDCG
        }
    }
}
