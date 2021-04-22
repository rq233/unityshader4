using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GussBlur : postEffect
{
    //********************指定shader和材质********************//
    public Shader GussBlurShader;
    public Material GussBlurMaterial = null;
    //********************调用基类，得到材质********************//
    public Material material{
        get{
            GussBlurMaterial = CheckShaderAndCreateMaterial( GussBlurShader , GussBlurMaterial);
            return GussBlurMaterial;
        }
    }

    //********************开始定义该shader需要控制的对象:迭代次数，模糊范围，缩放系数********************//
    [Range(0,3)]
    public int iteration = 2;      //iteration:迭代
    [Range(0.2f,3.0f)]
    public float blurSpeard = 2.0f;
    [Range(1,8)]
    public int downSample = 2;    //降低采样？
    //blurSpread downSample 都是出于性能的考虑。
    //在高斯核维数不变的情况下 BlurSize大，模糊程度越高 但采样数却不会受到影响。但过大的 BlurSize 值会造成虚影 
    //而downSample 越大需要处理的像素数越少，同时也能进一步提高模糊程度，过大的downSample可能会使图像像素化。

    //****************************************    方法一   ****************************************//
    
    //定义关键的 OnRenderlmage 函数，调用shader，实现效果
    /* void OnRenderImage( RenderTexture src , RenderTexture dest ){
        if (material != null)
        {
            int rtW = src.width;
            int rtH = src.height;
            //高斯模糊需要调用两个 Pass,我们需要使用一块中间缓存来存储第一个 Pass 执行完毕后得到的模糊结果
            //所以这里利用 RenderTexture GetTemporary 函数分配了一块与屏幕图像大小相同的缓冲区
            RenderTexture buffer = RenderTexture.GetTemporary( rtW , rtH , 0 );
            //Temporary:临时的
            
            //我们首先调用 Graphics Blit(src buffer, material, 0),
            //使用 Shader 中的第一个 Pass （即使用竖直方向的一维高斯核进行滤波）对 src 进行处理，并将结果存储在 buffer 中。
            Graphics.Blit(src , buffer , material , 0);
            //再调用 graphics.Blit（ buffer dest, material, 1)
            //使用 Shader中的第二个 Pass (即使用水平方向的一维高斯核进行滤波）对 buffer 进行处理，返回最终屏幕图像。
            Graphics.Blit(buffer , dest , material , 1);
            //最后，还需要调用 RenderTexture ReleaseTemporary 来释放之前分 的缓存。

            RenderTexture.ReleaseTemporary( buffer );
        }
        else
        {
            Graphics.Blit(src , dest);
        } 
    } */

    ////****************************************    方法二   ****************************************//

    //利用缩放对图像进行降采样 从而减少需要处理的像素，提高性能。
    /* void OnRenderImage( RenderTexture src , RenderTexture dest){
        if (material != null)
        {
            int rtW = src.width/downSample;
            int rtH = src.height/downSample;
            //在声明缓冲区的大小时 使用了小于原屏幕分辨率的尺寸。
            //对图像进行降采样不仅可以减少需要处理的像素个数，提高性能，而且适当的降采样往往还可以得到更好的模糊效果。
            
            RenderTexture buffer = RenderTexture.GetTemporary( rtW , rtH , 0 );  //这里的0/1，是深度缓冲
            
            buffer.filterMode = FilterMode.Bilinear;
            //filter 过滤器       biliter：双线性
            //将该临时渲染纹理的滤波模式设置为双线性
            //双线性滤波模式见纹理那一章
            
            Graphics.Blit( src , buffer , material , 0);
            Graphics.Blit( buffer , dest , material , 1);
            RenderTexture.ReleaseTemporary(buffer);
        }
        else
        {
            Graphics.Blit( src , dest);
        }
    } */

    ////****************************************    方法三   ****************************************//
    //考虑了高斯模糊的迭代次数：
    void OnRenderImage (RenderTexture src, RenderTexture dest){
        if (material != null)
        {
            int rtW = src.width/downSample;
			int rtH = src.height/downSample;
            //在迭代开始前，我们首先定义了第一个缓存 bufferO, 并把 src 中的图像缩放后存储到 bufferO 中
            RenderTexture buffer0 = RenderTexture.GetTemporary(rtW , rtH , 0);
            buffer0.filterMode = FilterMode.Bilinear;
            Graphics.Blit(src , buffer0);

            //设置迭代次数
            for (int i = 0; i < iteration; i++)
            {
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
            ////迭代完成后 bufferO 将存储最终的图像，我们再利用 Graphics.Blit(bufferO<lest) 结果显示到屏幕上，并释放缓存。
            Graphics.Blit(buffer0 , dest);
            RenderTexture.ReleaseTemporary(buffer0);
        }
        else
        {
            Graphics.Blit(src , dest);
        }
    }
}
