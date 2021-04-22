//需要实现的效果
//1.边缘检测
//2.离散阴影
//3.离散高光
//4.边缘高光
//5.简化颜色
Shader "Unlit/14.1Toon3"
{
    Properties{
        _Color("Color",Color) = (1,1,1,1)

        //贴图纹理，简化离散颜色
        _MainTex("Main Tex", 2D) = "white"{}
        _RampSmooth("Ramp Smooth",Range(0,5)) = 2          ///色阶间平滑度
        _RampThreshold("Ramp Threshold",Range(0,1)) = 0.5  ///色阶阈值

        //高光离散高光和边缘高光
        _Specular("Specular", Color) = (1,1,1,1)
        _SpecularScale("Specular Scale", Range(0,0.1)) = 0.03
        _SpecSmooth("Spec Smooth", Range(0,2)) = 1
        _Gloss("Gloss", Range(0,1)) = 0.5

        //边缘检测
        _OutlineColor("Outline Color", Color) = (0,0,0,1)
        _Outline("Outline", Range(0, 0.1)) = 0.05

        //离散阴影
        _Steps("Steps of toon",range(0,5)) = 3
        _RimColor("RimColor",Color) = (1,1,1,1)
        _RimSmooth("Rimp Smooth",Range(0,5)) = 4          ///色阶间平滑度
        _RimThreshold("Rimp Threshold",Range(0,1)) = 0.8  ///色阶阈值
        _SColor("SColor", Color) = (1,1,1,1)
        _HColor("HColor", Color) = (1,1,1,1)
    }

    SubShader{
        pass{
            //第一个pass  边缘检测
            Name "OUTLINE"
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

            v2f vert (a2v v){
                v2f o;
                float4 viewPos = mul(UNITY_MATRIX_MV, v.vertex);
                float3 viewNormal = mul((float3x3 )UNITY_MATRIX_IT_MV, v.normal);
                viewNormal.z = -0.5;
                viewPos = viewPos + float4(normalize(viewNormal), 0) *_Outline;
                o.pos = mul(UNITY_MATRIX_P,viewPos);
                
                return o;
            }

            fixed4 frag(v2f i):SV_TARGET{
                return fixed4(_OutlineColor.rgb,1.0);
            }ENDCG
        }

        //第二个pass
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
            fixed _RampSmooth;
            fixed _RampThreshold;
            
            float4 _Specular;
            fixed _SpecularScale;
            fixed _SpecSmooth;
            fixed _Gloss;
            
            fixed _Steps;
            float4 _RimColor;
            float _RimThreshold;
            float _RimSmooth;
            float4 _HColor;
            float4 _SColor;

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

            //片元着色器
            fixed4 frag (v2f i):SV_TARGET{
                //定义一些公用的
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                fixed3 halfView = normalize(worldLightDir + worldViewDir);
                
                //求diffuse 我们这里dif=lc*al*ram
                //已有lc 需求al ram
                //al：纹理采样*控制
                //ram：分二阶
                fixed3 albedo = tex2D(_MainTex,i.uv).rgb * _Color.rgb;
                //UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);
                float dif = max(0, dot(worldNormal, worldLightDir));
                /* dif = (dif+1)/2;
                dif = smoothstep(0,1,dif);
                float toon = floor(dif *_Steps)/_Steps; */
                fixed3 ramp = smoothstep(_RampThreshold - _RampSmooth * 0.5, _RampThreshold + _RampSmooth * 0.5, dif);
                //ramp *= atten;
                _SColor = lerp(_HColor, _SColor, _SColor.a);
                float3 rampColor = lerp(_SColor.rgb, _HColor.rgb, ramp);
                fixed3 diffuse = albedo * _LightColor0.rgb * rampColor ;

                //计算离散高光
                fixed spec= dot(worldNormal, halfView);
                fixed3 specular = _Specular.rgb * pow(max(0,dot(worldNormal,spec)),_Gloss);
                float3 toonSpec = floor(specular* 2)/ 2;

                //计算边缘高光
                float rim = max(0, dot(worldNormal, worldViewDir));
                float rimCol = (1.0 - rim) * dif;
                //rimCol *= atten;
                rimCol = smoothstep(_RimThreshold - _RimSmooth * 0.5, _RimThreshold + _RimSmooth * 0.5, rimCol);
                fixed3 rimmColor = _RimColor.rgb * _LightColor0.rgb * rimCol;

                //计算环境光
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb * albedo;

                fixed3 color = ambient + diffuse + toonSpec + rimmColor;
                return fixed4 (color, 1.0);
            }ENDCG
        }
    }Fallback "Diffuse"

}