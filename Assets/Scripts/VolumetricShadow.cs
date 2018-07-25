using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class VolumetricShadow : MonoBehaviour {

    public Shader mipShader, samplerShader;
    public Light mainLight;
    public RenderTexture shadowMapCopy, target;//for test
    public Texture2D sourceTex;

    [Range(0, 10)]
    public int miplevel;

    private Material mipMat, samplerMat;
    private Camera cam;
    private CommandBuffer cb_sm, cb_mip;

    private RenderTexture test;


    void Start () {
        mipMat = new Material(mipShader);
        samplerMat = new Material(samplerShader);
        cam = Camera.main;

        cb_sm = new CommandBuffer();
        cb_sm.name = "MZ Sample ShadowMap";
        mainLight.AddCommandBuffer(LightEvent.AfterShadowMap, cb_sm);

        RenderTargetIdentifier shadowmap = BuiltinRenderTextureType.CurrentActive;
        cb_sm.SetShadowSamplingMode(shadowmap, ShadowSamplingMode.RawDepth);
        cb_sm.Blit(shadowmap, new RenderTargetIdentifier(shadowMapCopy));
        cb_sm.Blit(shadowMapCopy, target, samplerMat);

        //cb_mip = new CommandBuffer();
        //cb_mip.name = "MZ Write Mip";
        //cam.AddCommandBuffer(CameraEvent.BeforeImageEffects, cb_mip);

        //hard coded for temp version       
        //int[] temp_mip = new int[10];
        //int size = 1024;
        //test = new RenderTexture(size, size, 0, RenderTextureFormat.RGHalf);
        //test.filterMode = FilterMode.Point;
        //test.useMipMap = true;
        //test.autoGenerateMips = false;
        //test.Create();

        //RenderTargetIdentifier sourceID = new RenderTargetIdentifier(test);

        //for (int i = 0; i < 10; i++)
        //{
        //    temp_mip[i] = Shader.PropertyToID("Temp_target " + i.ToString());
            

        //    if (size == 0)
        //        size = 1;

        //    cb_mip.GetTemporaryRT(temp_mip[i], size, size, 0, FilterMode.Point,
        //        RenderTextureFormat.RGHalf, RenderTextureReadWrite.Linear);

        //    if (i == 0)
        //        cb_mip.Blit(shadowMapCopy, temp_mip[0], mipMat, 0);
        //    else
        //        cb_mip.Blit(temp_mip[i - 1], temp_mip[i], mipMat, 0);

        //    cb_mip.CopyTexture(temp_mip[i], 0, 0, sourceID, 0, i);
        //    size >>= 1;
        //    if (i >= 1)
        //        cb_mip.ReleaseTemporaryRT(temp_mip[i - 1]);
        //}

        //cb_mip.ReleaseTemporaryRT(temp_mip[9]);

        //cb_mip = new CommandBuffer();
        //cb_mip.name = "MZ Write Mip";
        //cam.AddCommandBuffer(CameraEvent.BeforeImageEffects, cb_mip);
        //cb_mip.Blit(sourceTex, minmaxmip);

        //for (int i = 1; i < 11; i++)
        //{
        //    cb_mip.SetRenderTarget(minmaxmip, i);
        //    mipMat.SetInt("_miplvl", i);
        //    cb_mip.Blit(sourceTex, BuiltinRenderTextureType.CurrentActive, mipMat, 0);
        //}     
    }

    private void OnRenderImage(RenderTexture src, RenderTexture dst)
    {
        //generate min max mipmap
        RenderTexture buffer = new RenderTexture(shadowMapCopy.width, shadowMapCopy.height, 0, RenderTextureFormat.RGHalf);
        Graphics.Blit(shadowMapCopy, buffer, mipMat, 0); //from r to rg min max
        for (int i = 1; i < 10; i++)
        {
            mipMat.SetInt("_miplvl", i);
            Graphics.SetRenderTarget(shadowMapCopy, i);
            Graphics.Blit(buffer, mipMat, 1); //rg to rg
        }
        Graphics.Blit(src, dst);
    }
}
