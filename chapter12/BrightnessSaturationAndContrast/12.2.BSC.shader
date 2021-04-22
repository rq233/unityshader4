Shader "Unlit/12.2.BSC"{
    Properties{
        _Color("Color Tint",Color) = (1,1,1,1)
        //Graphics.Blit(src, dest, material)将把 个参数传递给 Shader 中名为MainTex 的属性
        _MainTex("Main Tex",2D) = "white"{}
        _Brightness("Brightness",float) = 1.0
        _Contrast("Contrast",float) = 1.0
        _Saturation("Saturation",float) = 1.0
    }

    SubShader{
        pass{
            //设置相关的渲染设置
            ZTest Always Cull Off ZWrite Off
            //关闭了深度写入，是为了防止它“挡住”在其后面被渲染的物体。
            //例如，如果当前的 OnRen erlmage 函数在所有不透明的 Pass 执行完毕后立即被调用，不关闭深度写入就会影响后面透明的 Pass 的渲染。
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            float _Color;
            sampler2D _MainTex;
            float _Saturation;
            float _Brightness;
            float _Contrast;

            struct a2v{
                float4 vertex :POSITION;
                float4 texcoord :TEXCOORD0;
            };
            struct v2f{
                float4 pos :SV_POSITION;
                float2 uv :TEXCOORD0;
            };
            v2f vert(a2v v){
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord;
                return o;
            }

            //用于调整亮度、饱和度和对比度的片元着色器：
            fixed4 frag(v2f i) :SV_TARGET{
                //到对原屏幕图像（存储在_MainTex 中）的采样结果 renderTex
                fixed4 renderTex = tex2D(_MainTex,i.uv);
                //利用_Brightness 属性来调整亮度
                fixed3 finalcol = renderTex.rgb * _Brightness;
                
                //计算饱和度
                //计算该像素的对应的亮度值(Luminance), 这是通过对每个颜色分盘乘以一个特定的系数再相加得到的。
                fixed Luminance =  0.2125 * renderTex.r + 0.7154 * renderTex.g + 0.0721 * renderTex.b;
                //我们使用该亮度值创建了一个饱和度为0的颜色值
                fixed3 LuminanceColor = fixed3( Luminance , Luminance , Luminance);
                finalcol  = lerp( LuminanceColor , finalcol , _Saturation );

                //计算对比度
                //首先创建 个对比度为 的颜色值 （各分趾均为 0.5),
                fixed3 avgColor = fixed3( 0.5 , 0.5 , 0.5 );
                finalcol = lerp( avgColor , finalcol , _Contrast);

                return fixed4 ( finalcol , renderTex.a);
            }ENDCG
        }
    }Fallback Off
}  