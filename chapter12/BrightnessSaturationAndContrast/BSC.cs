using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class BSC : postEffect
{
    //briSatConShader 是我们指定的 Shader, 对应了后面将会实现的 Chapter12-BrightnessSaturationAndContras
    public Shader BSCShader;
    //briSatConMaterial 是创建的材质，我们提供了名为 material 的材质来访问它
    private Material BSCMaterial;
    //material get 函数调用了基类的 CheckShaderAndCreateMaterial 函数来得到对应的材质
    public Material material {
        get{
            BSCMaterial = CheckShaderAndCreateMaterial( BSCShader , BSCMaterial );
            return BSCMaterial;
        }
    }

    //提供调整亮度、饱和度和对度的参数
    [Range(0.0f,3.0f)]
    public float brightness = 1.0f;
    [Range(0.0f,3.0f)]
    public float saturation = 1.0f;
    [Range(0.0f,3.0f)]
    public float contrast = 1.0f;

    //定义 OnRenderlmage 函数来进行真正的特效处理
    //调用onrenderimage首先会检查材质是否可用，如果可用则将参数传递给材质，否则就直接将图形显示到屏幕上
    
    //思路：
    //亮度：我们可以直接在采样texture后乘以一个系数，达到放大或者缩小rgb值的目的，这样就可以调整亮度了。
    
    //其次是饱和度，饱和度是离灰度偏离越大，饱和度越大，我们首先可以计算一下同等亮度条件下饱和度最低的值
    //根据公式：gray = 0.2125 * r + 0.7154 * g + 0.0721 * b即可求出该值（公式应该是一个经验公式）
    //然后我们使用该值和原始图像之间用一个系数进行差值，即可达到调整饱和度的目的。
    
    //最后是对比度，对比度表示颜色差异越大对比度越强，当颜色为纯灰色，也就是（0.5,0.5,0.5）时，对比度最小
    //我们通过在对比度最小的图像和原始图像通过系数差值，达到调整对比度的目的。
    void OnRenderImage( RenderTexture src , RenderTexture dest){
        if ( material != null)
        {
            //在每一帧设置Material的各项参数，通过Material.SetXXX("name",value)可以向shader中传递各种参数。
            material.SetFloat( "_Brightness" , brightness );
            material.SetFloat( "_Contrast", contrast );
            material.SetFloat( "_Saturation" , saturation );
            
            //graphics.blit：public static void Blit(Texture source,RenderTexture dest, Material mat, int pass = -1);    
            //将源纹理拷贝到目标纹理
            Graphics.Blit( src , dest , material );
        }
        else
        {
            Graphics.Blit( src , dest );
        }
    }
}
