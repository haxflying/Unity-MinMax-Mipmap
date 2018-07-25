using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class MinMaxOneD : MonoBehaviour {

    public Shader mmShader;
    public Light mainLight;
    public ComputeShader cs_light;
    public RenderTexture shadowMapCopy, target;

    private CommandBuffer cb_sm, cb_cs;
    private Material mmMat;
    private Camera cam;
    private ComputeBuffer mipTreeBuffer;

    private void Start()
    {
        mmMat = new Material(mmShader);
        cam = Camera.main;

        cb_sm = new CommandBuffer();
        cb_sm.name = "MZ Sample ShadowMap";
        mainLight.AddCommandBuffer(LightEvent.AfterShadowMap, cb_sm);

        RenderTargetIdentifier shadowmap = BuiltinRenderTextureType.CurrentActive;
        cb_sm.SetShadowSamplingMode(shadowmap, ShadowSamplingMode.RawDepth);
        cb_sm.Blit(shadowmap, new RenderTargetIdentifier(shadowMapCopy));
        

        int kernel = InitCS();
        cb_sm.DispatchCompute(cs_light, kernel, 128, 1, 1);

        cb_sm.Blit(null, target, mmMat);
    } 
    
    private int InitCS()
    {
        int count = 1024 * 2047;
        mipTreeBuffer = new ComputeBuffer(count, 2 * sizeof(float), ComputeBufferType.Default);      

        int kernel = cs_light.FindKernel("CSMain");
        if(kernel == -1)
            Debug.LogError("Failed to find kernel");

        cs_light.SetBuffer(kernel, "minmaxTree", mipTreeBuffer);
        cs_light.SetTexture(kernel, "shadowTex", shadowMapCopy);
        mmMat.SetBuffer("cs_res", mipTreeBuffer);
        return kernel;
    }

    //private void OnRenderImage(RenderTexture src, RenderTexture dst)
    //{
    //    Graphics.Blit(src, dst, mmMat);
    //}
}
