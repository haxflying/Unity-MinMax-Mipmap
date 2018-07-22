using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class VolumetricShadow : MonoBehaviour {

    public Shader zShader;
    public Light mainLight;
    public RenderTexture target;

    private Material mat;
    private Camera cam;
    private CommandBuffer cb;
    private RenderTextureDescriptor mipDes;
    private RenderTexture mip;

	void Start () {
        mat = new Material(zShader);
        cam = Camera.main;
        cb = new CommandBuffer();
        cb.name = "MZ CB";
        mainLight.AddCommandBuffer(LightEvent.BeforeScreenspaceMask, cb);

        mipDes = new RenderTextureDescriptor(1024, 768, RenderTextureFormat.RG16, 0);
        mipDes.useMipMap = true;
        mipDes.autoGenerateMips = false;

        mip = new RenderTexture(mipDes);
        mip.filterMode = FilterMode.Point;
        mip.wrapMode = TextureWrapMode.Clamp;

        cb.Blit(null, target, mat);
    }

    private void GenerateMinMaxMip(CommandBuffer cb, RenderTexture mip)
    {
        for (int i = 0; i < 10; i++)
        {

        }
    }
    private void OnPostRender()
    {
        
    }
   
}
