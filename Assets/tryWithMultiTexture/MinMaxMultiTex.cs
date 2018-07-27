using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class MinMaxMultiTex : MonoBehaviour {

    public Shader mmShader, raytraceShader;
    public Light mainLight;
    public RenderTexture shadowMapCopy;
    public Texture test;

    [Range(0, 9)]
    public int miplvl = 0;

    private Material mmMat, rayTraceMat;
    private CommandBuffer cb_sm;
    private Camera cam;
    private RenderTexture minmaxRT;

    private void Start()
    {
        mmMat = new Material(mmShader);
        rayTraceMat = new Material(raytraceShader);
        cam = Camera.main;

        cb_sm = new CommandBuffer();
        cb_sm.name = "MZ Sample ShadowMap";
        mainLight.AddCommandBuffer(LightEvent.AfterShadowMap, cb_sm);

        RenderTargetIdentifier shadowmap = BuiltinRenderTextureType.CurrentActive;
        cb_sm.SetShadowSamplingMode(shadowmap, ShadowSamplingMode.RawDepth);
        cb_sm.Blit(shadowmap, new RenderTargetIdentifier(shadowMapCopy));

        int[] mip_id = new int[10];
        int size = 1024;
        RenderTargetIdentifier sourceId = new RenderTargetIdentifier(shadowMapCopy);

        for (int i = 0; i < 10; i++)
        {
            mip_id[i] = Shader.PropertyToID("minmax_" + i.ToString());
            size = size >> 1;
            if (size == 0)
                size = 1;

            RenderTexture temp = RenderTexture.GetTemporary(size, 1024, 0, RenderTextureFormat.RGHalf, RenderTextureReadWrite.Linear);
            temp.filterMode = FilterMode.Point;
            temp.useMipMap = false;
            if(i == 0)
            {
                cb_sm.Blit(sourceId, temp, mmMat, 0);
            }
            else
            {
                cb_sm.Blit(sourceId, temp, mmMat, 1);
            }
            rayTraceMat.SetTexture("sm_mip_" + i.ToString(), temp);
            temp.Release();
        }
    }

    private void OnRenderImage(RenderTexture src, RenderTexture dst)
    {
        rayTraceMat.SetInt("_miplvl", miplvl);
        Graphics.Blit(src, dst, rayTraceMat);
    }
}
