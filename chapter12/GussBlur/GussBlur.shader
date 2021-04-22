Shader "Unlit/GussBlur"
{
    Properties{
        _MainTex("Main Tex", 2D) = "white"{}
        _Color("Color",Color) = (1,1,1,1)
        _BlurSize("Blur Size", float) = 1.0
    }

    SubShader{
        CGINCLUDE
        #include "UnityCG.cginc"
        //CGINCLUDE 类似于 ++中头文件的功能,使用 CGINCLUDE 可以避免我们编写两个完全一样的 frag 函数。
        //在sushader里写好函数，然后再用pass调用
        sampler2D _MainTex;
        //到相邻像素的纹理坐标，我们这里再一次使用了 Unity 提供的 MainTex TexelSize变量，以计算相邻像素的纹理坐标偏移妞。
        float4 _MainTex_TexelSize;
        float _BlurSize;

        struct a2v{
            float4 vertex :POSITION;
            float2 texcoord :TEXCOORD0;
        };
        struct v2f{
            float4 pos :SV_POSITION;
            //利用 5*5 大小的高斯核对原图像进行高斯模糊
            float2 uv[5] :TEXCOORD0;
        };

        //竖直方向的顶点着色器代码
        v2f vertVertical (a2v v){
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex);
            float2 uv = v.texcoord;
            o.uv[0] = uv;
            o.uv[1] = uv + float2(0.0 , _MainTex_TexelSize.y * 1.0) * _BlurSize;
            o.uv[2] = uv - float2(0.0 , _MainTex_TexelSize.y * 1.0) * _BlurSize;
            o.uv[3] = uv + float2(0.0 , _MainTex_TexelSize.y * 2.0) * _BlurSize;
            o.uv[4] = uv - float2(0.0 , _MainTex_TexelSize.y * 2.0) * _BlurSize;
            return o;
        }
        
        //水平方向的顶点着色器代码
        v2f vertHorizontal (a2v v){
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex);
            float2 uv = v.texcoord;
            o.uv[0] = uv;
            o.uv[1] = uv + float2(_MainTex_TexelSize.x * 1.0, 0.0 ) * _BlurSize;
            o.uv[2] = uv - float2(_MainTex_TexelSize.x * 1.0, 0.0 ) * _BlurSize;
            o.uv[3] = uv + float2(_MainTex_TexelSize.x * 2.0, 0.0 ) * _BlurSize;
            o.uv[4] = uv - float2(_MainTex_TexelSize.x * 2.0, 0.0 ) * _BlurSize;
            return o;
        }

        fixed4 frag (v2f i):SV_TARGET{
            //高斯计算
            //一个 5*5 的二维高斯核可以拆分成两个大小为 5 的一维高斯核， 并且由千它的对称性，我们只需要记录 3 个高斯权重，
            //这里的wight：权重
            //首先声明了各个邻域像素对应的权重 weight 
            float weight[3] = {0.4026, 0.2442, 0.0545};
            //然后将结果值 sum 初始化为当前的像素值乘以它的权重值。
            //根据对称性， 我们进行了两次迭代， 每次迭代包含了两次纹理采样，并把像素值和权重相乘后的结果叠加到 sum 中。 
            float3 sum = tex2D( _MainTex , i.uv[0] ).rgb * weight[0];
            for ( int it=1 ; it<3 ; it++){
                sum += tex2D(_MainTex,i.uv[it*2-1]).rgb * weight[it];
                sum += tex2D(_MainTex,i.uv[it*2]).rgb * weight[it];
            }
            //最后， 函数返回滤波结果 sum
            return fixed4(sum , 1.0);
        }
        ENDCG

        ZTest Always Cull Off ZWrite Off

        pass{
            //为 Pass 定义名字， 可以在其他Shader 中直接通过它们的名字来使用该 Pass, 而不需要再重复编写代码。
            Name "GUSS_BLUR_VERTICAL"
            CGPROGRAM
            #pragma vertex vertVertical
            #pragma fragment frag
            ENDCG
        }

        pass{
            Name "GUSS_BLUR_HORIZONTAL"
            CGPROGRAM
            #pragma vertex vertHorizontal
            #pragma fragment frag
            ENDCG
        }
        
    }Fallback "Diffuse"
}