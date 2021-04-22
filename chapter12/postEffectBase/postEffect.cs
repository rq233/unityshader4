using System.Collections;
using System.Collections.Generic;
using UnityEngine;

//******************将后处理都绑定在某个摄像机上，并可以在编辑器上也可以执行该脚本来查看效果******************//
//在编辑器状态下执行该脚本
[ExecuteInEditMode]
//刚需组件（Camera）
[RequireComponent(typeof (Camera))]
public class postEffect :MonoBehaviour
{
    //******************检查各种资源和条件是否满足，在start函数中调用函数检查******************//
    protected void CheckResources(){
        bool isSupported = CheckSupport();
        if (isSupported == false)
        {
            NotSupported();
        }
    }

    //检查是否该平台是否支持渲染纹理和屏幕特效
    protected bool CheckSupport(){
        if (SystemInfo.supportsImageEffects == false || SystemInfo.supportsRenderTextures == false)
        {
            Debug.LogWarning("This platform doesn't support this image effect or render texture");
            return false;
        }
        return true;
    }

    // 当不支持的时候，将脚本的enabled设置为false
    protected void NotSupported(){
        enabled = false;
    }

    //开始即执行检查操作
    protected void Start(){
        CheckResources();
    }
    
    //******************指定一个shader来创建用于处理渲染纹理的材质******************//
    //检测Material和Shader，在派生类中调用，绑定材质和shader
    //CheckSbaderAndCreateMateriaJ 函数接受两个参数 
    //第一个参数指定了该特效需要使用的Shader。
    //第二个参数则是用于后期处理的材质。
    //该函数首先检查 Shader 的可用性，检查通过后就返回一个使用了该 Shader 的材质，否则返回 null
    protected Material CheckShaderAndCreateMaterial( Shader shader, Material material ){
        if (shader == null)
        {
            return null;
        }
        if (shader.isSupported && material && material.shader == shader)
        {
            return material;
        }
        if (!shader.isSupported)
        {
            return null;
        }
        else
        {
            material = new Material(shader);
            material.hideFlags = HideFlags.DontSave;
            //hideFlags:位掩码，用于控制对象的销毁、保存和在 Inspector 中的可见性。
            //.dontsave 该对象不保存到场景。加载新场景时，也不会销毁它。
            if(material)
               return material;
            else
               return null;
        }
    }
}
