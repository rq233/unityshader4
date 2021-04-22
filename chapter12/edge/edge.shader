Shader "Unlit/edge"
{
    Properties{
        _MainTex("MainTex",2D) = "white"{}
        _EdgeColor("Edge Color" , Color) = (1,1,1,1)
        _EdgeStrength("Edge Strength", float) = 10
        _Background("Backgrond" , Color) = (1,1,1,1)
    }

    SubShader{
        pass{
            ZTest Always Cull Off ZWrite Off
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "unityCG.cginc"

            sampler2D _MainTex;
            //float _MainTex_ST; ？为什么不用这个
            uniform half4 _MainTex_TexelSize;
            ///xxx_Texe1Size 是Unity为我们提供的访问 xxx 纹理对应的每个纹素的大小
            //卷积计算要用
            float4 _EdgeColor;
            float _EdgeStrength;
            float4 _Background;

            struct a2v{
                float4 vertex :POSITION;
                float4 texcoord :TEXCOORD0;
            };
            struct v2f{
                float4 pos :SV_POSITION;
                half2 uv[9] :TEXCOORD0; 
                // v2 结构体中定义了一个维数为 9 的纹理数组，对应了使用 Sobel 算子采样时需要的个邻域纹理坐标
            };

            //在顶点着色器的代码中，我们计算了边缘检测时需要的纹理坐标
            //把在元着器中计算的采样纹理坐标的代码片，转移到顶点着色器中，可以减少运算，提高性能。
            //由于从顶点着色器到片元着色器的插值是线性的，因此这样的转移并不会影响纹理坐标的计算结果。
            //为什么是线性的就不会变？
            v2f vert (a2v v){
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                half2 uv = v.texcoord;
                o.uv[0] = uv + _MainTex_TexelSize.xy * half2(-1,1);
                o.uv[1] = uv + _MainTex_TexelSize.xy * half2(0,1);
                o.uv[2] = uv + _MainTex_TexelSize.xy * half2(1,1);
                o.uv[3] = uv + _MainTex_TexelSize.xy * half2(-1,0);
                o.uv[4] = uv + _MainTex_TexelSize.xy * half2(0,0);
                o.uv[5] = uv + _MainTex_TexelSize.xy * half2(1,0);
                o.uv[6] = uv + _MainTex_TexelSize.xy * half2(-1,-1);
                o.uv[7] = uv + _MainTex_TexelSize.xy * half2(0,-1);
                o.uv[8] = uv + _MainTex_TexelSize.xy * half2(1,-1);
                return o;
            }

            //定义sobei
            float luminance(fixed4 color){
                return 0.2125 * color.r + 0.7154 * color.g + 0.0721 * color.b; 
            }
            half sobel (v2f i){
                //首先定义了水平方向和竖直方向使用的卷积核 Gx Gy
                const half Gx[9] = {-1, -2 , -1,
                                0 , 0 , 0 ,
                                1 , 2 , 1 ,};
                const half Gy[9] = {-1 , 0 , 1,
                                -2 , 0 , 2 ,
                                -1 , 0 , 1 ,};
                //接着，我们依次对每个像素进行采样，计算它们的亮度值，
                half texColor;
                half edgeX = 0;
                half edgeY = 0;
                for (int it = 0 ; it < 9 ; it++){
                    texColor = Luminance( tex2D (_MainTex , i.uv[it]));
                    //再与卷积核 Gx Gy 中对应的权重相乘后
                    edgeX += texColor * Gx[it];
                    edgeY += texColor * Gy[it];
                }
                //叠加到各自的梯度值上。最后，我们从中减去水平方向和竖直方向的梯度值的绝对值
                //得到edge edge 值越小，表明该位置越可能是一个边缘点。至此，边缘检测过程结束
                half edge = 1 - abs(edgeX) - abs(edgeY);
                //abs:求数据绝对值的函数。
                return edge;
            }

            
            fixed4 frag (v2f i):SV_TARGET{
                //片元着色器需要计算的  1.用卷积计算出边缘 2.用边缘颜色控制颜色
                half edge = sobel(i);
                
                //并利用该值分别计算了背景为原图和纯色下的颜色值
                fixed4 withEdgecol = lerp( _EdgeColor, tex2D(_MainTex,i.uv[4]) , edge);
                fixed4 onlyEdgecol = lerp( _EdgeColor, _Background , edge);
                //然后利用_EdgeStrength 在两者之间插值得到最终的像素值。
                fixed4 edgeColor = lerp( withEdgecol , onlyEdgecol , _EdgeStrength);
                return edgeColor; 
            }ENDCG
        }
    }Fallback Off
}
