using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

public class MinMaxMultiTex : MonoBehaviour {

    public Shader mmShader;
    public Light mainLight;
    public RenderTexture shadowMapCopy;

    private Material mmMat;
    private CommandBuffer cb_sm;
    private Camera cam;

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

        int[] mip_id = new int[10];
        for (int i = 0; i < 10; i++)
        {
            
        }
    }
}
