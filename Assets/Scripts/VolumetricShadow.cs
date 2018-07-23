using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class VolumetricShadow : MonoBehaviour {

    public Shader mipShader;
    public Light mainLight;
    public RenderTexture shadowMapCopy, minmaxmip;
    public Texture2D testSource;

    private Material mipMat;
    private Camera cam;
    private CommandBuffer cb;

	void Start () {
        mipMat = new Material(mipShader);
        cam = Camera.main;
        cb = new CommandBuffer();
        cb.name = "MZ Sample ShadowMap";
        mainLight.AddCommandBuffer(LightEvent.AfterShadowMap, cb);

        RenderTargetIdentifier shadowmap = BuiltinRenderTextureType.CurrentActive;
        cb.SetShadowSamplingMode(shadowmap, ShadowSamplingMode.RawDepth);
        cb.Blit(shadowmap, new RenderTargetIdentifier(shadowMapCopy));

        cb.SetRenderTarget(minmaxmip, 0);
        mipMat.SetInt("_mipLevel", 1);
        cb.Blit(testSource, BuiltinRenderTextureType.CurrentActive);

        cb.SetRenderTarget(minmaxmip, 1);
        cb.Blit(testSource, BuiltinRenderTextureType.CurrentActive, mipMat);
    }    

    //private void OnRenderImage(RenderTexture src, RenderTexture dst)
    //{
    //    for (int i = 0; i < 10; i++)
    //    {
    //        mipMat.SetInt("_mipLevel", i + 1);
    //        Graphics.SetRenderTarget(minmaxmip, i + 1);
    //        Graphics.Blit(shadowMapCopy, minmaxmip, mipMat);
    //    }
    //}
}
