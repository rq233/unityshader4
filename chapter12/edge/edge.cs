using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class edge : postEffect
{
    // Start is called before the first frame update
    //void Start(){}
    // Update is called once per frame
    //void Update(){}

    public Shader edgeShader;
    private Material edgeMaterial = null;
    //调用基类 得到对应材质
    public Material material{
        get{
            edgeMaterial = CheckShaderAndCreateMaterial( edgeShader, edgeMaterial );
            return edgeMaterial;
        }
    }

    //卷积计算，得到梯度，比较边缘
    //需要的边缘的要素：边缘颜色，边缘粗细，背景颜色？为啥要背景颜色
    [Range( 0.0f , 1.0f )]
    //公私有类型 元素类型 元素名字 = 初始值
    public Color edgeColor = Color.black;
    public float edgeStrength = 0.0f;
    public Color background = Color.white;

    //edgesOnly值为 0 时，边缘将会叠加在原渲染图像上：当 dgesOnly 值为 1 时，则会只显示边缘，不显示原渲染图像。
    //其中，背景颜色由 backgroWldColor 指定，边缘颜色由 dgeColor 定。
    void OnRenderImage( RenderTexture src , RenderTexture dest){
        if (material != null)
        {
            material.SetColor("_EdgeColor",edgeColor);
            material.SetFloat("_EdgeStrength",edgeStrength);
            material.SetColor("_Background",background);
            Graphics.Blit( src , dest , material);
        }
        else
        {
            Graphics.Blit( src , dest );
        }
    }
}
