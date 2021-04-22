using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MotionBlur : postEffect
{
   public Shader MotionBlurShader;
   public Material MotionBlurMaterial = null;
   public Material material{
       get {
           MotionBlurMaterial = CheckShaderAndCreateMaterial( MotionBlurShader , MotionBlurMaterial );
           return MotionBlurMaterial; 
       }
   }

   [Range(0.0f, 0.9f)]
   //blurAmount 的值越大,运动拖尾的效果就越明显，为了防止拖尾效果完全替代当前帧的渲染结果,把它的值截取在 0.0 0.9 范围内。
   public float blurAmount = 0.5f;

   //定义一个RenderTexture 类型的变量，保存之前图像叠加的结果
   private RenderTexture accumulationTexture;

   //我们在该脚本不运行时,即调用 OnDisable 函数时，立即销毁 accumulatioTexture 
   //是因为，我们希望在下一次开始应用运动模糊时重新叠加图像。
   void OnDisable(){
       DestroyImmediate (accumulationTexture);
   }

   //渲染多张图形，来混合累积的东西
   //需要抓取当前屏幕图形，与前一个混合，混合之后渲染到屏幕上
   //首先判断，是否可以accumulationTexture满足条件   因为这个要跟src中的混合 混合肯定得条件一样  所以要先判断
   //hideflag：HideFlags为枚举类，用于控制Object对象的销毁方式及其在检视面板中的可视性。
   //这里的hideflag是说这个渲染纹理的   不设置会怎么样？
   void OnRenderImage( RenderTexture src , RenderTexture dest){
       if (material != null)
       {
           if (accumulationTexture != null || accumulationTexture.width != src.width || accumulationTexture.height != src.height)
           {
               DestroyImmediate(accumulationTexture);
               accumulationTexture = new RenderTexture(src.width ,src.height ,0);
               accumulationTexture.hideFlags = HideFlags.HideAndDontSave;
               Graphics.Blit(src , accumulationTexture);
           }
           accumulationTexture.MarkRestoreExpected();
           material.SetFloat("_blurAmount", 1.0f-blurAmount);
           Graphics.Blit(src, accumulationTexture, material);
           Graphics.Blit(accumulationTexture, dest);
       }
       else
       {
           Graphics.Blit(src,dest);
       }
   }
}
