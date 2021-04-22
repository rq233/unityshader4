//改善功能
//1.改善了高光
//2.增加了边缘光
//3.离散化色彩
Shader "Unlit/14.1Toon2"
{
    Properties{
        //需要控制的：总色彩 纹理 渐变纹理控制光照 边缘线---往外扩散--色彩 高光色彩 高光大小
        _Color("Color Tint", Color) = (1,1,1,1)
        _MainTex("Main Tex", 2D) = "white"{}
        _Ramp("Ramp", 2D) = "white"{}
        
        _Specular("Specular", Color) = (1,1,1,1)
        _SpecularScale("Specular Scale", Range(0,0.1)) = 0.03
        //高光反射阈值
        //这里不用gloss 因为gloss那种算法是真实感的算法，卡控渲染的高光边界分明 是色阶那种
        
        _OutlineColor("Outline Color", Color) = (0,0,0,1)
        _Outline("Outline", Range(0, 0.1)) = 0.05
        //轮廓线宽度

        _Steps("Steps of toon",range(0,9))=3
        //色阶层数
        _ToonEffect("Toon Effect",Range(0,5)) = 5
        _Gloss("Gloss",Range(0,1)) =0.5

    }

    SubShader{
        Tags{"RenderType" = "Opaque" "Queue" = "Geometry"}

        //第一个pass渲染背面，并将顶点外移，外移的多少的就边缘宽度
        pass{
            Name "OUTLINE"
            //因为描边常用，为了方便调用所以命了一个名字
            cull Front
            //我们使用 Cull 指令把正面的三角面片剔除，而只渲染背面
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag 
            #include "UnityCG.cginc"

            //因为这里只渲染背面轮廓线，所以这个pass里只处理轮廓线相关内容
            float4 _OutlineColor;
            fixed _Outline;

            struct a2v{
                float4 vertex :POSITION;
                float3 normal :NORMAL;
            };
            struct v2f{
                float4 pos :SV_POSITION;
            };

            //顶点着色器  计算出边缘线
            //如何计算边缘线----将背面顶点沿法线方向外移
            //但外移可能会造成背面遮住正面，所以，我们首先对顶点法线的分量进行处理，使它们等于一个定值
            //法相的z分量是判断正负用的  所以设定订制不会影响法线本来的样子，但会影响顶点沿着法线的移动的距离，使其扁平化
            //再将法线归一化再进行处理，降低遮住的可能
            v2f vert (a2v v){
                v2f o;
                float4 viewPos = mul(UNITY_MATRIX_MV, v.vertex);
                float3 viewNormal = mul((float3x3 )UNITY_MATRIX_IT_MV, v.normal);
                viewNormal.z = -0.5;
                viewPos = viewPos + float4(normalize(viewNormal), 0) *_Outline;
                //先将前面转化到view坐标系，最后转化到p坐标系
                o.pos = mul(UNITY_MATRIX_P,viewPos);
                
                return o;
            }

            //片元着色器需要做的事，给轮廓边上色
            fixed4 frag(v2f i):SV_TARGET{
                return fixed4(_OutlineColor.rgb,1.0);
            }ENDCG
        }

        //第二个pass，需要做的事：计算出物体的漫反射 高光 环境光
        pass{
            Tags{"LightMode" = "ForwardBase"}

            Cull Back

            CGPROGRAM
            #pragma vertex vert 
            #pragma fragment frag
            #include "Lighting.cginc"
            //还有阴影忘了算
            #include "UnityCG.cginc"
            #include "AutoLight.cginc"
            #include "UnityShaderVariables.cginc"
            //渲染阴影需要的声明
            #pragma multi_compile_fwdbase

            float4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _Ramp;
            //float _Ramp_ST;
            float4 _Specular;
            fixed _SpecularScale;
            fixed _Steps;
            fixed _ToonEffect;
            fixed _Gloss;

            //定点输入的东西：点 要储存贴图所以准备一个纹理来存放 法线 
            struct a2v{
                float4 vertex :POSITION;
                float4 texcoord :TEXCOORD;
                float3 normal :NORMAL;
                //float3 tangent :TANGENT;
            };
            struct v2f{
                float4 pos :SV_POSITION;
                float3 worldNormal :TEXCOORD0;
                float3 worldPos :TEXCOORD1;
                float2 uv :TEXCOORD2;
                SHADOW_COORDS(3)
            };

            //顶点着色器内容 计算出输出的量
            v2f vert (a2v v){
                v2f o;
                o.pos =UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul (unity_ObjectToWorld,v.vertex).xyz;
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                //o.uv.zw = TRANSFORM_TEX(v.texcoord, _Ramp);
                TRANSFER_SHADOW(o);
                return o;
            }

            //计算片元着色器 ：漫反射 高光 环境光 这里用半兰伯特光照
            fixed4 frag (v2f i):SV_TARGET{
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                fixed3 halfView = normalize(worldLightDir + worldViewDir);
                fixed3 albedo = tex2D(_MainTex,i.uv).rgb * _Color.rgb;

                //计算漫反射 高光 环境光 阴影  光照衰减
                
                //计算环境光
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb * albedo;
                    
                //计算光照衰减和阴影
                UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);
                //UNITY _LIGHT _ATTENUATION Unity 内置的用于计算光照衰减和阴影，
                //返回三个参数 （atten，i，b）atten在内置函数中有定义，所以不用再定义
                //i:第二个参数是结构体 v2f  i.worldPos第三参数是世界空间的坐标 这个参数会用于计算光源空间下的坐标，对光照衰减纹理采样来得到光照衰减

                atten = (atten+1)/2;//做亮化处理
			    atten = smoothstep(0,1,atten);//使颜色平滑的在[0,1]范围之内
			    float toon=floor(atten *_Steps)/_Steps;
                //选择光照模型  卡通材质一般都用的半兰伯特光照
                fixed halfLambert = dot(worldLightDir,halfView) * 0.5 + 0.5;
                //这边真正卡通阴影应该是
                fixed diff =  halfLambert * atten;
                //漫反射计算
                fixed3 diffuse = _LightColor0.rgb * albedo * tex2D(_Ramp, float2(diff, diff)).rgb * toon;

                //计算高光
                fixed spec= dot(worldNormal, halfView);
                //这样计算出的高光不平滑，所以得做一下插值让他平滑
                //选择使用邻域像素之间的近似导数值,用函数fwidth求得
                //fixed w = fwidth(spec) * 2;
                //求真正高光  用_specular控制高光颜色，用_SpecularScale控制光电你大小
                //smoothstep(a,b,c):其中a是个很小的值，当 c 小于 a 时，返回 0, 大于 b 时，返回 1, 否则在 0~1 之间进行插值。
                //step(a,b):step 函数接受两个参数，a是参考值，b是待比较的数值。如果 b>a ，则返回 1, 否则返回 0
                //fixed3 specular = _Specular.rgb * lerp(0,1,smoothstep(-w, w, spec + _SpecularScale - 1)) * step(0.0001, _SpecularScale);
                fixed specular = _Specular.rgb * pow(max(0,dot(worldNormal,spec)),_Gloss);
                float toonSpec=floor(specular* 2)/ 2;//把高光也离散化
			    //spec=lerp(spec,toonSpec,_ToonEffect);//调节卡通与现实高光的比重

                return fixed4 (ambient + diffuse + toonSpec , 1.0);
            }ENDCG
        }
    }Fallback "Diffuse"
}
