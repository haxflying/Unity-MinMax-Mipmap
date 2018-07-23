using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class MipMapWriter : MonoBehaviour {

    public Shader mipShader, sampleShader;
    public Texture sourceTex;
    
    [Range(0,10)]
    public int miplevel;
    public RenderTexture mip;

    private Camera cam;
    private Material mipMat, samplerMat;

    private void Start()
    {
        samplerMat = new Material(sampleShader);
        mipMat = new Material(mipShader);
    }

    private void OnRenderImage(RenderTexture src, RenderTexture dst)
    {
        Graphics.Blit(sourceTex, mip);
        for (int i = 1; i < 11; i++)
        {
            mipMat.SetInt("_miplvl", i);
            Graphics.SetRenderTarget(mip, i);
            Graphics.Blit(sourceTex, mipMat, 0);
        }

        samplerMat.SetInt("_miplvl", miplevel);
        Graphics.Blit(mip, dst, samplerMat);
    }
}
