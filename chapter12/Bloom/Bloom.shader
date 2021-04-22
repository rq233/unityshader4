Shader "Unlit/Bloom"
{
   Properties{
       _MainTex("Main Tex",2D) = "white"{}
       _Bloom("Bloom",2D) = "Black"{}
       _luminanceThreshold("Luminance Threshold", float) = 2.0
       _BlurSize("Blur Size", float) = 2.0
       _Color("Color", Color) = (1,1,1,1)
   }

   SubShader{
       CGINCLUDE
       #include "unityCG.cginc"

       sampler2D _MainTex;
       float4 _MainTex_TexelSize;
       sampler2D _Bloom;
       float4 _Bloom_TexelSize;
       float _luminanceThreshold;
       //来控制提取较亮区域时使用的阙值大小
       float _BlurSize;
       float4 _Color;

       struct a2v{
           float4 vertex :POSITION;
           float4 texcoord :TEXCOORD0;
       };
       struct v2f{
           float4 pos :SV_POSITION;
           float2 uv :TEXCOORD0;
       };

       //***************************定义亮区域所需要的顶点/片元着色器***************************
       v2f vertLight (a2v v){
           v2f o;
           o.pos = UnityObjectToClipPos(v.vertex);
           o.uv = v.texcoord;
           return o;
       }

       fixed luminance( fixed4 color){
           return 0.2125 * color.r + 0.7154 * color.g + 0.0721 * color.b; 
       }

       fixed4 fragLight (v2f i):SV_TARGET{
           //提取亮部，模糊亮部
           float4 c = tex2D(_MainTex,i.uv);
           float val = clamp( luminance(c) - _luminanceThreshold, 0.0, 1.0);
           return c*val;
       }

       //***************************定义亮部混合模糊后区域所需要的顶点/片元着色器***************************
       struct v2fBloom{
           float4 pos :POSITION;
           float4 uv :TEXCOORD0;
       };
       v2fBloom vertBloom (a2v v){
           v2fBloom p;
           p.pos = UnityObjectToClipPos(v.vertex);
           p.uv.xy = v.texcoord;
           p.uv.zw = v.texcoord;

           #if UNITY_UV_STARTS_AT_TOP 
           if (_MainTex_TexelSize.y < 0.0)
                p.uv.w = 1.0 - p.uv.w;
           #endif
           
           return p;
       }

       fixed4 fragBloom (v2fBloom q):SV_TARGET{
           return tex2D(_MainTex, q.uv.xy) + tex2D(_Bloom, q.uv.zw);
       }
       ENDCG

       ZTest Always Cull Off ZWrite Off
       pass{
           CGPROGRAM
           #pragma vertex vertLight
           #pragma fragment fragLight
           ENDCG
       }

       UsePass "Unlit/GussBlur/GUSS_BLUR_VERTICAL"
       UsePass "Unlit/GussBlur/GUSS_BLUR_HORIZONTAL"

       pass{
           CGPROGRAM
           #pragma vertex vertBloom
           #pragma fragment fragBloom
           ENDCG
       }
   }Fallback Off
}
