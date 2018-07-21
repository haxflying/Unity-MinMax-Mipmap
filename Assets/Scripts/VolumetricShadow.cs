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

	void Start () {
        mat = new Material(zShader);
        cam = Camera.main;
        cb = new CommandBuffer();
        cb.name = "MZ CB";
        mainLight.AddCommandBuffer(LightEvent.BeforeScreenspaceMask, cb);
        cb.Blit(BuiltinRenderTextureType.CurrentActive, target, mat);
    }

    private void OnPostRender()
    {
        
    }
   
}
