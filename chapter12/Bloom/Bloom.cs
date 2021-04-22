using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Bloom : postEffect
{
    //********************指定shader和材质********************//
    public Shader BloomShader;
    public Material BloomMaterial = null;
    //********************调用基类，得到材质********************//
    public Material material{
        get{
            BloomMaterial = CheckShaderAndCreateMaterial( BloomShader , BloomMaterial);
            return BloomMaterial;
        }
    }

    //********************开始定义该shader需要控制的对象:迭代次数，模糊范围，缩放系数********************//
    [Range(0,3)]
    public int iteration = 2;      //iteration:迭代
    [Range(0.2f,3.0f)]
    public float blurSpeard = 2.0f;
    [Range(1,8)]
    public int downSample = 2;    //降低采样？
    [Range(0.0f,4.0f)]
    public float luminanceThreshold  = 2.0f; 
    //提取亮部
    //在绝大多数情况下，图像的亮度值不会超过 1。
    //但开启了 HOR, 硬件会允许我们把颜色值存储在一个更高精度范围的缓冲中，此时像素的亮度值可能会超过1。
    
    ////****************************************   计算模糊   ****************************************//
    //考虑了高斯模糊的迭代次数：
    //脚本：负责在编辑中实时更新图像，同时也负责从主摄像机抓取render texture，然后把该texture传递给Shader。
    //Unity内置的OnRenderImage函数下面的代码允许我们访问当前被渲染的图像
    //OnRenderImage：负责从Unity渲染器中抓取当前的render texture
    //Graphics.Blit()：再传递给Shader（通过sourceTexture参数
    void OnRenderImage (RenderTexture src, RenderTexture dest){
        if (material != null)
        {
            material.SetFloat("_luminanceThreshold", luminanceThreshold);

            int rtW = src.width/downSample;
			int rtH = src.height/downSample;
            //在迭代开始前，我们首先定义了第一个缓存 bufferO, 并把 src 中的图像缩放后存储到 bufferO 中
            RenderTexture buffer0 = RenderTexture.GetTemporary(rtW , rtH , 0);
            buffer0.filterMode = FilterMode.Bilinear;
            Graphics.Blit(src , buffer0);

            //设置迭代次数
            for (int i = 0; i < iteration; i++)
            {
                //在每一帧设置Material的各项参数，通过Material.SetXXX("name",value)可以向shader中传递各种参数。
                material.SetFloat("_BlurSize",1.0f + i * blurSpeard);
                //在迭代过程中，我们又定义了第二个缓存 bufferl.
                RenderTexture buffer1 = RenderTexture.GetTemporary(rtW , rtH , 0);
                //在执行第一个 Pass 时，输入 bufferO, 输出是 bufferl,
                Graphics.Blit(buffer0 , buffer1 , material ,0);
                //完毕后首先把 bufferO 释放
                //再把结果值 buffer 存储到 bufferO 中，重新分配 bufferl, 然后再调用第二个Pass
                RenderTexture.ReleaseTemporary(buffer0);
                buffer0 = buffer1;
                buffer1 = RenderTexture.GetTemporary(rtW , rtH , 0);
                Graphics.Blit(buffer0, buffer1 , material ,1);
                //然后再调用第二个Pass, 重复上述过程。
                RenderTexture.ReleaseTemporary(buffer0);
                buffer0 = buffer1;
            }

            //迭代完成后,将bloom 将存储到buffer0
            material.SetTexture("_Bloom", buffer0);
            //再利用 Graphics.Blit(bufferO<lest) 结果显示到屏幕上，并释放缓存。
            Graphics.Blit(src, dest, material, 3);
            RenderTexture.ReleaseTemporary(buffer0);
        }
        else
        {
            Graphics.Blit(src , dest);
        }
    }
}
