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
    private CommandBuffer cb_sm, cb_mip;

	void Start () {
        mipMat = new Material(mipShader);
        cam = Camera.main;

        cb_sm = new CommandBuffer();
        cb_sm.name = "MZ Sample ShadowMap";
        mainLight.AddCommandBuffer(LightEvent.AfterShadowMap, cb_sm);

        RenderTargetIdentifier shadowmap = BuiltinRenderTextureType.CurrentActive;
        cb_sm.SetShadowSamplingMode(shadowmap, ShadowSamplingMode.RawDepth);
        cb_sm.Blit(shadowmap, new RenderTargetIdentifier(shadowMapCopy));

        cb_mip = new CommandBuffer();
        cb_mip.name = "MZ Write Mip";
        cam.AddCommandBuffer(CameraEvent.BeforeImageEffects, cb_mip);
        cb_mip.Blit(testSource, minmaxmip);
        cb_mip.SetRenderTarget(minmaxmip, 10);
        cb_mip.Blit(testSource, BuiltinRenderTextureType.CurrentActive, mipMat, 0);
    }    

}
