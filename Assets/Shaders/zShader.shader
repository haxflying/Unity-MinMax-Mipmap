﻿Shader "Hidden/zShader"
{

    CGINCLUDE

    #include "UnityCG.cginc"
    #include "UnityShadowLibrary.cginc"

    // Configuration

    // Should receiver plane bias be used? This estimates receiver slope using derivatives,
    // and tries to tilt the PCF kernel along it. However, since we're doing it in screenspace
    // from the depth texture, the derivatives are wrong on edges or intersections of objects,
    // leading to possible shadow artifacts. So it's disabled by default.
    // See also UnityGetReceiverPlaneDepthBias in UnityShadowLibrary.cginc.
    //#define UNITY_USE_RECEIVER_PLANE_BIAS
    // Blend between shadow cascades to hide the transition seams?
    #define UNITY_USE_CASCADE_BLENDING 0
    #define UNITY_CASCADE_BLEND_DISTANCE 0.1

    struct appdata
    {
        float4 vertex : POSITION;
        float2 texcoord : TEXCOORD0;

        UNITY_VERTEX_INPUT_INSTANCE_ID
    };

    struct v2f
    {

        float4 pos : SV_POSITION;

        // xy uv / zw screenpos
        float4 uv : TEXCOORD0;
        // View space ray, for perspective case
        float3 ray : TEXCOORD1;
        // Orthographic view space positions (need xy as well for oblique matrices)
        float3 orthoPosNear : TEXCOORD2;
        float3 orthoPosFar : TEXCOORD3;
        UNITY_VERTEX_INPUT_INSTANCE_ID
        UNITY_VERTEX_OUTPUT_STEREO
    };

    v2f vert(appdata v)
    {
        v2f o;
        UNITY_SETUP_INSTANCE_ID(v);
        UNITY_TRANSFER_INSTANCE_ID(v, o);
        UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
        float4 clipPos = UnityObjectToClipPos(v.vertex);
        o.pos = clipPos;
        o.uv.xy = v.texcoord;

        // unity_CameraInvProjection at the PS level.
        o.uv.zw = ComputeNonStereoScreenPos(clipPos);

        // Perspective case
        o.ray = mul(unity_CameraInvProjection, float4((float2(v.texcoord.x, v.texcoord.y) - 0.5) * 2, 1, -1) );
        // To compute view space position from Z buffer for orthographic case,

        // we need different code than for perspective case. We want to avoid
        // doing matrix multiply in the pixel shader: less operations, and less
        // constant registers used. Particularly with constant registers, having
        // unity_CameraInvProjection in the pixel shader would push the PS over SM2.0
        // limits.
        clipPos.y *= _ProjectionParams.x;
        float3 orthoPosNear = mul(unity_CameraInvProjection, float4(clipPos.x, clipPos.y, -1, 1)).xyz;
        float3 orthoPosFar = mul(unity_CameraInvProjection, float4(clipPos.x, clipPos.y, 1, 1)).xyz;
        orthoPosNear.z *= -1;
        orthoPosFar.z *= -1;
        o.orthoPosNear = orthoPosNear;
        o.orthoPosFar = orthoPosFar;

        return o;
    }
    // ------------------------------------------------------------------

    //  Helpers
    // ------------------------------------------------------------------
    UNITY_DECLARE_DEPTH_TEXTURE(_CameraDepthTexture);
    // sizes of cascade projections, relative to first one
    float4 unity_ShadowCascadeScales;
    //

    // Keywords based defines
    //
    #if defined (SHADOWS_SPLIT_SPHERES)
    #define GET_CASCADE_WEIGHTS(wpos, z)    getCascadeWeights_splitSpheres(wpos)
    #else
    #define GET_CASCADE_WEIGHTS(wpos, z)    getCascadeWeights( wpos, z )
    #endif

    #if defined (SHADOWS_SINGLE_CASCADE)
    #define GET_SHADOW_COORDINATES(wpos,cascadeWeights) getShadowCoord_SingleCascade(wpos)
    #else
    #define GET_SHADOW_COORDINATES(wpos,cascadeWeights) getShadowCoord(wpos,cascadeWeights)
    #endif

    /**
 * Gets the cascade weights based on the world position of the fragment.
 * Returns a float4 with only one component set that corresponds to the appropriate cascade.
 */
    inline fixed4 getCascadeWeights(float3 wpos, float z)
    {
        fixed4 zNear = float4(z >= _LightSplitsNear);
        fixed4 zFar = float4(z < _LightSplitsFar);
        fixed4 weights = zNear * zFar;
        return weights;
    }

    /**
 * Gets the cascade weights based on the world position of the fragment and the poisitions of the split spheres for each cascade.
 * Returns a float4 with only one component set that corresponds to the appropriate cascade.
 */
    inline fixed4 getCascadeWeights_splitSpheres(float3 wpos)
    {
        float3 fromCenter0 = wpos.xyz - unity_ShadowSplitSpheres[0].xyz;
        float3 fromCenter1 = wpos.xyz - unity_ShadowSplitSpheres[1].xyz;
        float3 fromCenter2 = wpos.xyz - unity_ShadowSplitSpheres[2].xyz;
        float3 fromCenter3 = wpos.xyz - unity_ShadowSplitSpheres[3].xyz;
        float4 distances2 = float4(dot(fromCenter0, fromCenter0), dot(fromCenter1, fromCenter1), dot(fromCenter2, fromCenter2), dot(fromCenter3, fromCenter3));
        fixed4 weights = float4(distances2 < unity_ShadowSplitSqRadii);
        weights.yzw = saturate(weights.yzw - weights.xyz);
        return weights;
    }

    /**
 * Returns the shadowmap coordinates for the given fragment based on the world position and z-depth.
 * These coordinates belong to the shadowmap atlas that contains the maps for all cascades.
 */
    inline float4 getShadowCoord(float4 wpos, fixed4 cascadeWeights)
    {
        float3 sc0 = mul(unity_WorldToShadow[0], wpos).xyz;
        float3 sc1 = mul(unity_WorldToShadow[1], wpos).xyz;
        float3 sc2 = mul(unity_WorldToShadow[2], wpos).xyz;
        float3 sc3 = mul(unity_WorldToShadow[3], wpos).xyz;
        float4 shadowMapCoordinate = float4(sc0 * cascadeWeights[0] + sc1 * cascadeWeights[1] + sc2 * cascadeWeights[2] + sc3 * cascadeWeights[3], 1);
        #if defined(UNITY_REVERSED_Z)
        float noCascadeWeights = 1 - dot(cascadeWeights, float4(1, 1, 1, 1));
        shadowMapCoordinate.z += noCascadeWeights;
        #endif
        return shadowMapCoordinate;
    }

    /**
 * Same as the getShadowCoord; but optimized for single cascade
 */
    inline float4 getShadowCoord_SingleCascade(float4 wpos)
    {
        return float4(mul(unity_WorldToShadow[0], wpos).xyz, 0);
    }

    /**
* Get camera space coord from depth and inv projection matrices
*/
    inline float3 computeCameraSpacePosFromDepthAndInvProjMat(v2f i)
    {
        float zdepth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv.xy);

        #if defined(UNITY_REVERSED_Z)
        zdepth = 1 - zdepth;
        #endif
        // View position calculation for oblique clipped projection case.

        // this will not be as precise nor as fast as the other method
        // (which computes it from interpolated ray & depth) but will work
        // with funky projections.
        float4 clipPos = float4(i.uv.zw, zdepth, 1.0);
        clipPos.xyz = 2.0f * clipPos.xyz - 1.0f;
        float4 camPos = mul(unity_CameraInvProjection, clipPos);
        camPos.xyz /= camPos.w;
        camPos.z *= -1;
        return camPos.xyz;
    }

    /**
* Get camera space coord from depth and info from VS
*/
    inline float3 computeCameraSpacePosFromDepthAndVSInfo(v2f i)
    {
        float zdepth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv.xy);

        // 0..1 linear depth, 0 at camera, 1 at far plane.
        float depth = lerp(Linear01Depth(zdepth), zdepth, unity_OrthoParams.w);
        #if defined(UNITY_REVERSED_Z)
        zdepth = 1 - zdepth;
        #endif

        // view position calculation for perspective & ortho cases
        float3 vposPersp = i.ray * depth;
        float3 vposOrtho = lerp(i.orthoPosNear, i.orthoPosFar, zdepth);
        // pick the perspective or ortho position as needed
        float3 camPos = lerp(vposPersp, vposOrtho, unity_OrthoParams.w);
        return camPos.xyz;
    }

    inline float3 computeCameraSpacePosFromDepth(v2f i);

    Texture2D _ShadowMapTexture;
    SamplerState sampler_ShadowMapTexture;
    //SamplerComparisonState sampler_ShadowMapTexture;
    //UNITY_DECLARE_SHADOWMAP(_ShadowMapTexture);
    //sampler2D _ShadowMapTexture;

    fixed4 frag_pcfSoft(v2f i) : SV_Target
    {
        UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
        i.ray.xyz *= 20;
        //return fixed4(i.ray.xyz, 1);
        // required for sampling the correct slice of the shadow map render texture array
        float3 vpos = computeCameraSpacePosFromDepth(i);

        // sample the cascade the pixel belongs to
        float4 wpos = mul(unity_CameraToWorld, float4(vpos, 1));
        fixed4 cascadeWeights = GET_CASCADE_WEIGHTS(wpos, vpos.z);
        float4 coord = GET_SHADOW_COORDINATES(wpos, cascadeWeights);
        //fixed shadow = UNITY_SAMPLE_SHADOW(_ShadowMapTexture, coord);
        //fixed shadow = _ShadowMapTexture.SampleCmpLevelZero(sampler_ShadowMapTexture, coord.xy, coord.z);
        //fixed shadow = tex2Dproj (_ShadowMapTexture,float4(coord.xyz,1)).r
        fixed shadow = _ShadowMapTexture.Sample(sampler_ShadowMapTexture, coord.xy).r;

        return shadow;
    }
    ENDCG
    // ----------------------------------------------------------------------------------------

    SubShader
    {
        Pass
        {
            Name "333"
            ZWrite Off
            ZTest Always
            Cull Off

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag_pcfSoft
            #pragma multi_compile_shadowcollector
            #pragma target 3.5
            

            inline float3 computeCameraSpacePosFromDepth(v2f i)
            {
                return computeCameraSpacePosFromDepthAndVSInfo(i);
            }
            ENDCG
        }
    }

    FallBack Off
}