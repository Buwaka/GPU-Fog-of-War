Shader "Clouds_Generated"
{
    Properties
    {
        Vector4_484BA326("Rotate Projection", Vector) = (1, 0, 0, 0)
        Vector1_8F075DBC("Noise Scale", Float) = 10
        Vector1_8AAD665C("Noise Speed", Float) = 0.1
        Vector1_E43D3892("Noise Height", Float) = 1
        Vector4_1696EE66("Noise Remap", Vector) = (0, 1, -1, 1)
        Color_2CFB5E2A("Color Peak", Color) = (1, 1, 1, 0)
        Color_58195353("Color Valley", Color) = (0, 0, 0, 0)
        Vector1_FADC0395("Noise Edge 1", Float) = 0
        Vector1_E505CA4B("Noise Edge 2", Float) = 1
        Vector1_4CE104D9("Noise Power", Float) = 2
        Vector1_5536221E("Base Scale", Float) = 5
        Vector1_9058DE8C("Base Speed", Float) = 0.2
        Vector1_350643F1("Base Strength", Float) = 2
        Vector1_2A80C598("Emission Strength", Float) = 2
        Vector1_A664731F("Curvature Radius", Float) = 1
        Vector1_B4ED823D("Fresnel Power", Float) = 1
        Vector1_2BA361A8("Fresnel Opacity", Float) = 1
        Vector1_EED1A887("Fade Depth", Float) = 100
        [HideInInspector][NoScaleOffset]unity_Lightmaps("unity_Lightmaps", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset]unity_LightmapsInd("unity_LightmapsInd", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset]unity_ShadowMasks("unity_ShadowMasks", 2DArray) = "" {}
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalPipeline"
            "RenderType"="Transparent"
            "UniversalMaterialType" = "Lit"
            "Queue"="Transparent"
        }
        Pass
        {
            Name "Universal Forward"
            Tags
            {
                "LightMode" = "UniversalForward"
            }

            // Render State
            Cull Back
        Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
        ZTest LEqual
        ZWrite Off

            // Debug
            // <None>

            // --------------------------------------------------
            // Pass

            HLSLPROGRAM

            // Pragmas
            #pragma target 4.5
        #pragma exclude_renderers gles gles3 glcore
        #pragma multi_compile_instancing
        #pragma multi_compile_fog
        #pragma multi_compile _ DOTS_INSTANCING_ON
        #pragma vertex vert
        #pragma fragment frag

            // DotsInstancingOptions: <None>
            // HybridV1InjectedBuiltinProperties: <None>

            // Keywords
            #pragma multi_compile _ _SCREEN_SPACE_OCCLUSION
        #pragma multi_compile _ LIGHTMAP_ON
        #pragma multi_compile _ DIRLIGHTMAP_COMBINED
        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
        #pragma multi_compile _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS _ADDITIONAL_OFF
        #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
        #pragma multi_compile _ _SHADOWS_SOFT
        #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
        #pragma multi_compile _ SHADOWS_SHADOWMASK
            // GraphKeywords: <None>

            // Defines
            #define _SURFACE_TYPE_TRANSPARENT 1
            #define _NORMALMAP 1
            #define _NORMAL_DROPOFF_TS 1
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define ATTRIBUTES_NEED_TEXCOORD1
            #define VARYINGS_NEED_POSITION_WS
            #define VARYINGS_NEED_NORMAL_WS
            #define VARYINGS_NEED_TANGENT_WS
            #define VARYINGS_NEED_VIEWDIRECTION_WS
            #define VARYINGS_NEED_FOG_AND_VERTEX_LIGHT
            #define FEATURES_GRAPH_VERTEX
            /* WARNING: $splice Could not find named fragment 'PassInstancing' */
            #define SHADERPASS SHADERPASS_FORWARD
        #define REQUIRE_DEPTH_TEXTURE
            /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

            // --------------------------------------------------
            // Structs and Packing

            struct Attributes
        {
            float3 positionOS : POSITION;
            float3 normalOS : NORMAL;
            float4 tangentOS : TANGENT;
            float4 uv1 : TEXCOORD1;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
            float4 positionCS : SV_POSITION;
            float3 positionWS;
            float3 normalWS;
            float4 tangentWS;
            float3 viewDirectionWS;
            #if defined(LIGHTMAP_ON)
            float2 lightmapUV;
            #endif
            #if !defined(LIGHTMAP_ON)
            float3 sh;
            #endif
            float4 fogFactorAndVertexLight;
            float4 shadowCoord;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
            float3 WorldSpaceNormal;
            float3 TangentSpaceNormal;
            float3 WorldSpaceViewDirection;
            float3 WorldSpacePosition;
            float4 ScreenPosition;
            float3 TimeParameters;
        };
        struct VertexDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 WorldSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 ObjectSpacePosition;
            float3 WorldSpacePosition;
            float3 TimeParameters;
        };
        struct PackedVaryings
        {
            float4 positionCS : SV_POSITION;
            float3 interp0 : TEXCOORD0;
            float3 interp1 : TEXCOORD1;
            float4 interp2 : TEXCOORD2;
            float3 interp3 : TEXCOORD3;
            #if defined(LIGHTMAP_ON)
            float2 interp4 : TEXCOORD4;
            #endif
            #if !defined(LIGHTMAP_ON)
            float3 interp5 : TEXCOORD5;
            #endif
            float4 interp6 : TEXCOORD6;
            float4 interp7 : TEXCOORD7;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };

            PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            output.interp2.xyzw =  input.tangentWS;
            output.interp3.xyz =  input.viewDirectionWS;
            #if defined(LIGHTMAP_ON)
            output.interp4.xy =  input.lightmapUV;
            #endif
            #if !defined(LIGHTMAP_ON)
            output.interp5.xyz =  input.sh;
            #endif
            output.interp6.xyzw =  input.fogFactorAndVertexLight;
            output.interp7.xyzw =  input.shadowCoord;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            output.tangentWS = input.interp2.xyzw;
            output.viewDirectionWS = input.interp3.xyz;
            #if defined(LIGHTMAP_ON)
            output.lightmapUV = input.interp4.xy;
            #endif
            #if !defined(LIGHTMAP_ON)
            output.sh = input.interp5.xyz;
            #endif
            output.fogFactorAndVertexLight = input.interp6.xyzw;
            output.shadowCoord = input.interp7.xyzw;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }

            // --------------------------------------------------
            // Graph

            // Graph Properties
            CBUFFER_START(UnityPerMaterial)
        float4 Vector4_484BA326;
        float Vector1_8F075DBC;
        float Vector1_8AAD665C;
        float Vector1_E43D3892;
        float4 Vector4_1696EE66;
        float4 Color_2CFB5E2A;
        float4 Color_58195353;
        float Vector1_FADC0395;
        float Vector1_E505CA4B;
        float Vector1_4CE104D9;
        float Vector1_5536221E;
        float Vector1_9058DE8C;
        float Vector1_350643F1;
        float Vector1_2A80C598;
        float Vector1_A664731F;
        float Vector1_B4ED823D;
        float Vector1_2BA361A8;
        float Vector1_EED1A887;
        CBUFFER_END

        // Object and Global properties

            // Graph Functions
            
        void Unity_Distance_float3(float3 A, float3 B, out float Out)
        {
            Out = distance(A, B);
        }

        void Unity_Divide_float(float A, float B, out float Out)
        {
            Out = A / B;
        }

        void Unity_Power_float(float A, float B, out float Out)
        {
            Out = pow(A, B);
        }

        void Unity_Multiply_float(float3 A, float3 B, out float3 Out)
        {
            Out = A * B;
        }

        void Unity_Rotate_About_Axis_Degrees_float(float3 In, float3 Axis, float Rotation, out float3 Out)
        {
            Rotation = radians(Rotation);

            float s = sin(Rotation);
            float c = cos(Rotation);
            float one_minus_c = 1.0 - c;
            
            Axis = normalize(Axis);

            float3x3 rot_mat = { one_minus_c * Axis.x * Axis.x + c,            one_minus_c * Axis.x * Axis.y - Axis.z * s,     one_minus_c * Axis.z * Axis.x + Axis.y * s,
                                      one_minus_c * Axis.x * Axis.y + Axis.z * s,   one_minus_c * Axis.y * Axis.y + c,              one_minus_c * Axis.y * Axis.z - Axis.x * s,
                                      one_minus_c * Axis.z * Axis.x - Axis.y * s,   one_minus_c * Axis.y * Axis.z + Axis.x * s,     one_minus_c * Axis.z * Axis.z + c
                                    };

            Out = mul(rot_mat,  In);
        }

        void Unity_Multiply_float(float A, float B, out float Out)
        {
            Out = A * B;
        }

        void Unity_TilingAndOffset_float(float2 UV, float2 Tiling, float2 Offset, out float2 Out)
        {
            Out = UV * Tiling + Offset;
        }


        float2 Unity_GradientNoise_Dir_float(float2 p)
        {
            // Permutation and hashing used in webgl-nosie goo.gl/pX7HtC
            p = p % 289;
            // need full precision, otherwise half overflows when p > 1
            float x = float(34 * p.x + 1) * p.x % 289 + p.y;
            x = (34 * x + 1) * x % 289;
            x = frac(x / 41) * 2 - 1;
            return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
        }

        void Unity_GradientNoise_float(float2 UV, float Scale, out float Out)
        { 
            float2 p = UV * Scale;
            float2 ip = floor(p);
            float2 fp = frac(p);
            float d00 = dot(Unity_GradientNoise_Dir_float(ip), fp);
            float d01 = dot(Unity_GradientNoise_Dir_float(ip + float2(0, 1)), fp - float2(0, 1));
            float d10 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 0)), fp - float2(1, 0));
            float d11 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 1)), fp - float2(1, 1));
            fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
            Out = lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x) + 0.5;
        }

        void Unity_Add_float(float A, float B, out float Out)
        {
            Out = A + B;
        }

        void Unity_Saturate_float(float In, out float Out)
        {
            Out = saturate(In);
        }

        void Unity_Combine_float(float R, float G, float B, float A, out float4 RGBA, out float3 RGB, out float2 RG)
        {
            RGBA = float4(R, G, B, A);
            RGB = float3(R, G, B);
            RG = float2(R, G);
        }

        void Unity_Remap_float(float In, float2 InMinMax, float2 OutMinMax, out float Out)
        {
            Out = OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
        }

        void Unity_Absolute_float(float In, out float Out)
        {
            Out = abs(In);
        }

        void Unity_Smoothstep_float(float Edge1, float Edge2, float In, out float Out)
        {
            Out = smoothstep(Edge1, Edge2, In);
        }

        void Unity_Add_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A + B;
        }

        void Unity_Lerp_float4(float4 A, float4 B, float4 T, out float4 Out)
        {
            Out = lerp(A, B, T);
        }

        void Unity_FresnelEffect_float(float3 Normal, float3 ViewDir, float Power, out float Out)
        {
            Out = pow((1.0 - saturate(dot(normalize(Normal), normalize(ViewDir)))), Power);
        }

        void Unity_Add_float4(float4 A, float4 B, out float4 Out)
        {
            Out = A + B;
        }

        void Unity_Multiply_float(float4 A, float4 B, out float4 Out)
        {
            Out = A * B;
        }

        void Unity_SceneDepth_Eye_float(float4 UV, out float Out)
        {
            Out = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH(UV.xy), _ZBufferParams);
        }

        void Unity_Subtract_float(float A, float B, out float Out)
        {
            Out = A - B;
        }

            // Graph Vertex
            struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };

        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            float _Distance_474c9e8e982c878dad2f0d5844b22ee9_Out_2;
            Unity_Distance_float3(SHADERGRAPH_OBJECT_POSITION, IN.WorldSpacePosition, _Distance_474c9e8e982c878dad2f0d5844b22ee9_Out_2);
            float _Property_95b6af28bf5d388fb7809e99d4ea7a10_Out_0 = Vector1_A664731F;
            float _Divide_2022c703e9e6de87965706bd214b7b67_Out_2;
            Unity_Divide_float(_Distance_474c9e8e982c878dad2f0d5844b22ee9_Out_2, _Property_95b6af28bf5d388fb7809e99d4ea7a10_Out_0, _Divide_2022c703e9e6de87965706bd214b7b67_Out_2);
            float _Power_8710b3fb1efe3183a2818b946e662a1e_Out_2;
            Unity_Power_float(_Divide_2022c703e9e6de87965706bd214b7b67_Out_2, 3, _Power_8710b3fb1efe3183a2818b946e662a1e_Out_2);
            float3 _Multiply_3fa32f2d7f56688684a8f5b0a0853be5_Out_2;
            Unity_Multiply_float(IN.WorldSpaceNormal, (_Power_8710b3fb1efe3183a2818b946e662a1e_Out_2.xxx), _Multiply_3fa32f2d7f56688684a8f5b0a0853be5_Out_2);
            float _Property_45fc02a5c65e898c82a51138ee7894c8_Out_0 = Vector1_FADC0395;
            float _Property_423be2625737e5829e3daa7b3cf8389d_Out_0 = Vector1_E505CA4B;
            float4 _Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0 = Vector4_484BA326;
            float _Split_e9324c176bf05a809ea8df8c413a826a_R_1 = _Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0[0];
            float _Split_e9324c176bf05a809ea8df8c413a826a_G_2 = _Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0[1];
            float _Split_e9324c176bf05a809ea8df8c413a826a_B_3 = _Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0[2];
            float _Split_e9324c176bf05a809ea8df8c413a826a_A_4 = _Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0[3];
            float3 _RotateAboutAxis_430e3c523bf85e84bdef451ab28beba0_Out_3;
            Unity_Rotate_About_Axis_Degrees_float(IN.WorldSpacePosition, (_Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0.xyz), _Split_e9324c176bf05a809ea8df8c413a826a_A_4, _RotateAboutAxis_430e3c523bf85e84bdef451ab28beba0_Out_3);
            float _Property_84dca49c8958708fac3276b0de15a6da_Out_0 = Vector1_8AAD665C;
            float _Multiply_89f92af49e152081ba549c92ab002e9c_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_84dca49c8958708fac3276b0de15a6da_Out_0, _Multiply_89f92af49e152081ba549c92ab002e9c_Out_2);
            float2 _TilingAndOffset_bd9fc632c3a6c185b226f93212ed8603_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_430e3c523bf85e84bdef451ab28beba0_Out_3.xy), float2 (1, 1), (_Multiply_89f92af49e152081ba549c92ab002e9c_Out_2.xx), _TilingAndOffset_bd9fc632c3a6c185b226f93212ed8603_Out_3);
            float _Property_f7111fce9be08b8c871514ffc219f648_Out_0 = Vector1_8F075DBC;
            float _GradientNoise_de42ec7fdd52ec8fa0b6cb7f34842c13_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_bd9fc632c3a6c185b226f93212ed8603_Out_3, _Property_f7111fce9be08b8c871514ffc219f648_Out_0, _GradientNoise_de42ec7fdd52ec8fa0b6cb7f34842c13_Out_2);
            float2 _TilingAndOffset_aa88c06674f4178889e657a2bb46c454_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_430e3c523bf85e84bdef451ab28beba0_Out_3.xy), float2 (1, 1), float2 (0, 0), _TilingAndOffset_aa88c06674f4178889e657a2bb46c454_Out_3);
            float _GradientNoise_28996fa0f6fbd08c97ed18d0621900b5_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_aa88c06674f4178889e657a2bb46c454_Out_3, _Property_f7111fce9be08b8c871514ffc219f648_Out_0, _GradientNoise_28996fa0f6fbd08c97ed18d0621900b5_Out_2);
            float _Add_caf5f972abacae878d9a6fde10e0986a_Out_2;
            Unity_Add_float(_GradientNoise_de42ec7fdd52ec8fa0b6cb7f34842c13_Out_2, _GradientNoise_28996fa0f6fbd08c97ed18d0621900b5_Out_2, _Add_caf5f972abacae878d9a6fde10e0986a_Out_2);
            float _Divide_27ef561e54cd208ca89512269c1d4d03_Out_2;
            Unity_Divide_float(_Add_caf5f972abacae878d9a6fde10e0986a_Out_2, 2, _Divide_27ef561e54cd208ca89512269c1d4d03_Out_2);
            float _Saturate_c56694103011198486afa78b0e89ec2c_Out_1;
            Unity_Saturate_float(_Divide_27ef561e54cd208ca89512269c1d4d03_Out_2, _Saturate_c56694103011198486afa78b0e89ec2c_Out_1);
            float _Property_8bd1d491d3050588a0b837b4b232170d_Out_0 = Vector1_4CE104D9;
            float _Power_abb6d235206009809ee431a98f2c8247_Out_2;
            Unity_Power_float(_Saturate_c56694103011198486afa78b0e89ec2c_Out_1, _Property_8bd1d491d3050588a0b837b4b232170d_Out_0, _Power_abb6d235206009809ee431a98f2c8247_Out_2);
            float4 _Property_8a81e8a6d963f384bddf6e75ec8e0a1c_Out_0 = Vector4_1696EE66;
            float _Split_f72e1ad87d56df8ba34ec31e2bc432b8_R_1 = _Property_8a81e8a6d963f384bddf6e75ec8e0a1c_Out_0[0];
            float _Split_f72e1ad87d56df8ba34ec31e2bc432b8_G_2 = _Property_8a81e8a6d963f384bddf6e75ec8e0a1c_Out_0[1];
            float _Split_f72e1ad87d56df8ba34ec31e2bc432b8_B_3 = _Property_8a81e8a6d963f384bddf6e75ec8e0a1c_Out_0[2];
            float _Split_f72e1ad87d56df8ba34ec31e2bc432b8_A_4 = _Property_8a81e8a6d963f384bddf6e75ec8e0a1c_Out_0[3];
            float4 _Combine_aeef4bbea8acc688b198e488208172f2_RGBA_4;
            float3 _Combine_aeef4bbea8acc688b198e488208172f2_RGB_5;
            float2 _Combine_aeef4bbea8acc688b198e488208172f2_RG_6;
            Unity_Combine_float(_Split_f72e1ad87d56df8ba34ec31e2bc432b8_R_1, _Split_f72e1ad87d56df8ba34ec31e2bc432b8_G_2, 0, 0, _Combine_aeef4bbea8acc688b198e488208172f2_RGBA_4, _Combine_aeef4bbea8acc688b198e488208172f2_RGB_5, _Combine_aeef4bbea8acc688b198e488208172f2_RG_6);
            float4 _Combine_feabe866dc39388d8ccd72275fb9be09_RGBA_4;
            float3 _Combine_feabe866dc39388d8ccd72275fb9be09_RGB_5;
            float2 _Combine_feabe866dc39388d8ccd72275fb9be09_RG_6;
            Unity_Combine_float(_Split_f72e1ad87d56df8ba34ec31e2bc432b8_B_3, _Split_f72e1ad87d56df8ba34ec31e2bc432b8_A_4, 0, 0, _Combine_feabe866dc39388d8ccd72275fb9be09_RGBA_4, _Combine_feabe866dc39388d8ccd72275fb9be09_RGB_5, _Combine_feabe866dc39388d8ccd72275fb9be09_RG_6);
            float _Remap_ca18d3412979f985809f3426d5282816_Out_3;
            Unity_Remap_float(_Power_abb6d235206009809ee431a98f2c8247_Out_2, _Combine_aeef4bbea8acc688b198e488208172f2_RG_6, _Combine_feabe866dc39388d8ccd72275fb9be09_RG_6, _Remap_ca18d3412979f985809f3426d5282816_Out_3);
            float _Absolute_01d69efb5b6b628b8142004f10302240_Out_1;
            Unity_Absolute_float(_Remap_ca18d3412979f985809f3426d5282816_Out_3, _Absolute_01d69efb5b6b628b8142004f10302240_Out_1);
            float _Smoothstep_5a0282a38f27848e9545f1e89a11f5a2_Out_3;
            Unity_Smoothstep_float(_Property_45fc02a5c65e898c82a51138ee7894c8_Out_0, _Property_423be2625737e5829e3daa7b3cf8389d_Out_0, _Absolute_01d69efb5b6b628b8142004f10302240_Out_1, _Smoothstep_5a0282a38f27848e9545f1e89a11f5a2_Out_3);
            float _Property_91482984669b1c8ab26a0f4a555b3801_Out_0 = Vector1_9058DE8C;
            float _Multiply_ad5811e4c08fae88a363e144af359987_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_91482984669b1c8ab26a0f4a555b3801_Out_0, _Multiply_ad5811e4c08fae88a363e144af359987_Out_2);
            float2 _TilingAndOffset_2345314be014258796bc32f9e66d2397_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_430e3c523bf85e84bdef451ab28beba0_Out_3.xy), float2 (1, 1), (_Multiply_ad5811e4c08fae88a363e144af359987_Out_2.xx), _TilingAndOffset_2345314be014258796bc32f9e66d2397_Out_3);
            float _Property_a13e388a84b18e89afce2f9f3ca9753f_Out_0 = Vector1_5536221E;
            float _GradientNoise_9f2e5d10ed34688f87f30e9a171b1f8b_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_2345314be014258796bc32f9e66d2397_Out_3, _Property_a13e388a84b18e89afce2f9f3ca9753f_Out_0, _GradientNoise_9f2e5d10ed34688f87f30e9a171b1f8b_Out_2);
            float _Property_b64fda08fa35398f9e0f45e316a434f9_Out_0 = Vector1_350643F1;
            float _Multiply_d03d0c5bc6770f8b8fbb46ec0c06b35b_Out_2;
            Unity_Multiply_float(_GradientNoise_9f2e5d10ed34688f87f30e9a171b1f8b_Out_2, _Property_b64fda08fa35398f9e0f45e316a434f9_Out_0, _Multiply_d03d0c5bc6770f8b8fbb46ec0c06b35b_Out_2);
            float _Add_f031b6931be259898e2d889c851d36d5_Out_2;
            Unity_Add_float(_Smoothstep_5a0282a38f27848e9545f1e89a11f5a2_Out_3, _Multiply_d03d0c5bc6770f8b8fbb46ec0c06b35b_Out_2, _Add_f031b6931be259898e2d889c851d36d5_Out_2);
            float _Add_e1b7452d2644ef8e96d652df6def6989_Out_2;
            Unity_Add_float(1, _Property_b64fda08fa35398f9e0f45e316a434f9_Out_0, _Add_e1b7452d2644ef8e96d652df6def6989_Out_2);
            float _Divide_b34aaac0718e8682bb2ab66e45d42421_Out_2;
            Unity_Divide_float(_Add_f031b6931be259898e2d889c851d36d5_Out_2, _Add_e1b7452d2644ef8e96d652df6def6989_Out_2, _Divide_b34aaac0718e8682bb2ab66e45d42421_Out_2);
            float3 _Multiply_a97d25c025f47f8fa4cfe3267dee485e_Out_2;
            Unity_Multiply_float(IN.ObjectSpaceNormal, (_Divide_b34aaac0718e8682bb2ab66e45d42421_Out_2.xxx), _Multiply_a97d25c025f47f8fa4cfe3267dee485e_Out_2);
            float _Property_6f2976fe72816a869d8677a4230164f0_Out_0 = Vector1_E43D3892;
            float3 _Multiply_08ef8c8995ef448a9ab1e43028223a19_Out_2;
            Unity_Multiply_float(_Multiply_a97d25c025f47f8fa4cfe3267dee485e_Out_2, (_Property_6f2976fe72816a869d8677a4230164f0_Out_0.xxx), _Multiply_08ef8c8995ef448a9ab1e43028223a19_Out_2);
            float3 _Add_ec1431816c726e8a827bfd7e7de3d614_Out_2;
            Unity_Add_float3(IN.ObjectSpacePosition, _Multiply_08ef8c8995ef448a9ab1e43028223a19_Out_2, _Add_ec1431816c726e8a827bfd7e7de3d614_Out_2);
            float3 _Add_cbfa9591f076e485a31b7f5b967f99f6_Out_2;
            Unity_Add_float3(_Multiply_3fa32f2d7f56688684a8f5b0a0853be5_Out_2, _Add_ec1431816c726e8a827bfd7e7de3d614_Out_2, _Add_cbfa9591f076e485a31b7f5b967f99f6_Out_2);
            description.Position = _Add_cbfa9591f076e485a31b7f5b967f99f6_Out_2;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }

            // Graph Pixel
            struct SurfaceDescription
        {
            float3 BaseColor;
            float3 NormalTS;
            float3 Emission;
            float Metallic;
            float Smoothness;
            float Occlusion;
            float Alpha;
        };

        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            float4 _Property_8602b260fe5c06829b7738349464dbbc_Out_0 = Color_58195353;
            float4 _Property_db73cd07c4394c82a6cd028523c127f3_Out_0 = Color_2CFB5E2A;
            float _Property_45fc02a5c65e898c82a51138ee7894c8_Out_0 = Vector1_FADC0395;
            float _Property_423be2625737e5829e3daa7b3cf8389d_Out_0 = Vector1_E505CA4B;
            float4 _Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0 = Vector4_484BA326;
            float _Split_e9324c176bf05a809ea8df8c413a826a_R_1 = _Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0[0];
            float _Split_e9324c176bf05a809ea8df8c413a826a_G_2 = _Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0[1];
            float _Split_e9324c176bf05a809ea8df8c413a826a_B_3 = _Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0[2];
            float _Split_e9324c176bf05a809ea8df8c413a826a_A_4 = _Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0[3];
            float3 _RotateAboutAxis_430e3c523bf85e84bdef451ab28beba0_Out_3;
            Unity_Rotate_About_Axis_Degrees_float(IN.WorldSpacePosition, (_Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0.xyz), _Split_e9324c176bf05a809ea8df8c413a826a_A_4, _RotateAboutAxis_430e3c523bf85e84bdef451ab28beba0_Out_3);
            float _Property_84dca49c8958708fac3276b0de15a6da_Out_0 = Vector1_8AAD665C;
            float _Multiply_89f92af49e152081ba549c92ab002e9c_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_84dca49c8958708fac3276b0de15a6da_Out_0, _Multiply_89f92af49e152081ba549c92ab002e9c_Out_2);
            float2 _TilingAndOffset_bd9fc632c3a6c185b226f93212ed8603_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_430e3c523bf85e84bdef451ab28beba0_Out_3.xy), float2 (1, 1), (_Multiply_89f92af49e152081ba549c92ab002e9c_Out_2.xx), _TilingAndOffset_bd9fc632c3a6c185b226f93212ed8603_Out_3);
            float _Property_f7111fce9be08b8c871514ffc219f648_Out_0 = Vector1_8F075DBC;
            float _GradientNoise_de42ec7fdd52ec8fa0b6cb7f34842c13_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_bd9fc632c3a6c185b226f93212ed8603_Out_3, _Property_f7111fce9be08b8c871514ffc219f648_Out_0, _GradientNoise_de42ec7fdd52ec8fa0b6cb7f34842c13_Out_2);
            float2 _TilingAndOffset_aa88c06674f4178889e657a2bb46c454_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_430e3c523bf85e84bdef451ab28beba0_Out_3.xy), float2 (1, 1), float2 (0, 0), _TilingAndOffset_aa88c06674f4178889e657a2bb46c454_Out_3);
            float _GradientNoise_28996fa0f6fbd08c97ed18d0621900b5_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_aa88c06674f4178889e657a2bb46c454_Out_3, _Property_f7111fce9be08b8c871514ffc219f648_Out_0, _GradientNoise_28996fa0f6fbd08c97ed18d0621900b5_Out_2);
            float _Add_caf5f972abacae878d9a6fde10e0986a_Out_2;
            Unity_Add_float(_GradientNoise_de42ec7fdd52ec8fa0b6cb7f34842c13_Out_2, _GradientNoise_28996fa0f6fbd08c97ed18d0621900b5_Out_2, _Add_caf5f972abacae878d9a6fde10e0986a_Out_2);
            float _Divide_27ef561e54cd208ca89512269c1d4d03_Out_2;
            Unity_Divide_float(_Add_caf5f972abacae878d9a6fde10e0986a_Out_2, 2, _Divide_27ef561e54cd208ca89512269c1d4d03_Out_2);
            float _Saturate_c56694103011198486afa78b0e89ec2c_Out_1;
            Unity_Saturate_float(_Divide_27ef561e54cd208ca89512269c1d4d03_Out_2, _Saturate_c56694103011198486afa78b0e89ec2c_Out_1);
            float _Property_8bd1d491d3050588a0b837b4b232170d_Out_0 = Vector1_4CE104D9;
            float _Power_abb6d235206009809ee431a98f2c8247_Out_2;
            Unity_Power_float(_Saturate_c56694103011198486afa78b0e89ec2c_Out_1, _Property_8bd1d491d3050588a0b837b4b232170d_Out_0, _Power_abb6d235206009809ee431a98f2c8247_Out_2);
            float4 _Property_8a81e8a6d963f384bddf6e75ec8e0a1c_Out_0 = Vector4_1696EE66;
            float _Split_f72e1ad87d56df8ba34ec31e2bc432b8_R_1 = _Property_8a81e8a6d963f384bddf6e75ec8e0a1c_Out_0[0];
            float _Split_f72e1ad87d56df8ba34ec31e2bc432b8_G_2 = _Property_8a81e8a6d963f384bddf6e75ec8e0a1c_Out_0[1];
            float _Split_f72e1ad87d56df8ba34ec31e2bc432b8_B_3 = _Property_8a81e8a6d963f384bddf6e75ec8e0a1c_Out_0[2];
            float _Split_f72e1ad87d56df8ba34ec31e2bc432b8_A_4 = _Property_8a81e8a6d963f384bddf6e75ec8e0a1c_Out_0[3];
            float4 _Combine_aeef4bbea8acc688b198e488208172f2_RGBA_4;
            float3 _Combine_aeef4bbea8acc688b198e488208172f2_RGB_5;
            float2 _Combine_aeef4bbea8acc688b198e488208172f2_RG_6;
            Unity_Combine_float(_Split_f72e1ad87d56df8ba34ec31e2bc432b8_R_1, _Split_f72e1ad87d56df8ba34ec31e2bc432b8_G_2, 0, 0, _Combine_aeef4bbea8acc688b198e488208172f2_RGBA_4, _Combine_aeef4bbea8acc688b198e488208172f2_RGB_5, _Combine_aeef4bbea8acc688b198e488208172f2_RG_6);
            float4 _Combine_feabe866dc39388d8ccd72275fb9be09_RGBA_4;
            float3 _Combine_feabe866dc39388d8ccd72275fb9be09_RGB_5;
            float2 _Combine_feabe866dc39388d8ccd72275fb9be09_RG_6;
            Unity_Combine_float(_Split_f72e1ad87d56df8ba34ec31e2bc432b8_B_3, _Split_f72e1ad87d56df8ba34ec31e2bc432b8_A_4, 0, 0, _Combine_feabe866dc39388d8ccd72275fb9be09_RGBA_4, _Combine_feabe866dc39388d8ccd72275fb9be09_RGB_5, _Combine_feabe866dc39388d8ccd72275fb9be09_RG_6);
            float _Remap_ca18d3412979f985809f3426d5282816_Out_3;
            Unity_Remap_float(_Power_abb6d235206009809ee431a98f2c8247_Out_2, _Combine_aeef4bbea8acc688b198e488208172f2_RG_6, _Combine_feabe866dc39388d8ccd72275fb9be09_RG_6, _Remap_ca18d3412979f985809f3426d5282816_Out_3);
            float _Absolute_01d69efb5b6b628b8142004f10302240_Out_1;
            Unity_Absolute_float(_Remap_ca18d3412979f985809f3426d5282816_Out_3, _Absolute_01d69efb5b6b628b8142004f10302240_Out_1);
            float _Smoothstep_5a0282a38f27848e9545f1e89a11f5a2_Out_3;
            Unity_Smoothstep_float(_Property_45fc02a5c65e898c82a51138ee7894c8_Out_0, _Property_423be2625737e5829e3daa7b3cf8389d_Out_0, _Absolute_01d69efb5b6b628b8142004f10302240_Out_1, _Smoothstep_5a0282a38f27848e9545f1e89a11f5a2_Out_3);
            float _Property_91482984669b1c8ab26a0f4a555b3801_Out_0 = Vector1_9058DE8C;
            float _Multiply_ad5811e4c08fae88a363e144af359987_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_91482984669b1c8ab26a0f4a555b3801_Out_0, _Multiply_ad5811e4c08fae88a363e144af359987_Out_2);
            float2 _TilingAndOffset_2345314be014258796bc32f9e66d2397_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_430e3c523bf85e84bdef451ab28beba0_Out_3.xy), float2 (1, 1), (_Multiply_ad5811e4c08fae88a363e144af359987_Out_2.xx), _TilingAndOffset_2345314be014258796bc32f9e66d2397_Out_3);
            float _Property_a13e388a84b18e89afce2f9f3ca9753f_Out_0 = Vector1_5536221E;
            float _GradientNoise_9f2e5d10ed34688f87f30e9a171b1f8b_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_2345314be014258796bc32f9e66d2397_Out_3, _Property_a13e388a84b18e89afce2f9f3ca9753f_Out_0, _GradientNoise_9f2e5d10ed34688f87f30e9a171b1f8b_Out_2);
            float _Property_b64fda08fa35398f9e0f45e316a434f9_Out_0 = Vector1_350643F1;
            float _Multiply_d03d0c5bc6770f8b8fbb46ec0c06b35b_Out_2;
            Unity_Multiply_float(_GradientNoise_9f2e5d10ed34688f87f30e9a171b1f8b_Out_2, _Property_b64fda08fa35398f9e0f45e316a434f9_Out_0, _Multiply_d03d0c5bc6770f8b8fbb46ec0c06b35b_Out_2);
            float _Add_f031b6931be259898e2d889c851d36d5_Out_2;
            Unity_Add_float(_Smoothstep_5a0282a38f27848e9545f1e89a11f5a2_Out_3, _Multiply_d03d0c5bc6770f8b8fbb46ec0c06b35b_Out_2, _Add_f031b6931be259898e2d889c851d36d5_Out_2);
            float _Add_e1b7452d2644ef8e96d652df6def6989_Out_2;
            Unity_Add_float(1, _Property_b64fda08fa35398f9e0f45e316a434f9_Out_0, _Add_e1b7452d2644ef8e96d652df6def6989_Out_2);
            float _Divide_b34aaac0718e8682bb2ab66e45d42421_Out_2;
            Unity_Divide_float(_Add_f031b6931be259898e2d889c851d36d5_Out_2, _Add_e1b7452d2644ef8e96d652df6def6989_Out_2, _Divide_b34aaac0718e8682bb2ab66e45d42421_Out_2);
            float4 _Lerp_0f05ab7309374f869f26c5de63c7685d_Out_3;
            Unity_Lerp_float4(_Property_8602b260fe5c06829b7738349464dbbc_Out_0, _Property_db73cd07c4394c82a6cd028523c127f3_Out_0, (_Divide_b34aaac0718e8682bb2ab66e45d42421_Out_2.xxxx), _Lerp_0f05ab7309374f869f26c5de63c7685d_Out_3);
            float _Property_0e672fb430de1988a91ebab3a6c55a4b_Out_0 = Vector1_B4ED823D;
            float _FresnelEffect_d3463b04b6387381ae221b6b9fda5a55_Out_3;
            Unity_FresnelEffect_float(IN.WorldSpaceNormal, IN.WorldSpaceViewDirection, _Property_0e672fb430de1988a91ebab3a6c55a4b_Out_0, _FresnelEffect_d3463b04b6387381ae221b6b9fda5a55_Out_3);
            float _Multiply_b1b397b5458b168183311fa585ce24cc_Out_2;
            Unity_Multiply_float(_Divide_b34aaac0718e8682bb2ab66e45d42421_Out_2, _FresnelEffect_d3463b04b6387381ae221b6b9fda5a55_Out_3, _Multiply_b1b397b5458b168183311fa585ce24cc_Out_2);
            float _Property_a0d7e69c6b484186aed4c837b9cfdf60_Out_0 = Vector1_2BA361A8;
            float _Multiply_c527b7ae93e59a82a8b685490472d140_Out_2;
            Unity_Multiply_float(_Multiply_b1b397b5458b168183311fa585ce24cc_Out_2, _Property_a0d7e69c6b484186aed4c837b9cfdf60_Out_0, _Multiply_c527b7ae93e59a82a8b685490472d140_Out_2);
            float4 _Add_e90a39812292588185bb8af6f98ac6ed_Out_2;
            Unity_Add_float4(_Lerp_0f05ab7309374f869f26c5de63c7685d_Out_3, (_Multiply_c527b7ae93e59a82a8b685490472d140_Out_2.xxxx), _Add_e90a39812292588185bb8af6f98ac6ed_Out_2);
            float _Property_2b5ded79d5faa287bcd134d3931fddbd_Out_0 = Vector1_2A80C598;
            float4 _Multiply_89abd19f1abd878f9e4e10491d20220d_Out_2;
            Unity_Multiply_float(_Add_e90a39812292588185bb8af6f98ac6ed_Out_2, (_Property_2b5ded79d5faa287bcd134d3931fddbd_Out_0.xxxx), _Multiply_89abd19f1abd878f9e4e10491d20220d_Out_2);
            float _SceneDepth_845bf60653d70482b562a739512eeda7_Out_1;
            Unity_SceneDepth_Eye_float(float4(IN.ScreenPosition.xy / IN.ScreenPosition.w, 0, 0), _SceneDepth_845bf60653d70482b562a739512eeda7_Out_1);
            float4 _ScreenPosition_b978995ebe1ba286935416b2a2d5cb85_Out_0 = IN.ScreenPosition;
            float _Split_c66584edb0487b8e8c2e107a89ed8e9f_R_1 = _ScreenPosition_b978995ebe1ba286935416b2a2d5cb85_Out_0[0];
            float _Split_c66584edb0487b8e8c2e107a89ed8e9f_G_2 = _ScreenPosition_b978995ebe1ba286935416b2a2d5cb85_Out_0[1];
            float _Split_c66584edb0487b8e8c2e107a89ed8e9f_B_3 = _ScreenPosition_b978995ebe1ba286935416b2a2d5cb85_Out_0[2];
            float _Split_c66584edb0487b8e8c2e107a89ed8e9f_A_4 = _ScreenPosition_b978995ebe1ba286935416b2a2d5cb85_Out_0[3];
            float _Subtract_39fffd64ebdafb84a6eb8e37e2faaa16_Out_2;
            Unity_Subtract_float(_Split_c66584edb0487b8e8c2e107a89ed8e9f_A_4, 1, _Subtract_39fffd64ebdafb84a6eb8e37e2faaa16_Out_2);
            float _Subtract_d8ff2e79b2fc8386b6172daebbe97366_Out_2;
            Unity_Subtract_float(_SceneDepth_845bf60653d70482b562a739512eeda7_Out_1, _Subtract_39fffd64ebdafb84a6eb8e37e2faaa16_Out_2, _Subtract_d8ff2e79b2fc8386b6172daebbe97366_Out_2);
            float _Property_0a2887e34569358bbc9cbee1a14acebb_Out_0 = Vector1_EED1A887;
            float _Divide_f3ff43869c02038db823cf0d91c23caf_Out_2;
            Unity_Divide_float(_Subtract_d8ff2e79b2fc8386b6172daebbe97366_Out_2, _Property_0a2887e34569358bbc9cbee1a14acebb_Out_0, _Divide_f3ff43869c02038db823cf0d91c23caf_Out_2);
            float _Saturate_676d84ccc0f0b88e9d1fdf263cfcf1d5_Out_1;
            Unity_Saturate_float(_Divide_f3ff43869c02038db823cf0d91c23caf_Out_2, _Saturate_676d84ccc0f0b88e9d1fdf263cfcf1d5_Out_1);
            float _Smoothstep_edf634d16c75cd829225bfca563f83fb_Out_3;
            Unity_Smoothstep_float(0, 1, _Saturate_676d84ccc0f0b88e9d1fdf263cfcf1d5_Out_1, _Smoothstep_edf634d16c75cd829225bfca563f83fb_Out_3);
            surface.BaseColor = IsGammaSpace() ? float3(0, 0, 0) : SRGBToLinear(float3(0, 0, 0));
            surface.NormalTS = IN.TangentSpaceNormal;
            surface.Emission = (_Multiply_89abd19f1abd878f9e4e10491d20220d_Out_2.xyz);
            surface.Metallic = 0;
            surface.Smoothness = 0.5;
            surface.Occlusion = 1;
            surface.Alpha = _Smoothstep_edf634d16c75cd829225bfca563f83fb_Out_3;
            return surface;
        }

            // --------------------------------------------------
            // Build Graph Inputs

            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);

            output.ObjectSpaceNormal =           input.normalOS;
            output.WorldSpaceNormal =            TransformObjectToWorldNormal(input.normalOS);
            output.ObjectSpaceTangent =          input.tangentOS.xyz;
            output.ObjectSpacePosition =         input.positionOS;
            output.WorldSpacePosition =          TransformObjectToWorld(input.positionOS);
            output.TimeParameters =              _TimeParameters.xyz;

            return output;
        }
            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);

        	// must use interpolated tangent, bitangent and normal before they are normalized in the pixel shader.
        	float3 unnormalizedNormalWS = input.normalWS;
            const float renormFactor = 1.0 / length(unnormalizedNormalWS);


            output.WorldSpaceNormal =            renormFactor*input.normalWS.xyz;		// we want a unit length Normal Vector node in shader graph
            output.TangentSpaceNormal =          float3(0.0f, 0.0f, 1.0f);


            output.WorldSpaceViewDirection =     input.viewDirectionWS; //TODO: by default normalized in HD, but not in universal
            output.WorldSpacePosition =          input.positionWS;
            output.ScreenPosition =              ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
            output.TimeParameters =              _TimeParameters.xyz; // This is mainly for LW as HD overwrite this value
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

            return output;
        }

            // --------------------------------------------------
            // Main

            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/PBRForwardPass.hlsl"

            ENDHLSL
        }
        Pass
        {
            Name "GBuffer"
            Tags
            {
                "LightMode" = "UniversalGBuffer"
            }

            // Render State
            Cull Back
        Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
        ZTest LEqual
        ZWrite Off

            // Debug
            // <None>

            // --------------------------------------------------
            // Pass

            HLSLPROGRAM

            // Pragmas
            #pragma target 4.5
        #pragma exclude_renderers gles gles3 glcore
        #pragma multi_compile_instancing
        #pragma multi_compile_fog
        #pragma multi_compile _ DOTS_INSTANCING_ON
        #pragma vertex vert
        #pragma fragment frag

            // DotsInstancingOptions: <None>
            // HybridV1InjectedBuiltinProperties: <None>

            // Keywords
            #pragma multi_compile _ LIGHTMAP_ON
        #pragma multi_compile _ DIRLIGHTMAP_COMBINED
        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
        #pragma multi_compile _ _SHADOWS_SOFT
        #pragma multi_compile _ _MIXED_LIGHTING_SUBTRACTIVE
        #pragma multi_compile _ _GBUFFER_NORMALS_OCT
            // GraphKeywords: <None>

            // Defines
            #define _SURFACE_TYPE_TRANSPARENT 1
            #define _NORMALMAP 1
            #define _NORMAL_DROPOFF_TS 1
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define ATTRIBUTES_NEED_TEXCOORD1
            #define VARYINGS_NEED_POSITION_WS
            #define VARYINGS_NEED_NORMAL_WS
            #define VARYINGS_NEED_TANGENT_WS
            #define VARYINGS_NEED_VIEWDIRECTION_WS
            #define VARYINGS_NEED_FOG_AND_VERTEX_LIGHT
            #define FEATURES_GRAPH_VERTEX
            /* WARNING: $splice Could not find named fragment 'PassInstancing' */
            #define SHADERPASS SHADERPASS_GBUFFER
        #define REQUIRE_DEPTH_TEXTURE
            /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

            // --------------------------------------------------
            // Structs and Packing

            struct Attributes
        {
            float3 positionOS : POSITION;
            float3 normalOS : NORMAL;
            float4 tangentOS : TANGENT;
            float4 uv1 : TEXCOORD1;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
            float4 positionCS : SV_POSITION;
            float3 positionWS;
            float3 normalWS;
            float4 tangentWS;
            float3 viewDirectionWS;
            #if defined(LIGHTMAP_ON)
            float2 lightmapUV;
            #endif
            #if !defined(LIGHTMAP_ON)
            float3 sh;
            #endif
            float4 fogFactorAndVertexLight;
            float4 shadowCoord;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
            float3 WorldSpaceNormal;
            float3 TangentSpaceNormal;
            float3 WorldSpaceViewDirection;
            float3 WorldSpacePosition;
            float4 ScreenPosition;
            float3 TimeParameters;
        };
        struct VertexDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 WorldSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 ObjectSpacePosition;
            float3 WorldSpacePosition;
            float3 TimeParameters;
        };
        struct PackedVaryings
        {
            float4 positionCS : SV_POSITION;
            float3 interp0 : TEXCOORD0;
            float3 interp1 : TEXCOORD1;
            float4 interp2 : TEXCOORD2;
            float3 interp3 : TEXCOORD3;
            #if defined(LIGHTMAP_ON)
            float2 interp4 : TEXCOORD4;
            #endif
            #if !defined(LIGHTMAP_ON)
            float3 interp5 : TEXCOORD5;
            #endif
            float4 interp6 : TEXCOORD6;
            float4 interp7 : TEXCOORD7;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };

            PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            output.interp2.xyzw =  input.tangentWS;
            output.interp3.xyz =  input.viewDirectionWS;
            #if defined(LIGHTMAP_ON)
            output.interp4.xy =  input.lightmapUV;
            #endif
            #if !defined(LIGHTMAP_ON)
            output.interp5.xyz =  input.sh;
            #endif
            output.interp6.xyzw =  input.fogFactorAndVertexLight;
            output.interp7.xyzw =  input.shadowCoord;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            output.tangentWS = input.interp2.xyzw;
            output.viewDirectionWS = input.interp3.xyz;
            #if defined(LIGHTMAP_ON)
            output.lightmapUV = input.interp4.xy;
            #endif
            #if !defined(LIGHTMAP_ON)
            output.sh = input.interp5.xyz;
            #endif
            output.fogFactorAndVertexLight = input.interp6.xyzw;
            output.shadowCoord = input.interp7.xyzw;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }

            // --------------------------------------------------
            // Graph

            // Graph Properties
            CBUFFER_START(UnityPerMaterial)
        float4 Vector4_484BA326;
        float Vector1_8F075DBC;
        float Vector1_8AAD665C;
        float Vector1_E43D3892;
        float4 Vector4_1696EE66;
        float4 Color_2CFB5E2A;
        float4 Color_58195353;
        float Vector1_FADC0395;
        float Vector1_E505CA4B;
        float Vector1_4CE104D9;
        float Vector1_5536221E;
        float Vector1_9058DE8C;
        float Vector1_350643F1;
        float Vector1_2A80C598;
        float Vector1_A664731F;
        float Vector1_B4ED823D;
        float Vector1_2BA361A8;
        float Vector1_EED1A887;
        CBUFFER_END

        // Object and Global properties

            // Graph Functions
            
        void Unity_Distance_float3(float3 A, float3 B, out float Out)
        {
            Out = distance(A, B);
        }

        void Unity_Divide_float(float A, float B, out float Out)
        {
            Out = A / B;
        }

        void Unity_Power_float(float A, float B, out float Out)
        {
            Out = pow(A, B);
        }

        void Unity_Multiply_float(float3 A, float3 B, out float3 Out)
        {
            Out = A * B;
        }

        void Unity_Rotate_About_Axis_Degrees_float(float3 In, float3 Axis, float Rotation, out float3 Out)
        {
            Rotation = radians(Rotation);

            float s = sin(Rotation);
            float c = cos(Rotation);
            float one_minus_c = 1.0 - c;
            
            Axis = normalize(Axis);

            float3x3 rot_mat = { one_minus_c * Axis.x * Axis.x + c,            one_minus_c * Axis.x * Axis.y - Axis.z * s,     one_minus_c * Axis.z * Axis.x + Axis.y * s,
                                      one_minus_c * Axis.x * Axis.y + Axis.z * s,   one_minus_c * Axis.y * Axis.y + c,              one_minus_c * Axis.y * Axis.z - Axis.x * s,
                                      one_minus_c * Axis.z * Axis.x - Axis.y * s,   one_minus_c * Axis.y * Axis.z + Axis.x * s,     one_minus_c * Axis.z * Axis.z + c
                                    };

            Out = mul(rot_mat,  In);
        }

        void Unity_Multiply_float(float A, float B, out float Out)
        {
            Out = A * B;
        }

        void Unity_TilingAndOffset_float(float2 UV, float2 Tiling, float2 Offset, out float2 Out)
        {
            Out = UV * Tiling + Offset;
        }


        float2 Unity_GradientNoise_Dir_float(float2 p)
        {
            // Permutation and hashing used in webgl-nosie goo.gl/pX7HtC
            p = p % 289;
            // need full precision, otherwise half overflows when p > 1
            float x = float(34 * p.x + 1) * p.x % 289 + p.y;
            x = (34 * x + 1) * x % 289;
            x = frac(x / 41) * 2 - 1;
            return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
        }

        void Unity_GradientNoise_float(float2 UV, float Scale, out float Out)
        { 
            float2 p = UV * Scale;
            float2 ip = floor(p);
            float2 fp = frac(p);
            float d00 = dot(Unity_GradientNoise_Dir_float(ip), fp);
            float d01 = dot(Unity_GradientNoise_Dir_float(ip + float2(0, 1)), fp - float2(0, 1));
            float d10 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 0)), fp - float2(1, 0));
            float d11 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 1)), fp - float2(1, 1));
            fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
            Out = lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x) + 0.5;
        }

        void Unity_Add_float(float A, float B, out float Out)
        {
            Out = A + B;
        }

        void Unity_Saturate_float(float In, out float Out)
        {
            Out = saturate(In);
        }

        void Unity_Combine_float(float R, float G, float B, float A, out float4 RGBA, out float3 RGB, out float2 RG)
        {
            RGBA = float4(R, G, B, A);
            RGB = float3(R, G, B);
            RG = float2(R, G);
        }

        void Unity_Remap_float(float In, float2 InMinMax, float2 OutMinMax, out float Out)
        {
            Out = OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
        }

        void Unity_Absolute_float(float In, out float Out)
        {
            Out = abs(In);
        }

        void Unity_Smoothstep_float(float Edge1, float Edge2, float In, out float Out)
        {
            Out = smoothstep(Edge1, Edge2, In);
        }

        void Unity_Add_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A + B;
        }

        void Unity_Lerp_float4(float4 A, float4 B, float4 T, out float4 Out)
        {
            Out = lerp(A, B, T);
        }

        void Unity_FresnelEffect_float(float3 Normal, float3 ViewDir, float Power, out float Out)
        {
            Out = pow((1.0 - saturate(dot(normalize(Normal), normalize(ViewDir)))), Power);
        }

        void Unity_Add_float4(float4 A, float4 B, out float4 Out)
        {
            Out = A + B;
        }

        void Unity_Multiply_float(float4 A, float4 B, out float4 Out)
        {
            Out = A * B;
        }

        void Unity_SceneDepth_Eye_float(float4 UV, out float Out)
        {
            Out = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH(UV.xy), _ZBufferParams);
        }

        void Unity_Subtract_float(float A, float B, out float Out)
        {
            Out = A - B;
        }

            // Graph Vertex
            struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };

        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            float _Distance_474c9e8e982c878dad2f0d5844b22ee9_Out_2;
            Unity_Distance_float3(SHADERGRAPH_OBJECT_POSITION, IN.WorldSpacePosition, _Distance_474c9e8e982c878dad2f0d5844b22ee9_Out_2);
            float _Property_95b6af28bf5d388fb7809e99d4ea7a10_Out_0 = Vector1_A664731F;
            float _Divide_2022c703e9e6de87965706bd214b7b67_Out_2;
            Unity_Divide_float(_Distance_474c9e8e982c878dad2f0d5844b22ee9_Out_2, _Property_95b6af28bf5d388fb7809e99d4ea7a10_Out_0, _Divide_2022c703e9e6de87965706bd214b7b67_Out_2);
            float _Power_8710b3fb1efe3183a2818b946e662a1e_Out_2;
            Unity_Power_float(_Divide_2022c703e9e6de87965706bd214b7b67_Out_2, 3, _Power_8710b3fb1efe3183a2818b946e662a1e_Out_2);
            float3 _Multiply_3fa32f2d7f56688684a8f5b0a0853be5_Out_2;
            Unity_Multiply_float(IN.WorldSpaceNormal, (_Power_8710b3fb1efe3183a2818b946e662a1e_Out_2.xxx), _Multiply_3fa32f2d7f56688684a8f5b0a0853be5_Out_2);
            float _Property_45fc02a5c65e898c82a51138ee7894c8_Out_0 = Vector1_FADC0395;
            float _Property_423be2625737e5829e3daa7b3cf8389d_Out_0 = Vector1_E505CA4B;
            float4 _Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0 = Vector4_484BA326;
            float _Split_e9324c176bf05a809ea8df8c413a826a_R_1 = _Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0[0];
            float _Split_e9324c176bf05a809ea8df8c413a826a_G_2 = _Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0[1];
            float _Split_e9324c176bf05a809ea8df8c413a826a_B_3 = _Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0[2];
            float _Split_e9324c176bf05a809ea8df8c413a826a_A_4 = _Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0[3];
            float3 _RotateAboutAxis_430e3c523bf85e84bdef451ab28beba0_Out_3;
            Unity_Rotate_About_Axis_Degrees_float(IN.WorldSpacePosition, (_Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0.xyz), _Split_e9324c176bf05a809ea8df8c413a826a_A_4, _RotateAboutAxis_430e3c523bf85e84bdef451ab28beba0_Out_3);
            float _Property_84dca49c8958708fac3276b0de15a6da_Out_0 = Vector1_8AAD665C;
            float _Multiply_89f92af49e152081ba549c92ab002e9c_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_84dca49c8958708fac3276b0de15a6da_Out_0, _Multiply_89f92af49e152081ba549c92ab002e9c_Out_2);
            float2 _TilingAndOffset_bd9fc632c3a6c185b226f93212ed8603_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_430e3c523bf85e84bdef451ab28beba0_Out_3.xy), float2 (1, 1), (_Multiply_89f92af49e152081ba549c92ab002e9c_Out_2.xx), _TilingAndOffset_bd9fc632c3a6c185b226f93212ed8603_Out_3);
            float _Property_f7111fce9be08b8c871514ffc219f648_Out_0 = Vector1_8F075DBC;
            float _GradientNoise_de42ec7fdd52ec8fa0b6cb7f34842c13_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_bd9fc632c3a6c185b226f93212ed8603_Out_3, _Property_f7111fce9be08b8c871514ffc219f648_Out_0, _GradientNoise_de42ec7fdd52ec8fa0b6cb7f34842c13_Out_2);
            float2 _TilingAndOffset_aa88c06674f4178889e657a2bb46c454_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_430e3c523bf85e84bdef451ab28beba0_Out_3.xy), float2 (1, 1), float2 (0, 0), _TilingAndOffset_aa88c06674f4178889e657a2bb46c454_Out_3);
            float _GradientNoise_28996fa0f6fbd08c97ed18d0621900b5_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_aa88c06674f4178889e657a2bb46c454_Out_3, _Property_f7111fce9be08b8c871514ffc219f648_Out_0, _GradientNoise_28996fa0f6fbd08c97ed18d0621900b5_Out_2);
            float _Add_caf5f972abacae878d9a6fde10e0986a_Out_2;
            Unity_Add_float(_GradientNoise_de42ec7fdd52ec8fa0b6cb7f34842c13_Out_2, _GradientNoise_28996fa0f6fbd08c97ed18d0621900b5_Out_2, _Add_caf5f972abacae878d9a6fde10e0986a_Out_2);
            float _Divide_27ef561e54cd208ca89512269c1d4d03_Out_2;
            Unity_Divide_float(_Add_caf5f972abacae878d9a6fde10e0986a_Out_2, 2, _Divide_27ef561e54cd208ca89512269c1d4d03_Out_2);
            float _Saturate_c56694103011198486afa78b0e89ec2c_Out_1;
            Unity_Saturate_float(_Divide_27ef561e54cd208ca89512269c1d4d03_Out_2, _Saturate_c56694103011198486afa78b0e89ec2c_Out_1);
            float _Property_8bd1d491d3050588a0b837b4b232170d_Out_0 = Vector1_4CE104D9;
            float _Power_abb6d235206009809ee431a98f2c8247_Out_2;
            Unity_Power_float(_Saturate_c56694103011198486afa78b0e89ec2c_Out_1, _Property_8bd1d491d3050588a0b837b4b232170d_Out_0, _Power_abb6d235206009809ee431a98f2c8247_Out_2);
            float4 _Property_8a81e8a6d963f384bddf6e75ec8e0a1c_Out_0 = Vector4_1696EE66;
            float _Split_f72e1ad87d56df8ba34ec31e2bc432b8_R_1 = _Property_8a81e8a6d963f384bddf6e75ec8e0a1c_Out_0[0];
            float _Split_f72e1ad87d56df8ba34ec31e2bc432b8_G_2 = _Property_8a81e8a6d963f384bddf6e75ec8e0a1c_Out_0[1];
            float _Split_f72e1ad87d56df8ba34ec31e2bc432b8_B_3 = _Property_8a81e8a6d963f384bddf6e75ec8e0a1c_Out_0[2];
            float _Split_f72e1ad87d56df8ba34ec31e2bc432b8_A_4 = _Property_8a81e8a6d963f384bddf6e75ec8e0a1c_Out_0[3];
            float4 _Combine_aeef4bbea8acc688b198e488208172f2_RGBA_4;
            float3 _Combine_aeef4bbea8acc688b198e488208172f2_RGB_5;
            float2 _Combine_aeef4bbea8acc688b198e488208172f2_RG_6;
            Unity_Combine_float(_Split_f72e1ad87d56df8ba34ec31e2bc432b8_R_1, _Split_f72e1ad87d56df8ba34ec31e2bc432b8_G_2, 0, 0, _Combine_aeef4bbea8acc688b198e488208172f2_RGBA_4, _Combine_aeef4bbea8acc688b198e488208172f2_RGB_5, _Combine_aeef4bbea8acc688b198e488208172f2_RG_6);
            float4 _Combine_feabe866dc39388d8ccd72275fb9be09_RGBA_4;
            float3 _Combine_feabe866dc39388d8ccd72275fb9be09_RGB_5;
            float2 _Combine_feabe866dc39388d8ccd72275fb9be09_RG_6;
            Unity_Combine_float(_Split_f72e1ad87d56df8ba34ec31e2bc432b8_B_3, _Split_f72e1ad87d56df8ba34ec31e2bc432b8_A_4, 0, 0, _Combine_feabe866dc39388d8ccd72275fb9be09_RGBA_4, _Combine_feabe866dc39388d8ccd72275fb9be09_RGB_5, _Combine_feabe866dc39388d8ccd72275fb9be09_RG_6);
            float _Remap_ca18d3412979f985809f3426d5282816_Out_3;
            Unity_Remap_float(_Power_abb6d235206009809ee431a98f2c8247_Out_2, _Combine_aeef4bbea8acc688b198e488208172f2_RG_6, _Combine_feabe866dc39388d8ccd72275fb9be09_RG_6, _Remap_ca18d3412979f985809f3426d5282816_Out_3);
            float _Absolute_01d69efb5b6b628b8142004f10302240_Out_1;
            Unity_Absolute_float(_Remap_ca18d3412979f985809f3426d5282816_Out_3, _Absolute_01d69efb5b6b628b8142004f10302240_Out_1);
            float _Smoothstep_5a0282a38f27848e9545f1e89a11f5a2_Out_3;
            Unity_Smoothstep_float(_Property_45fc02a5c65e898c82a51138ee7894c8_Out_0, _Property_423be2625737e5829e3daa7b3cf8389d_Out_0, _Absolute_01d69efb5b6b628b8142004f10302240_Out_1, _Smoothstep_5a0282a38f27848e9545f1e89a11f5a2_Out_3);
            float _Property_91482984669b1c8ab26a0f4a555b3801_Out_0 = Vector1_9058DE8C;
            float _Multiply_ad5811e4c08fae88a363e144af359987_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_91482984669b1c8ab26a0f4a555b3801_Out_0, _Multiply_ad5811e4c08fae88a363e144af359987_Out_2);
            float2 _TilingAndOffset_2345314be014258796bc32f9e66d2397_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_430e3c523bf85e84bdef451ab28beba0_Out_3.xy), float2 (1, 1), (_Multiply_ad5811e4c08fae88a363e144af359987_Out_2.xx), _TilingAndOffset_2345314be014258796bc32f9e66d2397_Out_3);
            float _Property_a13e388a84b18e89afce2f9f3ca9753f_Out_0 = Vector1_5536221E;
            float _GradientNoise_9f2e5d10ed34688f87f30e9a171b1f8b_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_2345314be014258796bc32f9e66d2397_Out_3, _Property_a13e388a84b18e89afce2f9f3ca9753f_Out_0, _GradientNoise_9f2e5d10ed34688f87f30e9a171b1f8b_Out_2);
            float _Property_b64fda08fa35398f9e0f45e316a434f9_Out_0 = Vector1_350643F1;
            float _Multiply_d03d0c5bc6770f8b8fbb46ec0c06b35b_Out_2;
            Unity_Multiply_float(_GradientNoise_9f2e5d10ed34688f87f30e9a171b1f8b_Out_2, _Property_b64fda08fa35398f9e0f45e316a434f9_Out_0, _Multiply_d03d0c5bc6770f8b8fbb46ec0c06b35b_Out_2);
            float _Add_f031b6931be259898e2d889c851d36d5_Out_2;
            Unity_Add_float(_Smoothstep_5a0282a38f27848e9545f1e89a11f5a2_Out_3, _Multiply_d03d0c5bc6770f8b8fbb46ec0c06b35b_Out_2, _Add_f031b6931be259898e2d889c851d36d5_Out_2);
            float _Add_e1b7452d2644ef8e96d652df6def6989_Out_2;
            Unity_Add_float(1, _Property_b64fda08fa35398f9e0f45e316a434f9_Out_0, _Add_e1b7452d2644ef8e96d652df6def6989_Out_2);
            float _Divide_b34aaac0718e8682bb2ab66e45d42421_Out_2;
            Unity_Divide_float(_Add_f031b6931be259898e2d889c851d36d5_Out_2, _Add_e1b7452d2644ef8e96d652df6def6989_Out_2, _Divide_b34aaac0718e8682bb2ab66e45d42421_Out_2);
            float3 _Multiply_a97d25c025f47f8fa4cfe3267dee485e_Out_2;
            Unity_Multiply_float(IN.ObjectSpaceNormal, (_Divide_b34aaac0718e8682bb2ab66e45d42421_Out_2.xxx), _Multiply_a97d25c025f47f8fa4cfe3267dee485e_Out_2);
            float _Property_6f2976fe72816a869d8677a4230164f0_Out_0 = Vector1_E43D3892;
            float3 _Multiply_08ef8c8995ef448a9ab1e43028223a19_Out_2;
            Unity_Multiply_float(_Multiply_a97d25c025f47f8fa4cfe3267dee485e_Out_2, (_Property_6f2976fe72816a869d8677a4230164f0_Out_0.xxx), _Multiply_08ef8c8995ef448a9ab1e43028223a19_Out_2);
            float3 _Add_ec1431816c726e8a827bfd7e7de3d614_Out_2;
            Unity_Add_float3(IN.ObjectSpacePosition, _Multiply_08ef8c8995ef448a9ab1e43028223a19_Out_2, _Add_ec1431816c726e8a827bfd7e7de3d614_Out_2);
            float3 _Add_cbfa9591f076e485a31b7f5b967f99f6_Out_2;
            Unity_Add_float3(_Multiply_3fa32f2d7f56688684a8f5b0a0853be5_Out_2, _Add_ec1431816c726e8a827bfd7e7de3d614_Out_2, _Add_cbfa9591f076e485a31b7f5b967f99f6_Out_2);
            description.Position = _Add_cbfa9591f076e485a31b7f5b967f99f6_Out_2;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }

            // Graph Pixel
            struct SurfaceDescription
        {
            float3 BaseColor;
            float3 NormalTS;
            float3 Emission;
            float Metallic;
            float Smoothness;
            float Occlusion;
            float Alpha;
        };

        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            float4 _Property_8602b260fe5c06829b7738349464dbbc_Out_0 = Color_58195353;
            float4 _Property_db73cd07c4394c82a6cd028523c127f3_Out_0 = Color_2CFB5E2A;
            float _Property_45fc02a5c65e898c82a51138ee7894c8_Out_0 = Vector1_FADC0395;
            float _Property_423be2625737e5829e3daa7b3cf8389d_Out_0 = Vector1_E505CA4B;
            float4 _Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0 = Vector4_484BA326;
            float _Split_e9324c176bf05a809ea8df8c413a826a_R_1 = _Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0[0];
            float _Split_e9324c176bf05a809ea8df8c413a826a_G_2 = _Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0[1];
            float _Split_e9324c176bf05a809ea8df8c413a826a_B_3 = _Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0[2];
            float _Split_e9324c176bf05a809ea8df8c413a826a_A_4 = _Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0[3];
            float3 _RotateAboutAxis_430e3c523bf85e84bdef451ab28beba0_Out_3;
            Unity_Rotate_About_Axis_Degrees_float(IN.WorldSpacePosition, (_Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0.xyz), _Split_e9324c176bf05a809ea8df8c413a826a_A_4, _RotateAboutAxis_430e3c523bf85e84bdef451ab28beba0_Out_3);
            float _Property_84dca49c8958708fac3276b0de15a6da_Out_0 = Vector1_8AAD665C;
            float _Multiply_89f92af49e152081ba549c92ab002e9c_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_84dca49c8958708fac3276b0de15a6da_Out_0, _Multiply_89f92af49e152081ba549c92ab002e9c_Out_2);
            float2 _TilingAndOffset_bd9fc632c3a6c185b226f93212ed8603_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_430e3c523bf85e84bdef451ab28beba0_Out_3.xy), float2 (1, 1), (_Multiply_89f92af49e152081ba549c92ab002e9c_Out_2.xx), _TilingAndOffset_bd9fc632c3a6c185b226f93212ed8603_Out_3);
            float _Property_f7111fce9be08b8c871514ffc219f648_Out_0 = Vector1_8F075DBC;
            float _GradientNoise_de42ec7fdd52ec8fa0b6cb7f34842c13_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_bd9fc632c3a6c185b226f93212ed8603_Out_3, _Property_f7111fce9be08b8c871514ffc219f648_Out_0, _GradientNoise_de42ec7fdd52ec8fa0b6cb7f34842c13_Out_2);
            float2 _TilingAndOffset_aa88c06674f4178889e657a2bb46c454_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_430e3c523bf85e84bdef451ab28beba0_Out_3.xy), float2 (1, 1), float2 (0, 0), _TilingAndOffset_aa88c06674f4178889e657a2bb46c454_Out_3);
            float _GradientNoise_28996fa0f6fbd08c97ed18d0621900b5_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_aa88c06674f4178889e657a2bb46c454_Out_3, _Property_f7111fce9be08b8c871514ffc219f648_Out_0, _GradientNoise_28996fa0f6fbd08c97ed18d0621900b5_Out_2);
            float _Add_caf5f972abacae878d9a6fde10e0986a_Out_2;
            Unity_Add_float(_GradientNoise_de42ec7fdd52ec8fa0b6cb7f34842c13_Out_2, _GradientNoise_28996fa0f6fbd08c97ed18d0621900b5_Out_2, _Add_caf5f972abacae878d9a6fde10e0986a_Out_2);
            float _Divide_27ef561e54cd208ca89512269c1d4d03_Out_2;
            Unity_Divide_float(_Add_caf5f972abacae878d9a6fde10e0986a_Out_2, 2, _Divide_27ef561e54cd208ca89512269c1d4d03_Out_2);
            float _Saturate_c56694103011198486afa78b0e89ec2c_Out_1;
            Unity_Saturate_float(_Divide_27ef561e54cd208ca89512269c1d4d03_Out_2, _Saturate_c56694103011198486afa78b0e89ec2c_Out_1);
            float _Property_8bd1d491d3050588a0b837b4b232170d_Out_0 = Vector1_4CE104D9;
            float _Power_abb6d235206009809ee431a98f2c8247_Out_2;
            Unity_Power_float(_Saturate_c56694103011198486afa78b0e89ec2c_Out_1, _Property_8bd1d491d3050588a0b837b4b232170d_Out_0, _Power_abb6d235206009809ee431a98f2c8247_Out_2);
            float4 _Property_8a81e8a6d963f384bddf6e75ec8e0a1c_Out_0 = Vector4_1696EE66;
            float _Split_f72e1ad87d56df8ba34ec31e2bc432b8_R_1 = _Property_8a81e8a6d963f384bddf6e75ec8e0a1c_Out_0[0];
            float _Split_f72e1ad87d56df8ba34ec31e2bc432b8_G_2 = _Property_8a81e8a6d963f384bddf6e75ec8e0a1c_Out_0[1];
            float _Split_f72e1ad87d56df8ba34ec31e2bc432b8_B_3 = _Property_8a81e8a6d963f384bddf6e75ec8e0a1c_Out_0[2];
            float _Split_f72e1ad87d56df8ba34ec31e2bc432b8_A_4 = _Property_8a81e8a6d963f384bddf6e75ec8e0a1c_Out_0[3];
            float4 _Combine_aeef4bbea8acc688b198e488208172f2_RGBA_4;
            float3 _Combine_aeef4bbea8acc688b198e488208172f2_RGB_5;
            float2 _Combine_aeef4bbea8acc688b198e488208172f2_RG_6;
            Unity_Combine_float(_Split_f72e1ad87d56df8ba34ec31e2bc432b8_R_1, _Split_f72e1ad87d56df8ba34ec31e2bc432b8_G_2, 0, 0, _Combine_aeef4bbea8acc688b198e488208172f2_RGBA_4, _Combine_aeef4bbea8acc688b198e488208172f2_RGB_5, _Combine_aeef4bbea8acc688b198e488208172f2_RG_6);
            float4 _Combine_feabe866dc39388d8ccd72275fb9be09_RGBA_4;
            float3 _Combine_feabe866dc39388d8ccd72275fb9be09_RGB_5;
            float2 _Combine_feabe866dc39388d8ccd72275fb9be09_RG_6;
            Unity_Combine_float(_Split_f72e1ad87d56df8ba34ec31e2bc432b8_B_3, _Split_f72e1ad87d56df8ba34ec31e2bc432b8_A_4, 0, 0, _Combine_feabe866dc39388d8ccd72275fb9be09_RGBA_4, _Combine_feabe866dc39388d8ccd72275fb9be09_RGB_5, _Combine_feabe866dc39388d8ccd72275fb9be09_RG_6);
            float _Remap_ca18d3412979f985809f3426d5282816_Out_3;
            Unity_Remap_float(_Power_abb6d235206009809ee431a98f2c8247_Out_2, _Combine_aeef4bbea8acc688b198e488208172f2_RG_6, _Combine_feabe866dc39388d8ccd72275fb9be09_RG_6, _Remap_ca18d3412979f985809f3426d5282816_Out_3);
            float _Absolute_01d69efb5b6b628b8142004f10302240_Out_1;
            Unity_Absolute_float(_Remap_ca18d3412979f985809f3426d5282816_Out_3, _Absolute_01d69efb5b6b628b8142004f10302240_Out_1);
            float _Smoothstep_5a0282a38f27848e9545f1e89a11f5a2_Out_3;
            Unity_Smoothstep_float(_Property_45fc02a5c65e898c82a51138ee7894c8_Out_0, _Property_423be2625737e5829e3daa7b3cf8389d_Out_0, _Absolute_01d69efb5b6b628b8142004f10302240_Out_1, _Smoothstep_5a0282a38f27848e9545f1e89a11f5a2_Out_3);
            float _Property_91482984669b1c8ab26a0f4a555b3801_Out_0 = Vector1_9058DE8C;
            float _Multiply_ad5811e4c08fae88a363e144af359987_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_91482984669b1c8ab26a0f4a555b3801_Out_0, _Multiply_ad5811e4c08fae88a363e144af359987_Out_2);
            float2 _TilingAndOffset_2345314be014258796bc32f9e66d2397_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_430e3c523bf85e84bdef451ab28beba0_Out_3.xy), float2 (1, 1), (_Multiply_ad5811e4c08fae88a363e144af359987_Out_2.xx), _TilingAndOffset_2345314be014258796bc32f9e66d2397_Out_3);
            float _Property_a13e388a84b18e89afce2f9f3ca9753f_Out_0 = Vector1_5536221E;
            float _GradientNoise_9f2e5d10ed34688f87f30e9a171b1f8b_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_2345314be014258796bc32f9e66d2397_Out_3, _Property_a13e388a84b18e89afce2f9f3ca9753f_Out_0, _GradientNoise_9f2e5d10ed34688f87f30e9a171b1f8b_Out_2);
            float _Property_b64fda08fa35398f9e0f45e316a434f9_Out_0 = Vector1_350643F1;
            float _Multiply_d03d0c5bc6770f8b8fbb46ec0c06b35b_Out_2;
            Unity_Multiply_float(_GradientNoise_9f2e5d10ed34688f87f30e9a171b1f8b_Out_2, _Property_b64fda08fa35398f9e0f45e316a434f9_Out_0, _Multiply_d03d0c5bc6770f8b8fbb46ec0c06b35b_Out_2);
            float _Add_f031b6931be259898e2d889c851d36d5_Out_2;
            Unity_Add_float(_Smoothstep_5a0282a38f27848e9545f1e89a11f5a2_Out_3, _Multiply_d03d0c5bc6770f8b8fbb46ec0c06b35b_Out_2, _Add_f031b6931be259898e2d889c851d36d5_Out_2);
            float _Add_e1b7452d2644ef8e96d652df6def6989_Out_2;
            Unity_Add_float(1, _Property_b64fda08fa35398f9e0f45e316a434f9_Out_0, _Add_e1b7452d2644ef8e96d652df6def6989_Out_2);
            float _Divide_b34aaac0718e8682bb2ab66e45d42421_Out_2;
            Unity_Divide_float(_Add_f031b6931be259898e2d889c851d36d5_Out_2, _Add_e1b7452d2644ef8e96d652df6def6989_Out_2, _Divide_b34aaac0718e8682bb2ab66e45d42421_Out_2);
            float4 _Lerp_0f05ab7309374f869f26c5de63c7685d_Out_3;
            Unity_Lerp_float4(_Property_8602b260fe5c06829b7738349464dbbc_Out_0, _Property_db73cd07c4394c82a6cd028523c127f3_Out_0, (_Divide_b34aaac0718e8682bb2ab66e45d42421_Out_2.xxxx), _Lerp_0f05ab7309374f869f26c5de63c7685d_Out_3);
            float _Property_0e672fb430de1988a91ebab3a6c55a4b_Out_0 = Vector1_B4ED823D;
            float _FresnelEffect_d3463b04b6387381ae221b6b9fda5a55_Out_3;
            Unity_FresnelEffect_float(IN.WorldSpaceNormal, IN.WorldSpaceViewDirection, _Property_0e672fb430de1988a91ebab3a6c55a4b_Out_0, _FresnelEffect_d3463b04b6387381ae221b6b9fda5a55_Out_3);
            float _Multiply_b1b397b5458b168183311fa585ce24cc_Out_2;
            Unity_Multiply_float(_Divide_b34aaac0718e8682bb2ab66e45d42421_Out_2, _FresnelEffect_d3463b04b6387381ae221b6b9fda5a55_Out_3, _Multiply_b1b397b5458b168183311fa585ce24cc_Out_2);
            float _Property_a0d7e69c6b484186aed4c837b9cfdf60_Out_0 = Vector1_2BA361A8;
            float _Multiply_c527b7ae93e59a82a8b685490472d140_Out_2;
            Unity_Multiply_float(_Multiply_b1b397b5458b168183311fa585ce24cc_Out_2, _Property_a0d7e69c6b484186aed4c837b9cfdf60_Out_0, _Multiply_c527b7ae93e59a82a8b685490472d140_Out_2);
            float4 _Add_e90a39812292588185bb8af6f98ac6ed_Out_2;
            Unity_Add_float4(_Lerp_0f05ab7309374f869f26c5de63c7685d_Out_3, (_Multiply_c527b7ae93e59a82a8b685490472d140_Out_2.xxxx), _Add_e90a39812292588185bb8af6f98ac6ed_Out_2);
            float _Property_2b5ded79d5faa287bcd134d3931fddbd_Out_0 = Vector1_2A80C598;
            float4 _Multiply_89abd19f1abd878f9e4e10491d20220d_Out_2;
            Unity_Multiply_float(_Add_e90a39812292588185bb8af6f98ac6ed_Out_2, (_Property_2b5ded79d5faa287bcd134d3931fddbd_Out_0.xxxx), _Multiply_89abd19f1abd878f9e4e10491d20220d_Out_2);
            float _SceneDepth_845bf60653d70482b562a739512eeda7_Out_1;
            Unity_SceneDepth_Eye_float(float4(IN.ScreenPosition.xy / IN.ScreenPosition.w, 0, 0), _SceneDepth_845bf60653d70482b562a739512eeda7_Out_1);
            float4 _ScreenPosition_b978995ebe1ba286935416b2a2d5cb85_Out_0 = IN.ScreenPosition;
            float _Split_c66584edb0487b8e8c2e107a89ed8e9f_R_1 = _ScreenPosition_b978995ebe1ba286935416b2a2d5cb85_Out_0[0];
            float _Split_c66584edb0487b8e8c2e107a89ed8e9f_G_2 = _ScreenPosition_b978995ebe1ba286935416b2a2d5cb85_Out_0[1];
            float _Split_c66584edb0487b8e8c2e107a89ed8e9f_B_3 = _ScreenPosition_b978995ebe1ba286935416b2a2d5cb85_Out_0[2];
            float _Split_c66584edb0487b8e8c2e107a89ed8e9f_A_4 = _ScreenPosition_b978995ebe1ba286935416b2a2d5cb85_Out_0[3];
            float _Subtract_39fffd64ebdafb84a6eb8e37e2faaa16_Out_2;
            Unity_Subtract_float(_Split_c66584edb0487b8e8c2e107a89ed8e9f_A_4, 1, _Subtract_39fffd64ebdafb84a6eb8e37e2faaa16_Out_2);
            float _Subtract_d8ff2e79b2fc8386b6172daebbe97366_Out_2;
            Unity_Subtract_float(_SceneDepth_845bf60653d70482b562a739512eeda7_Out_1, _Subtract_39fffd64ebdafb84a6eb8e37e2faaa16_Out_2, _Subtract_d8ff2e79b2fc8386b6172daebbe97366_Out_2);
            float _Property_0a2887e34569358bbc9cbee1a14acebb_Out_0 = Vector1_EED1A887;
            float _Divide_f3ff43869c02038db823cf0d91c23caf_Out_2;
            Unity_Divide_float(_Subtract_d8ff2e79b2fc8386b6172daebbe97366_Out_2, _Property_0a2887e34569358bbc9cbee1a14acebb_Out_0, _Divide_f3ff43869c02038db823cf0d91c23caf_Out_2);
            float _Saturate_676d84ccc0f0b88e9d1fdf263cfcf1d5_Out_1;
            Unity_Saturate_float(_Divide_f3ff43869c02038db823cf0d91c23caf_Out_2, _Saturate_676d84ccc0f0b88e9d1fdf263cfcf1d5_Out_1);
            float _Smoothstep_edf634d16c75cd829225bfca563f83fb_Out_3;
            Unity_Smoothstep_float(0, 1, _Saturate_676d84ccc0f0b88e9d1fdf263cfcf1d5_Out_1, _Smoothstep_edf634d16c75cd829225bfca563f83fb_Out_3);
            surface.BaseColor = IsGammaSpace() ? float3(0, 0, 0) : SRGBToLinear(float3(0, 0, 0));
            surface.NormalTS = IN.TangentSpaceNormal;
            surface.Emission = (_Multiply_89abd19f1abd878f9e4e10491d20220d_Out_2.xyz);
            surface.Metallic = 0;
            surface.Smoothness = 0.5;
            surface.Occlusion = 1;
            surface.Alpha = _Smoothstep_edf634d16c75cd829225bfca563f83fb_Out_3;
            return surface;
        }

            // --------------------------------------------------
            // Build Graph Inputs

            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);

            output.ObjectSpaceNormal =           input.normalOS;
            output.WorldSpaceNormal =            TransformObjectToWorldNormal(input.normalOS);
            output.ObjectSpaceTangent =          input.tangentOS.xyz;
            output.ObjectSpacePosition =         input.positionOS;
            output.WorldSpacePosition =          TransformObjectToWorld(input.positionOS);
            output.TimeParameters =              _TimeParameters.xyz;

            return output;
        }
            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);

        	// must use interpolated tangent, bitangent and normal before they are normalized in the pixel shader.
        	float3 unnormalizedNormalWS = input.normalWS;
            const float renormFactor = 1.0 / length(unnormalizedNormalWS);


            output.WorldSpaceNormal =            renormFactor*input.normalWS.xyz;		// we want a unit length Normal Vector node in shader graph
            output.TangentSpaceNormal =          float3(0.0f, 0.0f, 1.0f);


            output.WorldSpaceViewDirection =     input.viewDirectionWS; //TODO: by default normalized in HD, but not in universal
            output.WorldSpacePosition =          input.positionWS;
            output.ScreenPosition =              ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
            output.TimeParameters =              _TimeParameters.xyz; // This is mainly for LW as HD overwrite this value
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

            return output;
        }

            // --------------------------------------------------
            // Main

            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/UnityGBuffer.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/PBRGBufferPass.hlsl"

            ENDHLSL
        }
        Pass
        {
            Name "ShadowCaster"
            Tags
            {
                "LightMode" = "ShadowCaster"
            }

            // Render State
            Cull Back
        Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
        ZTest LEqual
        ZWrite On
        ColorMask 0

            // Debug
            // <None>

            // --------------------------------------------------
            // Pass

            HLSLPROGRAM

            // Pragmas
            #pragma target 4.5
        #pragma exclude_renderers gles gles3 glcore
        #pragma multi_compile_instancing
        #pragma multi_compile _ DOTS_INSTANCING_ON
        #pragma vertex vert
        #pragma fragment frag

            // DotsInstancingOptions: <None>
            // HybridV1InjectedBuiltinProperties: <None>

            // Keywords
            // PassKeywords: <None>
            // GraphKeywords: <None>

            // Defines
            #define _SURFACE_TYPE_TRANSPARENT 1
            #define _NORMALMAP 1
            #define _NORMAL_DROPOFF_TS 1
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define VARYINGS_NEED_POSITION_WS
            #define FEATURES_GRAPH_VERTEX
            /* WARNING: $splice Could not find named fragment 'PassInstancing' */
            #define SHADERPASS SHADERPASS_SHADOWCASTER
        #define REQUIRE_DEPTH_TEXTURE
            /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

            // --------------------------------------------------
            // Structs and Packing

            struct Attributes
        {
            float3 positionOS : POSITION;
            float3 normalOS : NORMAL;
            float4 tangentOS : TANGENT;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
            float4 positionCS : SV_POSITION;
            float3 positionWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
            float3 WorldSpacePosition;
            float4 ScreenPosition;
        };
        struct VertexDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 WorldSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 ObjectSpacePosition;
            float3 WorldSpacePosition;
            float3 TimeParameters;
        };
        struct PackedVaryings
        {
            float4 positionCS : SV_POSITION;
            float3 interp0 : TEXCOORD0;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };

            PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }

            // --------------------------------------------------
            // Graph

            // Graph Properties
            CBUFFER_START(UnityPerMaterial)
        float4 Vector4_484BA326;
        float Vector1_8F075DBC;
        float Vector1_8AAD665C;
        float Vector1_E43D3892;
        float4 Vector4_1696EE66;
        float4 Color_2CFB5E2A;
        float4 Color_58195353;
        float Vector1_FADC0395;
        float Vector1_E505CA4B;
        float Vector1_4CE104D9;
        float Vector1_5536221E;
        float Vector1_9058DE8C;
        float Vector1_350643F1;
        float Vector1_2A80C598;
        float Vector1_A664731F;
        float Vector1_B4ED823D;
        float Vector1_2BA361A8;
        float Vector1_EED1A887;
        CBUFFER_END

        // Object and Global properties

            // Graph Functions
            
        void Unity_Distance_float3(float3 A, float3 B, out float Out)
        {
            Out = distance(A, B);
        }

        void Unity_Divide_float(float A, float B, out float Out)
        {
            Out = A / B;
        }

        void Unity_Power_float(float A, float B, out float Out)
        {
            Out = pow(A, B);
        }

        void Unity_Multiply_float(float3 A, float3 B, out float3 Out)
        {
            Out = A * B;
        }

        void Unity_Rotate_About_Axis_Degrees_float(float3 In, float3 Axis, float Rotation, out float3 Out)
        {
            Rotation = radians(Rotation);

            float s = sin(Rotation);
            float c = cos(Rotation);
            float one_minus_c = 1.0 - c;
            
            Axis = normalize(Axis);

            float3x3 rot_mat = { one_minus_c * Axis.x * Axis.x + c,            one_minus_c * Axis.x * Axis.y - Axis.z * s,     one_minus_c * Axis.z * Axis.x + Axis.y * s,
                                      one_minus_c * Axis.x * Axis.y + Axis.z * s,   one_minus_c * Axis.y * Axis.y + c,              one_minus_c * Axis.y * Axis.z - Axis.x * s,
                                      one_minus_c * Axis.z * Axis.x - Axis.y * s,   one_minus_c * Axis.y * Axis.z + Axis.x * s,     one_minus_c * Axis.z * Axis.z + c
                                    };

            Out = mul(rot_mat,  In);
        }

        void Unity_Multiply_float(float A, float B, out float Out)
        {
            Out = A * B;
        }

        void Unity_TilingAndOffset_float(float2 UV, float2 Tiling, float2 Offset, out float2 Out)
        {
            Out = UV * Tiling + Offset;
        }


        float2 Unity_GradientNoise_Dir_float(float2 p)
        {
            // Permutation and hashing used in webgl-nosie goo.gl/pX7HtC
            p = p % 289;
            // need full precision, otherwise half overflows when p > 1
            float x = float(34 * p.x + 1) * p.x % 289 + p.y;
            x = (34 * x + 1) * x % 289;
            x = frac(x / 41) * 2 - 1;
            return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
        }

        void Unity_GradientNoise_float(float2 UV, float Scale, out float Out)
        { 
            float2 p = UV * Scale;
            float2 ip = floor(p);
            float2 fp = frac(p);
            float d00 = dot(Unity_GradientNoise_Dir_float(ip), fp);
            float d01 = dot(Unity_GradientNoise_Dir_float(ip + float2(0, 1)), fp - float2(0, 1));
            float d10 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 0)), fp - float2(1, 0));
            float d11 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 1)), fp - float2(1, 1));
            fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
            Out = lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x) + 0.5;
        }

        void Unity_Add_float(float A, float B, out float Out)
        {
            Out = A + B;
        }

        void Unity_Saturate_float(float In, out float Out)
        {
            Out = saturate(In);
        }

        void Unity_Combine_float(float R, float G, float B, float A, out float4 RGBA, out float3 RGB, out float2 RG)
        {
            RGBA = float4(R, G, B, A);
            RGB = float3(R, G, B);
            RG = float2(R, G);
        }

        void Unity_Remap_float(float In, float2 InMinMax, float2 OutMinMax, out float Out)
        {
            Out = OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
        }

        void Unity_Absolute_float(float In, out float Out)
        {
            Out = abs(In);
        }

        void Unity_Smoothstep_float(float Edge1, float Edge2, float In, out float Out)
        {
            Out = smoothstep(Edge1, Edge2, In);
        }

        void Unity_Add_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A + B;
        }

        void Unity_SceneDepth_Eye_float(float4 UV, out float Out)
        {
            Out = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH(UV.xy), _ZBufferParams);
        }

        void Unity_Subtract_float(float A, float B, out float Out)
        {
            Out = A - B;
        }

            // Graph Vertex
            struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };

        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            float _Distance_474c9e8e982c878dad2f0d5844b22ee9_Out_2;
            Unity_Distance_float3(SHADERGRAPH_OBJECT_POSITION, IN.WorldSpacePosition, _Distance_474c9e8e982c878dad2f0d5844b22ee9_Out_2);
            float _Property_95b6af28bf5d388fb7809e99d4ea7a10_Out_0 = Vector1_A664731F;
            float _Divide_2022c703e9e6de87965706bd214b7b67_Out_2;
            Unity_Divide_float(_Distance_474c9e8e982c878dad2f0d5844b22ee9_Out_2, _Property_95b6af28bf5d388fb7809e99d4ea7a10_Out_0, _Divide_2022c703e9e6de87965706bd214b7b67_Out_2);
            float _Power_8710b3fb1efe3183a2818b946e662a1e_Out_2;
            Unity_Power_float(_Divide_2022c703e9e6de87965706bd214b7b67_Out_2, 3, _Power_8710b3fb1efe3183a2818b946e662a1e_Out_2);
            float3 _Multiply_3fa32f2d7f56688684a8f5b0a0853be5_Out_2;
            Unity_Multiply_float(IN.WorldSpaceNormal, (_Power_8710b3fb1efe3183a2818b946e662a1e_Out_2.xxx), _Multiply_3fa32f2d7f56688684a8f5b0a0853be5_Out_2);
            float _Property_45fc02a5c65e898c82a51138ee7894c8_Out_0 = Vector1_FADC0395;
            float _Property_423be2625737e5829e3daa7b3cf8389d_Out_0 = Vector1_E505CA4B;
            float4 _Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0 = Vector4_484BA326;
            float _Split_e9324c176bf05a809ea8df8c413a826a_R_1 = _Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0[0];
            float _Split_e9324c176bf05a809ea8df8c413a826a_G_2 = _Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0[1];
            float _Split_e9324c176bf05a809ea8df8c413a826a_B_3 = _Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0[2];
            float _Split_e9324c176bf05a809ea8df8c413a826a_A_4 = _Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0[3];
            float3 _RotateAboutAxis_430e3c523bf85e84bdef451ab28beba0_Out_3;
            Unity_Rotate_About_Axis_Degrees_float(IN.WorldSpacePosition, (_Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0.xyz), _Split_e9324c176bf05a809ea8df8c413a826a_A_4, _RotateAboutAxis_430e3c523bf85e84bdef451ab28beba0_Out_3);
            float _Property_84dca49c8958708fac3276b0de15a6da_Out_0 = Vector1_8AAD665C;
            float _Multiply_89f92af49e152081ba549c92ab002e9c_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_84dca49c8958708fac3276b0de15a6da_Out_0, _Multiply_89f92af49e152081ba549c92ab002e9c_Out_2);
            float2 _TilingAndOffset_bd9fc632c3a6c185b226f93212ed8603_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_430e3c523bf85e84bdef451ab28beba0_Out_3.xy), float2 (1, 1), (_Multiply_89f92af49e152081ba549c92ab002e9c_Out_2.xx), _TilingAndOffset_bd9fc632c3a6c185b226f93212ed8603_Out_3);
            float _Property_f7111fce9be08b8c871514ffc219f648_Out_0 = Vector1_8F075DBC;
            float _GradientNoise_de42ec7fdd52ec8fa0b6cb7f34842c13_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_bd9fc632c3a6c185b226f93212ed8603_Out_3, _Property_f7111fce9be08b8c871514ffc219f648_Out_0, _GradientNoise_de42ec7fdd52ec8fa0b6cb7f34842c13_Out_2);
            float2 _TilingAndOffset_aa88c06674f4178889e657a2bb46c454_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_430e3c523bf85e84bdef451ab28beba0_Out_3.xy), float2 (1, 1), float2 (0, 0), _TilingAndOffset_aa88c06674f4178889e657a2bb46c454_Out_3);
            float _GradientNoise_28996fa0f6fbd08c97ed18d0621900b5_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_aa88c06674f4178889e657a2bb46c454_Out_3, _Property_f7111fce9be08b8c871514ffc219f648_Out_0, _GradientNoise_28996fa0f6fbd08c97ed18d0621900b5_Out_2);
            float _Add_caf5f972abacae878d9a6fde10e0986a_Out_2;
            Unity_Add_float(_GradientNoise_de42ec7fdd52ec8fa0b6cb7f34842c13_Out_2, _GradientNoise_28996fa0f6fbd08c97ed18d0621900b5_Out_2, _Add_caf5f972abacae878d9a6fde10e0986a_Out_2);
            float _Divide_27ef561e54cd208ca89512269c1d4d03_Out_2;
            Unity_Divide_float(_Add_caf5f972abacae878d9a6fde10e0986a_Out_2, 2, _Divide_27ef561e54cd208ca89512269c1d4d03_Out_2);
            float _Saturate_c56694103011198486afa78b0e89ec2c_Out_1;
            Unity_Saturate_float(_Divide_27ef561e54cd208ca89512269c1d4d03_Out_2, _Saturate_c56694103011198486afa78b0e89ec2c_Out_1);
            float _Property_8bd1d491d3050588a0b837b4b232170d_Out_0 = Vector1_4CE104D9;
            float _Power_abb6d235206009809ee431a98f2c8247_Out_2;
            Unity_Power_float(_Saturate_c56694103011198486afa78b0e89ec2c_Out_1, _Property_8bd1d491d3050588a0b837b4b232170d_Out_0, _Power_abb6d235206009809ee431a98f2c8247_Out_2);
            float4 _Property_8a81e8a6d963f384bddf6e75ec8e0a1c_Out_0 = Vector4_1696EE66;
            float _Split_f72e1ad87d56df8ba34ec31e2bc432b8_R_1 = _Property_8a81e8a6d963f384bddf6e75ec8e0a1c_Out_0[0];
            float _Split_f72e1ad87d56df8ba34ec31e2bc432b8_G_2 = _Property_8a81e8a6d963f384bddf6e75ec8e0a1c_Out_0[1];
            float _Split_f72e1ad87d56df8ba34ec31e2bc432b8_B_3 = _Property_8a81e8a6d963f384bddf6e75ec8e0a1c_Out_0[2];
            float _Split_f72e1ad87d56df8ba34ec31e2bc432b8_A_4 = _Property_8a81e8a6d963f384bddf6e75ec8e0a1c_Out_0[3];
            float4 _Combine_aeef4bbea8acc688b198e488208172f2_RGBA_4;
            float3 _Combine_aeef4bbea8acc688b198e488208172f2_RGB_5;
            float2 _Combine_aeef4bbea8acc688b198e488208172f2_RG_6;
            Unity_Combine_float(_Split_f72e1ad87d56df8ba34ec31e2bc432b8_R_1, _Split_f72e1ad87d56df8ba34ec31e2bc432b8_G_2, 0, 0, _Combine_aeef4bbea8acc688b198e488208172f2_RGBA_4, _Combine_aeef4bbea8acc688b198e488208172f2_RGB_5, _Combine_aeef4bbea8acc688b198e488208172f2_RG_6);
            float4 _Combine_feabe866dc39388d8ccd72275fb9be09_RGBA_4;
            float3 _Combine_feabe866dc39388d8ccd72275fb9be09_RGB_5;
            float2 _Combine_feabe866dc39388d8ccd72275fb9be09_RG_6;
            Unity_Combine_float(_Split_f72e1ad87d56df8ba34ec31e2bc432b8_B_3, _Split_f72e1ad87d56df8ba34ec31e2bc432b8_A_4, 0, 0, _Combine_feabe866dc39388d8ccd72275fb9be09_RGBA_4, _Combine_feabe866dc39388d8ccd72275fb9be09_RGB_5, _Combine_feabe866dc39388d8ccd72275fb9be09_RG_6);
            float _Remap_ca18d3412979f985809f3426d5282816_Out_3;
            Unity_Remap_float(_Power_abb6d235206009809ee431a98f2c8247_Out_2, _Combine_aeef4bbea8acc688b198e488208172f2_RG_6, _Combine_feabe866dc39388d8ccd72275fb9be09_RG_6, _Remap_ca18d3412979f985809f3426d5282816_Out_3);
            float _Absolute_01d69efb5b6b628b8142004f10302240_Out_1;
            Unity_Absolute_float(_Remap_ca18d3412979f985809f3426d5282816_Out_3, _Absolute_01d69efb5b6b628b8142004f10302240_Out_1);
            float _Smoothstep_5a0282a38f27848e9545f1e89a11f5a2_Out_3;
            Unity_Smoothstep_float(_Property_45fc02a5c65e898c82a51138ee7894c8_Out_0, _Property_423be2625737e5829e3daa7b3cf8389d_Out_0, _Absolute_01d69efb5b6b628b8142004f10302240_Out_1, _Smoothstep_5a0282a38f27848e9545f1e89a11f5a2_Out_3);
            float _Property_91482984669b1c8ab26a0f4a555b3801_Out_0 = Vector1_9058DE8C;
            float _Multiply_ad5811e4c08fae88a363e144af359987_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_91482984669b1c8ab26a0f4a555b3801_Out_0, _Multiply_ad5811e4c08fae88a363e144af359987_Out_2);
            float2 _TilingAndOffset_2345314be014258796bc32f9e66d2397_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_430e3c523bf85e84bdef451ab28beba0_Out_3.xy), float2 (1, 1), (_Multiply_ad5811e4c08fae88a363e144af359987_Out_2.xx), _TilingAndOffset_2345314be014258796bc32f9e66d2397_Out_3);
            float _Property_a13e388a84b18e89afce2f9f3ca9753f_Out_0 = Vector1_5536221E;
            float _GradientNoise_9f2e5d10ed34688f87f30e9a171b1f8b_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_2345314be014258796bc32f9e66d2397_Out_3, _Property_a13e388a84b18e89afce2f9f3ca9753f_Out_0, _GradientNoise_9f2e5d10ed34688f87f30e9a171b1f8b_Out_2);
            float _Property_b64fda08fa35398f9e0f45e316a434f9_Out_0 = Vector1_350643F1;
            float _Multiply_d03d0c5bc6770f8b8fbb46ec0c06b35b_Out_2;
            Unity_Multiply_float(_GradientNoise_9f2e5d10ed34688f87f30e9a171b1f8b_Out_2, _Property_b64fda08fa35398f9e0f45e316a434f9_Out_0, _Multiply_d03d0c5bc6770f8b8fbb46ec0c06b35b_Out_2);
            float _Add_f031b6931be259898e2d889c851d36d5_Out_2;
            Unity_Add_float(_Smoothstep_5a0282a38f27848e9545f1e89a11f5a2_Out_3, _Multiply_d03d0c5bc6770f8b8fbb46ec0c06b35b_Out_2, _Add_f031b6931be259898e2d889c851d36d5_Out_2);
            float _Add_e1b7452d2644ef8e96d652df6def6989_Out_2;
            Unity_Add_float(1, _Property_b64fda08fa35398f9e0f45e316a434f9_Out_0, _Add_e1b7452d2644ef8e96d652df6def6989_Out_2);
            float _Divide_b34aaac0718e8682bb2ab66e45d42421_Out_2;
            Unity_Divide_float(_Add_f031b6931be259898e2d889c851d36d5_Out_2, _Add_e1b7452d2644ef8e96d652df6def6989_Out_2, _Divide_b34aaac0718e8682bb2ab66e45d42421_Out_2);
            float3 _Multiply_a97d25c025f47f8fa4cfe3267dee485e_Out_2;
            Unity_Multiply_float(IN.ObjectSpaceNormal, (_Divide_b34aaac0718e8682bb2ab66e45d42421_Out_2.xxx), _Multiply_a97d25c025f47f8fa4cfe3267dee485e_Out_2);
            float _Property_6f2976fe72816a869d8677a4230164f0_Out_0 = Vector1_E43D3892;
            float3 _Multiply_08ef8c8995ef448a9ab1e43028223a19_Out_2;
            Unity_Multiply_float(_Multiply_a97d25c025f47f8fa4cfe3267dee485e_Out_2, (_Property_6f2976fe72816a869d8677a4230164f0_Out_0.xxx), _Multiply_08ef8c8995ef448a9ab1e43028223a19_Out_2);
            float3 _Add_ec1431816c726e8a827bfd7e7de3d614_Out_2;
            Unity_Add_float3(IN.ObjectSpacePosition, _Multiply_08ef8c8995ef448a9ab1e43028223a19_Out_2, _Add_ec1431816c726e8a827bfd7e7de3d614_Out_2);
            float3 _Add_cbfa9591f076e485a31b7f5b967f99f6_Out_2;
            Unity_Add_float3(_Multiply_3fa32f2d7f56688684a8f5b0a0853be5_Out_2, _Add_ec1431816c726e8a827bfd7e7de3d614_Out_2, _Add_cbfa9591f076e485a31b7f5b967f99f6_Out_2);
            description.Position = _Add_cbfa9591f076e485a31b7f5b967f99f6_Out_2;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }

            // Graph Pixel
            struct SurfaceDescription
        {
            float Alpha;
        };

        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            float _SceneDepth_845bf60653d70482b562a739512eeda7_Out_1;
            Unity_SceneDepth_Eye_float(float4(IN.ScreenPosition.xy / IN.ScreenPosition.w, 0, 0), _SceneDepth_845bf60653d70482b562a739512eeda7_Out_1);
            float4 _ScreenPosition_b978995ebe1ba286935416b2a2d5cb85_Out_0 = IN.ScreenPosition;
            float _Split_c66584edb0487b8e8c2e107a89ed8e9f_R_1 = _ScreenPosition_b978995ebe1ba286935416b2a2d5cb85_Out_0[0];
            float _Split_c66584edb0487b8e8c2e107a89ed8e9f_G_2 = _ScreenPosition_b978995ebe1ba286935416b2a2d5cb85_Out_0[1];
            float _Split_c66584edb0487b8e8c2e107a89ed8e9f_B_3 = _ScreenPosition_b978995ebe1ba286935416b2a2d5cb85_Out_0[2];
            float _Split_c66584edb0487b8e8c2e107a89ed8e9f_A_4 = _ScreenPosition_b978995ebe1ba286935416b2a2d5cb85_Out_0[3];
            float _Subtract_39fffd64ebdafb84a6eb8e37e2faaa16_Out_2;
            Unity_Subtract_float(_Split_c66584edb0487b8e8c2e107a89ed8e9f_A_4, 1, _Subtract_39fffd64ebdafb84a6eb8e37e2faaa16_Out_2);
            float _Subtract_d8ff2e79b2fc8386b6172daebbe97366_Out_2;
            Unity_Subtract_float(_SceneDepth_845bf60653d70482b562a739512eeda7_Out_1, _Subtract_39fffd64ebdafb84a6eb8e37e2faaa16_Out_2, _Subtract_d8ff2e79b2fc8386b6172daebbe97366_Out_2);
            float _Property_0a2887e34569358bbc9cbee1a14acebb_Out_0 = Vector1_EED1A887;
            float _Divide_f3ff43869c02038db823cf0d91c23caf_Out_2;
            Unity_Divide_float(_Subtract_d8ff2e79b2fc8386b6172daebbe97366_Out_2, _Property_0a2887e34569358bbc9cbee1a14acebb_Out_0, _Divide_f3ff43869c02038db823cf0d91c23caf_Out_2);
            float _Saturate_676d84ccc0f0b88e9d1fdf263cfcf1d5_Out_1;
            Unity_Saturate_float(_Divide_f3ff43869c02038db823cf0d91c23caf_Out_2, _Saturate_676d84ccc0f0b88e9d1fdf263cfcf1d5_Out_1);
            float _Smoothstep_edf634d16c75cd829225bfca563f83fb_Out_3;
            Unity_Smoothstep_float(0, 1, _Saturate_676d84ccc0f0b88e9d1fdf263cfcf1d5_Out_1, _Smoothstep_edf634d16c75cd829225bfca563f83fb_Out_3);
            surface.Alpha = _Smoothstep_edf634d16c75cd829225bfca563f83fb_Out_3;
            return surface;
        }

            // --------------------------------------------------
            // Build Graph Inputs

            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);

            output.ObjectSpaceNormal =           input.normalOS;
            output.WorldSpaceNormal =            TransformObjectToWorldNormal(input.normalOS);
            output.ObjectSpaceTangent =          input.tangentOS.xyz;
            output.ObjectSpacePosition =         input.positionOS;
            output.WorldSpacePosition =          TransformObjectToWorld(input.positionOS);
            output.TimeParameters =              _TimeParameters.xyz;

            return output;
        }
            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);





            output.WorldSpacePosition =          input.positionWS;
            output.ScreenPosition =              ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

            return output;
        }

            // --------------------------------------------------
            // Main

            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShadowCasterPass.hlsl"

            ENDHLSL
        }
        Pass
        {
            Name "DepthOnly"
            Tags
            {
                "LightMode" = "DepthOnly"
            }

            // Render State
            Cull Back
        Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
        ZTest LEqual
        ZWrite On
        ColorMask 0

            // Debug
            // <None>

            // --------------------------------------------------
            // Pass

            HLSLPROGRAM

            // Pragmas
            #pragma target 4.5
        #pragma exclude_renderers gles gles3 glcore
        #pragma multi_compile_instancing
        #pragma multi_compile _ DOTS_INSTANCING_ON
        #pragma vertex vert
        #pragma fragment frag

            // DotsInstancingOptions: <None>
            // HybridV1InjectedBuiltinProperties: <None>

            // Keywords
            // PassKeywords: <None>
            // GraphKeywords: <None>

            // Defines
            #define _SURFACE_TYPE_TRANSPARENT 1
            #define _NORMALMAP 1
            #define _NORMAL_DROPOFF_TS 1
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define VARYINGS_NEED_POSITION_WS
            #define FEATURES_GRAPH_VERTEX
            /* WARNING: $splice Could not find named fragment 'PassInstancing' */
            #define SHADERPASS SHADERPASS_DEPTHONLY
        #define REQUIRE_DEPTH_TEXTURE
            /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

            // --------------------------------------------------
            // Structs and Packing

            struct Attributes
        {
            float3 positionOS : POSITION;
            float3 normalOS : NORMAL;
            float4 tangentOS : TANGENT;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
            float4 positionCS : SV_POSITION;
            float3 positionWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
            float3 WorldSpacePosition;
            float4 ScreenPosition;
        };
        struct VertexDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 WorldSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 ObjectSpacePosition;
            float3 WorldSpacePosition;
            float3 TimeParameters;
        };
        struct PackedVaryings
        {
            float4 positionCS : SV_POSITION;
            float3 interp0 : TEXCOORD0;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };

            PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }

            // --------------------------------------------------
            // Graph

            // Graph Properties
            CBUFFER_START(UnityPerMaterial)
        float4 Vector4_484BA326;
        float Vector1_8F075DBC;
        float Vector1_8AAD665C;
        float Vector1_E43D3892;
        float4 Vector4_1696EE66;
        float4 Color_2CFB5E2A;
        float4 Color_58195353;
        float Vector1_FADC0395;
        float Vector1_E505CA4B;
        float Vector1_4CE104D9;
        float Vector1_5536221E;
        float Vector1_9058DE8C;
        float Vector1_350643F1;
        float Vector1_2A80C598;
        float Vector1_A664731F;
        float Vector1_B4ED823D;
        float Vector1_2BA361A8;
        float Vector1_EED1A887;
        CBUFFER_END

        // Object and Global properties

            // Graph Functions
            
        void Unity_Distance_float3(float3 A, float3 B, out float Out)
        {
            Out = distance(A, B);
        }

        void Unity_Divide_float(float A, float B, out float Out)
        {
            Out = A / B;
        }

        void Unity_Power_float(float A, float B, out float Out)
        {
            Out = pow(A, B);
        }

        void Unity_Multiply_float(float3 A, float3 B, out float3 Out)
        {
            Out = A * B;
        }

        void Unity_Rotate_About_Axis_Degrees_float(float3 In, float3 Axis, float Rotation, out float3 Out)
        {
            Rotation = radians(Rotation);

            float s = sin(Rotation);
            float c = cos(Rotation);
            float one_minus_c = 1.0 - c;
            
            Axis = normalize(Axis);

            float3x3 rot_mat = { one_minus_c * Axis.x * Axis.x + c,            one_minus_c * Axis.x * Axis.y - Axis.z * s,     one_minus_c * Axis.z * Axis.x + Axis.y * s,
                                      one_minus_c * Axis.x * Axis.y + Axis.z * s,   one_minus_c * Axis.y * Axis.y + c,              one_minus_c * Axis.y * Axis.z - Axis.x * s,
                                      one_minus_c * Axis.z * Axis.x - Axis.y * s,   one_minus_c * Axis.y * Axis.z + Axis.x * s,     one_minus_c * Axis.z * Axis.z + c
                                    };

            Out = mul(rot_mat,  In);
        }

        void Unity_Multiply_float(float A, float B, out float Out)
        {
            Out = A * B;
        }

        void Unity_TilingAndOffset_float(float2 UV, float2 Tiling, float2 Offset, out float2 Out)
        {
            Out = UV * Tiling + Offset;
        }


        float2 Unity_GradientNoise_Dir_float(float2 p)
        {
            // Permutation and hashing used in webgl-nosie goo.gl/pX7HtC
            p = p % 289;
            // need full precision, otherwise half overflows when p > 1
            float x = float(34 * p.x + 1) * p.x % 289 + p.y;
            x = (34 * x + 1) * x % 289;
            x = frac(x / 41) * 2 - 1;
            return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
        }

        void Unity_GradientNoise_float(float2 UV, float Scale, out float Out)
        { 
            float2 p = UV * Scale;
            float2 ip = floor(p);
            float2 fp = frac(p);
            float d00 = dot(Unity_GradientNoise_Dir_float(ip), fp);
            float d01 = dot(Unity_GradientNoise_Dir_float(ip + float2(0, 1)), fp - float2(0, 1));
            float d10 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 0)), fp - float2(1, 0));
            float d11 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 1)), fp - float2(1, 1));
            fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
            Out = lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x) + 0.5;
        }

        void Unity_Add_float(float A, float B, out float Out)
        {
            Out = A + B;
        }

        void Unity_Saturate_float(float In, out float Out)
        {
            Out = saturate(In);
        }

        void Unity_Combine_float(float R, float G, float B, float A, out float4 RGBA, out float3 RGB, out float2 RG)
        {
            RGBA = float4(R, G, B, A);
            RGB = float3(R, G, B);
            RG = float2(R, G);
        }

        void Unity_Remap_float(float In, float2 InMinMax, float2 OutMinMax, out float Out)
        {
            Out = OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
        }

        void Unity_Absolute_float(float In, out float Out)
        {
            Out = abs(In);
        }

        void Unity_Smoothstep_float(float Edge1, float Edge2, float In, out float Out)
        {
            Out = smoothstep(Edge1, Edge2, In);
        }

        void Unity_Add_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A + B;
        }

        void Unity_SceneDepth_Eye_float(float4 UV, out float Out)
        {
            Out = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH(UV.xy), _ZBufferParams);
        }

        void Unity_Subtract_float(float A, float B, out float Out)
        {
            Out = A - B;
        }

            // Graph Vertex
            struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };

        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            float _Distance_474c9e8e982c878dad2f0d5844b22ee9_Out_2;
            Unity_Distance_float3(SHADERGRAPH_OBJECT_POSITION, IN.WorldSpacePosition, _Distance_474c9e8e982c878dad2f0d5844b22ee9_Out_2);
            float _Property_95b6af28bf5d388fb7809e99d4ea7a10_Out_0 = Vector1_A664731F;
            float _Divide_2022c703e9e6de87965706bd214b7b67_Out_2;
            Unity_Divide_float(_Distance_474c9e8e982c878dad2f0d5844b22ee9_Out_2, _Property_95b6af28bf5d388fb7809e99d4ea7a10_Out_0, _Divide_2022c703e9e6de87965706bd214b7b67_Out_2);
            float _Power_8710b3fb1efe3183a2818b946e662a1e_Out_2;
            Unity_Power_float(_Divide_2022c703e9e6de87965706bd214b7b67_Out_2, 3, _Power_8710b3fb1efe3183a2818b946e662a1e_Out_2);
            float3 _Multiply_3fa32f2d7f56688684a8f5b0a0853be5_Out_2;
            Unity_Multiply_float(IN.WorldSpaceNormal, (_Power_8710b3fb1efe3183a2818b946e662a1e_Out_2.xxx), _Multiply_3fa32f2d7f56688684a8f5b0a0853be5_Out_2);
            float _Property_45fc02a5c65e898c82a51138ee7894c8_Out_0 = Vector1_FADC0395;
            float _Property_423be2625737e5829e3daa7b3cf8389d_Out_0 = Vector1_E505CA4B;
            float4 _Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0 = Vector4_484BA326;
            float _Split_e9324c176bf05a809ea8df8c413a826a_R_1 = _Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0[0];
            float _Split_e9324c176bf05a809ea8df8c413a826a_G_2 = _Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0[1];
            float _Split_e9324c176bf05a809ea8df8c413a826a_B_3 = _Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0[2];
            float _Split_e9324c176bf05a809ea8df8c413a826a_A_4 = _Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0[3];
            float3 _RotateAboutAxis_430e3c523bf85e84bdef451ab28beba0_Out_3;
            Unity_Rotate_About_Axis_Degrees_float(IN.WorldSpacePosition, (_Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0.xyz), _Split_e9324c176bf05a809ea8df8c413a826a_A_4, _RotateAboutAxis_430e3c523bf85e84bdef451ab28beba0_Out_3);
            float _Property_84dca49c8958708fac3276b0de15a6da_Out_0 = Vector1_8AAD665C;
            float _Multiply_89f92af49e152081ba549c92ab002e9c_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_84dca49c8958708fac3276b0de15a6da_Out_0, _Multiply_89f92af49e152081ba549c92ab002e9c_Out_2);
            float2 _TilingAndOffset_bd9fc632c3a6c185b226f93212ed8603_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_430e3c523bf85e84bdef451ab28beba0_Out_3.xy), float2 (1, 1), (_Multiply_89f92af49e152081ba549c92ab002e9c_Out_2.xx), _TilingAndOffset_bd9fc632c3a6c185b226f93212ed8603_Out_3);
            float _Property_f7111fce9be08b8c871514ffc219f648_Out_0 = Vector1_8F075DBC;
            float _GradientNoise_de42ec7fdd52ec8fa0b6cb7f34842c13_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_bd9fc632c3a6c185b226f93212ed8603_Out_3, _Property_f7111fce9be08b8c871514ffc219f648_Out_0, _GradientNoise_de42ec7fdd52ec8fa0b6cb7f34842c13_Out_2);
            float2 _TilingAndOffset_aa88c06674f4178889e657a2bb46c454_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_430e3c523bf85e84bdef451ab28beba0_Out_3.xy), float2 (1, 1), float2 (0, 0), _TilingAndOffset_aa88c06674f4178889e657a2bb46c454_Out_3);
            float _GradientNoise_28996fa0f6fbd08c97ed18d0621900b5_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_aa88c06674f4178889e657a2bb46c454_Out_3, _Property_f7111fce9be08b8c871514ffc219f648_Out_0, _GradientNoise_28996fa0f6fbd08c97ed18d0621900b5_Out_2);
            float _Add_caf5f972abacae878d9a6fde10e0986a_Out_2;
            Unity_Add_float(_GradientNoise_de42ec7fdd52ec8fa0b6cb7f34842c13_Out_2, _GradientNoise_28996fa0f6fbd08c97ed18d0621900b5_Out_2, _Add_caf5f972abacae878d9a6fde10e0986a_Out_2);
            float _Divide_27ef561e54cd208ca89512269c1d4d03_Out_2;
            Unity_Divide_float(_Add_caf5f972abacae878d9a6fde10e0986a_Out_2, 2, _Divide_27ef561e54cd208ca89512269c1d4d03_Out_2);
            float _Saturate_c56694103011198486afa78b0e89ec2c_Out_1;
            Unity_Saturate_float(_Divide_27ef561e54cd208ca89512269c1d4d03_Out_2, _Saturate_c56694103011198486afa78b0e89ec2c_Out_1);
            float _Property_8bd1d491d3050588a0b837b4b232170d_Out_0 = Vector1_4CE104D9;
            float _Power_abb6d235206009809ee431a98f2c8247_Out_2;
            Unity_Power_float(_Saturate_c56694103011198486afa78b0e89ec2c_Out_1, _Property_8bd1d491d3050588a0b837b4b232170d_Out_0, _Power_abb6d235206009809ee431a98f2c8247_Out_2);
            float4 _Property_8a81e8a6d963f384bddf6e75ec8e0a1c_Out_0 = Vector4_1696EE66;
            float _Split_f72e1ad87d56df8ba34ec31e2bc432b8_R_1 = _Property_8a81e8a6d963f384bddf6e75ec8e0a1c_Out_0[0];
            float _Split_f72e1ad87d56df8ba34ec31e2bc432b8_G_2 = _Property_8a81e8a6d963f384bddf6e75ec8e0a1c_Out_0[1];
            float _Split_f72e1ad87d56df8ba34ec31e2bc432b8_B_3 = _Property_8a81e8a6d963f384bddf6e75ec8e0a1c_Out_0[2];
            float _Split_f72e1ad87d56df8ba34ec31e2bc432b8_A_4 = _Property_8a81e8a6d963f384bddf6e75ec8e0a1c_Out_0[3];
            float4 _Combine_aeef4bbea8acc688b198e488208172f2_RGBA_4;
            float3 _Combine_aeef4bbea8acc688b198e488208172f2_RGB_5;
            float2 _Combine_aeef4bbea8acc688b198e488208172f2_RG_6;
            Unity_Combine_float(_Split_f72e1ad87d56df8ba34ec31e2bc432b8_R_1, _Split_f72e1ad87d56df8ba34ec31e2bc432b8_G_2, 0, 0, _Combine_aeef4bbea8acc688b198e488208172f2_RGBA_4, _Combine_aeef4bbea8acc688b198e488208172f2_RGB_5, _Combine_aeef4bbea8acc688b198e488208172f2_RG_6);
            float4 _Combine_feabe866dc39388d8ccd72275fb9be09_RGBA_4;
            float3 _Combine_feabe866dc39388d8ccd72275fb9be09_RGB_5;
            float2 _Combine_feabe866dc39388d8ccd72275fb9be09_RG_6;
            Unity_Combine_float(_Split_f72e1ad87d56df8ba34ec31e2bc432b8_B_3, _Split_f72e1ad87d56df8ba34ec31e2bc432b8_A_4, 0, 0, _Combine_feabe866dc39388d8ccd72275fb9be09_RGBA_4, _Combine_feabe866dc39388d8ccd72275fb9be09_RGB_5, _Combine_feabe866dc39388d8ccd72275fb9be09_RG_6);
            float _Remap_ca18d3412979f985809f3426d5282816_Out_3;
            Unity_Remap_float(_Power_abb6d235206009809ee431a98f2c8247_Out_2, _Combine_aeef4bbea8acc688b198e488208172f2_RG_6, _Combine_feabe866dc39388d8ccd72275fb9be09_RG_6, _Remap_ca18d3412979f985809f3426d5282816_Out_3);
            float _Absolute_01d69efb5b6b628b8142004f10302240_Out_1;
            Unity_Absolute_float(_Remap_ca18d3412979f985809f3426d5282816_Out_3, _Absolute_01d69efb5b6b628b8142004f10302240_Out_1);
            float _Smoothstep_5a0282a38f27848e9545f1e89a11f5a2_Out_3;
            Unity_Smoothstep_float(_Property_45fc02a5c65e898c82a51138ee7894c8_Out_0, _Property_423be2625737e5829e3daa7b3cf8389d_Out_0, _Absolute_01d69efb5b6b628b8142004f10302240_Out_1, _Smoothstep_5a0282a38f27848e9545f1e89a11f5a2_Out_3);
            float _Property_91482984669b1c8ab26a0f4a555b3801_Out_0 = Vector1_9058DE8C;
            float _Multiply_ad5811e4c08fae88a363e144af359987_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_91482984669b1c8ab26a0f4a555b3801_Out_0, _Multiply_ad5811e4c08fae88a363e144af359987_Out_2);
            float2 _TilingAndOffset_2345314be014258796bc32f9e66d2397_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_430e3c523bf85e84bdef451ab28beba0_Out_3.xy), float2 (1, 1), (_Multiply_ad5811e4c08fae88a363e144af359987_Out_2.xx), _TilingAndOffset_2345314be014258796bc32f9e66d2397_Out_3);
            float _Property_a13e388a84b18e89afce2f9f3ca9753f_Out_0 = Vector1_5536221E;
            float _GradientNoise_9f2e5d10ed34688f87f30e9a171b1f8b_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_2345314be014258796bc32f9e66d2397_Out_3, _Property_a13e388a84b18e89afce2f9f3ca9753f_Out_0, _GradientNoise_9f2e5d10ed34688f87f30e9a171b1f8b_Out_2);
            float _Property_b64fda08fa35398f9e0f45e316a434f9_Out_0 = Vector1_350643F1;
            float _Multiply_d03d0c5bc6770f8b8fbb46ec0c06b35b_Out_2;
            Unity_Multiply_float(_GradientNoise_9f2e5d10ed34688f87f30e9a171b1f8b_Out_2, _Property_b64fda08fa35398f9e0f45e316a434f9_Out_0, _Multiply_d03d0c5bc6770f8b8fbb46ec0c06b35b_Out_2);
            float _Add_f031b6931be259898e2d889c851d36d5_Out_2;
            Unity_Add_float(_Smoothstep_5a0282a38f27848e9545f1e89a11f5a2_Out_3, _Multiply_d03d0c5bc6770f8b8fbb46ec0c06b35b_Out_2, _Add_f031b6931be259898e2d889c851d36d5_Out_2);
            float _Add_e1b7452d2644ef8e96d652df6def6989_Out_2;
            Unity_Add_float(1, _Property_b64fda08fa35398f9e0f45e316a434f9_Out_0, _Add_e1b7452d2644ef8e96d652df6def6989_Out_2);
            float _Divide_b34aaac0718e8682bb2ab66e45d42421_Out_2;
            Unity_Divide_float(_Add_f031b6931be259898e2d889c851d36d5_Out_2, _Add_e1b7452d2644ef8e96d652df6def6989_Out_2, _Divide_b34aaac0718e8682bb2ab66e45d42421_Out_2);
            float3 _Multiply_a97d25c025f47f8fa4cfe3267dee485e_Out_2;
            Unity_Multiply_float(IN.ObjectSpaceNormal, (_Divide_b34aaac0718e8682bb2ab66e45d42421_Out_2.xxx), _Multiply_a97d25c025f47f8fa4cfe3267dee485e_Out_2);
            float _Property_6f2976fe72816a869d8677a4230164f0_Out_0 = Vector1_E43D3892;
            float3 _Multiply_08ef8c8995ef448a9ab1e43028223a19_Out_2;
            Unity_Multiply_float(_Multiply_a97d25c025f47f8fa4cfe3267dee485e_Out_2, (_Property_6f2976fe72816a869d8677a4230164f0_Out_0.xxx), _Multiply_08ef8c8995ef448a9ab1e43028223a19_Out_2);
            float3 _Add_ec1431816c726e8a827bfd7e7de3d614_Out_2;
            Unity_Add_float3(IN.ObjectSpacePosition, _Multiply_08ef8c8995ef448a9ab1e43028223a19_Out_2, _Add_ec1431816c726e8a827bfd7e7de3d614_Out_2);
            float3 _Add_cbfa9591f076e485a31b7f5b967f99f6_Out_2;
            Unity_Add_float3(_Multiply_3fa32f2d7f56688684a8f5b0a0853be5_Out_2, _Add_ec1431816c726e8a827bfd7e7de3d614_Out_2, _Add_cbfa9591f076e485a31b7f5b967f99f6_Out_2);
            description.Position = _Add_cbfa9591f076e485a31b7f5b967f99f6_Out_2;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }

            // Graph Pixel
            struct SurfaceDescription
        {
            float Alpha;
        };

        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            float _SceneDepth_845bf60653d70482b562a739512eeda7_Out_1;
            Unity_SceneDepth_Eye_float(float4(IN.ScreenPosition.xy / IN.ScreenPosition.w, 0, 0), _SceneDepth_845bf60653d70482b562a739512eeda7_Out_1);
            float4 _ScreenPosition_b978995ebe1ba286935416b2a2d5cb85_Out_0 = IN.ScreenPosition;
            float _Split_c66584edb0487b8e8c2e107a89ed8e9f_R_1 = _ScreenPosition_b978995ebe1ba286935416b2a2d5cb85_Out_0[0];
            float _Split_c66584edb0487b8e8c2e107a89ed8e9f_G_2 = _ScreenPosition_b978995ebe1ba286935416b2a2d5cb85_Out_0[1];
            float _Split_c66584edb0487b8e8c2e107a89ed8e9f_B_3 = _ScreenPosition_b978995ebe1ba286935416b2a2d5cb85_Out_0[2];
            float _Split_c66584edb0487b8e8c2e107a89ed8e9f_A_4 = _ScreenPosition_b978995ebe1ba286935416b2a2d5cb85_Out_0[3];
            float _Subtract_39fffd64ebdafb84a6eb8e37e2faaa16_Out_2;
            Unity_Subtract_float(_Split_c66584edb0487b8e8c2e107a89ed8e9f_A_4, 1, _Subtract_39fffd64ebdafb84a6eb8e37e2faaa16_Out_2);
            float _Subtract_d8ff2e79b2fc8386b6172daebbe97366_Out_2;
            Unity_Subtract_float(_SceneDepth_845bf60653d70482b562a739512eeda7_Out_1, _Subtract_39fffd64ebdafb84a6eb8e37e2faaa16_Out_2, _Subtract_d8ff2e79b2fc8386b6172daebbe97366_Out_2);
            float _Property_0a2887e34569358bbc9cbee1a14acebb_Out_0 = Vector1_EED1A887;
            float _Divide_f3ff43869c02038db823cf0d91c23caf_Out_2;
            Unity_Divide_float(_Subtract_d8ff2e79b2fc8386b6172daebbe97366_Out_2, _Property_0a2887e34569358bbc9cbee1a14acebb_Out_0, _Divide_f3ff43869c02038db823cf0d91c23caf_Out_2);
            float _Saturate_676d84ccc0f0b88e9d1fdf263cfcf1d5_Out_1;
            Unity_Saturate_float(_Divide_f3ff43869c02038db823cf0d91c23caf_Out_2, _Saturate_676d84ccc0f0b88e9d1fdf263cfcf1d5_Out_1);
            float _Smoothstep_edf634d16c75cd829225bfca563f83fb_Out_3;
            Unity_Smoothstep_float(0, 1, _Saturate_676d84ccc0f0b88e9d1fdf263cfcf1d5_Out_1, _Smoothstep_edf634d16c75cd829225bfca563f83fb_Out_3);
            surface.Alpha = _Smoothstep_edf634d16c75cd829225bfca563f83fb_Out_3;
            return surface;
        }

            // --------------------------------------------------
            // Build Graph Inputs

            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);

            output.ObjectSpaceNormal =           input.normalOS;
            output.WorldSpaceNormal =            TransformObjectToWorldNormal(input.normalOS);
            output.ObjectSpaceTangent =          input.tangentOS.xyz;
            output.ObjectSpacePosition =         input.positionOS;
            output.WorldSpacePosition =          TransformObjectToWorld(input.positionOS);
            output.TimeParameters =              _TimeParameters.xyz;

            return output;
        }
            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);





            output.WorldSpacePosition =          input.positionWS;
            output.ScreenPosition =              ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

            return output;
        }

            // --------------------------------------------------
            // Main

            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/DepthOnlyPass.hlsl"

            ENDHLSL
        }
        Pass
        {
            Name "DepthNormals"
            Tags
            {
                "LightMode" = "DepthNormals"
            }

            // Render State
            Cull Back
        Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
        ZTest LEqual
        ZWrite On

            // Debug
            // <None>

            // --------------------------------------------------
            // Pass

            HLSLPROGRAM

            // Pragmas
            #pragma target 4.5
        #pragma exclude_renderers gles gles3 glcore
        #pragma multi_compile_instancing
        #pragma multi_compile _ DOTS_INSTANCING_ON
        #pragma vertex vert
        #pragma fragment frag

            // DotsInstancingOptions: <None>
            // HybridV1InjectedBuiltinProperties: <None>

            // Keywords
            // PassKeywords: <None>
            // GraphKeywords: <None>

            // Defines
            #define _SURFACE_TYPE_TRANSPARENT 1
            #define _NORMALMAP 1
            #define _NORMAL_DROPOFF_TS 1
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define ATTRIBUTES_NEED_TEXCOORD1
            #define VARYINGS_NEED_POSITION_WS
            #define VARYINGS_NEED_NORMAL_WS
            #define VARYINGS_NEED_TANGENT_WS
            #define FEATURES_GRAPH_VERTEX
            /* WARNING: $splice Could not find named fragment 'PassInstancing' */
            #define SHADERPASS SHADERPASS_DEPTHNORMALSONLY
        #define REQUIRE_DEPTH_TEXTURE
            /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

            // --------------------------------------------------
            // Structs and Packing

            struct Attributes
        {
            float3 positionOS : POSITION;
            float3 normalOS : NORMAL;
            float4 tangentOS : TANGENT;
            float4 uv1 : TEXCOORD1;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
            float4 positionCS : SV_POSITION;
            float3 positionWS;
            float3 normalWS;
            float4 tangentWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
            float3 TangentSpaceNormal;
            float3 WorldSpacePosition;
            float4 ScreenPosition;
        };
        struct VertexDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 WorldSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 ObjectSpacePosition;
            float3 WorldSpacePosition;
            float3 TimeParameters;
        };
        struct PackedVaryings
        {
            float4 positionCS : SV_POSITION;
            float3 interp0 : TEXCOORD0;
            float3 interp1 : TEXCOORD1;
            float4 interp2 : TEXCOORD2;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };

            PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            output.interp2.xyzw =  input.tangentWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            output.tangentWS = input.interp2.xyzw;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }

            // --------------------------------------------------
            // Graph

            // Graph Properties
            CBUFFER_START(UnityPerMaterial)
        float4 Vector4_484BA326;
        float Vector1_8F075DBC;
        float Vector1_8AAD665C;
        float Vector1_E43D3892;
        float4 Vector4_1696EE66;
        float4 Color_2CFB5E2A;
        float4 Color_58195353;
        float Vector1_FADC0395;
        float Vector1_E505CA4B;
        float Vector1_4CE104D9;
        float Vector1_5536221E;
        float Vector1_9058DE8C;
        float Vector1_350643F1;
        float Vector1_2A80C598;
        float Vector1_A664731F;
        float Vector1_B4ED823D;
        float Vector1_2BA361A8;
        float Vector1_EED1A887;
        CBUFFER_END

        // Object and Global properties

            // Graph Functions
            
        void Unity_Distance_float3(float3 A, float3 B, out float Out)
        {
            Out = distance(A, B);
        }

        void Unity_Divide_float(float A, float B, out float Out)
        {
            Out = A / B;
        }

        void Unity_Power_float(float A, float B, out float Out)
        {
            Out = pow(A, B);
        }

        void Unity_Multiply_float(float3 A, float3 B, out float3 Out)
        {
            Out = A * B;
        }

        void Unity_Rotate_About_Axis_Degrees_float(float3 In, float3 Axis, float Rotation, out float3 Out)
        {
            Rotation = radians(Rotation);

            float s = sin(Rotation);
            float c = cos(Rotation);
            float one_minus_c = 1.0 - c;
            
            Axis = normalize(Axis);

            float3x3 rot_mat = { one_minus_c * Axis.x * Axis.x + c,            one_minus_c * Axis.x * Axis.y - Axis.z * s,     one_minus_c * Axis.z * Axis.x + Axis.y * s,
                                      one_minus_c * Axis.x * Axis.y + Axis.z * s,   one_minus_c * Axis.y * Axis.y + c,              one_minus_c * Axis.y * Axis.z - Axis.x * s,
                                      one_minus_c * Axis.z * Axis.x - Axis.y * s,   one_minus_c * Axis.y * Axis.z + Axis.x * s,     one_minus_c * Axis.z * Axis.z + c
                                    };

            Out = mul(rot_mat,  In);
        }

        void Unity_Multiply_float(float A, float B, out float Out)
        {
            Out = A * B;
        }

        void Unity_TilingAndOffset_float(float2 UV, float2 Tiling, float2 Offset, out float2 Out)
        {
            Out = UV * Tiling + Offset;
        }


        float2 Unity_GradientNoise_Dir_float(float2 p)
        {
            // Permutation and hashing used in webgl-nosie goo.gl/pX7HtC
            p = p % 289;
            // need full precision, otherwise half overflows when p > 1
            float x = float(34 * p.x + 1) * p.x % 289 + p.y;
            x = (34 * x + 1) * x % 289;
            x = frac(x / 41) * 2 - 1;
            return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
        }

        void Unity_GradientNoise_float(float2 UV, float Scale, out float Out)
        { 
            float2 p = UV * Scale;
            float2 ip = floor(p);
            float2 fp = frac(p);
            float d00 = dot(Unity_GradientNoise_Dir_float(ip), fp);
            float d01 = dot(Unity_GradientNoise_Dir_float(ip + float2(0, 1)), fp - float2(0, 1));
            float d10 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 0)), fp - float2(1, 0));
            float d11 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 1)), fp - float2(1, 1));
            fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
            Out = lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x) + 0.5;
        }

        void Unity_Add_float(float A, float B, out float Out)
        {
            Out = A + B;
        }

        void Unity_Saturate_float(float In, out float Out)
        {
            Out = saturate(In);
        }

        void Unity_Combine_float(float R, float G, float B, float A, out float4 RGBA, out float3 RGB, out float2 RG)
        {
            RGBA = float4(R, G, B, A);
            RGB = float3(R, G, B);
            RG = float2(R, G);
        }

        void Unity_Remap_float(float In, float2 InMinMax, float2 OutMinMax, out float Out)
        {
            Out = OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
        }

        void Unity_Absolute_float(float In, out float Out)
        {
            Out = abs(In);
        }

        void Unity_Smoothstep_float(float Edge1, float Edge2, float In, out float Out)
        {
            Out = smoothstep(Edge1, Edge2, In);
        }

        void Unity_Add_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A + B;
        }

        void Unity_SceneDepth_Eye_float(float4 UV, out float Out)
        {
            Out = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH(UV.xy), _ZBufferParams);
        }

        void Unity_Subtract_float(float A, float B, out float Out)
        {
            Out = A - B;
        }

            // Graph Vertex
            struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };

        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            float _Distance_474c9e8e982c878dad2f0d5844b22ee9_Out_2;
            Unity_Distance_float3(SHADERGRAPH_OBJECT_POSITION, IN.WorldSpacePosition, _Distance_474c9e8e982c878dad2f0d5844b22ee9_Out_2);
            float _Property_95b6af28bf5d388fb7809e99d4ea7a10_Out_0 = Vector1_A664731F;
            float _Divide_2022c703e9e6de87965706bd214b7b67_Out_2;
            Unity_Divide_float(_Distance_474c9e8e982c878dad2f0d5844b22ee9_Out_2, _Property_95b6af28bf5d388fb7809e99d4ea7a10_Out_0, _Divide_2022c703e9e6de87965706bd214b7b67_Out_2);
            float _Power_8710b3fb1efe3183a2818b946e662a1e_Out_2;
            Unity_Power_float(_Divide_2022c703e9e6de87965706bd214b7b67_Out_2, 3, _Power_8710b3fb1efe3183a2818b946e662a1e_Out_2);
            float3 _Multiply_3fa32f2d7f56688684a8f5b0a0853be5_Out_2;
            Unity_Multiply_float(IN.WorldSpaceNormal, (_Power_8710b3fb1efe3183a2818b946e662a1e_Out_2.xxx), _Multiply_3fa32f2d7f56688684a8f5b0a0853be5_Out_2);
            float _Property_45fc02a5c65e898c82a51138ee7894c8_Out_0 = Vector1_FADC0395;
            float _Property_423be2625737e5829e3daa7b3cf8389d_Out_0 = Vector1_E505CA4B;
            float4 _Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0 = Vector4_484BA326;
            float _Split_e9324c176bf05a809ea8df8c413a826a_R_1 = _Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0[0];
            float _Split_e9324c176bf05a809ea8df8c413a826a_G_2 = _Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0[1];
            float _Split_e9324c176bf05a809ea8df8c413a826a_B_3 = _Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0[2];
            float _Split_e9324c176bf05a809ea8df8c413a826a_A_4 = _Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0[3];
            float3 _RotateAboutAxis_430e3c523bf85e84bdef451ab28beba0_Out_3;
            Unity_Rotate_About_Axis_Degrees_float(IN.WorldSpacePosition, (_Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0.xyz), _Split_e9324c176bf05a809ea8df8c413a826a_A_4, _RotateAboutAxis_430e3c523bf85e84bdef451ab28beba0_Out_3);
            float _Property_84dca49c8958708fac3276b0de15a6da_Out_0 = Vector1_8AAD665C;
            float _Multiply_89f92af49e152081ba549c92ab002e9c_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_84dca49c8958708fac3276b0de15a6da_Out_0, _Multiply_89f92af49e152081ba549c92ab002e9c_Out_2);
            float2 _TilingAndOffset_bd9fc632c3a6c185b226f93212ed8603_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_430e3c523bf85e84bdef451ab28beba0_Out_3.xy), float2 (1, 1), (_Multiply_89f92af49e152081ba549c92ab002e9c_Out_2.xx), _TilingAndOffset_bd9fc632c3a6c185b226f93212ed8603_Out_3);
            float _Property_f7111fce9be08b8c871514ffc219f648_Out_0 = Vector1_8F075DBC;
            float _GradientNoise_de42ec7fdd52ec8fa0b6cb7f34842c13_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_bd9fc632c3a6c185b226f93212ed8603_Out_3, _Property_f7111fce9be08b8c871514ffc219f648_Out_0, _GradientNoise_de42ec7fdd52ec8fa0b6cb7f34842c13_Out_2);
            float2 _TilingAndOffset_aa88c06674f4178889e657a2bb46c454_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_430e3c523bf85e84bdef451ab28beba0_Out_3.xy), float2 (1, 1), float2 (0, 0), _TilingAndOffset_aa88c06674f4178889e657a2bb46c454_Out_3);
            float _GradientNoise_28996fa0f6fbd08c97ed18d0621900b5_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_aa88c06674f4178889e657a2bb46c454_Out_3, _Property_f7111fce9be08b8c871514ffc219f648_Out_0, _GradientNoise_28996fa0f6fbd08c97ed18d0621900b5_Out_2);
            float _Add_caf5f972abacae878d9a6fde10e0986a_Out_2;
            Unity_Add_float(_GradientNoise_de42ec7fdd52ec8fa0b6cb7f34842c13_Out_2, _GradientNoise_28996fa0f6fbd08c97ed18d0621900b5_Out_2, _Add_caf5f972abacae878d9a6fde10e0986a_Out_2);
            float _Divide_27ef561e54cd208ca89512269c1d4d03_Out_2;
            Unity_Divide_float(_Add_caf5f972abacae878d9a6fde10e0986a_Out_2, 2, _Divide_27ef561e54cd208ca89512269c1d4d03_Out_2);
            float _Saturate_c56694103011198486afa78b0e89ec2c_Out_1;
            Unity_Saturate_float(_Divide_27ef561e54cd208ca89512269c1d4d03_Out_2, _Saturate_c56694103011198486afa78b0e89ec2c_Out_1);
            float _Property_8bd1d491d3050588a0b837b4b232170d_Out_0 = Vector1_4CE104D9;
            float _Power_abb6d235206009809ee431a98f2c8247_Out_2;
            Unity_Power_float(_Saturate_c56694103011198486afa78b0e89ec2c_Out_1, _Property_8bd1d491d3050588a0b837b4b232170d_Out_0, _Power_abb6d235206009809ee431a98f2c8247_Out_2);
            float4 _Property_8a81e8a6d963f384bddf6e75ec8e0a1c_Out_0 = Vector4_1696EE66;
            float _Split_f72e1ad87d56df8ba34ec31e2bc432b8_R_1 = _Property_8a81e8a6d963f384bddf6e75ec8e0a1c_Out_0[0];
            float _Split_f72e1ad87d56df8ba34ec31e2bc432b8_G_2 = _Property_8a81e8a6d963f384bddf6e75ec8e0a1c_Out_0[1];
            float _Split_f72e1ad87d56df8ba34ec31e2bc432b8_B_3 = _Property_8a81e8a6d963f384bddf6e75ec8e0a1c_Out_0[2];
            float _Split_f72e1ad87d56df8ba34ec31e2bc432b8_A_4 = _Property_8a81e8a6d963f384bddf6e75ec8e0a1c_Out_0[3];
            float4 _Combine_aeef4bbea8acc688b198e488208172f2_RGBA_4;
            float3 _Combine_aeef4bbea8acc688b198e488208172f2_RGB_5;
            float2 _Combine_aeef4bbea8acc688b198e488208172f2_RG_6;
            Unity_Combine_float(_Split_f72e1ad87d56df8ba34ec31e2bc432b8_R_1, _Split_f72e1ad87d56df8ba34ec31e2bc432b8_G_2, 0, 0, _Combine_aeef4bbea8acc688b198e488208172f2_RGBA_4, _Combine_aeef4bbea8acc688b198e488208172f2_RGB_5, _Combine_aeef4bbea8acc688b198e488208172f2_RG_6);
            float4 _Combine_feabe866dc39388d8ccd72275fb9be09_RGBA_4;
            float3 _Combine_feabe866dc39388d8ccd72275fb9be09_RGB_5;
            float2 _Combine_feabe866dc39388d8ccd72275fb9be09_RG_6;
            Unity_Combine_float(_Split_f72e1ad87d56df8ba34ec31e2bc432b8_B_3, _Split_f72e1ad87d56df8ba34ec31e2bc432b8_A_4, 0, 0, _Combine_feabe866dc39388d8ccd72275fb9be09_RGBA_4, _Combine_feabe866dc39388d8ccd72275fb9be09_RGB_5, _Combine_feabe866dc39388d8ccd72275fb9be09_RG_6);
            float _Remap_ca18d3412979f985809f3426d5282816_Out_3;
            Unity_Remap_float(_Power_abb6d235206009809ee431a98f2c8247_Out_2, _Combine_aeef4bbea8acc688b198e488208172f2_RG_6, _Combine_feabe866dc39388d8ccd72275fb9be09_RG_6, _Remap_ca18d3412979f985809f3426d5282816_Out_3);
            float _Absolute_01d69efb5b6b628b8142004f10302240_Out_1;
            Unity_Absolute_float(_Remap_ca18d3412979f985809f3426d5282816_Out_3, _Absolute_01d69efb5b6b628b8142004f10302240_Out_1);
            float _Smoothstep_5a0282a38f27848e9545f1e89a11f5a2_Out_3;
            Unity_Smoothstep_float(_Property_45fc02a5c65e898c82a51138ee7894c8_Out_0, _Property_423be2625737e5829e3daa7b3cf8389d_Out_0, _Absolute_01d69efb5b6b628b8142004f10302240_Out_1, _Smoothstep_5a0282a38f27848e9545f1e89a11f5a2_Out_3);
            float _Property_91482984669b1c8ab26a0f4a555b3801_Out_0 = Vector1_9058DE8C;
            float _Multiply_ad5811e4c08fae88a363e144af359987_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_91482984669b1c8ab26a0f4a555b3801_Out_0, _Multiply_ad5811e4c08fae88a363e144af359987_Out_2);
            float2 _TilingAndOffset_2345314be014258796bc32f9e66d2397_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_430e3c523bf85e84bdef451ab28beba0_Out_3.xy), float2 (1, 1), (_Multiply_ad5811e4c08fae88a363e144af359987_Out_2.xx), _TilingAndOffset_2345314be014258796bc32f9e66d2397_Out_3);
            float _Property_a13e388a84b18e89afce2f9f3ca9753f_Out_0 = Vector1_5536221E;
            float _GradientNoise_9f2e5d10ed34688f87f30e9a171b1f8b_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_2345314be014258796bc32f9e66d2397_Out_3, _Property_a13e388a84b18e89afce2f9f3ca9753f_Out_0, _GradientNoise_9f2e5d10ed34688f87f30e9a171b1f8b_Out_2);
            float _Property_b64fda08fa35398f9e0f45e316a434f9_Out_0 = Vector1_350643F1;
            float _Multiply_d03d0c5bc6770f8b8fbb46ec0c06b35b_Out_2;
            Unity_Multiply_float(_GradientNoise_9f2e5d10ed34688f87f30e9a171b1f8b_Out_2, _Property_b64fda08fa35398f9e0f45e316a434f9_Out_0, _Multiply_d03d0c5bc6770f8b8fbb46ec0c06b35b_Out_2);
            float _Add_f031b6931be259898e2d889c851d36d5_Out_2;
            Unity_Add_float(_Smoothstep_5a0282a38f27848e9545f1e89a11f5a2_Out_3, _Multiply_d03d0c5bc6770f8b8fbb46ec0c06b35b_Out_2, _Add_f031b6931be259898e2d889c851d36d5_Out_2);
            float _Add_e1b7452d2644ef8e96d652df6def6989_Out_2;
            Unity_Add_float(1, _Property_b64fda08fa35398f9e0f45e316a434f9_Out_0, _Add_e1b7452d2644ef8e96d652df6def6989_Out_2);
            float _Divide_b34aaac0718e8682bb2ab66e45d42421_Out_2;
            Unity_Divide_float(_Add_f031b6931be259898e2d889c851d36d5_Out_2, _Add_e1b7452d2644ef8e96d652df6def6989_Out_2, _Divide_b34aaac0718e8682bb2ab66e45d42421_Out_2);
            float3 _Multiply_a97d25c025f47f8fa4cfe3267dee485e_Out_2;
            Unity_Multiply_float(IN.ObjectSpaceNormal, (_Divide_b34aaac0718e8682bb2ab66e45d42421_Out_2.xxx), _Multiply_a97d25c025f47f8fa4cfe3267dee485e_Out_2);
            float _Property_6f2976fe72816a869d8677a4230164f0_Out_0 = Vector1_E43D3892;
            float3 _Multiply_08ef8c8995ef448a9ab1e43028223a19_Out_2;
            Unity_Multiply_float(_Multiply_a97d25c025f47f8fa4cfe3267dee485e_Out_2, (_Property_6f2976fe72816a869d8677a4230164f0_Out_0.xxx), _Multiply_08ef8c8995ef448a9ab1e43028223a19_Out_2);
            float3 _Add_ec1431816c726e8a827bfd7e7de3d614_Out_2;
            Unity_Add_float3(IN.ObjectSpacePosition, _Multiply_08ef8c8995ef448a9ab1e43028223a19_Out_2, _Add_ec1431816c726e8a827bfd7e7de3d614_Out_2);
            float3 _Add_cbfa9591f076e485a31b7f5b967f99f6_Out_2;
            Unity_Add_float3(_Multiply_3fa32f2d7f56688684a8f5b0a0853be5_Out_2, _Add_ec1431816c726e8a827bfd7e7de3d614_Out_2, _Add_cbfa9591f076e485a31b7f5b967f99f6_Out_2);
            description.Position = _Add_cbfa9591f076e485a31b7f5b967f99f6_Out_2;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }

            // Graph Pixel
            struct SurfaceDescription
        {
            float3 NormalTS;
            float Alpha;
        };

        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            float _SceneDepth_845bf60653d70482b562a739512eeda7_Out_1;
            Unity_SceneDepth_Eye_float(float4(IN.ScreenPosition.xy / IN.ScreenPosition.w, 0, 0), _SceneDepth_845bf60653d70482b562a739512eeda7_Out_1);
            float4 _ScreenPosition_b978995ebe1ba286935416b2a2d5cb85_Out_0 = IN.ScreenPosition;
            float _Split_c66584edb0487b8e8c2e107a89ed8e9f_R_1 = _ScreenPosition_b978995ebe1ba286935416b2a2d5cb85_Out_0[0];
            float _Split_c66584edb0487b8e8c2e107a89ed8e9f_G_2 = _ScreenPosition_b978995ebe1ba286935416b2a2d5cb85_Out_0[1];
            float _Split_c66584edb0487b8e8c2e107a89ed8e9f_B_3 = _ScreenPosition_b978995ebe1ba286935416b2a2d5cb85_Out_0[2];
            float _Split_c66584edb0487b8e8c2e107a89ed8e9f_A_4 = _ScreenPosition_b978995ebe1ba286935416b2a2d5cb85_Out_0[3];
            float _Subtract_39fffd64ebdafb84a6eb8e37e2faaa16_Out_2;
            Unity_Subtract_float(_Split_c66584edb0487b8e8c2e107a89ed8e9f_A_4, 1, _Subtract_39fffd64ebdafb84a6eb8e37e2faaa16_Out_2);
            float _Subtract_d8ff2e79b2fc8386b6172daebbe97366_Out_2;
            Unity_Subtract_float(_SceneDepth_845bf60653d70482b562a739512eeda7_Out_1, _Subtract_39fffd64ebdafb84a6eb8e37e2faaa16_Out_2, _Subtract_d8ff2e79b2fc8386b6172daebbe97366_Out_2);
            float _Property_0a2887e34569358bbc9cbee1a14acebb_Out_0 = Vector1_EED1A887;
            float _Divide_f3ff43869c02038db823cf0d91c23caf_Out_2;
            Unity_Divide_float(_Subtract_d8ff2e79b2fc8386b6172daebbe97366_Out_2, _Property_0a2887e34569358bbc9cbee1a14acebb_Out_0, _Divide_f3ff43869c02038db823cf0d91c23caf_Out_2);
            float _Saturate_676d84ccc0f0b88e9d1fdf263cfcf1d5_Out_1;
            Unity_Saturate_float(_Divide_f3ff43869c02038db823cf0d91c23caf_Out_2, _Saturate_676d84ccc0f0b88e9d1fdf263cfcf1d5_Out_1);
            float _Smoothstep_edf634d16c75cd829225bfca563f83fb_Out_3;
            Unity_Smoothstep_float(0, 1, _Saturate_676d84ccc0f0b88e9d1fdf263cfcf1d5_Out_1, _Smoothstep_edf634d16c75cd829225bfca563f83fb_Out_3);
            surface.NormalTS = IN.TangentSpaceNormal;
            surface.Alpha = _Smoothstep_edf634d16c75cd829225bfca563f83fb_Out_3;
            return surface;
        }

            // --------------------------------------------------
            // Build Graph Inputs

            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);

            output.ObjectSpaceNormal =           input.normalOS;
            output.WorldSpaceNormal =            TransformObjectToWorldNormal(input.normalOS);
            output.ObjectSpaceTangent =          input.tangentOS.xyz;
            output.ObjectSpacePosition =         input.positionOS;
            output.WorldSpacePosition =          TransformObjectToWorld(input.positionOS);
            output.TimeParameters =              _TimeParameters.xyz;

            return output;
        }
            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);



            output.TangentSpaceNormal =          float3(0.0f, 0.0f, 1.0f);


            output.WorldSpacePosition =          input.positionWS;
            output.ScreenPosition =              ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

            return output;
        }

            // --------------------------------------------------
            // Main

            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/DepthNormalsOnlyPass.hlsl"

            ENDHLSL
        }
        Pass
        {
            Name "Meta"
            Tags
            {
                "LightMode" = "Meta"
            }

            // Render State
            Cull Off

            // Debug
            // <None>

            // --------------------------------------------------
            // Pass

            HLSLPROGRAM

            // Pragmas
            #pragma target 4.5
        #pragma exclude_renderers gles gles3 glcore
        #pragma vertex vert
        #pragma fragment frag

            // DotsInstancingOptions: <None>
            // HybridV1InjectedBuiltinProperties: <None>

            // Keywords
            #pragma shader_feature _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            // GraphKeywords: <None>

            // Defines
            #define _SURFACE_TYPE_TRANSPARENT 1
            #define _NORMALMAP 1
            #define _NORMAL_DROPOFF_TS 1
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define ATTRIBUTES_NEED_TEXCOORD1
            #define ATTRIBUTES_NEED_TEXCOORD2
            #define VARYINGS_NEED_POSITION_WS
            #define VARYINGS_NEED_NORMAL_WS
            #define VARYINGS_NEED_VIEWDIRECTION_WS
            #define FEATURES_GRAPH_VERTEX
            /* WARNING: $splice Could not find named fragment 'PassInstancing' */
            #define SHADERPASS SHADERPASS_META
        #define REQUIRE_DEPTH_TEXTURE
            /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/MetaInput.hlsl"

            // --------------------------------------------------
            // Structs and Packing

            struct Attributes
        {
            float3 positionOS : POSITION;
            float3 normalOS : NORMAL;
            float4 tangentOS : TANGENT;
            float4 uv1 : TEXCOORD1;
            float4 uv2 : TEXCOORD2;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
            float4 positionCS : SV_POSITION;
            float3 positionWS;
            float3 normalWS;
            float3 viewDirectionWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
            float3 WorldSpaceNormal;
            float3 WorldSpaceViewDirection;
            float3 WorldSpacePosition;
            float4 ScreenPosition;
            float3 TimeParameters;
        };
        struct VertexDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 WorldSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 ObjectSpacePosition;
            float3 WorldSpacePosition;
            float3 TimeParameters;
        };
        struct PackedVaryings
        {
            float4 positionCS : SV_POSITION;
            float3 interp0 : TEXCOORD0;
            float3 interp1 : TEXCOORD1;
            float3 interp2 : TEXCOORD2;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };

            PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            output.interp2.xyz =  input.viewDirectionWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            output.viewDirectionWS = input.interp2.xyz;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }

            // --------------------------------------------------
            // Graph

            // Graph Properties
            CBUFFER_START(UnityPerMaterial)
        float4 Vector4_484BA326;
        float Vector1_8F075DBC;
        float Vector1_8AAD665C;
        float Vector1_E43D3892;
        float4 Vector4_1696EE66;
        float4 Color_2CFB5E2A;
        float4 Color_58195353;
        float Vector1_FADC0395;
        float Vector1_E505CA4B;
        float Vector1_4CE104D9;
        float Vector1_5536221E;
        float Vector1_9058DE8C;
        float Vector1_350643F1;
        float Vector1_2A80C598;
        float Vector1_A664731F;
        float Vector1_B4ED823D;
        float Vector1_2BA361A8;
        float Vector1_EED1A887;
        CBUFFER_END

        // Object and Global properties

            // Graph Functions
            
        void Unity_Distance_float3(float3 A, float3 B, out float Out)
        {
            Out = distance(A, B);
        }

        void Unity_Divide_float(float A, float B, out float Out)
        {
            Out = A / B;
        }

        void Unity_Power_float(float A, float B, out float Out)
        {
            Out = pow(A, B);
        }

        void Unity_Multiply_float(float3 A, float3 B, out float3 Out)
        {
            Out = A * B;
        }

        void Unity_Rotate_About_Axis_Degrees_float(float3 In, float3 Axis, float Rotation, out float3 Out)
        {
            Rotation = radians(Rotation);

            float s = sin(Rotation);
            float c = cos(Rotation);
            float one_minus_c = 1.0 - c;
            
            Axis = normalize(Axis);

            float3x3 rot_mat = { one_minus_c * Axis.x * Axis.x + c,            one_minus_c * Axis.x * Axis.y - Axis.z * s,     one_minus_c * Axis.z * Axis.x + Axis.y * s,
                                      one_minus_c * Axis.x * Axis.y + Axis.z * s,   one_minus_c * Axis.y * Axis.y + c,              one_minus_c * Axis.y * Axis.z - Axis.x * s,
                                      one_minus_c * Axis.z * Axis.x - Axis.y * s,   one_minus_c * Axis.y * Axis.z + Axis.x * s,     one_minus_c * Axis.z * Axis.z + c
                                    };

            Out = mul(rot_mat,  In);
        }

        void Unity_Multiply_float(float A, float B, out float Out)
        {
            Out = A * B;
        }

        void Unity_TilingAndOffset_float(float2 UV, float2 Tiling, float2 Offset, out float2 Out)
        {
            Out = UV * Tiling + Offset;
        }


        float2 Unity_GradientNoise_Dir_float(float2 p)
        {
            // Permutation and hashing used in webgl-nosie goo.gl/pX7HtC
            p = p % 289;
            // need full precision, otherwise half overflows when p > 1
            float x = float(34 * p.x + 1) * p.x % 289 + p.y;
            x = (34 * x + 1) * x % 289;
            x = frac(x / 41) * 2 - 1;
            return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
        }

        void Unity_GradientNoise_float(float2 UV, float Scale, out float Out)
        { 
            float2 p = UV * Scale;
            float2 ip = floor(p);
            float2 fp = frac(p);
            float d00 = dot(Unity_GradientNoise_Dir_float(ip), fp);
            float d01 = dot(Unity_GradientNoise_Dir_float(ip + float2(0, 1)), fp - float2(0, 1));
            float d10 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 0)), fp - float2(1, 0));
            float d11 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 1)), fp - float2(1, 1));
            fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
            Out = lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x) + 0.5;
        }

        void Unity_Add_float(float A, float B, out float Out)
        {
            Out = A + B;
        }

        void Unity_Saturate_float(float In, out float Out)
        {
            Out = saturate(In);
        }

        void Unity_Combine_float(float R, float G, float B, float A, out float4 RGBA, out float3 RGB, out float2 RG)
        {
            RGBA = float4(R, G, B, A);
            RGB = float3(R, G, B);
            RG = float2(R, G);
        }

        void Unity_Remap_float(float In, float2 InMinMax, float2 OutMinMax, out float Out)
        {
            Out = OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
        }

        void Unity_Absolute_float(float In, out float Out)
        {
            Out = abs(In);
        }

        void Unity_Smoothstep_float(float Edge1, float Edge2, float In, out float Out)
        {
            Out = smoothstep(Edge1, Edge2, In);
        }

        void Unity_Add_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A + B;
        }

        void Unity_Lerp_float4(float4 A, float4 B, float4 T, out float4 Out)
        {
            Out = lerp(A, B, T);
        }

        void Unity_FresnelEffect_float(float3 Normal, float3 ViewDir, float Power, out float Out)
        {
            Out = pow((1.0 - saturate(dot(normalize(Normal), normalize(ViewDir)))), Power);
        }

        void Unity_Add_float4(float4 A, float4 B, out float4 Out)
        {
            Out = A + B;
        }

        void Unity_Multiply_float(float4 A, float4 B, out float4 Out)
        {
            Out = A * B;
        }

        void Unity_SceneDepth_Eye_float(float4 UV, out float Out)
        {
            Out = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH(UV.xy), _ZBufferParams);
        }

        void Unity_Subtract_float(float A, float B, out float Out)
        {
            Out = A - B;
        }

            // Graph Vertex
            struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };

        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            float _Distance_474c9e8e982c878dad2f0d5844b22ee9_Out_2;
            Unity_Distance_float3(SHADERGRAPH_OBJECT_POSITION, IN.WorldSpacePosition, _Distance_474c9e8e982c878dad2f0d5844b22ee9_Out_2);
            float _Property_95b6af28bf5d388fb7809e99d4ea7a10_Out_0 = Vector1_A664731F;
            float _Divide_2022c703e9e6de87965706bd214b7b67_Out_2;
            Unity_Divide_float(_Distance_474c9e8e982c878dad2f0d5844b22ee9_Out_2, _Property_95b6af28bf5d388fb7809e99d4ea7a10_Out_0, _Divide_2022c703e9e6de87965706bd214b7b67_Out_2);
            float _Power_8710b3fb1efe3183a2818b946e662a1e_Out_2;
            Unity_Power_float(_Divide_2022c703e9e6de87965706bd214b7b67_Out_2, 3, _Power_8710b3fb1efe3183a2818b946e662a1e_Out_2);
            float3 _Multiply_3fa32f2d7f56688684a8f5b0a0853be5_Out_2;
            Unity_Multiply_float(IN.WorldSpaceNormal, (_Power_8710b3fb1efe3183a2818b946e662a1e_Out_2.xxx), _Multiply_3fa32f2d7f56688684a8f5b0a0853be5_Out_2);
            float _Property_45fc02a5c65e898c82a51138ee7894c8_Out_0 = Vector1_FADC0395;
            float _Property_423be2625737e5829e3daa7b3cf8389d_Out_0 = Vector1_E505CA4B;
            float4 _Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0 = Vector4_484BA326;
            float _Split_e9324c176bf05a809ea8df8c413a826a_R_1 = _Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0[0];
            float _Split_e9324c176bf05a809ea8df8c413a826a_G_2 = _Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0[1];
            float _Split_e9324c176bf05a809ea8df8c413a826a_B_3 = _Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0[2];
            float _Split_e9324c176bf05a809ea8df8c413a826a_A_4 = _Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0[3];
            float3 _RotateAboutAxis_430e3c523bf85e84bdef451ab28beba0_Out_3;
            Unity_Rotate_About_Axis_Degrees_float(IN.WorldSpacePosition, (_Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0.xyz), _Split_e9324c176bf05a809ea8df8c413a826a_A_4, _RotateAboutAxis_430e3c523bf85e84bdef451ab28beba0_Out_3);
            float _Property_84dca49c8958708fac3276b0de15a6da_Out_0 = Vector1_8AAD665C;
            float _Multiply_89f92af49e152081ba549c92ab002e9c_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_84dca49c8958708fac3276b0de15a6da_Out_0, _Multiply_89f92af49e152081ba549c92ab002e9c_Out_2);
            float2 _TilingAndOffset_bd9fc632c3a6c185b226f93212ed8603_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_430e3c523bf85e84bdef451ab28beba0_Out_3.xy), float2 (1, 1), (_Multiply_89f92af49e152081ba549c92ab002e9c_Out_2.xx), _TilingAndOffset_bd9fc632c3a6c185b226f93212ed8603_Out_3);
            float _Property_f7111fce9be08b8c871514ffc219f648_Out_0 = Vector1_8F075DBC;
            float _GradientNoise_de42ec7fdd52ec8fa0b6cb7f34842c13_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_bd9fc632c3a6c185b226f93212ed8603_Out_3, _Property_f7111fce9be08b8c871514ffc219f648_Out_0, _GradientNoise_de42ec7fdd52ec8fa0b6cb7f34842c13_Out_2);
            float2 _TilingAndOffset_aa88c06674f4178889e657a2bb46c454_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_430e3c523bf85e84bdef451ab28beba0_Out_3.xy), float2 (1, 1), float2 (0, 0), _TilingAndOffset_aa88c06674f4178889e657a2bb46c454_Out_3);
            float _GradientNoise_28996fa0f6fbd08c97ed18d0621900b5_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_aa88c06674f4178889e657a2bb46c454_Out_3, _Property_f7111fce9be08b8c871514ffc219f648_Out_0, _GradientNoise_28996fa0f6fbd08c97ed18d0621900b5_Out_2);
            float _Add_caf5f972abacae878d9a6fde10e0986a_Out_2;
            Unity_Add_float(_GradientNoise_de42ec7fdd52ec8fa0b6cb7f34842c13_Out_2, _GradientNoise_28996fa0f6fbd08c97ed18d0621900b5_Out_2, _Add_caf5f972abacae878d9a6fde10e0986a_Out_2);
            float _Divide_27ef561e54cd208ca89512269c1d4d03_Out_2;
            Unity_Divide_float(_Add_caf5f972abacae878d9a6fde10e0986a_Out_2, 2, _Divide_27ef561e54cd208ca89512269c1d4d03_Out_2);
            float _Saturate_c56694103011198486afa78b0e89ec2c_Out_1;
            Unity_Saturate_float(_Divide_27ef561e54cd208ca89512269c1d4d03_Out_2, _Saturate_c56694103011198486afa78b0e89ec2c_Out_1);
            float _Property_8bd1d491d3050588a0b837b4b232170d_Out_0 = Vector1_4CE104D9;
            float _Power_abb6d235206009809ee431a98f2c8247_Out_2;
            Unity_Power_float(_Saturate_c56694103011198486afa78b0e89ec2c_Out_1, _Property_8bd1d491d3050588a0b837b4b232170d_Out_0, _Power_abb6d235206009809ee431a98f2c8247_Out_2);
            float4 _Property_8a81e8a6d963f384bddf6e75ec8e0a1c_Out_0 = Vector4_1696EE66;
            float _Split_f72e1ad87d56df8ba34ec31e2bc432b8_R_1 = _Property_8a81e8a6d963f384bddf6e75ec8e0a1c_Out_0[0];
            float _Split_f72e1ad87d56df8ba34ec31e2bc432b8_G_2 = _Property_8a81e8a6d963f384bddf6e75ec8e0a1c_Out_0[1];
            float _Split_f72e1ad87d56df8ba34ec31e2bc432b8_B_3 = _Property_8a81e8a6d963f384bddf6e75ec8e0a1c_Out_0[2];
            float _Split_f72e1ad87d56df8ba34ec31e2bc432b8_A_4 = _Property_8a81e8a6d963f384bddf6e75ec8e0a1c_Out_0[3];
            float4 _Combine_aeef4bbea8acc688b198e488208172f2_RGBA_4;
            float3 _Combine_aeef4bbea8acc688b198e488208172f2_RGB_5;
            float2 _Combine_aeef4bbea8acc688b198e488208172f2_RG_6;
            Unity_Combine_float(_Split_f72e1ad87d56df8ba34ec31e2bc432b8_R_1, _Split_f72e1ad87d56df8ba34ec31e2bc432b8_G_2, 0, 0, _Combine_aeef4bbea8acc688b198e488208172f2_RGBA_4, _Combine_aeef4bbea8acc688b198e488208172f2_RGB_5, _Combine_aeef4bbea8acc688b198e488208172f2_RG_6);
            float4 _Combine_feabe866dc39388d8ccd72275fb9be09_RGBA_4;
            float3 _Combine_feabe866dc39388d8ccd72275fb9be09_RGB_5;
            float2 _Combine_feabe866dc39388d8ccd72275fb9be09_RG_6;
            Unity_Combine_float(_Split_f72e1ad87d56df8ba34ec31e2bc432b8_B_3, _Split_f72e1ad87d56df8ba34ec31e2bc432b8_A_4, 0, 0, _Combine_feabe866dc39388d8ccd72275fb9be09_RGBA_4, _Combine_feabe866dc39388d8ccd72275fb9be09_RGB_5, _Combine_feabe866dc39388d8ccd72275fb9be09_RG_6);
            float _Remap_ca18d3412979f985809f3426d5282816_Out_3;
            Unity_Remap_float(_Power_abb6d235206009809ee431a98f2c8247_Out_2, _Combine_aeef4bbea8acc688b198e488208172f2_RG_6, _Combine_feabe866dc39388d8ccd72275fb9be09_RG_6, _Remap_ca18d3412979f985809f3426d5282816_Out_3);
            float _Absolute_01d69efb5b6b628b8142004f10302240_Out_1;
            Unity_Absolute_float(_Remap_ca18d3412979f985809f3426d5282816_Out_3, _Absolute_01d69efb5b6b628b8142004f10302240_Out_1);
            float _Smoothstep_5a0282a38f27848e9545f1e89a11f5a2_Out_3;
            Unity_Smoothstep_float(_Property_45fc02a5c65e898c82a51138ee7894c8_Out_0, _Property_423be2625737e5829e3daa7b3cf8389d_Out_0, _Absolute_01d69efb5b6b628b8142004f10302240_Out_1, _Smoothstep_5a0282a38f27848e9545f1e89a11f5a2_Out_3);
            float _Property_91482984669b1c8ab26a0f4a555b3801_Out_0 = Vector1_9058DE8C;
            float _Multiply_ad5811e4c08fae88a363e144af359987_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_91482984669b1c8ab26a0f4a555b3801_Out_0, _Multiply_ad5811e4c08fae88a363e144af359987_Out_2);
            float2 _TilingAndOffset_2345314be014258796bc32f9e66d2397_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_430e3c523bf85e84bdef451ab28beba0_Out_3.xy), float2 (1, 1), (_Multiply_ad5811e4c08fae88a363e144af359987_Out_2.xx), _TilingAndOffset_2345314be014258796bc32f9e66d2397_Out_3);
            float _Property_a13e388a84b18e89afce2f9f3ca9753f_Out_0 = Vector1_5536221E;
            float _GradientNoise_9f2e5d10ed34688f87f30e9a171b1f8b_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_2345314be014258796bc32f9e66d2397_Out_3, _Property_a13e388a84b18e89afce2f9f3ca9753f_Out_0, _GradientNoise_9f2e5d10ed34688f87f30e9a171b1f8b_Out_2);
            float _Property_b64fda08fa35398f9e0f45e316a434f9_Out_0 = Vector1_350643F1;
            float _Multiply_d03d0c5bc6770f8b8fbb46ec0c06b35b_Out_2;
            Unity_Multiply_float(_GradientNoise_9f2e5d10ed34688f87f30e9a171b1f8b_Out_2, _Property_b64fda08fa35398f9e0f45e316a434f9_Out_0, _Multiply_d03d0c5bc6770f8b8fbb46ec0c06b35b_Out_2);
            float _Add_f031b6931be259898e2d889c851d36d5_Out_2;
            Unity_Add_float(_Smoothstep_5a0282a38f27848e9545f1e89a11f5a2_Out_3, _Multiply_d03d0c5bc6770f8b8fbb46ec0c06b35b_Out_2, _Add_f031b6931be259898e2d889c851d36d5_Out_2);
            float _Add_e1b7452d2644ef8e96d652df6def6989_Out_2;
            Unity_Add_float(1, _Property_b64fda08fa35398f9e0f45e316a434f9_Out_0, _Add_e1b7452d2644ef8e96d652df6def6989_Out_2);
            float _Divide_b34aaac0718e8682bb2ab66e45d42421_Out_2;
            Unity_Divide_float(_Add_f031b6931be259898e2d889c851d36d5_Out_2, _Add_e1b7452d2644ef8e96d652df6def6989_Out_2, _Divide_b34aaac0718e8682bb2ab66e45d42421_Out_2);
            float3 _Multiply_a97d25c025f47f8fa4cfe3267dee485e_Out_2;
            Unity_Multiply_float(IN.ObjectSpaceNormal, (_Divide_b34aaac0718e8682bb2ab66e45d42421_Out_2.xxx), _Multiply_a97d25c025f47f8fa4cfe3267dee485e_Out_2);
            float _Property_6f2976fe72816a869d8677a4230164f0_Out_0 = Vector1_E43D3892;
            float3 _Multiply_08ef8c8995ef448a9ab1e43028223a19_Out_2;
            Unity_Multiply_float(_Multiply_a97d25c025f47f8fa4cfe3267dee485e_Out_2, (_Property_6f2976fe72816a869d8677a4230164f0_Out_0.xxx), _Multiply_08ef8c8995ef448a9ab1e43028223a19_Out_2);
            float3 _Add_ec1431816c726e8a827bfd7e7de3d614_Out_2;
            Unity_Add_float3(IN.ObjectSpacePosition, _Multiply_08ef8c8995ef448a9ab1e43028223a19_Out_2, _Add_ec1431816c726e8a827bfd7e7de3d614_Out_2);
            float3 _Add_cbfa9591f076e485a31b7f5b967f99f6_Out_2;
            Unity_Add_float3(_Multiply_3fa32f2d7f56688684a8f5b0a0853be5_Out_2, _Add_ec1431816c726e8a827bfd7e7de3d614_Out_2, _Add_cbfa9591f076e485a31b7f5b967f99f6_Out_2);
            description.Position = _Add_cbfa9591f076e485a31b7f5b967f99f6_Out_2;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }

            // Graph Pixel
            struct SurfaceDescription
        {
            float3 BaseColor;
            float3 Emission;
            float Alpha;
        };

        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            float4 _Property_8602b260fe5c06829b7738349464dbbc_Out_0 = Color_58195353;
            float4 _Property_db73cd07c4394c82a6cd028523c127f3_Out_0 = Color_2CFB5E2A;
            float _Property_45fc02a5c65e898c82a51138ee7894c8_Out_0 = Vector1_FADC0395;
            float _Property_423be2625737e5829e3daa7b3cf8389d_Out_0 = Vector1_E505CA4B;
            float4 _Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0 = Vector4_484BA326;
            float _Split_e9324c176bf05a809ea8df8c413a826a_R_1 = _Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0[0];
            float _Split_e9324c176bf05a809ea8df8c413a826a_G_2 = _Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0[1];
            float _Split_e9324c176bf05a809ea8df8c413a826a_B_3 = _Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0[2];
            float _Split_e9324c176bf05a809ea8df8c413a826a_A_4 = _Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0[3];
            float3 _RotateAboutAxis_430e3c523bf85e84bdef451ab28beba0_Out_3;
            Unity_Rotate_About_Axis_Degrees_float(IN.WorldSpacePosition, (_Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0.xyz), _Split_e9324c176bf05a809ea8df8c413a826a_A_4, _RotateAboutAxis_430e3c523bf85e84bdef451ab28beba0_Out_3);
            float _Property_84dca49c8958708fac3276b0de15a6da_Out_0 = Vector1_8AAD665C;
            float _Multiply_89f92af49e152081ba549c92ab002e9c_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_84dca49c8958708fac3276b0de15a6da_Out_0, _Multiply_89f92af49e152081ba549c92ab002e9c_Out_2);
            float2 _TilingAndOffset_bd9fc632c3a6c185b226f93212ed8603_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_430e3c523bf85e84bdef451ab28beba0_Out_3.xy), float2 (1, 1), (_Multiply_89f92af49e152081ba549c92ab002e9c_Out_2.xx), _TilingAndOffset_bd9fc632c3a6c185b226f93212ed8603_Out_3);
            float _Property_f7111fce9be08b8c871514ffc219f648_Out_0 = Vector1_8F075DBC;
            float _GradientNoise_de42ec7fdd52ec8fa0b6cb7f34842c13_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_bd9fc632c3a6c185b226f93212ed8603_Out_3, _Property_f7111fce9be08b8c871514ffc219f648_Out_0, _GradientNoise_de42ec7fdd52ec8fa0b6cb7f34842c13_Out_2);
            float2 _TilingAndOffset_aa88c06674f4178889e657a2bb46c454_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_430e3c523bf85e84bdef451ab28beba0_Out_3.xy), float2 (1, 1), float2 (0, 0), _TilingAndOffset_aa88c06674f4178889e657a2bb46c454_Out_3);
            float _GradientNoise_28996fa0f6fbd08c97ed18d0621900b5_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_aa88c06674f4178889e657a2bb46c454_Out_3, _Property_f7111fce9be08b8c871514ffc219f648_Out_0, _GradientNoise_28996fa0f6fbd08c97ed18d0621900b5_Out_2);
            float _Add_caf5f972abacae878d9a6fde10e0986a_Out_2;
            Unity_Add_float(_GradientNoise_de42ec7fdd52ec8fa0b6cb7f34842c13_Out_2, _GradientNoise_28996fa0f6fbd08c97ed18d0621900b5_Out_2, _Add_caf5f972abacae878d9a6fde10e0986a_Out_2);
            float _Divide_27ef561e54cd208ca89512269c1d4d03_Out_2;
            Unity_Divide_float(_Add_caf5f972abacae878d9a6fde10e0986a_Out_2, 2, _Divide_27ef561e54cd208ca89512269c1d4d03_Out_2);
            float _Saturate_c56694103011198486afa78b0e89ec2c_Out_1;
            Unity_Saturate_float(_Divide_27ef561e54cd208ca89512269c1d4d03_Out_2, _Saturate_c56694103011198486afa78b0e89ec2c_Out_1);
            float _Property_8bd1d491d3050588a0b837b4b232170d_Out_0 = Vector1_4CE104D9;
            float _Power_abb6d235206009809ee431a98f2c8247_Out_2;
            Unity_Power_float(_Saturate_c56694103011198486afa78b0e89ec2c_Out_1, _Property_8bd1d491d3050588a0b837b4b232170d_Out_0, _Power_abb6d235206009809ee431a98f2c8247_Out_2);
            float4 _Property_8a81e8a6d963f384bddf6e75ec8e0a1c_Out_0 = Vector4_1696EE66;
            float _Split_f72e1ad87d56df8ba34ec31e2bc432b8_R_1 = _Property_8a81e8a6d963f384bddf6e75ec8e0a1c_Out_0[0];
            float _Split_f72e1ad87d56df8ba34ec31e2bc432b8_G_2 = _Property_8a81e8a6d963f384bddf6e75ec8e0a1c_Out_0[1];
            float _Split_f72e1ad87d56df8ba34ec31e2bc432b8_B_3 = _Property_8a81e8a6d963f384bddf6e75ec8e0a1c_Out_0[2];
            float _Split_f72e1ad87d56df8ba34ec31e2bc432b8_A_4 = _Property_8a81e8a6d963f384bddf6e75ec8e0a1c_Out_0[3];
            float4 _Combine_aeef4bbea8acc688b198e488208172f2_RGBA_4;
            float3 _Combine_aeef4bbea8acc688b198e488208172f2_RGB_5;
            float2 _Combine_aeef4bbea8acc688b198e488208172f2_RG_6;
            Unity_Combine_float(_Split_f72e1ad87d56df8ba34ec31e2bc432b8_R_1, _Split_f72e1ad87d56df8ba34ec31e2bc432b8_G_2, 0, 0, _Combine_aeef4bbea8acc688b198e488208172f2_RGBA_4, _Combine_aeef4bbea8acc688b198e488208172f2_RGB_5, _Combine_aeef4bbea8acc688b198e488208172f2_RG_6);
            float4 _Combine_feabe866dc39388d8ccd72275fb9be09_RGBA_4;
            float3 _Combine_feabe866dc39388d8ccd72275fb9be09_RGB_5;
            float2 _Combine_feabe866dc39388d8ccd72275fb9be09_RG_6;
            Unity_Combine_float(_Split_f72e1ad87d56df8ba34ec31e2bc432b8_B_3, _Split_f72e1ad87d56df8ba34ec31e2bc432b8_A_4, 0, 0, _Combine_feabe866dc39388d8ccd72275fb9be09_RGBA_4, _Combine_feabe866dc39388d8ccd72275fb9be09_RGB_5, _Combine_feabe866dc39388d8ccd72275fb9be09_RG_6);
            float _Remap_ca18d3412979f985809f3426d5282816_Out_3;
            Unity_Remap_float(_Power_abb6d235206009809ee431a98f2c8247_Out_2, _Combine_aeef4bbea8acc688b198e488208172f2_RG_6, _Combine_feabe866dc39388d8ccd72275fb9be09_RG_6, _Remap_ca18d3412979f985809f3426d5282816_Out_3);
            float _Absolute_01d69efb5b6b628b8142004f10302240_Out_1;
            Unity_Absolute_float(_Remap_ca18d3412979f985809f3426d5282816_Out_3, _Absolute_01d69efb5b6b628b8142004f10302240_Out_1);
            float _Smoothstep_5a0282a38f27848e9545f1e89a11f5a2_Out_3;
            Unity_Smoothstep_float(_Property_45fc02a5c65e898c82a51138ee7894c8_Out_0, _Property_423be2625737e5829e3daa7b3cf8389d_Out_0, _Absolute_01d69efb5b6b628b8142004f10302240_Out_1, _Smoothstep_5a0282a38f27848e9545f1e89a11f5a2_Out_3);
            float _Property_91482984669b1c8ab26a0f4a555b3801_Out_0 = Vector1_9058DE8C;
            float _Multiply_ad5811e4c08fae88a363e144af359987_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_91482984669b1c8ab26a0f4a555b3801_Out_0, _Multiply_ad5811e4c08fae88a363e144af359987_Out_2);
            float2 _TilingAndOffset_2345314be014258796bc32f9e66d2397_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_430e3c523bf85e84bdef451ab28beba0_Out_3.xy), float2 (1, 1), (_Multiply_ad5811e4c08fae88a363e144af359987_Out_2.xx), _TilingAndOffset_2345314be014258796bc32f9e66d2397_Out_3);
            float _Property_a13e388a84b18e89afce2f9f3ca9753f_Out_0 = Vector1_5536221E;
            float _GradientNoise_9f2e5d10ed34688f87f30e9a171b1f8b_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_2345314be014258796bc32f9e66d2397_Out_3, _Property_a13e388a84b18e89afce2f9f3ca9753f_Out_0, _GradientNoise_9f2e5d10ed34688f87f30e9a171b1f8b_Out_2);
            float _Property_b64fda08fa35398f9e0f45e316a434f9_Out_0 = Vector1_350643F1;
            float _Multiply_d03d0c5bc6770f8b8fbb46ec0c06b35b_Out_2;
            Unity_Multiply_float(_GradientNoise_9f2e5d10ed34688f87f30e9a171b1f8b_Out_2, _Property_b64fda08fa35398f9e0f45e316a434f9_Out_0, _Multiply_d03d0c5bc6770f8b8fbb46ec0c06b35b_Out_2);
            float _Add_f031b6931be259898e2d889c851d36d5_Out_2;
            Unity_Add_float(_Smoothstep_5a0282a38f27848e9545f1e89a11f5a2_Out_3, _Multiply_d03d0c5bc6770f8b8fbb46ec0c06b35b_Out_2, _Add_f031b6931be259898e2d889c851d36d5_Out_2);
            float _Add_e1b7452d2644ef8e96d652df6def6989_Out_2;
            Unity_Add_float(1, _Property_b64fda08fa35398f9e0f45e316a434f9_Out_0, _Add_e1b7452d2644ef8e96d652df6def6989_Out_2);
            float _Divide_b34aaac0718e8682bb2ab66e45d42421_Out_2;
            Unity_Divide_float(_Add_f031b6931be259898e2d889c851d36d5_Out_2, _Add_e1b7452d2644ef8e96d652df6def6989_Out_2, _Divide_b34aaac0718e8682bb2ab66e45d42421_Out_2);
            float4 _Lerp_0f05ab7309374f869f26c5de63c7685d_Out_3;
            Unity_Lerp_float4(_Property_8602b260fe5c06829b7738349464dbbc_Out_0, _Property_db73cd07c4394c82a6cd028523c127f3_Out_0, (_Divide_b34aaac0718e8682bb2ab66e45d42421_Out_2.xxxx), _Lerp_0f05ab7309374f869f26c5de63c7685d_Out_3);
            float _Property_0e672fb430de1988a91ebab3a6c55a4b_Out_0 = Vector1_B4ED823D;
            float _FresnelEffect_d3463b04b6387381ae221b6b9fda5a55_Out_3;
            Unity_FresnelEffect_float(IN.WorldSpaceNormal, IN.WorldSpaceViewDirection, _Property_0e672fb430de1988a91ebab3a6c55a4b_Out_0, _FresnelEffect_d3463b04b6387381ae221b6b9fda5a55_Out_3);
            float _Multiply_b1b397b5458b168183311fa585ce24cc_Out_2;
            Unity_Multiply_float(_Divide_b34aaac0718e8682bb2ab66e45d42421_Out_2, _FresnelEffect_d3463b04b6387381ae221b6b9fda5a55_Out_3, _Multiply_b1b397b5458b168183311fa585ce24cc_Out_2);
            float _Property_a0d7e69c6b484186aed4c837b9cfdf60_Out_0 = Vector1_2BA361A8;
            float _Multiply_c527b7ae93e59a82a8b685490472d140_Out_2;
            Unity_Multiply_float(_Multiply_b1b397b5458b168183311fa585ce24cc_Out_2, _Property_a0d7e69c6b484186aed4c837b9cfdf60_Out_0, _Multiply_c527b7ae93e59a82a8b685490472d140_Out_2);
            float4 _Add_e90a39812292588185bb8af6f98ac6ed_Out_2;
            Unity_Add_float4(_Lerp_0f05ab7309374f869f26c5de63c7685d_Out_3, (_Multiply_c527b7ae93e59a82a8b685490472d140_Out_2.xxxx), _Add_e90a39812292588185bb8af6f98ac6ed_Out_2);
            float _Property_2b5ded79d5faa287bcd134d3931fddbd_Out_0 = Vector1_2A80C598;
            float4 _Multiply_89abd19f1abd878f9e4e10491d20220d_Out_2;
            Unity_Multiply_float(_Add_e90a39812292588185bb8af6f98ac6ed_Out_2, (_Property_2b5ded79d5faa287bcd134d3931fddbd_Out_0.xxxx), _Multiply_89abd19f1abd878f9e4e10491d20220d_Out_2);
            float _SceneDepth_845bf60653d70482b562a739512eeda7_Out_1;
            Unity_SceneDepth_Eye_float(float4(IN.ScreenPosition.xy / IN.ScreenPosition.w, 0, 0), _SceneDepth_845bf60653d70482b562a739512eeda7_Out_1);
            float4 _ScreenPosition_b978995ebe1ba286935416b2a2d5cb85_Out_0 = IN.ScreenPosition;
            float _Split_c66584edb0487b8e8c2e107a89ed8e9f_R_1 = _ScreenPosition_b978995ebe1ba286935416b2a2d5cb85_Out_0[0];
            float _Split_c66584edb0487b8e8c2e107a89ed8e9f_G_2 = _ScreenPosition_b978995ebe1ba286935416b2a2d5cb85_Out_0[1];
            float _Split_c66584edb0487b8e8c2e107a89ed8e9f_B_3 = _ScreenPosition_b978995ebe1ba286935416b2a2d5cb85_Out_0[2];
            float _Split_c66584edb0487b8e8c2e107a89ed8e9f_A_4 = _ScreenPosition_b978995ebe1ba286935416b2a2d5cb85_Out_0[3];
            float _Subtract_39fffd64ebdafb84a6eb8e37e2faaa16_Out_2;
            Unity_Subtract_float(_Split_c66584edb0487b8e8c2e107a89ed8e9f_A_4, 1, _Subtract_39fffd64ebdafb84a6eb8e37e2faaa16_Out_2);
            float _Subtract_d8ff2e79b2fc8386b6172daebbe97366_Out_2;
            Unity_Subtract_float(_SceneDepth_845bf60653d70482b562a739512eeda7_Out_1, _Subtract_39fffd64ebdafb84a6eb8e37e2faaa16_Out_2, _Subtract_d8ff2e79b2fc8386b6172daebbe97366_Out_2);
            float _Property_0a2887e34569358bbc9cbee1a14acebb_Out_0 = Vector1_EED1A887;
            float _Divide_f3ff43869c02038db823cf0d91c23caf_Out_2;
            Unity_Divide_float(_Subtract_d8ff2e79b2fc8386b6172daebbe97366_Out_2, _Property_0a2887e34569358bbc9cbee1a14acebb_Out_0, _Divide_f3ff43869c02038db823cf0d91c23caf_Out_2);
            float _Saturate_676d84ccc0f0b88e9d1fdf263cfcf1d5_Out_1;
            Unity_Saturate_float(_Divide_f3ff43869c02038db823cf0d91c23caf_Out_2, _Saturate_676d84ccc0f0b88e9d1fdf263cfcf1d5_Out_1);
            float _Smoothstep_edf634d16c75cd829225bfca563f83fb_Out_3;
            Unity_Smoothstep_float(0, 1, _Saturate_676d84ccc0f0b88e9d1fdf263cfcf1d5_Out_1, _Smoothstep_edf634d16c75cd829225bfca563f83fb_Out_3);
            surface.BaseColor = IsGammaSpace() ? float3(0, 0, 0) : SRGBToLinear(float3(0, 0, 0));
            surface.Emission = (_Multiply_89abd19f1abd878f9e4e10491d20220d_Out_2.xyz);
            surface.Alpha = _Smoothstep_edf634d16c75cd829225bfca563f83fb_Out_3;
            return surface;
        }

            // --------------------------------------------------
            // Build Graph Inputs

            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);

            output.ObjectSpaceNormal =           input.normalOS;
            output.WorldSpaceNormal =            TransformObjectToWorldNormal(input.normalOS);
            output.ObjectSpaceTangent =          input.tangentOS.xyz;
            output.ObjectSpacePosition =         input.positionOS;
            output.WorldSpacePosition =          TransformObjectToWorld(input.positionOS);
            output.TimeParameters =              _TimeParameters.xyz;

            return output;
        }
            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);

        	// must use interpolated tangent, bitangent and normal before they are normalized in the pixel shader.
        	float3 unnormalizedNormalWS = input.normalWS;
            const float renormFactor = 1.0 / length(unnormalizedNormalWS);


            output.WorldSpaceNormal =            renormFactor*input.normalWS.xyz;		// we want a unit length Normal Vector node in shader graph


            output.WorldSpaceViewDirection =     input.viewDirectionWS; //TODO: by default normalized in HD, but not in universal
            output.WorldSpacePosition =          input.positionWS;
            output.ScreenPosition =              ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
            output.TimeParameters =              _TimeParameters.xyz; // This is mainly for LW as HD overwrite this value
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

            return output;
        }

            // --------------------------------------------------
            // Main

            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/LightingMetaPass.hlsl"

            ENDHLSL
        }
        Pass
        {
            // Name: <None>
            Tags
            {
                "LightMode" = "Universal2D"
            }

            // Render State
            Cull Back
        Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
        ZTest LEqual
        ZWrite Off

            // Debug
            // <None>

            // --------------------------------------------------
            // Pass

            HLSLPROGRAM

            // Pragmas
            #pragma target 4.5
        #pragma exclude_renderers gles gles3 glcore
        #pragma vertex vert
        #pragma fragment frag

            // DotsInstancingOptions: <None>
            // HybridV1InjectedBuiltinProperties: <None>

            // Keywords
            // PassKeywords: <None>
            // GraphKeywords: <None>

            // Defines
            #define _SURFACE_TYPE_TRANSPARENT 1
            #define _NORMALMAP 1
            #define _NORMAL_DROPOFF_TS 1
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define VARYINGS_NEED_POSITION_WS
            #define FEATURES_GRAPH_VERTEX
            /* WARNING: $splice Could not find named fragment 'PassInstancing' */
            #define SHADERPASS SHADERPASS_2D
        #define REQUIRE_DEPTH_TEXTURE
            /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

            // --------------------------------------------------
            // Structs and Packing

            struct Attributes
        {
            float3 positionOS : POSITION;
            float3 normalOS : NORMAL;
            float4 tangentOS : TANGENT;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
            float4 positionCS : SV_POSITION;
            float3 positionWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
            float3 WorldSpacePosition;
            float4 ScreenPosition;
        };
        struct VertexDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 WorldSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 ObjectSpacePosition;
            float3 WorldSpacePosition;
            float3 TimeParameters;
        };
        struct PackedVaryings
        {
            float4 positionCS : SV_POSITION;
            float3 interp0 : TEXCOORD0;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };

            PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }

            // --------------------------------------------------
            // Graph

            // Graph Properties
            CBUFFER_START(UnityPerMaterial)
        float4 Vector4_484BA326;
        float Vector1_8F075DBC;
        float Vector1_8AAD665C;
        float Vector1_E43D3892;
        float4 Vector4_1696EE66;
        float4 Color_2CFB5E2A;
        float4 Color_58195353;
        float Vector1_FADC0395;
        float Vector1_E505CA4B;
        float Vector1_4CE104D9;
        float Vector1_5536221E;
        float Vector1_9058DE8C;
        float Vector1_350643F1;
        float Vector1_2A80C598;
        float Vector1_A664731F;
        float Vector1_B4ED823D;
        float Vector1_2BA361A8;
        float Vector1_EED1A887;
        CBUFFER_END

        // Object and Global properties

            // Graph Functions
            
        void Unity_Distance_float3(float3 A, float3 B, out float Out)
        {
            Out = distance(A, B);
        }

        void Unity_Divide_float(float A, float B, out float Out)
        {
            Out = A / B;
        }

        void Unity_Power_float(float A, float B, out float Out)
        {
            Out = pow(A, B);
        }

        void Unity_Multiply_float(float3 A, float3 B, out float3 Out)
        {
            Out = A * B;
        }

        void Unity_Rotate_About_Axis_Degrees_float(float3 In, float3 Axis, float Rotation, out float3 Out)
        {
            Rotation = radians(Rotation);

            float s = sin(Rotation);
            float c = cos(Rotation);
            float one_minus_c = 1.0 - c;
            
            Axis = normalize(Axis);

            float3x3 rot_mat = { one_minus_c * Axis.x * Axis.x + c,            one_minus_c * Axis.x * Axis.y - Axis.z * s,     one_minus_c * Axis.z * Axis.x + Axis.y * s,
                                      one_minus_c * Axis.x * Axis.y + Axis.z * s,   one_minus_c * Axis.y * Axis.y + c,              one_minus_c * Axis.y * Axis.z - Axis.x * s,
                                      one_minus_c * Axis.z * Axis.x - Axis.y * s,   one_minus_c * Axis.y * Axis.z + Axis.x * s,     one_minus_c * Axis.z * Axis.z + c
                                    };

            Out = mul(rot_mat,  In);
        }

        void Unity_Multiply_float(float A, float B, out float Out)
        {
            Out = A * B;
        }

        void Unity_TilingAndOffset_float(float2 UV, float2 Tiling, float2 Offset, out float2 Out)
        {
            Out = UV * Tiling + Offset;
        }


        float2 Unity_GradientNoise_Dir_float(float2 p)
        {
            // Permutation and hashing used in webgl-nosie goo.gl/pX7HtC
            p = p % 289;
            // need full precision, otherwise half overflows when p > 1
            float x = float(34 * p.x + 1) * p.x % 289 + p.y;
            x = (34 * x + 1) * x % 289;
            x = frac(x / 41) * 2 - 1;
            return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
        }

        void Unity_GradientNoise_float(float2 UV, float Scale, out float Out)
        { 
            float2 p = UV * Scale;
            float2 ip = floor(p);
            float2 fp = frac(p);
            float d00 = dot(Unity_GradientNoise_Dir_float(ip), fp);
            float d01 = dot(Unity_GradientNoise_Dir_float(ip + float2(0, 1)), fp - float2(0, 1));
            float d10 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 0)), fp - float2(1, 0));
            float d11 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 1)), fp - float2(1, 1));
            fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
            Out = lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x) + 0.5;
        }

        void Unity_Add_float(float A, float B, out float Out)
        {
            Out = A + B;
        }

        void Unity_Saturate_float(float In, out float Out)
        {
            Out = saturate(In);
        }

        void Unity_Combine_float(float R, float G, float B, float A, out float4 RGBA, out float3 RGB, out float2 RG)
        {
            RGBA = float4(R, G, B, A);
            RGB = float3(R, G, B);
            RG = float2(R, G);
        }

        void Unity_Remap_float(float In, float2 InMinMax, float2 OutMinMax, out float Out)
        {
            Out = OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
        }

        void Unity_Absolute_float(float In, out float Out)
        {
            Out = abs(In);
        }

        void Unity_Smoothstep_float(float Edge1, float Edge2, float In, out float Out)
        {
            Out = smoothstep(Edge1, Edge2, In);
        }

        void Unity_Add_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A + B;
        }

        void Unity_SceneDepth_Eye_float(float4 UV, out float Out)
        {
            Out = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH(UV.xy), _ZBufferParams);
        }

        void Unity_Subtract_float(float A, float B, out float Out)
        {
            Out = A - B;
        }

            // Graph Vertex
            struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };

        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            float _Distance_474c9e8e982c878dad2f0d5844b22ee9_Out_2;
            Unity_Distance_float3(SHADERGRAPH_OBJECT_POSITION, IN.WorldSpacePosition, _Distance_474c9e8e982c878dad2f0d5844b22ee9_Out_2);
            float _Property_95b6af28bf5d388fb7809e99d4ea7a10_Out_0 = Vector1_A664731F;
            float _Divide_2022c703e9e6de87965706bd214b7b67_Out_2;
            Unity_Divide_float(_Distance_474c9e8e982c878dad2f0d5844b22ee9_Out_2, _Property_95b6af28bf5d388fb7809e99d4ea7a10_Out_0, _Divide_2022c703e9e6de87965706bd214b7b67_Out_2);
            float _Power_8710b3fb1efe3183a2818b946e662a1e_Out_2;
            Unity_Power_float(_Divide_2022c703e9e6de87965706bd214b7b67_Out_2, 3, _Power_8710b3fb1efe3183a2818b946e662a1e_Out_2);
            float3 _Multiply_3fa32f2d7f56688684a8f5b0a0853be5_Out_2;
            Unity_Multiply_float(IN.WorldSpaceNormal, (_Power_8710b3fb1efe3183a2818b946e662a1e_Out_2.xxx), _Multiply_3fa32f2d7f56688684a8f5b0a0853be5_Out_2);
            float _Property_45fc02a5c65e898c82a51138ee7894c8_Out_0 = Vector1_FADC0395;
            float _Property_423be2625737e5829e3daa7b3cf8389d_Out_0 = Vector1_E505CA4B;
            float4 _Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0 = Vector4_484BA326;
            float _Split_e9324c176bf05a809ea8df8c413a826a_R_1 = _Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0[0];
            float _Split_e9324c176bf05a809ea8df8c413a826a_G_2 = _Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0[1];
            float _Split_e9324c176bf05a809ea8df8c413a826a_B_3 = _Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0[2];
            float _Split_e9324c176bf05a809ea8df8c413a826a_A_4 = _Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0[3];
            float3 _RotateAboutAxis_430e3c523bf85e84bdef451ab28beba0_Out_3;
            Unity_Rotate_About_Axis_Degrees_float(IN.WorldSpacePosition, (_Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0.xyz), _Split_e9324c176bf05a809ea8df8c413a826a_A_4, _RotateAboutAxis_430e3c523bf85e84bdef451ab28beba0_Out_3);
            float _Property_84dca49c8958708fac3276b0de15a6da_Out_0 = Vector1_8AAD665C;
            float _Multiply_89f92af49e152081ba549c92ab002e9c_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_84dca49c8958708fac3276b0de15a6da_Out_0, _Multiply_89f92af49e152081ba549c92ab002e9c_Out_2);
            float2 _TilingAndOffset_bd9fc632c3a6c185b226f93212ed8603_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_430e3c523bf85e84bdef451ab28beba0_Out_3.xy), float2 (1, 1), (_Multiply_89f92af49e152081ba549c92ab002e9c_Out_2.xx), _TilingAndOffset_bd9fc632c3a6c185b226f93212ed8603_Out_3);
            float _Property_f7111fce9be08b8c871514ffc219f648_Out_0 = Vector1_8F075DBC;
            float _GradientNoise_de42ec7fdd52ec8fa0b6cb7f34842c13_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_bd9fc632c3a6c185b226f93212ed8603_Out_3, _Property_f7111fce9be08b8c871514ffc219f648_Out_0, _GradientNoise_de42ec7fdd52ec8fa0b6cb7f34842c13_Out_2);
            float2 _TilingAndOffset_aa88c06674f4178889e657a2bb46c454_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_430e3c523bf85e84bdef451ab28beba0_Out_3.xy), float2 (1, 1), float2 (0, 0), _TilingAndOffset_aa88c06674f4178889e657a2bb46c454_Out_3);
            float _GradientNoise_28996fa0f6fbd08c97ed18d0621900b5_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_aa88c06674f4178889e657a2bb46c454_Out_3, _Property_f7111fce9be08b8c871514ffc219f648_Out_0, _GradientNoise_28996fa0f6fbd08c97ed18d0621900b5_Out_2);
            float _Add_caf5f972abacae878d9a6fde10e0986a_Out_2;
            Unity_Add_float(_GradientNoise_de42ec7fdd52ec8fa0b6cb7f34842c13_Out_2, _GradientNoise_28996fa0f6fbd08c97ed18d0621900b5_Out_2, _Add_caf5f972abacae878d9a6fde10e0986a_Out_2);
            float _Divide_27ef561e54cd208ca89512269c1d4d03_Out_2;
            Unity_Divide_float(_Add_caf5f972abacae878d9a6fde10e0986a_Out_2, 2, _Divide_27ef561e54cd208ca89512269c1d4d03_Out_2);
            float _Saturate_c56694103011198486afa78b0e89ec2c_Out_1;
            Unity_Saturate_float(_Divide_27ef561e54cd208ca89512269c1d4d03_Out_2, _Saturate_c56694103011198486afa78b0e89ec2c_Out_1);
            float _Property_8bd1d491d3050588a0b837b4b232170d_Out_0 = Vector1_4CE104D9;
            float _Power_abb6d235206009809ee431a98f2c8247_Out_2;
            Unity_Power_float(_Saturate_c56694103011198486afa78b0e89ec2c_Out_1, _Property_8bd1d491d3050588a0b837b4b232170d_Out_0, _Power_abb6d235206009809ee431a98f2c8247_Out_2);
            float4 _Property_8a81e8a6d963f384bddf6e75ec8e0a1c_Out_0 = Vector4_1696EE66;
            float _Split_f72e1ad87d56df8ba34ec31e2bc432b8_R_1 = _Property_8a81e8a6d963f384bddf6e75ec8e0a1c_Out_0[0];
            float _Split_f72e1ad87d56df8ba34ec31e2bc432b8_G_2 = _Property_8a81e8a6d963f384bddf6e75ec8e0a1c_Out_0[1];
            float _Split_f72e1ad87d56df8ba34ec31e2bc432b8_B_3 = _Property_8a81e8a6d963f384bddf6e75ec8e0a1c_Out_0[2];
            float _Split_f72e1ad87d56df8ba34ec31e2bc432b8_A_4 = _Property_8a81e8a6d963f384bddf6e75ec8e0a1c_Out_0[3];
            float4 _Combine_aeef4bbea8acc688b198e488208172f2_RGBA_4;
            float3 _Combine_aeef4bbea8acc688b198e488208172f2_RGB_5;
            float2 _Combine_aeef4bbea8acc688b198e488208172f2_RG_6;
            Unity_Combine_float(_Split_f72e1ad87d56df8ba34ec31e2bc432b8_R_1, _Split_f72e1ad87d56df8ba34ec31e2bc432b8_G_2, 0, 0, _Combine_aeef4bbea8acc688b198e488208172f2_RGBA_4, _Combine_aeef4bbea8acc688b198e488208172f2_RGB_5, _Combine_aeef4bbea8acc688b198e488208172f2_RG_6);
            float4 _Combine_feabe866dc39388d8ccd72275fb9be09_RGBA_4;
            float3 _Combine_feabe866dc39388d8ccd72275fb9be09_RGB_5;
            float2 _Combine_feabe866dc39388d8ccd72275fb9be09_RG_6;
            Unity_Combine_float(_Split_f72e1ad87d56df8ba34ec31e2bc432b8_B_3, _Split_f72e1ad87d56df8ba34ec31e2bc432b8_A_4, 0, 0, _Combine_feabe866dc39388d8ccd72275fb9be09_RGBA_4, _Combine_feabe866dc39388d8ccd72275fb9be09_RGB_5, _Combine_feabe866dc39388d8ccd72275fb9be09_RG_6);
            float _Remap_ca18d3412979f985809f3426d5282816_Out_3;
            Unity_Remap_float(_Power_abb6d235206009809ee431a98f2c8247_Out_2, _Combine_aeef4bbea8acc688b198e488208172f2_RG_6, _Combine_feabe866dc39388d8ccd72275fb9be09_RG_6, _Remap_ca18d3412979f985809f3426d5282816_Out_3);
            float _Absolute_01d69efb5b6b628b8142004f10302240_Out_1;
            Unity_Absolute_float(_Remap_ca18d3412979f985809f3426d5282816_Out_3, _Absolute_01d69efb5b6b628b8142004f10302240_Out_1);
            float _Smoothstep_5a0282a38f27848e9545f1e89a11f5a2_Out_3;
            Unity_Smoothstep_float(_Property_45fc02a5c65e898c82a51138ee7894c8_Out_0, _Property_423be2625737e5829e3daa7b3cf8389d_Out_0, _Absolute_01d69efb5b6b628b8142004f10302240_Out_1, _Smoothstep_5a0282a38f27848e9545f1e89a11f5a2_Out_3);
            float _Property_91482984669b1c8ab26a0f4a555b3801_Out_0 = Vector1_9058DE8C;
            float _Multiply_ad5811e4c08fae88a363e144af359987_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_91482984669b1c8ab26a0f4a555b3801_Out_0, _Multiply_ad5811e4c08fae88a363e144af359987_Out_2);
            float2 _TilingAndOffset_2345314be014258796bc32f9e66d2397_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_430e3c523bf85e84bdef451ab28beba0_Out_3.xy), float2 (1, 1), (_Multiply_ad5811e4c08fae88a363e144af359987_Out_2.xx), _TilingAndOffset_2345314be014258796bc32f9e66d2397_Out_3);
            float _Property_a13e388a84b18e89afce2f9f3ca9753f_Out_0 = Vector1_5536221E;
            float _GradientNoise_9f2e5d10ed34688f87f30e9a171b1f8b_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_2345314be014258796bc32f9e66d2397_Out_3, _Property_a13e388a84b18e89afce2f9f3ca9753f_Out_0, _GradientNoise_9f2e5d10ed34688f87f30e9a171b1f8b_Out_2);
            float _Property_b64fda08fa35398f9e0f45e316a434f9_Out_0 = Vector1_350643F1;
            float _Multiply_d03d0c5bc6770f8b8fbb46ec0c06b35b_Out_2;
            Unity_Multiply_float(_GradientNoise_9f2e5d10ed34688f87f30e9a171b1f8b_Out_2, _Property_b64fda08fa35398f9e0f45e316a434f9_Out_0, _Multiply_d03d0c5bc6770f8b8fbb46ec0c06b35b_Out_2);
            float _Add_f031b6931be259898e2d889c851d36d5_Out_2;
            Unity_Add_float(_Smoothstep_5a0282a38f27848e9545f1e89a11f5a2_Out_3, _Multiply_d03d0c5bc6770f8b8fbb46ec0c06b35b_Out_2, _Add_f031b6931be259898e2d889c851d36d5_Out_2);
            float _Add_e1b7452d2644ef8e96d652df6def6989_Out_2;
            Unity_Add_float(1, _Property_b64fda08fa35398f9e0f45e316a434f9_Out_0, _Add_e1b7452d2644ef8e96d652df6def6989_Out_2);
            float _Divide_b34aaac0718e8682bb2ab66e45d42421_Out_2;
            Unity_Divide_float(_Add_f031b6931be259898e2d889c851d36d5_Out_2, _Add_e1b7452d2644ef8e96d652df6def6989_Out_2, _Divide_b34aaac0718e8682bb2ab66e45d42421_Out_2);
            float3 _Multiply_a97d25c025f47f8fa4cfe3267dee485e_Out_2;
            Unity_Multiply_float(IN.ObjectSpaceNormal, (_Divide_b34aaac0718e8682bb2ab66e45d42421_Out_2.xxx), _Multiply_a97d25c025f47f8fa4cfe3267dee485e_Out_2);
            float _Property_6f2976fe72816a869d8677a4230164f0_Out_0 = Vector1_E43D3892;
            float3 _Multiply_08ef8c8995ef448a9ab1e43028223a19_Out_2;
            Unity_Multiply_float(_Multiply_a97d25c025f47f8fa4cfe3267dee485e_Out_2, (_Property_6f2976fe72816a869d8677a4230164f0_Out_0.xxx), _Multiply_08ef8c8995ef448a9ab1e43028223a19_Out_2);
            float3 _Add_ec1431816c726e8a827bfd7e7de3d614_Out_2;
            Unity_Add_float3(IN.ObjectSpacePosition, _Multiply_08ef8c8995ef448a9ab1e43028223a19_Out_2, _Add_ec1431816c726e8a827bfd7e7de3d614_Out_2);
            float3 _Add_cbfa9591f076e485a31b7f5b967f99f6_Out_2;
            Unity_Add_float3(_Multiply_3fa32f2d7f56688684a8f5b0a0853be5_Out_2, _Add_ec1431816c726e8a827bfd7e7de3d614_Out_2, _Add_cbfa9591f076e485a31b7f5b967f99f6_Out_2);
            description.Position = _Add_cbfa9591f076e485a31b7f5b967f99f6_Out_2;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }

            // Graph Pixel
            struct SurfaceDescription
        {
            float3 BaseColor;
            float Alpha;
        };

        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            float _SceneDepth_845bf60653d70482b562a739512eeda7_Out_1;
            Unity_SceneDepth_Eye_float(float4(IN.ScreenPosition.xy / IN.ScreenPosition.w, 0, 0), _SceneDepth_845bf60653d70482b562a739512eeda7_Out_1);
            float4 _ScreenPosition_b978995ebe1ba286935416b2a2d5cb85_Out_0 = IN.ScreenPosition;
            float _Split_c66584edb0487b8e8c2e107a89ed8e9f_R_1 = _ScreenPosition_b978995ebe1ba286935416b2a2d5cb85_Out_0[0];
            float _Split_c66584edb0487b8e8c2e107a89ed8e9f_G_2 = _ScreenPosition_b978995ebe1ba286935416b2a2d5cb85_Out_0[1];
            float _Split_c66584edb0487b8e8c2e107a89ed8e9f_B_3 = _ScreenPosition_b978995ebe1ba286935416b2a2d5cb85_Out_0[2];
            float _Split_c66584edb0487b8e8c2e107a89ed8e9f_A_4 = _ScreenPosition_b978995ebe1ba286935416b2a2d5cb85_Out_0[3];
            float _Subtract_39fffd64ebdafb84a6eb8e37e2faaa16_Out_2;
            Unity_Subtract_float(_Split_c66584edb0487b8e8c2e107a89ed8e9f_A_4, 1, _Subtract_39fffd64ebdafb84a6eb8e37e2faaa16_Out_2);
            float _Subtract_d8ff2e79b2fc8386b6172daebbe97366_Out_2;
            Unity_Subtract_float(_SceneDepth_845bf60653d70482b562a739512eeda7_Out_1, _Subtract_39fffd64ebdafb84a6eb8e37e2faaa16_Out_2, _Subtract_d8ff2e79b2fc8386b6172daebbe97366_Out_2);
            float _Property_0a2887e34569358bbc9cbee1a14acebb_Out_0 = Vector1_EED1A887;
            float _Divide_f3ff43869c02038db823cf0d91c23caf_Out_2;
            Unity_Divide_float(_Subtract_d8ff2e79b2fc8386b6172daebbe97366_Out_2, _Property_0a2887e34569358bbc9cbee1a14acebb_Out_0, _Divide_f3ff43869c02038db823cf0d91c23caf_Out_2);
            float _Saturate_676d84ccc0f0b88e9d1fdf263cfcf1d5_Out_1;
            Unity_Saturate_float(_Divide_f3ff43869c02038db823cf0d91c23caf_Out_2, _Saturate_676d84ccc0f0b88e9d1fdf263cfcf1d5_Out_1);
            float _Smoothstep_edf634d16c75cd829225bfca563f83fb_Out_3;
            Unity_Smoothstep_float(0, 1, _Saturate_676d84ccc0f0b88e9d1fdf263cfcf1d5_Out_1, _Smoothstep_edf634d16c75cd829225bfca563f83fb_Out_3);
            surface.BaseColor = IsGammaSpace() ? float3(0, 0, 0) : SRGBToLinear(float3(0, 0, 0));
            surface.Alpha = _Smoothstep_edf634d16c75cd829225bfca563f83fb_Out_3;
            return surface;
        }

            // --------------------------------------------------
            // Build Graph Inputs

            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);

            output.ObjectSpaceNormal =           input.normalOS;
            output.WorldSpaceNormal =            TransformObjectToWorldNormal(input.normalOS);
            output.ObjectSpaceTangent =          input.tangentOS.xyz;
            output.ObjectSpacePosition =         input.positionOS;
            output.WorldSpacePosition =          TransformObjectToWorld(input.positionOS);
            output.TimeParameters =              _TimeParameters.xyz;

            return output;
        }
            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);





            output.WorldSpacePosition =          input.positionWS;
            output.ScreenPosition =              ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

            return output;
        }

            // --------------------------------------------------
            // Main

            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/PBR2DPass.hlsl"

            ENDHLSL
        }
    }
    SubShader
    {
        Tags
        {
            "RenderPipeline"="UniversalPipeline"
            "RenderType"="Transparent"
            "UniversalMaterialType" = "Lit"
            "Queue"="Transparent"
        }
        Pass
        {
            Name "Universal Forward"
            Tags
            {
                "LightMode" = "UniversalForward"
            }

            // Render State
            Cull Back
        Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
        ZTest LEqual
        ZWrite Off

            // Debug
            // <None>

            // --------------------------------------------------
            // Pass

            HLSLPROGRAM

            // Pragmas
            #pragma target 2.0
        #pragma only_renderers gles gles3 glcore d3d11
        #pragma multi_compile_instancing
        #pragma multi_compile_fog
        #pragma vertex vert
        #pragma fragment frag

            // DotsInstancingOptions: <None>
            // HybridV1InjectedBuiltinProperties: <None>

            // Keywords
            #pragma multi_compile _ _SCREEN_SPACE_OCCLUSION
        #pragma multi_compile _ LIGHTMAP_ON
        #pragma multi_compile _ DIRLIGHTMAP_COMBINED
        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
        #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
        #pragma multi_compile _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS _ADDITIONAL_OFF
        #pragma multi_compile _ _ADDITIONAL_LIGHT_SHADOWS
        #pragma multi_compile _ _SHADOWS_SOFT
        #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
        #pragma multi_compile _ SHADOWS_SHADOWMASK
            // GraphKeywords: <None>

            // Defines
            #define _SURFACE_TYPE_TRANSPARENT 1
            #define _NORMALMAP 1
            #define _NORMAL_DROPOFF_TS 1
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define ATTRIBUTES_NEED_TEXCOORD1
            #define VARYINGS_NEED_POSITION_WS
            #define VARYINGS_NEED_NORMAL_WS
            #define VARYINGS_NEED_TANGENT_WS
            #define VARYINGS_NEED_VIEWDIRECTION_WS
            #define VARYINGS_NEED_FOG_AND_VERTEX_LIGHT
            #define FEATURES_GRAPH_VERTEX
            /* WARNING: $splice Could not find named fragment 'PassInstancing' */
            #define SHADERPASS SHADERPASS_FORWARD
        #define REQUIRE_DEPTH_TEXTURE
            /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

            // --------------------------------------------------
            // Structs and Packing

            struct Attributes
        {
            float3 positionOS : POSITION;
            float3 normalOS : NORMAL;
            float4 tangentOS : TANGENT;
            float4 uv1 : TEXCOORD1;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
            float4 positionCS : SV_POSITION;
            float3 positionWS;
            float3 normalWS;
            float4 tangentWS;
            float3 viewDirectionWS;
            #if defined(LIGHTMAP_ON)
            float2 lightmapUV;
            #endif
            #if !defined(LIGHTMAP_ON)
            float3 sh;
            #endif
            float4 fogFactorAndVertexLight;
            float4 shadowCoord;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
            float3 WorldSpaceNormal;
            float3 TangentSpaceNormal;
            float3 WorldSpaceViewDirection;
            float3 WorldSpacePosition;
            float4 ScreenPosition;
            float3 TimeParameters;
        };
        struct VertexDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 WorldSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 ObjectSpacePosition;
            float3 WorldSpacePosition;
            float3 TimeParameters;
        };
        struct PackedVaryings
        {
            float4 positionCS : SV_POSITION;
            float3 interp0 : TEXCOORD0;
            float3 interp1 : TEXCOORD1;
            float4 interp2 : TEXCOORD2;
            float3 interp3 : TEXCOORD3;
            #if defined(LIGHTMAP_ON)
            float2 interp4 : TEXCOORD4;
            #endif
            #if !defined(LIGHTMAP_ON)
            float3 interp5 : TEXCOORD5;
            #endif
            float4 interp6 : TEXCOORD6;
            float4 interp7 : TEXCOORD7;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };

            PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            output.interp2.xyzw =  input.tangentWS;
            output.interp3.xyz =  input.viewDirectionWS;
            #if defined(LIGHTMAP_ON)
            output.interp4.xy =  input.lightmapUV;
            #endif
            #if !defined(LIGHTMAP_ON)
            output.interp5.xyz =  input.sh;
            #endif
            output.interp6.xyzw =  input.fogFactorAndVertexLight;
            output.interp7.xyzw =  input.shadowCoord;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            output.tangentWS = input.interp2.xyzw;
            output.viewDirectionWS = input.interp3.xyz;
            #if defined(LIGHTMAP_ON)
            output.lightmapUV = input.interp4.xy;
            #endif
            #if !defined(LIGHTMAP_ON)
            output.sh = input.interp5.xyz;
            #endif
            output.fogFactorAndVertexLight = input.interp6.xyzw;
            output.shadowCoord = input.interp7.xyzw;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }

            // --------------------------------------------------
            // Graph

            // Graph Properties
            CBUFFER_START(UnityPerMaterial)
        float4 Vector4_484BA326;
        float Vector1_8F075DBC;
        float Vector1_8AAD665C;
        float Vector1_E43D3892;
        float4 Vector4_1696EE66;
        float4 Color_2CFB5E2A;
        float4 Color_58195353;
        float Vector1_FADC0395;
        float Vector1_E505CA4B;
        float Vector1_4CE104D9;
        float Vector1_5536221E;
        float Vector1_9058DE8C;
        float Vector1_350643F1;
        float Vector1_2A80C598;
        float Vector1_A664731F;
        float Vector1_B4ED823D;
        float Vector1_2BA361A8;
        float Vector1_EED1A887;
        CBUFFER_END

        // Object and Global properties

            // Graph Functions
            
        void Unity_Distance_float3(float3 A, float3 B, out float Out)
        {
            Out = distance(A, B);
        }

        void Unity_Divide_float(float A, float B, out float Out)
        {
            Out = A / B;
        }

        void Unity_Power_float(float A, float B, out float Out)
        {
            Out = pow(A, B);
        }

        void Unity_Multiply_float(float3 A, float3 B, out float3 Out)
        {
            Out = A * B;
        }

        void Unity_Rotate_About_Axis_Degrees_float(float3 In, float3 Axis, float Rotation, out float3 Out)
        {
            Rotation = radians(Rotation);

            float s = sin(Rotation);
            float c = cos(Rotation);
            float one_minus_c = 1.0 - c;
            
            Axis = normalize(Axis);

            float3x3 rot_mat = { one_minus_c * Axis.x * Axis.x + c,            one_minus_c * Axis.x * Axis.y - Axis.z * s,     one_minus_c * Axis.z * Axis.x + Axis.y * s,
                                      one_minus_c * Axis.x * Axis.y + Axis.z * s,   one_minus_c * Axis.y * Axis.y + c,              one_minus_c * Axis.y * Axis.z - Axis.x * s,
                                      one_minus_c * Axis.z * Axis.x - Axis.y * s,   one_minus_c * Axis.y * Axis.z + Axis.x * s,     one_minus_c * Axis.z * Axis.z + c
                                    };

            Out = mul(rot_mat,  In);
        }

        void Unity_Multiply_float(float A, float B, out float Out)
        {
            Out = A * B;
        }

        void Unity_TilingAndOffset_float(float2 UV, float2 Tiling, float2 Offset, out float2 Out)
        {
            Out = UV * Tiling + Offset;
        }


        float2 Unity_GradientNoise_Dir_float(float2 p)
        {
            // Permutation and hashing used in webgl-nosie goo.gl/pX7HtC
            p = p % 289;
            // need full precision, otherwise half overflows when p > 1
            float x = float(34 * p.x + 1) * p.x % 289 + p.y;
            x = (34 * x + 1) * x % 289;
            x = frac(x / 41) * 2 - 1;
            return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
        }

        void Unity_GradientNoise_float(float2 UV, float Scale, out float Out)
        { 
            float2 p = UV * Scale;
            float2 ip = floor(p);
            float2 fp = frac(p);
            float d00 = dot(Unity_GradientNoise_Dir_float(ip), fp);
            float d01 = dot(Unity_GradientNoise_Dir_float(ip + float2(0, 1)), fp - float2(0, 1));
            float d10 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 0)), fp - float2(1, 0));
            float d11 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 1)), fp - float2(1, 1));
            fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
            Out = lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x) + 0.5;
        }

        void Unity_Add_float(float A, float B, out float Out)
        {
            Out = A + B;
        }

        void Unity_Saturate_float(float In, out float Out)
        {
            Out = saturate(In);
        }

        void Unity_Combine_float(float R, float G, float B, float A, out float4 RGBA, out float3 RGB, out float2 RG)
        {
            RGBA = float4(R, G, B, A);
            RGB = float3(R, G, B);
            RG = float2(R, G);
        }

        void Unity_Remap_float(float In, float2 InMinMax, float2 OutMinMax, out float Out)
        {
            Out = OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
        }

        void Unity_Absolute_float(float In, out float Out)
        {
            Out = abs(In);
        }

        void Unity_Smoothstep_float(float Edge1, float Edge2, float In, out float Out)
        {
            Out = smoothstep(Edge1, Edge2, In);
        }

        void Unity_Add_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A + B;
        }

        void Unity_Lerp_float4(float4 A, float4 B, float4 T, out float4 Out)
        {
            Out = lerp(A, B, T);
        }

        void Unity_FresnelEffect_float(float3 Normal, float3 ViewDir, float Power, out float Out)
        {
            Out = pow((1.0 - saturate(dot(normalize(Normal), normalize(ViewDir)))), Power);
        }

        void Unity_Add_float4(float4 A, float4 B, out float4 Out)
        {
            Out = A + B;
        }

        void Unity_Multiply_float(float4 A, float4 B, out float4 Out)
        {
            Out = A * B;
        }

        void Unity_SceneDepth_Eye_float(float4 UV, out float Out)
        {
            Out = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH(UV.xy), _ZBufferParams);
        }

        void Unity_Subtract_float(float A, float B, out float Out)
        {
            Out = A - B;
        }

            // Graph Vertex
            struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };

        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            float _Distance_474c9e8e982c878dad2f0d5844b22ee9_Out_2;
            Unity_Distance_float3(SHADERGRAPH_OBJECT_POSITION, IN.WorldSpacePosition, _Distance_474c9e8e982c878dad2f0d5844b22ee9_Out_2);
            float _Property_95b6af28bf5d388fb7809e99d4ea7a10_Out_0 = Vector1_A664731F;
            float _Divide_2022c703e9e6de87965706bd214b7b67_Out_2;
            Unity_Divide_float(_Distance_474c9e8e982c878dad2f0d5844b22ee9_Out_2, _Property_95b6af28bf5d388fb7809e99d4ea7a10_Out_0, _Divide_2022c703e9e6de87965706bd214b7b67_Out_2);
            float _Power_8710b3fb1efe3183a2818b946e662a1e_Out_2;
            Unity_Power_float(_Divide_2022c703e9e6de87965706bd214b7b67_Out_2, 3, _Power_8710b3fb1efe3183a2818b946e662a1e_Out_2);
            float3 _Multiply_3fa32f2d7f56688684a8f5b0a0853be5_Out_2;
            Unity_Multiply_float(IN.WorldSpaceNormal, (_Power_8710b3fb1efe3183a2818b946e662a1e_Out_2.xxx), _Multiply_3fa32f2d7f56688684a8f5b0a0853be5_Out_2);
            float _Property_45fc02a5c65e898c82a51138ee7894c8_Out_0 = Vector1_FADC0395;
            float _Property_423be2625737e5829e3daa7b3cf8389d_Out_0 = Vector1_E505CA4B;
            float4 _Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0 = Vector4_484BA326;
            float _Split_e9324c176bf05a809ea8df8c413a826a_R_1 = _Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0[0];
            float _Split_e9324c176bf05a809ea8df8c413a826a_G_2 = _Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0[1];
            float _Split_e9324c176bf05a809ea8df8c413a826a_B_3 = _Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0[2];
            float _Split_e9324c176bf05a809ea8df8c413a826a_A_4 = _Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0[3];
            float3 _RotateAboutAxis_430e3c523bf85e84bdef451ab28beba0_Out_3;
            Unity_Rotate_About_Axis_Degrees_float(IN.WorldSpacePosition, (_Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0.xyz), _Split_e9324c176bf05a809ea8df8c413a826a_A_4, _RotateAboutAxis_430e3c523bf85e84bdef451ab28beba0_Out_3);
            float _Property_84dca49c8958708fac3276b0de15a6da_Out_0 = Vector1_8AAD665C;
            float _Multiply_89f92af49e152081ba549c92ab002e9c_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_84dca49c8958708fac3276b0de15a6da_Out_0, _Multiply_89f92af49e152081ba549c92ab002e9c_Out_2);
            float2 _TilingAndOffset_bd9fc632c3a6c185b226f93212ed8603_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_430e3c523bf85e84bdef451ab28beba0_Out_3.xy), float2 (1, 1), (_Multiply_89f92af49e152081ba549c92ab002e9c_Out_2.xx), _TilingAndOffset_bd9fc632c3a6c185b226f93212ed8603_Out_3);
            float _Property_f7111fce9be08b8c871514ffc219f648_Out_0 = Vector1_8F075DBC;
            float _GradientNoise_de42ec7fdd52ec8fa0b6cb7f34842c13_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_bd9fc632c3a6c185b226f93212ed8603_Out_3, _Property_f7111fce9be08b8c871514ffc219f648_Out_0, _GradientNoise_de42ec7fdd52ec8fa0b6cb7f34842c13_Out_2);
            float2 _TilingAndOffset_aa88c06674f4178889e657a2bb46c454_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_430e3c523bf85e84bdef451ab28beba0_Out_3.xy), float2 (1, 1), float2 (0, 0), _TilingAndOffset_aa88c06674f4178889e657a2bb46c454_Out_3);
            float _GradientNoise_28996fa0f6fbd08c97ed18d0621900b5_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_aa88c06674f4178889e657a2bb46c454_Out_3, _Property_f7111fce9be08b8c871514ffc219f648_Out_0, _GradientNoise_28996fa0f6fbd08c97ed18d0621900b5_Out_2);
            float _Add_caf5f972abacae878d9a6fde10e0986a_Out_2;
            Unity_Add_float(_GradientNoise_de42ec7fdd52ec8fa0b6cb7f34842c13_Out_2, _GradientNoise_28996fa0f6fbd08c97ed18d0621900b5_Out_2, _Add_caf5f972abacae878d9a6fde10e0986a_Out_2);
            float _Divide_27ef561e54cd208ca89512269c1d4d03_Out_2;
            Unity_Divide_float(_Add_caf5f972abacae878d9a6fde10e0986a_Out_2, 2, _Divide_27ef561e54cd208ca89512269c1d4d03_Out_2);
            float _Saturate_c56694103011198486afa78b0e89ec2c_Out_1;
            Unity_Saturate_float(_Divide_27ef561e54cd208ca89512269c1d4d03_Out_2, _Saturate_c56694103011198486afa78b0e89ec2c_Out_1);
            float _Property_8bd1d491d3050588a0b837b4b232170d_Out_0 = Vector1_4CE104D9;
            float _Power_abb6d235206009809ee431a98f2c8247_Out_2;
            Unity_Power_float(_Saturate_c56694103011198486afa78b0e89ec2c_Out_1, _Property_8bd1d491d3050588a0b837b4b232170d_Out_0, _Power_abb6d235206009809ee431a98f2c8247_Out_2);
            float4 _Property_8a81e8a6d963f384bddf6e75ec8e0a1c_Out_0 = Vector4_1696EE66;
            float _Split_f72e1ad87d56df8ba34ec31e2bc432b8_R_1 = _Property_8a81e8a6d963f384bddf6e75ec8e0a1c_Out_0[0];
            float _Split_f72e1ad87d56df8ba34ec31e2bc432b8_G_2 = _Property_8a81e8a6d963f384bddf6e75ec8e0a1c_Out_0[1];
            float _Split_f72e1ad87d56df8ba34ec31e2bc432b8_B_3 = _Property_8a81e8a6d963f384bddf6e75ec8e0a1c_Out_0[2];
            float _Split_f72e1ad87d56df8ba34ec31e2bc432b8_A_4 = _Property_8a81e8a6d963f384bddf6e75ec8e0a1c_Out_0[3];
            float4 _Combine_aeef4bbea8acc688b198e488208172f2_RGBA_4;
            float3 _Combine_aeef4bbea8acc688b198e488208172f2_RGB_5;
            float2 _Combine_aeef4bbea8acc688b198e488208172f2_RG_6;
            Unity_Combine_float(_Split_f72e1ad87d56df8ba34ec31e2bc432b8_R_1, _Split_f72e1ad87d56df8ba34ec31e2bc432b8_G_2, 0, 0, _Combine_aeef4bbea8acc688b198e488208172f2_RGBA_4, _Combine_aeef4bbea8acc688b198e488208172f2_RGB_5, _Combine_aeef4bbea8acc688b198e488208172f2_RG_6);
            float4 _Combine_feabe866dc39388d8ccd72275fb9be09_RGBA_4;
            float3 _Combine_feabe866dc39388d8ccd72275fb9be09_RGB_5;
            float2 _Combine_feabe866dc39388d8ccd72275fb9be09_RG_6;
            Unity_Combine_float(_Split_f72e1ad87d56df8ba34ec31e2bc432b8_B_3, _Split_f72e1ad87d56df8ba34ec31e2bc432b8_A_4, 0, 0, _Combine_feabe866dc39388d8ccd72275fb9be09_RGBA_4, _Combine_feabe866dc39388d8ccd72275fb9be09_RGB_5, _Combine_feabe866dc39388d8ccd72275fb9be09_RG_6);
            float _Remap_ca18d3412979f985809f3426d5282816_Out_3;
            Unity_Remap_float(_Power_abb6d235206009809ee431a98f2c8247_Out_2, _Combine_aeef4bbea8acc688b198e488208172f2_RG_6, _Combine_feabe866dc39388d8ccd72275fb9be09_RG_6, _Remap_ca18d3412979f985809f3426d5282816_Out_3);
            float _Absolute_01d69efb5b6b628b8142004f10302240_Out_1;
            Unity_Absolute_float(_Remap_ca18d3412979f985809f3426d5282816_Out_3, _Absolute_01d69efb5b6b628b8142004f10302240_Out_1);
            float _Smoothstep_5a0282a38f27848e9545f1e89a11f5a2_Out_3;
            Unity_Smoothstep_float(_Property_45fc02a5c65e898c82a51138ee7894c8_Out_0, _Property_423be2625737e5829e3daa7b3cf8389d_Out_0, _Absolute_01d69efb5b6b628b8142004f10302240_Out_1, _Smoothstep_5a0282a38f27848e9545f1e89a11f5a2_Out_3);
            float _Property_91482984669b1c8ab26a0f4a555b3801_Out_0 = Vector1_9058DE8C;
            float _Multiply_ad5811e4c08fae88a363e144af359987_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_91482984669b1c8ab26a0f4a555b3801_Out_0, _Multiply_ad5811e4c08fae88a363e144af359987_Out_2);
            float2 _TilingAndOffset_2345314be014258796bc32f9e66d2397_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_430e3c523bf85e84bdef451ab28beba0_Out_3.xy), float2 (1, 1), (_Multiply_ad5811e4c08fae88a363e144af359987_Out_2.xx), _TilingAndOffset_2345314be014258796bc32f9e66d2397_Out_3);
            float _Property_a13e388a84b18e89afce2f9f3ca9753f_Out_0 = Vector1_5536221E;
            float _GradientNoise_9f2e5d10ed34688f87f30e9a171b1f8b_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_2345314be014258796bc32f9e66d2397_Out_3, _Property_a13e388a84b18e89afce2f9f3ca9753f_Out_0, _GradientNoise_9f2e5d10ed34688f87f30e9a171b1f8b_Out_2);
            float _Property_b64fda08fa35398f9e0f45e316a434f9_Out_0 = Vector1_350643F1;
            float _Multiply_d03d0c5bc6770f8b8fbb46ec0c06b35b_Out_2;
            Unity_Multiply_float(_GradientNoise_9f2e5d10ed34688f87f30e9a171b1f8b_Out_2, _Property_b64fda08fa35398f9e0f45e316a434f9_Out_0, _Multiply_d03d0c5bc6770f8b8fbb46ec0c06b35b_Out_2);
            float _Add_f031b6931be259898e2d889c851d36d5_Out_2;
            Unity_Add_float(_Smoothstep_5a0282a38f27848e9545f1e89a11f5a2_Out_3, _Multiply_d03d0c5bc6770f8b8fbb46ec0c06b35b_Out_2, _Add_f031b6931be259898e2d889c851d36d5_Out_2);
            float _Add_e1b7452d2644ef8e96d652df6def6989_Out_2;
            Unity_Add_float(1, _Property_b64fda08fa35398f9e0f45e316a434f9_Out_0, _Add_e1b7452d2644ef8e96d652df6def6989_Out_2);
            float _Divide_b34aaac0718e8682bb2ab66e45d42421_Out_2;
            Unity_Divide_float(_Add_f031b6931be259898e2d889c851d36d5_Out_2, _Add_e1b7452d2644ef8e96d652df6def6989_Out_2, _Divide_b34aaac0718e8682bb2ab66e45d42421_Out_2);
            float3 _Multiply_a97d25c025f47f8fa4cfe3267dee485e_Out_2;
            Unity_Multiply_float(IN.ObjectSpaceNormal, (_Divide_b34aaac0718e8682bb2ab66e45d42421_Out_2.xxx), _Multiply_a97d25c025f47f8fa4cfe3267dee485e_Out_2);
            float _Property_6f2976fe72816a869d8677a4230164f0_Out_0 = Vector1_E43D3892;
            float3 _Multiply_08ef8c8995ef448a9ab1e43028223a19_Out_2;
            Unity_Multiply_float(_Multiply_a97d25c025f47f8fa4cfe3267dee485e_Out_2, (_Property_6f2976fe72816a869d8677a4230164f0_Out_0.xxx), _Multiply_08ef8c8995ef448a9ab1e43028223a19_Out_2);
            float3 _Add_ec1431816c726e8a827bfd7e7de3d614_Out_2;
            Unity_Add_float3(IN.ObjectSpacePosition, _Multiply_08ef8c8995ef448a9ab1e43028223a19_Out_2, _Add_ec1431816c726e8a827bfd7e7de3d614_Out_2);
            float3 _Add_cbfa9591f076e485a31b7f5b967f99f6_Out_2;
            Unity_Add_float3(_Multiply_3fa32f2d7f56688684a8f5b0a0853be5_Out_2, _Add_ec1431816c726e8a827bfd7e7de3d614_Out_2, _Add_cbfa9591f076e485a31b7f5b967f99f6_Out_2);
            description.Position = _Add_cbfa9591f076e485a31b7f5b967f99f6_Out_2;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }

            // Graph Pixel
            struct SurfaceDescription
        {
            float3 BaseColor;
            float3 NormalTS;
            float3 Emission;
            float Metallic;
            float Smoothness;
            float Occlusion;
            float Alpha;
        };

        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            float4 _Property_8602b260fe5c06829b7738349464dbbc_Out_0 = Color_58195353;
            float4 _Property_db73cd07c4394c82a6cd028523c127f3_Out_0 = Color_2CFB5E2A;
            float _Property_45fc02a5c65e898c82a51138ee7894c8_Out_0 = Vector1_FADC0395;
            float _Property_423be2625737e5829e3daa7b3cf8389d_Out_0 = Vector1_E505CA4B;
            float4 _Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0 = Vector4_484BA326;
            float _Split_e9324c176bf05a809ea8df8c413a826a_R_1 = _Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0[0];
            float _Split_e9324c176bf05a809ea8df8c413a826a_G_2 = _Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0[1];
            float _Split_e9324c176bf05a809ea8df8c413a826a_B_3 = _Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0[2];
            float _Split_e9324c176bf05a809ea8df8c413a826a_A_4 = _Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0[3];
            float3 _RotateAboutAxis_430e3c523bf85e84bdef451ab28beba0_Out_3;
            Unity_Rotate_About_Axis_Degrees_float(IN.WorldSpacePosition, (_Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0.xyz), _Split_e9324c176bf05a809ea8df8c413a826a_A_4, _RotateAboutAxis_430e3c523bf85e84bdef451ab28beba0_Out_3);
            float _Property_84dca49c8958708fac3276b0de15a6da_Out_0 = Vector1_8AAD665C;
            float _Multiply_89f92af49e152081ba549c92ab002e9c_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_84dca49c8958708fac3276b0de15a6da_Out_0, _Multiply_89f92af49e152081ba549c92ab002e9c_Out_2);
            float2 _TilingAndOffset_bd9fc632c3a6c185b226f93212ed8603_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_430e3c523bf85e84bdef451ab28beba0_Out_3.xy), float2 (1, 1), (_Multiply_89f92af49e152081ba549c92ab002e9c_Out_2.xx), _TilingAndOffset_bd9fc632c3a6c185b226f93212ed8603_Out_3);
            float _Property_f7111fce9be08b8c871514ffc219f648_Out_0 = Vector1_8F075DBC;
            float _GradientNoise_de42ec7fdd52ec8fa0b6cb7f34842c13_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_bd9fc632c3a6c185b226f93212ed8603_Out_3, _Property_f7111fce9be08b8c871514ffc219f648_Out_0, _GradientNoise_de42ec7fdd52ec8fa0b6cb7f34842c13_Out_2);
            float2 _TilingAndOffset_aa88c06674f4178889e657a2bb46c454_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_430e3c523bf85e84bdef451ab28beba0_Out_3.xy), float2 (1, 1), float2 (0, 0), _TilingAndOffset_aa88c06674f4178889e657a2bb46c454_Out_3);
            float _GradientNoise_28996fa0f6fbd08c97ed18d0621900b5_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_aa88c06674f4178889e657a2bb46c454_Out_3, _Property_f7111fce9be08b8c871514ffc219f648_Out_0, _GradientNoise_28996fa0f6fbd08c97ed18d0621900b5_Out_2);
            float _Add_caf5f972abacae878d9a6fde10e0986a_Out_2;
            Unity_Add_float(_GradientNoise_de42ec7fdd52ec8fa0b6cb7f34842c13_Out_2, _GradientNoise_28996fa0f6fbd08c97ed18d0621900b5_Out_2, _Add_caf5f972abacae878d9a6fde10e0986a_Out_2);
            float _Divide_27ef561e54cd208ca89512269c1d4d03_Out_2;
            Unity_Divide_float(_Add_caf5f972abacae878d9a6fde10e0986a_Out_2, 2, _Divide_27ef561e54cd208ca89512269c1d4d03_Out_2);
            float _Saturate_c56694103011198486afa78b0e89ec2c_Out_1;
            Unity_Saturate_float(_Divide_27ef561e54cd208ca89512269c1d4d03_Out_2, _Saturate_c56694103011198486afa78b0e89ec2c_Out_1);
            float _Property_8bd1d491d3050588a0b837b4b232170d_Out_0 = Vector1_4CE104D9;
            float _Power_abb6d235206009809ee431a98f2c8247_Out_2;
            Unity_Power_float(_Saturate_c56694103011198486afa78b0e89ec2c_Out_1, _Property_8bd1d491d3050588a0b837b4b232170d_Out_0, _Power_abb6d235206009809ee431a98f2c8247_Out_2);
            float4 _Property_8a81e8a6d963f384bddf6e75ec8e0a1c_Out_0 = Vector4_1696EE66;
            float _Split_f72e1ad87d56df8ba34ec31e2bc432b8_R_1 = _Property_8a81e8a6d963f384bddf6e75ec8e0a1c_Out_0[0];
            float _Split_f72e1ad87d56df8ba34ec31e2bc432b8_G_2 = _Property_8a81e8a6d963f384bddf6e75ec8e0a1c_Out_0[1];
            float _Split_f72e1ad87d56df8ba34ec31e2bc432b8_B_3 = _Property_8a81e8a6d963f384bddf6e75ec8e0a1c_Out_0[2];
            float _Split_f72e1ad87d56df8ba34ec31e2bc432b8_A_4 = _Property_8a81e8a6d963f384bddf6e75ec8e0a1c_Out_0[3];
            float4 _Combine_aeef4bbea8acc688b198e488208172f2_RGBA_4;
            float3 _Combine_aeef4bbea8acc688b198e488208172f2_RGB_5;
            float2 _Combine_aeef4bbea8acc688b198e488208172f2_RG_6;
            Unity_Combine_float(_Split_f72e1ad87d56df8ba34ec31e2bc432b8_R_1, _Split_f72e1ad87d56df8ba34ec31e2bc432b8_G_2, 0, 0, _Combine_aeef4bbea8acc688b198e488208172f2_RGBA_4, _Combine_aeef4bbea8acc688b198e488208172f2_RGB_5, _Combine_aeef4bbea8acc688b198e488208172f2_RG_6);
            float4 _Combine_feabe866dc39388d8ccd72275fb9be09_RGBA_4;
            float3 _Combine_feabe866dc39388d8ccd72275fb9be09_RGB_5;
            float2 _Combine_feabe866dc39388d8ccd72275fb9be09_RG_6;
            Unity_Combine_float(_Split_f72e1ad87d56df8ba34ec31e2bc432b8_B_3, _Split_f72e1ad87d56df8ba34ec31e2bc432b8_A_4, 0, 0, _Combine_feabe866dc39388d8ccd72275fb9be09_RGBA_4, _Combine_feabe866dc39388d8ccd72275fb9be09_RGB_5, _Combine_feabe866dc39388d8ccd72275fb9be09_RG_6);
            float _Remap_ca18d3412979f985809f3426d5282816_Out_3;
            Unity_Remap_float(_Power_abb6d235206009809ee431a98f2c8247_Out_2, _Combine_aeef4bbea8acc688b198e488208172f2_RG_6, _Combine_feabe866dc39388d8ccd72275fb9be09_RG_6, _Remap_ca18d3412979f985809f3426d5282816_Out_3);
            float _Absolute_01d69efb5b6b628b8142004f10302240_Out_1;
            Unity_Absolute_float(_Remap_ca18d3412979f985809f3426d5282816_Out_3, _Absolute_01d69efb5b6b628b8142004f10302240_Out_1);
            float _Smoothstep_5a0282a38f27848e9545f1e89a11f5a2_Out_3;
            Unity_Smoothstep_float(_Property_45fc02a5c65e898c82a51138ee7894c8_Out_0, _Property_423be2625737e5829e3daa7b3cf8389d_Out_0, _Absolute_01d69efb5b6b628b8142004f10302240_Out_1, _Smoothstep_5a0282a38f27848e9545f1e89a11f5a2_Out_3);
            float _Property_91482984669b1c8ab26a0f4a555b3801_Out_0 = Vector1_9058DE8C;
            float _Multiply_ad5811e4c08fae88a363e144af359987_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_91482984669b1c8ab26a0f4a555b3801_Out_0, _Multiply_ad5811e4c08fae88a363e144af359987_Out_2);
            float2 _TilingAndOffset_2345314be014258796bc32f9e66d2397_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_430e3c523bf85e84bdef451ab28beba0_Out_3.xy), float2 (1, 1), (_Multiply_ad5811e4c08fae88a363e144af359987_Out_2.xx), _TilingAndOffset_2345314be014258796bc32f9e66d2397_Out_3);
            float _Property_a13e388a84b18e89afce2f9f3ca9753f_Out_0 = Vector1_5536221E;
            float _GradientNoise_9f2e5d10ed34688f87f30e9a171b1f8b_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_2345314be014258796bc32f9e66d2397_Out_3, _Property_a13e388a84b18e89afce2f9f3ca9753f_Out_0, _GradientNoise_9f2e5d10ed34688f87f30e9a171b1f8b_Out_2);
            float _Property_b64fda08fa35398f9e0f45e316a434f9_Out_0 = Vector1_350643F1;
            float _Multiply_d03d0c5bc6770f8b8fbb46ec0c06b35b_Out_2;
            Unity_Multiply_float(_GradientNoise_9f2e5d10ed34688f87f30e9a171b1f8b_Out_2, _Property_b64fda08fa35398f9e0f45e316a434f9_Out_0, _Multiply_d03d0c5bc6770f8b8fbb46ec0c06b35b_Out_2);
            float _Add_f031b6931be259898e2d889c851d36d5_Out_2;
            Unity_Add_float(_Smoothstep_5a0282a38f27848e9545f1e89a11f5a2_Out_3, _Multiply_d03d0c5bc6770f8b8fbb46ec0c06b35b_Out_2, _Add_f031b6931be259898e2d889c851d36d5_Out_2);
            float _Add_e1b7452d2644ef8e96d652df6def6989_Out_2;
            Unity_Add_float(1, _Property_b64fda08fa35398f9e0f45e316a434f9_Out_0, _Add_e1b7452d2644ef8e96d652df6def6989_Out_2);
            float _Divide_b34aaac0718e8682bb2ab66e45d42421_Out_2;
            Unity_Divide_float(_Add_f031b6931be259898e2d889c851d36d5_Out_2, _Add_e1b7452d2644ef8e96d652df6def6989_Out_2, _Divide_b34aaac0718e8682bb2ab66e45d42421_Out_2);
            float4 _Lerp_0f05ab7309374f869f26c5de63c7685d_Out_3;
            Unity_Lerp_float4(_Property_8602b260fe5c06829b7738349464dbbc_Out_0, _Property_db73cd07c4394c82a6cd028523c127f3_Out_0, (_Divide_b34aaac0718e8682bb2ab66e45d42421_Out_2.xxxx), _Lerp_0f05ab7309374f869f26c5de63c7685d_Out_3);
            float _Property_0e672fb430de1988a91ebab3a6c55a4b_Out_0 = Vector1_B4ED823D;
            float _FresnelEffect_d3463b04b6387381ae221b6b9fda5a55_Out_3;
            Unity_FresnelEffect_float(IN.WorldSpaceNormal, IN.WorldSpaceViewDirection, _Property_0e672fb430de1988a91ebab3a6c55a4b_Out_0, _FresnelEffect_d3463b04b6387381ae221b6b9fda5a55_Out_3);
            float _Multiply_b1b397b5458b168183311fa585ce24cc_Out_2;
            Unity_Multiply_float(_Divide_b34aaac0718e8682bb2ab66e45d42421_Out_2, _FresnelEffect_d3463b04b6387381ae221b6b9fda5a55_Out_3, _Multiply_b1b397b5458b168183311fa585ce24cc_Out_2);
            float _Property_a0d7e69c6b484186aed4c837b9cfdf60_Out_0 = Vector1_2BA361A8;
            float _Multiply_c527b7ae93e59a82a8b685490472d140_Out_2;
            Unity_Multiply_float(_Multiply_b1b397b5458b168183311fa585ce24cc_Out_2, _Property_a0d7e69c6b484186aed4c837b9cfdf60_Out_0, _Multiply_c527b7ae93e59a82a8b685490472d140_Out_2);
            float4 _Add_e90a39812292588185bb8af6f98ac6ed_Out_2;
            Unity_Add_float4(_Lerp_0f05ab7309374f869f26c5de63c7685d_Out_3, (_Multiply_c527b7ae93e59a82a8b685490472d140_Out_2.xxxx), _Add_e90a39812292588185bb8af6f98ac6ed_Out_2);
            float _Property_2b5ded79d5faa287bcd134d3931fddbd_Out_0 = Vector1_2A80C598;
            float4 _Multiply_89abd19f1abd878f9e4e10491d20220d_Out_2;
            Unity_Multiply_float(_Add_e90a39812292588185bb8af6f98ac6ed_Out_2, (_Property_2b5ded79d5faa287bcd134d3931fddbd_Out_0.xxxx), _Multiply_89abd19f1abd878f9e4e10491d20220d_Out_2);
            float _SceneDepth_845bf60653d70482b562a739512eeda7_Out_1;
            Unity_SceneDepth_Eye_float(float4(IN.ScreenPosition.xy / IN.ScreenPosition.w, 0, 0), _SceneDepth_845bf60653d70482b562a739512eeda7_Out_1);
            float4 _ScreenPosition_b978995ebe1ba286935416b2a2d5cb85_Out_0 = IN.ScreenPosition;
            float _Split_c66584edb0487b8e8c2e107a89ed8e9f_R_1 = _ScreenPosition_b978995ebe1ba286935416b2a2d5cb85_Out_0[0];
            float _Split_c66584edb0487b8e8c2e107a89ed8e9f_G_2 = _ScreenPosition_b978995ebe1ba286935416b2a2d5cb85_Out_0[1];
            float _Split_c66584edb0487b8e8c2e107a89ed8e9f_B_3 = _ScreenPosition_b978995ebe1ba286935416b2a2d5cb85_Out_0[2];
            float _Split_c66584edb0487b8e8c2e107a89ed8e9f_A_4 = _ScreenPosition_b978995ebe1ba286935416b2a2d5cb85_Out_0[3];
            float _Subtract_39fffd64ebdafb84a6eb8e37e2faaa16_Out_2;
            Unity_Subtract_float(_Split_c66584edb0487b8e8c2e107a89ed8e9f_A_4, 1, _Subtract_39fffd64ebdafb84a6eb8e37e2faaa16_Out_2);
            float _Subtract_d8ff2e79b2fc8386b6172daebbe97366_Out_2;
            Unity_Subtract_float(_SceneDepth_845bf60653d70482b562a739512eeda7_Out_1, _Subtract_39fffd64ebdafb84a6eb8e37e2faaa16_Out_2, _Subtract_d8ff2e79b2fc8386b6172daebbe97366_Out_2);
            float _Property_0a2887e34569358bbc9cbee1a14acebb_Out_0 = Vector1_EED1A887;
            float _Divide_f3ff43869c02038db823cf0d91c23caf_Out_2;
            Unity_Divide_float(_Subtract_d8ff2e79b2fc8386b6172daebbe97366_Out_2, _Property_0a2887e34569358bbc9cbee1a14acebb_Out_0, _Divide_f3ff43869c02038db823cf0d91c23caf_Out_2);
            float _Saturate_676d84ccc0f0b88e9d1fdf263cfcf1d5_Out_1;
            Unity_Saturate_float(_Divide_f3ff43869c02038db823cf0d91c23caf_Out_2, _Saturate_676d84ccc0f0b88e9d1fdf263cfcf1d5_Out_1);
            float _Smoothstep_edf634d16c75cd829225bfca563f83fb_Out_3;
            Unity_Smoothstep_float(0, 1, _Saturate_676d84ccc0f0b88e9d1fdf263cfcf1d5_Out_1, _Smoothstep_edf634d16c75cd829225bfca563f83fb_Out_3);
            surface.BaseColor = IsGammaSpace() ? float3(0, 0, 0) : SRGBToLinear(float3(0, 0, 0));
            surface.NormalTS = IN.TangentSpaceNormal;
            surface.Emission = (_Multiply_89abd19f1abd878f9e4e10491d20220d_Out_2.xyz);
            surface.Metallic = 0;
            surface.Smoothness = 0.5;
            surface.Occlusion = 1;
            surface.Alpha = _Smoothstep_edf634d16c75cd829225bfca563f83fb_Out_3;
            return surface;
        }

            // --------------------------------------------------
            // Build Graph Inputs

            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);

            output.ObjectSpaceNormal =           input.normalOS;
            output.WorldSpaceNormal =            TransformObjectToWorldNormal(input.normalOS);
            output.ObjectSpaceTangent =          input.tangentOS.xyz;
            output.ObjectSpacePosition =         input.positionOS;
            output.WorldSpacePosition =          TransformObjectToWorld(input.positionOS);
            output.TimeParameters =              _TimeParameters.xyz;

            return output;
        }
            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);

        	// must use interpolated tangent, bitangent and normal before they are normalized in the pixel shader.
        	float3 unnormalizedNormalWS = input.normalWS;
            const float renormFactor = 1.0 / length(unnormalizedNormalWS);


            output.WorldSpaceNormal =            renormFactor*input.normalWS.xyz;		// we want a unit length Normal Vector node in shader graph
            output.TangentSpaceNormal =          float3(0.0f, 0.0f, 1.0f);


            output.WorldSpaceViewDirection =     input.viewDirectionWS; //TODO: by default normalized in HD, but not in universal
            output.WorldSpacePosition =          input.positionWS;
            output.ScreenPosition =              ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
            output.TimeParameters =              _TimeParameters.xyz; // This is mainly for LW as HD overwrite this value
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

            return output;
        }

            // --------------------------------------------------
            // Main

            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/PBRForwardPass.hlsl"

            ENDHLSL
        }
        Pass
        {
            Name "ShadowCaster"
            Tags
            {
                "LightMode" = "ShadowCaster"
            }

            // Render State
            Cull Back
        Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
        ZTest LEqual
        ZWrite On
        ColorMask 0

            // Debug
            // <None>

            // --------------------------------------------------
            // Pass

            HLSLPROGRAM

            // Pragmas
            #pragma target 2.0
        #pragma only_renderers gles gles3 glcore d3d11
        #pragma multi_compile_instancing
        #pragma vertex vert
        #pragma fragment frag

            // DotsInstancingOptions: <None>
            // HybridV1InjectedBuiltinProperties: <None>

            // Keywords
            // PassKeywords: <None>
            // GraphKeywords: <None>

            // Defines
            #define _SURFACE_TYPE_TRANSPARENT 1
            #define _NORMALMAP 1
            #define _NORMAL_DROPOFF_TS 1
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define VARYINGS_NEED_POSITION_WS
            #define FEATURES_GRAPH_VERTEX
            /* WARNING: $splice Could not find named fragment 'PassInstancing' */
            #define SHADERPASS SHADERPASS_SHADOWCASTER
        #define REQUIRE_DEPTH_TEXTURE
            /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

            // --------------------------------------------------
            // Structs and Packing

            struct Attributes
        {
            float3 positionOS : POSITION;
            float3 normalOS : NORMAL;
            float4 tangentOS : TANGENT;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
            float4 positionCS : SV_POSITION;
            float3 positionWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
            float3 WorldSpacePosition;
            float4 ScreenPosition;
        };
        struct VertexDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 WorldSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 ObjectSpacePosition;
            float3 WorldSpacePosition;
            float3 TimeParameters;
        };
        struct PackedVaryings
        {
            float4 positionCS : SV_POSITION;
            float3 interp0 : TEXCOORD0;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };

            PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }

            // --------------------------------------------------
            // Graph

            // Graph Properties
            CBUFFER_START(UnityPerMaterial)
        float4 Vector4_484BA326;
        float Vector1_8F075DBC;
        float Vector1_8AAD665C;
        float Vector1_E43D3892;
        float4 Vector4_1696EE66;
        float4 Color_2CFB5E2A;
        float4 Color_58195353;
        float Vector1_FADC0395;
        float Vector1_E505CA4B;
        float Vector1_4CE104D9;
        float Vector1_5536221E;
        float Vector1_9058DE8C;
        float Vector1_350643F1;
        float Vector1_2A80C598;
        float Vector1_A664731F;
        float Vector1_B4ED823D;
        float Vector1_2BA361A8;
        float Vector1_EED1A887;
        CBUFFER_END

        // Object and Global properties

            // Graph Functions
            
        void Unity_Distance_float3(float3 A, float3 B, out float Out)
        {
            Out = distance(A, B);
        }

        void Unity_Divide_float(float A, float B, out float Out)
        {
            Out = A / B;
        }

        void Unity_Power_float(float A, float B, out float Out)
        {
            Out = pow(A, B);
        }

        void Unity_Multiply_float(float3 A, float3 B, out float3 Out)
        {
            Out = A * B;
        }

        void Unity_Rotate_About_Axis_Degrees_float(float3 In, float3 Axis, float Rotation, out float3 Out)
        {
            Rotation = radians(Rotation);

            float s = sin(Rotation);
            float c = cos(Rotation);
            float one_minus_c = 1.0 - c;
            
            Axis = normalize(Axis);

            float3x3 rot_mat = { one_minus_c * Axis.x * Axis.x + c,            one_minus_c * Axis.x * Axis.y - Axis.z * s,     one_minus_c * Axis.z * Axis.x + Axis.y * s,
                                      one_minus_c * Axis.x * Axis.y + Axis.z * s,   one_minus_c * Axis.y * Axis.y + c,              one_minus_c * Axis.y * Axis.z - Axis.x * s,
                                      one_minus_c * Axis.z * Axis.x - Axis.y * s,   one_minus_c * Axis.y * Axis.z + Axis.x * s,     one_minus_c * Axis.z * Axis.z + c
                                    };

            Out = mul(rot_mat,  In);
        }

        void Unity_Multiply_float(float A, float B, out float Out)
        {
            Out = A * B;
        }

        void Unity_TilingAndOffset_float(float2 UV, float2 Tiling, float2 Offset, out float2 Out)
        {
            Out = UV * Tiling + Offset;
        }


        float2 Unity_GradientNoise_Dir_float(float2 p)
        {
            // Permutation and hashing used in webgl-nosie goo.gl/pX7HtC
            p = p % 289;
            // need full precision, otherwise half overflows when p > 1
            float x = float(34 * p.x + 1) * p.x % 289 + p.y;
            x = (34 * x + 1) * x % 289;
            x = frac(x / 41) * 2 - 1;
            return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
        }

        void Unity_GradientNoise_float(float2 UV, float Scale, out float Out)
        { 
            float2 p = UV * Scale;
            float2 ip = floor(p);
            float2 fp = frac(p);
            float d00 = dot(Unity_GradientNoise_Dir_float(ip), fp);
            float d01 = dot(Unity_GradientNoise_Dir_float(ip + float2(0, 1)), fp - float2(0, 1));
            float d10 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 0)), fp - float2(1, 0));
            float d11 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 1)), fp - float2(1, 1));
            fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
            Out = lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x) + 0.5;
        }

        void Unity_Add_float(float A, float B, out float Out)
        {
            Out = A + B;
        }

        void Unity_Saturate_float(float In, out float Out)
        {
            Out = saturate(In);
        }

        void Unity_Combine_float(float R, float G, float B, float A, out float4 RGBA, out float3 RGB, out float2 RG)
        {
            RGBA = float4(R, G, B, A);
            RGB = float3(R, G, B);
            RG = float2(R, G);
        }

        void Unity_Remap_float(float In, float2 InMinMax, float2 OutMinMax, out float Out)
        {
            Out = OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
        }

        void Unity_Absolute_float(float In, out float Out)
        {
            Out = abs(In);
        }

        void Unity_Smoothstep_float(float Edge1, float Edge2, float In, out float Out)
        {
            Out = smoothstep(Edge1, Edge2, In);
        }

        void Unity_Add_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A + B;
        }

        void Unity_SceneDepth_Eye_float(float4 UV, out float Out)
        {
            Out = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH(UV.xy), _ZBufferParams);
        }

        void Unity_Subtract_float(float A, float B, out float Out)
        {
            Out = A - B;
        }

            // Graph Vertex
            struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };

        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            float _Distance_474c9e8e982c878dad2f0d5844b22ee9_Out_2;
            Unity_Distance_float3(SHADERGRAPH_OBJECT_POSITION, IN.WorldSpacePosition, _Distance_474c9e8e982c878dad2f0d5844b22ee9_Out_2);
            float _Property_95b6af28bf5d388fb7809e99d4ea7a10_Out_0 = Vector1_A664731F;
            float _Divide_2022c703e9e6de87965706bd214b7b67_Out_2;
            Unity_Divide_float(_Distance_474c9e8e982c878dad2f0d5844b22ee9_Out_2, _Property_95b6af28bf5d388fb7809e99d4ea7a10_Out_0, _Divide_2022c703e9e6de87965706bd214b7b67_Out_2);
            float _Power_8710b3fb1efe3183a2818b946e662a1e_Out_2;
            Unity_Power_float(_Divide_2022c703e9e6de87965706bd214b7b67_Out_2, 3, _Power_8710b3fb1efe3183a2818b946e662a1e_Out_2);
            float3 _Multiply_3fa32f2d7f56688684a8f5b0a0853be5_Out_2;
            Unity_Multiply_float(IN.WorldSpaceNormal, (_Power_8710b3fb1efe3183a2818b946e662a1e_Out_2.xxx), _Multiply_3fa32f2d7f56688684a8f5b0a0853be5_Out_2);
            float _Property_45fc02a5c65e898c82a51138ee7894c8_Out_0 = Vector1_FADC0395;
            float _Property_423be2625737e5829e3daa7b3cf8389d_Out_0 = Vector1_E505CA4B;
            float4 _Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0 = Vector4_484BA326;
            float _Split_e9324c176bf05a809ea8df8c413a826a_R_1 = _Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0[0];
            float _Split_e9324c176bf05a809ea8df8c413a826a_G_2 = _Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0[1];
            float _Split_e9324c176bf05a809ea8df8c413a826a_B_3 = _Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0[2];
            float _Split_e9324c176bf05a809ea8df8c413a826a_A_4 = _Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0[3];
            float3 _RotateAboutAxis_430e3c523bf85e84bdef451ab28beba0_Out_3;
            Unity_Rotate_About_Axis_Degrees_float(IN.WorldSpacePosition, (_Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0.xyz), _Split_e9324c176bf05a809ea8df8c413a826a_A_4, _RotateAboutAxis_430e3c523bf85e84bdef451ab28beba0_Out_3);
            float _Property_84dca49c8958708fac3276b0de15a6da_Out_0 = Vector1_8AAD665C;
            float _Multiply_89f92af49e152081ba549c92ab002e9c_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_84dca49c8958708fac3276b0de15a6da_Out_0, _Multiply_89f92af49e152081ba549c92ab002e9c_Out_2);
            float2 _TilingAndOffset_bd9fc632c3a6c185b226f93212ed8603_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_430e3c523bf85e84bdef451ab28beba0_Out_3.xy), float2 (1, 1), (_Multiply_89f92af49e152081ba549c92ab002e9c_Out_2.xx), _TilingAndOffset_bd9fc632c3a6c185b226f93212ed8603_Out_3);
            float _Property_f7111fce9be08b8c871514ffc219f648_Out_0 = Vector1_8F075DBC;
            float _GradientNoise_de42ec7fdd52ec8fa0b6cb7f34842c13_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_bd9fc632c3a6c185b226f93212ed8603_Out_3, _Property_f7111fce9be08b8c871514ffc219f648_Out_0, _GradientNoise_de42ec7fdd52ec8fa0b6cb7f34842c13_Out_2);
            float2 _TilingAndOffset_aa88c06674f4178889e657a2bb46c454_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_430e3c523bf85e84bdef451ab28beba0_Out_3.xy), float2 (1, 1), float2 (0, 0), _TilingAndOffset_aa88c06674f4178889e657a2bb46c454_Out_3);
            float _GradientNoise_28996fa0f6fbd08c97ed18d0621900b5_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_aa88c06674f4178889e657a2bb46c454_Out_3, _Property_f7111fce9be08b8c871514ffc219f648_Out_0, _GradientNoise_28996fa0f6fbd08c97ed18d0621900b5_Out_2);
            float _Add_caf5f972abacae878d9a6fde10e0986a_Out_2;
            Unity_Add_float(_GradientNoise_de42ec7fdd52ec8fa0b6cb7f34842c13_Out_2, _GradientNoise_28996fa0f6fbd08c97ed18d0621900b5_Out_2, _Add_caf5f972abacae878d9a6fde10e0986a_Out_2);
            float _Divide_27ef561e54cd208ca89512269c1d4d03_Out_2;
            Unity_Divide_float(_Add_caf5f972abacae878d9a6fde10e0986a_Out_2, 2, _Divide_27ef561e54cd208ca89512269c1d4d03_Out_2);
            float _Saturate_c56694103011198486afa78b0e89ec2c_Out_1;
            Unity_Saturate_float(_Divide_27ef561e54cd208ca89512269c1d4d03_Out_2, _Saturate_c56694103011198486afa78b0e89ec2c_Out_1);
            float _Property_8bd1d491d3050588a0b837b4b232170d_Out_0 = Vector1_4CE104D9;
            float _Power_abb6d235206009809ee431a98f2c8247_Out_2;
            Unity_Power_float(_Saturate_c56694103011198486afa78b0e89ec2c_Out_1, _Property_8bd1d491d3050588a0b837b4b232170d_Out_0, _Power_abb6d235206009809ee431a98f2c8247_Out_2);
            float4 _Property_8a81e8a6d963f384bddf6e75ec8e0a1c_Out_0 = Vector4_1696EE66;
            float _Split_f72e1ad87d56df8ba34ec31e2bc432b8_R_1 = _Property_8a81e8a6d963f384bddf6e75ec8e0a1c_Out_0[0];
            float _Split_f72e1ad87d56df8ba34ec31e2bc432b8_G_2 = _Property_8a81e8a6d963f384bddf6e75ec8e0a1c_Out_0[1];
            float _Split_f72e1ad87d56df8ba34ec31e2bc432b8_B_3 = _Property_8a81e8a6d963f384bddf6e75ec8e0a1c_Out_0[2];
            float _Split_f72e1ad87d56df8ba34ec31e2bc432b8_A_4 = _Property_8a81e8a6d963f384bddf6e75ec8e0a1c_Out_0[3];
            float4 _Combine_aeef4bbea8acc688b198e488208172f2_RGBA_4;
            float3 _Combine_aeef4bbea8acc688b198e488208172f2_RGB_5;
            float2 _Combine_aeef4bbea8acc688b198e488208172f2_RG_6;
            Unity_Combine_float(_Split_f72e1ad87d56df8ba34ec31e2bc432b8_R_1, _Split_f72e1ad87d56df8ba34ec31e2bc432b8_G_2, 0, 0, _Combine_aeef4bbea8acc688b198e488208172f2_RGBA_4, _Combine_aeef4bbea8acc688b198e488208172f2_RGB_5, _Combine_aeef4bbea8acc688b198e488208172f2_RG_6);
            float4 _Combine_feabe866dc39388d8ccd72275fb9be09_RGBA_4;
            float3 _Combine_feabe866dc39388d8ccd72275fb9be09_RGB_5;
            float2 _Combine_feabe866dc39388d8ccd72275fb9be09_RG_6;
            Unity_Combine_float(_Split_f72e1ad87d56df8ba34ec31e2bc432b8_B_3, _Split_f72e1ad87d56df8ba34ec31e2bc432b8_A_4, 0, 0, _Combine_feabe866dc39388d8ccd72275fb9be09_RGBA_4, _Combine_feabe866dc39388d8ccd72275fb9be09_RGB_5, _Combine_feabe866dc39388d8ccd72275fb9be09_RG_6);
            float _Remap_ca18d3412979f985809f3426d5282816_Out_3;
            Unity_Remap_float(_Power_abb6d235206009809ee431a98f2c8247_Out_2, _Combine_aeef4bbea8acc688b198e488208172f2_RG_6, _Combine_feabe866dc39388d8ccd72275fb9be09_RG_6, _Remap_ca18d3412979f985809f3426d5282816_Out_3);
            float _Absolute_01d69efb5b6b628b8142004f10302240_Out_1;
            Unity_Absolute_float(_Remap_ca18d3412979f985809f3426d5282816_Out_3, _Absolute_01d69efb5b6b628b8142004f10302240_Out_1);
            float _Smoothstep_5a0282a38f27848e9545f1e89a11f5a2_Out_3;
            Unity_Smoothstep_float(_Property_45fc02a5c65e898c82a51138ee7894c8_Out_0, _Property_423be2625737e5829e3daa7b3cf8389d_Out_0, _Absolute_01d69efb5b6b628b8142004f10302240_Out_1, _Smoothstep_5a0282a38f27848e9545f1e89a11f5a2_Out_3);
            float _Property_91482984669b1c8ab26a0f4a555b3801_Out_0 = Vector1_9058DE8C;
            float _Multiply_ad5811e4c08fae88a363e144af359987_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_91482984669b1c8ab26a0f4a555b3801_Out_0, _Multiply_ad5811e4c08fae88a363e144af359987_Out_2);
            float2 _TilingAndOffset_2345314be014258796bc32f9e66d2397_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_430e3c523bf85e84bdef451ab28beba0_Out_3.xy), float2 (1, 1), (_Multiply_ad5811e4c08fae88a363e144af359987_Out_2.xx), _TilingAndOffset_2345314be014258796bc32f9e66d2397_Out_3);
            float _Property_a13e388a84b18e89afce2f9f3ca9753f_Out_0 = Vector1_5536221E;
            float _GradientNoise_9f2e5d10ed34688f87f30e9a171b1f8b_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_2345314be014258796bc32f9e66d2397_Out_3, _Property_a13e388a84b18e89afce2f9f3ca9753f_Out_0, _GradientNoise_9f2e5d10ed34688f87f30e9a171b1f8b_Out_2);
            float _Property_b64fda08fa35398f9e0f45e316a434f9_Out_0 = Vector1_350643F1;
            float _Multiply_d03d0c5bc6770f8b8fbb46ec0c06b35b_Out_2;
            Unity_Multiply_float(_GradientNoise_9f2e5d10ed34688f87f30e9a171b1f8b_Out_2, _Property_b64fda08fa35398f9e0f45e316a434f9_Out_0, _Multiply_d03d0c5bc6770f8b8fbb46ec0c06b35b_Out_2);
            float _Add_f031b6931be259898e2d889c851d36d5_Out_2;
            Unity_Add_float(_Smoothstep_5a0282a38f27848e9545f1e89a11f5a2_Out_3, _Multiply_d03d0c5bc6770f8b8fbb46ec0c06b35b_Out_2, _Add_f031b6931be259898e2d889c851d36d5_Out_2);
            float _Add_e1b7452d2644ef8e96d652df6def6989_Out_2;
            Unity_Add_float(1, _Property_b64fda08fa35398f9e0f45e316a434f9_Out_0, _Add_e1b7452d2644ef8e96d652df6def6989_Out_2);
            float _Divide_b34aaac0718e8682bb2ab66e45d42421_Out_2;
            Unity_Divide_float(_Add_f031b6931be259898e2d889c851d36d5_Out_2, _Add_e1b7452d2644ef8e96d652df6def6989_Out_2, _Divide_b34aaac0718e8682bb2ab66e45d42421_Out_2);
            float3 _Multiply_a97d25c025f47f8fa4cfe3267dee485e_Out_2;
            Unity_Multiply_float(IN.ObjectSpaceNormal, (_Divide_b34aaac0718e8682bb2ab66e45d42421_Out_2.xxx), _Multiply_a97d25c025f47f8fa4cfe3267dee485e_Out_2);
            float _Property_6f2976fe72816a869d8677a4230164f0_Out_0 = Vector1_E43D3892;
            float3 _Multiply_08ef8c8995ef448a9ab1e43028223a19_Out_2;
            Unity_Multiply_float(_Multiply_a97d25c025f47f8fa4cfe3267dee485e_Out_2, (_Property_6f2976fe72816a869d8677a4230164f0_Out_0.xxx), _Multiply_08ef8c8995ef448a9ab1e43028223a19_Out_2);
            float3 _Add_ec1431816c726e8a827bfd7e7de3d614_Out_2;
            Unity_Add_float3(IN.ObjectSpacePosition, _Multiply_08ef8c8995ef448a9ab1e43028223a19_Out_2, _Add_ec1431816c726e8a827bfd7e7de3d614_Out_2);
            float3 _Add_cbfa9591f076e485a31b7f5b967f99f6_Out_2;
            Unity_Add_float3(_Multiply_3fa32f2d7f56688684a8f5b0a0853be5_Out_2, _Add_ec1431816c726e8a827bfd7e7de3d614_Out_2, _Add_cbfa9591f076e485a31b7f5b967f99f6_Out_2);
            description.Position = _Add_cbfa9591f076e485a31b7f5b967f99f6_Out_2;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }

            // Graph Pixel
            struct SurfaceDescription
        {
            float Alpha;
        };

        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            float _SceneDepth_845bf60653d70482b562a739512eeda7_Out_1;
            Unity_SceneDepth_Eye_float(float4(IN.ScreenPosition.xy / IN.ScreenPosition.w, 0, 0), _SceneDepth_845bf60653d70482b562a739512eeda7_Out_1);
            float4 _ScreenPosition_b978995ebe1ba286935416b2a2d5cb85_Out_0 = IN.ScreenPosition;
            float _Split_c66584edb0487b8e8c2e107a89ed8e9f_R_1 = _ScreenPosition_b978995ebe1ba286935416b2a2d5cb85_Out_0[0];
            float _Split_c66584edb0487b8e8c2e107a89ed8e9f_G_2 = _ScreenPosition_b978995ebe1ba286935416b2a2d5cb85_Out_0[1];
            float _Split_c66584edb0487b8e8c2e107a89ed8e9f_B_3 = _ScreenPosition_b978995ebe1ba286935416b2a2d5cb85_Out_0[2];
            float _Split_c66584edb0487b8e8c2e107a89ed8e9f_A_4 = _ScreenPosition_b978995ebe1ba286935416b2a2d5cb85_Out_0[3];
            float _Subtract_39fffd64ebdafb84a6eb8e37e2faaa16_Out_2;
            Unity_Subtract_float(_Split_c66584edb0487b8e8c2e107a89ed8e9f_A_4, 1, _Subtract_39fffd64ebdafb84a6eb8e37e2faaa16_Out_2);
            float _Subtract_d8ff2e79b2fc8386b6172daebbe97366_Out_2;
            Unity_Subtract_float(_SceneDepth_845bf60653d70482b562a739512eeda7_Out_1, _Subtract_39fffd64ebdafb84a6eb8e37e2faaa16_Out_2, _Subtract_d8ff2e79b2fc8386b6172daebbe97366_Out_2);
            float _Property_0a2887e34569358bbc9cbee1a14acebb_Out_0 = Vector1_EED1A887;
            float _Divide_f3ff43869c02038db823cf0d91c23caf_Out_2;
            Unity_Divide_float(_Subtract_d8ff2e79b2fc8386b6172daebbe97366_Out_2, _Property_0a2887e34569358bbc9cbee1a14acebb_Out_0, _Divide_f3ff43869c02038db823cf0d91c23caf_Out_2);
            float _Saturate_676d84ccc0f0b88e9d1fdf263cfcf1d5_Out_1;
            Unity_Saturate_float(_Divide_f3ff43869c02038db823cf0d91c23caf_Out_2, _Saturate_676d84ccc0f0b88e9d1fdf263cfcf1d5_Out_1);
            float _Smoothstep_edf634d16c75cd829225bfca563f83fb_Out_3;
            Unity_Smoothstep_float(0, 1, _Saturate_676d84ccc0f0b88e9d1fdf263cfcf1d5_Out_1, _Smoothstep_edf634d16c75cd829225bfca563f83fb_Out_3);
            surface.Alpha = _Smoothstep_edf634d16c75cd829225bfca563f83fb_Out_3;
            return surface;
        }

            // --------------------------------------------------
            // Build Graph Inputs

            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);

            output.ObjectSpaceNormal =           input.normalOS;
            output.WorldSpaceNormal =            TransformObjectToWorldNormal(input.normalOS);
            output.ObjectSpaceTangent =          input.tangentOS.xyz;
            output.ObjectSpacePosition =         input.positionOS;
            output.WorldSpacePosition =          TransformObjectToWorld(input.positionOS);
            output.TimeParameters =              _TimeParameters.xyz;

            return output;
        }
            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);





            output.WorldSpacePosition =          input.positionWS;
            output.ScreenPosition =              ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

            return output;
        }

            // --------------------------------------------------
            // Main

            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShadowCasterPass.hlsl"

            ENDHLSL
        }
        Pass
        {
            Name "DepthOnly"
            Tags
            {
                "LightMode" = "DepthOnly"
            }

            // Render State
            Cull Back
        Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
        ZTest LEqual
        ZWrite On
        ColorMask 0

            // Debug
            // <None>

            // --------------------------------------------------
            // Pass

            HLSLPROGRAM

            // Pragmas
            #pragma target 2.0
        #pragma only_renderers gles gles3 glcore d3d11
        #pragma multi_compile_instancing
        #pragma vertex vert
        #pragma fragment frag

            // DotsInstancingOptions: <None>
            // HybridV1InjectedBuiltinProperties: <None>

            // Keywords
            // PassKeywords: <None>
            // GraphKeywords: <None>

            // Defines
            #define _SURFACE_TYPE_TRANSPARENT 1
            #define _NORMALMAP 1
            #define _NORMAL_DROPOFF_TS 1
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define VARYINGS_NEED_POSITION_WS
            #define FEATURES_GRAPH_VERTEX
            /* WARNING: $splice Could not find named fragment 'PassInstancing' */
            #define SHADERPASS SHADERPASS_DEPTHONLY
        #define REQUIRE_DEPTH_TEXTURE
            /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

            // --------------------------------------------------
            // Structs and Packing

            struct Attributes
        {
            float3 positionOS : POSITION;
            float3 normalOS : NORMAL;
            float4 tangentOS : TANGENT;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
            float4 positionCS : SV_POSITION;
            float3 positionWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
            float3 WorldSpacePosition;
            float4 ScreenPosition;
        };
        struct VertexDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 WorldSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 ObjectSpacePosition;
            float3 WorldSpacePosition;
            float3 TimeParameters;
        };
        struct PackedVaryings
        {
            float4 positionCS : SV_POSITION;
            float3 interp0 : TEXCOORD0;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };

            PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }

            // --------------------------------------------------
            // Graph

            // Graph Properties
            CBUFFER_START(UnityPerMaterial)
        float4 Vector4_484BA326;
        float Vector1_8F075DBC;
        float Vector1_8AAD665C;
        float Vector1_E43D3892;
        float4 Vector4_1696EE66;
        float4 Color_2CFB5E2A;
        float4 Color_58195353;
        float Vector1_FADC0395;
        float Vector1_E505CA4B;
        float Vector1_4CE104D9;
        float Vector1_5536221E;
        float Vector1_9058DE8C;
        float Vector1_350643F1;
        float Vector1_2A80C598;
        float Vector1_A664731F;
        float Vector1_B4ED823D;
        float Vector1_2BA361A8;
        float Vector1_EED1A887;
        CBUFFER_END

        // Object and Global properties

            // Graph Functions
            
        void Unity_Distance_float3(float3 A, float3 B, out float Out)
        {
            Out = distance(A, B);
        }

        void Unity_Divide_float(float A, float B, out float Out)
        {
            Out = A / B;
        }

        void Unity_Power_float(float A, float B, out float Out)
        {
            Out = pow(A, B);
        }

        void Unity_Multiply_float(float3 A, float3 B, out float3 Out)
        {
            Out = A * B;
        }

        void Unity_Rotate_About_Axis_Degrees_float(float3 In, float3 Axis, float Rotation, out float3 Out)
        {
            Rotation = radians(Rotation);

            float s = sin(Rotation);
            float c = cos(Rotation);
            float one_minus_c = 1.0 - c;
            
            Axis = normalize(Axis);

            float3x3 rot_mat = { one_minus_c * Axis.x * Axis.x + c,            one_minus_c * Axis.x * Axis.y - Axis.z * s,     one_minus_c * Axis.z * Axis.x + Axis.y * s,
                                      one_minus_c * Axis.x * Axis.y + Axis.z * s,   one_minus_c * Axis.y * Axis.y + c,              one_minus_c * Axis.y * Axis.z - Axis.x * s,
                                      one_minus_c * Axis.z * Axis.x - Axis.y * s,   one_minus_c * Axis.y * Axis.z + Axis.x * s,     one_minus_c * Axis.z * Axis.z + c
                                    };

            Out = mul(rot_mat,  In);
        }

        void Unity_Multiply_float(float A, float B, out float Out)
        {
            Out = A * B;
        }

        void Unity_TilingAndOffset_float(float2 UV, float2 Tiling, float2 Offset, out float2 Out)
        {
            Out = UV * Tiling + Offset;
        }


        float2 Unity_GradientNoise_Dir_float(float2 p)
        {
            // Permutation and hashing used in webgl-nosie goo.gl/pX7HtC
            p = p % 289;
            // need full precision, otherwise half overflows when p > 1
            float x = float(34 * p.x + 1) * p.x % 289 + p.y;
            x = (34 * x + 1) * x % 289;
            x = frac(x / 41) * 2 - 1;
            return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
        }

        void Unity_GradientNoise_float(float2 UV, float Scale, out float Out)
        { 
            float2 p = UV * Scale;
            float2 ip = floor(p);
            float2 fp = frac(p);
            float d00 = dot(Unity_GradientNoise_Dir_float(ip), fp);
            float d01 = dot(Unity_GradientNoise_Dir_float(ip + float2(0, 1)), fp - float2(0, 1));
            float d10 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 0)), fp - float2(1, 0));
            float d11 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 1)), fp - float2(1, 1));
            fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
            Out = lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x) + 0.5;
        }

        void Unity_Add_float(float A, float B, out float Out)
        {
            Out = A + B;
        }

        void Unity_Saturate_float(float In, out float Out)
        {
            Out = saturate(In);
        }

        void Unity_Combine_float(float R, float G, float B, float A, out float4 RGBA, out float3 RGB, out float2 RG)
        {
            RGBA = float4(R, G, B, A);
            RGB = float3(R, G, B);
            RG = float2(R, G);
        }

        void Unity_Remap_float(float In, float2 InMinMax, float2 OutMinMax, out float Out)
        {
            Out = OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
        }

        void Unity_Absolute_float(float In, out float Out)
        {
            Out = abs(In);
        }

        void Unity_Smoothstep_float(float Edge1, float Edge2, float In, out float Out)
        {
            Out = smoothstep(Edge1, Edge2, In);
        }

        void Unity_Add_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A + B;
        }

        void Unity_SceneDepth_Eye_float(float4 UV, out float Out)
        {
            Out = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH(UV.xy), _ZBufferParams);
        }

        void Unity_Subtract_float(float A, float B, out float Out)
        {
            Out = A - B;
        }

            // Graph Vertex
            struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };

        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            float _Distance_474c9e8e982c878dad2f0d5844b22ee9_Out_2;
            Unity_Distance_float3(SHADERGRAPH_OBJECT_POSITION, IN.WorldSpacePosition, _Distance_474c9e8e982c878dad2f0d5844b22ee9_Out_2);
            float _Property_95b6af28bf5d388fb7809e99d4ea7a10_Out_0 = Vector1_A664731F;
            float _Divide_2022c703e9e6de87965706bd214b7b67_Out_2;
            Unity_Divide_float(_Distance_474c9e8e982c878dad2f0d5844b22ee9_Out_2, _Property_95b6af28bf5d388fb7809e99d4ea7a10_Out_0, _Divide_2022c703e9e6de87965706bd214b7b67_Out_2);
            float _Power_8710b3fb1efe3183a2818b946e662a1e_Out_2;
            Unity_Power_float(_Divide_2022c703e9e6de87965706bd214b7b67_Out_2, 3, _Power_8710b3fb1efe3183a2818b946e662a1e_Out_2);
            float3 _Multiply_3fa32f2d7f56688684a8f5b0a0853be5_Out_2;
            Unity_Multiply_float(IN.WorldSpaceNormal, (_Power_8710b3fb1efe3183a2818b946e662a1e_Out_2.xxx), _Multiply_3fa32f2d7f56688684a8f5b0a0853be5_Out_2);
            float _Property_45fc02a5c65e898c82a51138ee7894c8_Out_0 = Vector1_FADC0395;
            float _Property_423be2625737e5829e3daa7b3cf8389d_Out_0 = Vector1_E505CA4B;
            float4 _Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0 = Vector4_484BA326;
            float _Split_e9324c176bf05a809ea8df8c413a826a_R_1 = _Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0[0];
            float _Split_e9324c176bf05a809ea8df8c413a826a_G_2 = _Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0[1];
            float _Split_e9324c176bf05a809ea8df8c413a826a_B_3 = _Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0[2];
            float _Split_e9324c176bf05a809ea8df8c413a826a_A_4 = _Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0[3];
            float3 _RotateAboutAxis_430e3c523bf85e84bdef451ab28beba0_Out_3;
            Unity_Rotate_About_Axis_Degrees_float(IN.WorldSpacePosition, (_Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0.xyz), _Split_e9324c176bf05a809ea8df8c413a826a_A_4, _RotateAboutAxis_430e3c523bf85e84bdef451ab28beba0_Out_3);
            float _Property_84dca49c8958708fac3276b0de15a6da_Out_0 = Vector1_8AAD665C;
            float _Multiply_89f92af49e152081ba549c92ab002e9c_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_84dca49c8958708fac3276b0de15a6da_Out_0, _Multiply_89f92af49e152081ba549c92ab002e9c_Out_2);
            float2 _TilingAndOffset_bd9fc632c3a6c185b226f93212ed8603_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_430e3c523bf85e84bdef451ab28beba0_Out_3.xy), float2 (1, 1), (_Multiply_89f92af49e152081ba549c92ab002e9c_Out_2.xx), _TilingAndOffset_bd9fc632c3a6c185b226f93212ed8603_Out_3);
            float _Property_f7111fce9be08b8c871514ffc219f648_Out_0 = Vector1_8F075DBC;
            float _GradientNoise_de42ec7fdd52ec8fa0b6cb7f34842c13_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_bd9fc632c3a6c185b226f93212ed8603_Out_3, _Property_f7111fce9be08b8c871514ffc219f648_Out_0, _GradientNoise_de42ec7fdd52ec8fa0b6cb7f34842c13_Out_2);
            float2 _TilingAndOffset_aa88c06674f4178889e657a2bb46c454_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_430e3c523bf85e84bdef451ab28beba0_Out_3.xy), float2 (1, 1), float2 (0, 0), _TilingAndOffset_aa88c06674f4178889e657a2bb46c454_Out_3);
            float _GradientNoise_28996fa0f6fbd08c97ed18d0621900b5_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_aa88c06674f4178889e657a2bb46c454_Out_3, _Property_f7111fce9be08b8c871514ffc219f648_Out_0, _GradientNoise_28996fa0f6fbd08c97ed18d0621900b5_Out_2);
            float _Add_caf5f972abacae878d9a6fde10e0986a_Out_2;
            Unity_Add_float(_GradientNoise_de42ec7fdd52ec8fa0b6cb7f34842c13_Out_2, _GradientNoise_28996fa0f6fbd08c97ed18d0621900b5_Out_2, _Add_caf5f972abacae878d9a6fde10e0986a_Out_2);
            float _Divide_27ef561e54cd208ca89512269c1d4d03_Out_2;
            Unity_Divide_float(_Add_caf5f972abacae878d9a6fde10e0986a_Out_2, 2, _Divide_27ef561e54cd208ca89512269c1d4d03_Out_2);
            float _Saturate_c56694103011198486afa78b0e89ec2c_Out_1;
            Unity_Saturate_float(_Divide_27ef561e54cd208ca89512269c1d4d03_Out_2, _Saturate_c56694103011198486afa78b0e89ec2c_Out_1);
            float _Property_8bd1d491d3050588a0b837b4b232170d_Out_0 = Vector1_4CE104D9;
            float _Power_abb6d235206009809ee431a98f2c8247_Out_2;
            Unity_Power_float(_Saturate_c56694103011198486afa78b0e89ec2c_Out_1, _Property_8bd1d491d3050588a0b837b4b232170d_Out_0, _Power_abb6d235206009809ee431a98f2c8247_Out_2);
            float4 _Property_8a81e8a6d963f384bddf6e75ec8e0a1c_Out_0 = Vector4_1696EE66;
            float _Split_f72e1ad87d56df8ba34ec31e2bc432b8_R_1 = _Property_8a81e8a6d963f384bddf6e75ec8e0a1c_Out_0[0];
            float _Split_f72e1ad87d56df8ba34ec31e2bc432b8_G_2 = _Property_8a81e8a6d963f384bddf6e75ec8e0a1c_Out_0[1];
            float _Split_f72e1ad87d56df8ba34ec31e2bc432b8_B_3 = _Property_8a81e8a6d963f384bddf6e75ec8e0a1c_Out_0[2];
            float _Split_f72e1ad87d56df8ba34ec31e2bc432b8_A_4 = _Property_8a81e8a6d963f384bddf6e75ec8e0a1c_Out_0[3];
            float4 _Combine_aeef4bbea8acc688b198e488208172f2_RGBA_4;
            float3 _Combine_aeef4bbea8acc688b198e488208172f2_RGB_5;
            float2 _Combine_aeef4bbea8acc688b198e488208172f2_RG_6;
            Unity_Combine_float(_Split_f72e1ad87d56df8ba34ec31e2bc432b8_R_1, _Split_f72e1ad87d56df8ba34ec31e2bc432b8_G_2, 0, 0, _Combine_aeef4bbea8acc688b198e488208172f2_RGBA_4, _Combine_aeef4bbea8acc688b198e488208172f2_RGB_5, _Combine_aeef4bbea8acc688b198e488208172f2_RG_6);
            float4 _Combine_feabe866dc39388d8ccd72275fb9be09_RGBA_4;
            float3 _Combine_feabe866dc39388d8ccd72275fb9be09_RGB_5;
            float2 _Combine_feabe866dc39388d8ccd72275fb9be09_RG_6;
            Unity_Combine_float(_Split_f72e1ad87d56df8ba34ec31e2bc432b8_B_3, _Split_f72e1ad87d56df8ba34ec31e2bc432b8_A_4, 0, 0, _Combine_feabe866dc39388d8ccd72275fb9be09_RGBA_4, _Combine_feabe866dc39388d8ccd72275fb9be09_RGB_5, _Combine_feabe866dc39388d8ccd72275fb9be09_RG_6);
            float _Remap_ca18d3412979f985809f3426d5282816_Out_3;
            Unity_Remap_float(_Power_abb6d235206009809ee431a98f2c8247_Out_2, _Combine_aeef4bbea8acc688b198e488208172f2_RG_6, _Combine_feabe866dc39388d8ccd72275fb9be09_RG_6, _Remap_ca18d3412979f985809f3426d5282816_Out_3);
            float _Absolute_01d69efb5b6b628b8142004f10302240_Out_1;
            Unity_Absolute_float(_Remap_ca18d3412979f985809f3426d5282816_Out_3, _Absolute_01d69efb5b6b628b8142004f10302240_Out_1);
            float _Smoothstep_5a0282a38f27848e9545f1e89a11f5a2_Out_3;
            Unity_Smoothstep_float(_Property_45fc02a5c65e898c82a51138ee7894c8_Out_0, _Property_423be2625737e5829e3daa7b3cf8389d_Out_0, _Absolute_01d69efb5b6b628b8142004f10302240_Out_1, _Smoothstep_5a0282a38f27848e9545f1e89a11f5a2_Out_3);
            float _Property_91482984669b1c8ab26a0f4a555b3801_Out_0 = Vector1_9058DE8C;
            float _Multiply_ad5811e4c08fae88a363e144af359987_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_91482984669b1c8ab26a0f4a555b3801_Out_0, _Multiply_ad5811e4c08fae88a363e144af359987_Out_2);
            float2 _TilingAndOffset_2345314be014258796bc32f9e66d2397_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_430e3c523bf85e84bdef451ab28beba0_Out_3.xy), float2 (1, 1), (_Multiply_ad5811e4c08fae88a363e144af359987_Out_2.xx), _TilingAndOffset_2345314be014258796bc32f9e66d2397_Out_3);
            float _Property_a13e388a84b18e89afce2f9f3ca9753f_Out_0 = Vector1_5536221E;
            float _GradientNoise_9f2e5d10ed34688f87f30e9a171b1f8b_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_2345314be014258796bc32f9e66d2397_Out_3, _Property_a13e388a84b18e89afce2f9f3ca9753f_Out_0, _GradientNoise_9f2e5d10ed34688f87f30e9a171b1f8b_Out_2);
            float _Property_b64fda08fa35398f9e0f45e316a434f9_Out_0 = Vector1_350643F1;
            float _Multiply_d03d0c5bc6770f8b8fbb46ec0c06b35b_Out_2;
            Unity_Multiply_float(_GradientNoise_9f2e5d10ed34688f87f30e9a171b1f8b_Out_2, _Property_b64fda08fa35398f9e0f45e316a434f9_Out_0, _Multiply_d03d0c5bc6770f8b8fbb46ec0c06b35b_Out_2);
            float _Add_f031b6931be259898e2d889c851d36d5_Out_2;
            Unity_Add_float(_Smoothstep_5a0282a38f27848e9545f1e89a11f5a2_Out_3, _Multiply_d03d0c5bc6770f8b8fbb46ec0c06b35b_Out_2, _Add_f031b6931be259898e2d889c851d36d5_Out_2);
            float _Add_e1b7452d2644ef8e96d652df6def6989_Out_2;
            Unity_Add_float(1, _Property_b64fda08fa35398f9e0f45e316a434f9_Out_0, _Add_e1b7452d2644ef8e96d652df6def6989_Out_2);
            float _Divide_b34aaac0718e8682bb2ab66e45d42421_Out_2;
            Unity_Divide_float(_Add_f031b6931be259898e2d889c851d36d5_Out_2, _Add_e1b7452d2644ef8e96d652df6def6989_Out_2, _Divide_b34aaac0718e8682bb2ab66e45d42421_Out_2);
            float3 _Multiply_a97d25c025f47f8fa4cfe3267dee485e_Out_2;
            Unity_Multiply_float(IN.ObjectSpaceNormal, (_Divide_b34aaac0718e8682bb2ab66e45d42421_Out_2.xxx), _Multiply_a97d25c025f47f8fa4cfe3267dee485e_Out_2);
            float _Property_6f2976fe72816a869d8677a4230164f0_Out_0 = Vector1_E43D3892;
            float3 _Multiply_08ef8c8995ef448a9ab1e43028223a19_Out_2;
            Unity_Multiply_float(_Multiply_a97d25c025f47f8fa4cfe3267dee485e_Out_2, (_Property_6f2976fe72816a869d8677a4230164f0_Out_0.xxx), _Multiply_08ef8c8995ef448a9ab1e43028223a19_Out_2);
            float3 _Add_ec1431816c726e8a827bfd7e7de3d614_Out_2;
            Unity_Add_float3(IN.ObjectSpacePosition, _Multiply_08ef8c8995ef448a9ab1e43028223a19_Out_2, _Add_ec1431816c726e8a827bfd7e7de3d614_Out_2);
            float3 _Add_cbfa9591f076e485a31b7f5b967f99f6_Out_2;
            Unity_Add_float3(_Multiply_3fa32f2d7f56688684a8f5b0a0853be5_Out_2, _Add_ec1431816c726e8a827bfd7e7de3d614_Out_2, _Add_cbfa9591f076e485a31b7f5b967f99f6_Out_2);
            description.Position = _Add_cbfa9591f076e485a31b7f5b967f99f6_Out_2;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }

            // Graph Pixel
            struct SurfaceDescription
        {
            float Alpha;
        };

        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            float _SceneDepth_845bf60653d70482b562a739512eeda7_Out_1;
            Unity_SceneDepth_Eye_float(float4(IN.ScreenPosition.xy / IN.ScreenPosition.w, 0, 0), _SceneDepth_845bf60653d70482b562a739512eeda7_Out_1);
            float4 _ScreenPosition_b978995ebe1ba286935416b2a2d5cb85_Out_0 = IN.ScreenPosition;
            float _Split_c66584edb0487b8e8c2e107a89ed8e9f_R_1 = _ScreenPosition_b978995ebe1ba286935416b2a2d5cb85_Out_0[0];
            float _Split_c66584edb0487b8e8c2e107a89ed8e9f_G_2 = _ScreenPosition_b978995ebe1ba286935416b2a2d5cb85_Out_0[1];
            float _Split_c66584edb0487b8e8c2e107a89ed8e9f_B_3 = _ScreenPosition_b978995ebe1ba286935416b2a2d5cb85_Out_0[2];
            float _Split_c66584edb0487b8e8c2e107a89ed8e9f_A_4 = _ScreenPosition_b978995ebe1ba286935416b2a2d5cb85_Out_0[3];
            float _Subtract_39fffd64ebdafb84a6eb8e37e2faaa16_Out_2;
            Unity_Subtract_float(_Split_c66584edb0487b8e8c2e107a89ed8e9f_A_4, 1, _Subtract_39fffd64ebdafb84a6eb8e37e2faaa16_Out_2);
            float _Subtract_d8ff2e79b2fc8386b6172daebbe97366_Out_2;
            Unity_Subtract_float(_SceneDepth_845bf60653d70482b562a739512eeda7_Out_1, _Subtract_39fffd64ebdafb84a6eb8e37e2faaa16_Out_2, _Subtract_d8ff2e79b2fc8386b6172daebbe97366_Out_2);
            float _Property_0a2887e34569358bbc9cbee1a14acebb_Out_0 = Vector1_EED1A887;
            float _Divide_f3ff43869c02038db823cf0d91c23caf_Out_2;
            Unity_Divide_float(_Subtract_d8ff2e79b2fc8386b6172daebbe97366_Out_2, _Property_0a2887e34569358bbc9cbee1a14acebb_Out_0, _Divide_f3ff43869c02038db823cf0d91c23caf_Out_2);
            float _Saturate_676d84ccc0f0b88e9d1fdf263cfcf1d5_Out_1;
            Unity_Saturate_float(_Divide_f3ff43869c02038db823cf0d91c23caf_Out_2, _Saturate_676d84ccc0f0b88e9d1fdf263cfcf1d5_Out_1);
            float _Smoothstep_edf634d16c75cd829225bfca563f83fb_Out_3;
            Unity_Smoothstep_float(0, 1, _Saturate_676d84ccc0f0b88e9d1fdf263cfcf1d5_Out_1, _Smoothstep_edf634d16c75cd829225bfca563f83fb_Out_3);
            surface.Alpha = _Smoothstep_edf634d16c75cd829225bfca563f83fb_Out_3;
            return surface;
        }

            // --------------------------------------------------
            // Build Graph Inputs

            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);

            output.ObjectSpaceNormal =           input.normalOS;
            output.WorldSpaceNormal =            TransformObjectToWorldNormal(input.normalOS);
            output.ObjectSpaceTangent =          input.tangentOS.xyz;
            output.ObjectSpacePosition =         input.positionOS;
            output.WorldSpacePosition =          TransformObjectToWorld(input.positionOS);
            output.TimeParameters =              _TimeParameters.xyz;

            return output;
        }
            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);





            output.WorldSpacePosition =          input.positionWS;
            output.ScreenPosition =              ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

            return output;
        }

            // --------------------------------------------------
            // Main

            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/DepthOnlyPass.hlsl"

            ENDHLSL
        }
        Pass
        {
            Name "DepthNormals"
            Tags
            {
                "LightMode" = "DepthNormals"
            }

            // Render State
            Cull Back
        Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
        ZTest LEqual
        ZWrite On

            // Debug
            // <None>

            // --------------------------------------------------
            // Pass

            HLSLPROGRAM

            // Pragmas
            #pragma target 2.0
        #pragma only_renderers gles gles3 glcore d3d11
        #pragma multi_compile_instancing
        #pragma vertex vert
        #pragma fragment frag

            // DotsInstancingOptions: <None>
            // HybridV1InjectedBuiltinProperties: <None>

            // Keywords
            // PassKeywords: <None>
            // GraphKeywords: <None>

            // Defines
            #define _SURFACE_TYPE_TRANSPARENT 1
            #define _NORMALMAP 1
            #define _NORMAL_DROPOFF_TS 1
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define ATTRIBUTES_NEED_TEXCOORD1
            #define VARYINGS_NEED_POSITION_WS
            #define VARYINGS_NEED_NORMAL_WS
            #define VARYINGS_NEED_TANGENT_WS
            #define FEATURES_GRAPH_VERTEX
            /* WARNING: $splice Could not find named fragment 'PassInstancing' */
            #define SHADERPASS SHADERPASS_DEPTHNORMALSONLY
        #define REQUIRE_DEPTH_TEXTURE
            /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

            // --------------------------------------------------
            // Structs and Packing

            struct Attributes
        {
            float3 positionOS : POSITION;
            float3 normalOS : NORMAL;
            float4 tangentOS : TANGENT;
            float4 uv1 : TEXCOORD1;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
            float4 positionCS : SV_POSITION;
            float3 positionWS;
            float3 normalWS;
            float4 tangentWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
            float3 TangentSpaceNormal;
            float3 WorldSpacePosition;
            float4 ScreenPosition;
        };
        struct VertexDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 WorldSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 ObjectSpacePosition;
            float3 WorldSpacePosition;
            float3 TimeParameters;
        };
        struct PackedVaryings
        {
            float4 positionCS : SV_POSITION;
            float3 interp0 : TEXCOORD0;
            float3 interp1 : TEXCOORD1;
            float4 interp2 : TEXCOORD2;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };

            PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            output.interp2.xyzw =  input.tangentWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            output.tangentWS = input.interp2.xyzw;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }

            // --------------------------------------------------
            // Graph

            // Graph Properties
            CBUFFER_START(UnityPerMaterial)
        float4 Vector4_484BA326;
        float Vector1_8F075DBC;
        float Vector1_8AAD665C;
        float Vector1_E43D3892;
        float4 Vector4_1696EE66;
        float4 Color_2CFB5E2A;
        float4 Color_58195353;
        float Vector1_FADC0395;
        float Vector1_E505CA4B;
        float Vector1_4CE104D9;
        float Vector1_5536221E;
        float Vector1_9058DE8C;
        float Vector1_350643F1;
        float Vector1_2A80C598;
        float Vector1_A664731F;
        float Vector1_B4ED823D;
        float Vector1_2BA361A8;
        float Vector1_EED1A887;
        CBUFFER_END

        // Object and Global properties

            // Graph Functions
            
        void Unity_Distance_float3(float3 A, float3 B, out float Out)
        {
            Out = distance(A, B);
        }

        void Unity_Divide_float(float A, float B, out float Out)
        {
            Out = A / B;
        }

        void Unity_Power_float(float A, float B, out float Out)
        {
            Out = pow(A, B);
        }

        void Unity_Multiply_float(float3 A, float3 B, out float3 Out)
        {
            Out = A * B;
        }

        void Unity_Rotate_About_Axis_Degrees_float(float3 In, float3 Axis, float Rotation, out float3 Out)
        {
            Rotation = radians(Rotation);

            float s = sin(Rotation);
            float c = cos(Rotation);
            float one_minus_c = 1.0 - c;
            
            Axis = normalize(Axis);

            float3x3 rot_mat = { one_minus_c * Axis.x * Axis.x + c,            one_minus_c * Axis.x * Axis.y - Axis.z * s,     one_minus_c * Axis.z * Axis.x + Axis.y * s,
                                      one_minus_c * Axis.x * Axis.y + Axis.z * s,   one_minus_c * Axis.y * Axis.y + c,              one_minus_c * Axis.y * Axis.z - Axis.x * s,
                                      one_minus_c * Axis.z * Axis.x - Axis.y * s,   one_minus_c * Axis.y * Axis.z + Axis.x * s,     one_minus_c * Axis.z * Axis.z + c
                                    };

            Out = mul(rot_mat,  In);
        }

        void Unity_Multiply_float(float A, float B, out float Out)
        {
            Out = A * B;
        }

        void Unity_TilingAndOffset_float(float2 UV, float2 Tiling, float2 Offset, out float2 Out)
        {
            Out = UV * Tiling + Offset;
        }


        float2 Unity_GradientNoise_Dir_float(float2 p)
        {
            // Permutation and hashing used in webgl-nosie goo.gl/pX7HtC
            p = p % 289;
            // need full precision, otherwise half overflows when p > 1
            float x = float(34 * p.x + 1) * p.x % 289 + p.y;
            x = (34 * x + 1) * x % 289;
            x = frac(x / 41) * 2 - 1;
            return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
        }

        void Unity_GradientNoise_float(float2 UV, float Scale, out float Out)
        { 
            float2 p = UV * Scale;
            float2 ip = floor(p);
            float2 fp = frac(p);
            float d00 = dot(Unity_GradientNoise_Dir_float(ip), fp);
            float d01 = dot(Unity_GradientNoise_Dir_float(ip + float2(0, 1)), fp - float2(0, 1));
            float d10 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 0)), fp - float2(1, 0));
            float d11 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 1)), fp - float2(1, 1));
            fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
            Out = lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x) + 0.5;
        }

        void Unity_Add_float(float A, float B, out float Out)
        {
            Out = A + B;
        }

        void Unity_Saturate_float(float In, out float Out)
        {
            Out = saturate(In);
        }

        void Unity_Combine_float(float R, float G, float B, float A, out float4 RGBA, out float3 RGB, out float2 RG)
        {
            RGBA = float4(R, G, B, A);
            RGB = float3(R, G, B);
            RG = float2(R, G);
        }

        void Unity_Remap_float(float In, float2 InMinMax, float2 OutMinMax, out float Out)
        {
            Out = OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
        }

        void Unity_Absolute_float(float In, out float Out)
        {
            Out = abs(In);
        }

        void Unity_Smoothstep_float(float Edge1, float Edge2, float In, out float Out)
        {
            Out = smoothstep(Edge1, Edge2, In);
        }

        void Unity_Add_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A + B;
        }

        void Unity_SceneDepth_Eye_float(float4 UV, out float Out)
        {
            Out = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH(UV.xy), _ZBufferParams);
        }

        void Unity_Subtract_float(float A, float B, out float Out)
        {
            Out = A - B;
        }

            // Graph Vertex
            struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };

        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            float _Distance_474c9e8e982c878dad2f0d5844b22ee9_Out_2;
            Unity_Distance_float3(SHADERGRAPH_OBJECT_POSITION, IN.WorldSpacePosition, _Distance_474c9e8e982c878dad2f0d5844b22ee9_Out_2);
            float _Property_95b6af28bf5d388fb7809e99d4ea7a10_Out_0 = Vector1_A664731F;
            float _Divide_2022c703e9e6de87965706bd214b7b67_Out_2;
            Unity_Divide_float(_Distance_474c9e8e982c878dad2f0d5844b22ee9_Out_2, _Property_95b6af28bf5d388fb7809e99d4ea7a10_Out_0, _Divide_2022c703e9e6de87965706bd214b7b67_Out_2);
            float _Power_8710b3fb1efe3183a2818b946e662a1e_Out_2;
            Unity_Power_float(_Divide_2022c703e9e6de87965706bd214b7b67_Out_2, 3, _Power_8710b3fb1efe3183a2818b946e662a1e_Out_2);
            float3 _Multiply_3fa32f2d7f56688684a8f5b0a0853be5_Out_2;
            Unity_Multiply_float(IN.WorldSpaceNormal, (_Power_8710b3fb1efe3183a2818b946e662a1e_Out_2.xxx), _Multiply_3fa32f2d7f56688684a8f5b0a0853be5_Out_2);
            float _Property_45fc02a5c65e898c82a51138ee7894c8_Out_0 = Vector1_FADC0395;
            float _Property_423be2625737e5829e3daa7b3cf8389d_Out_0 = Vector1_E505CA4B;
            float4 _Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0 = Vector4_484BA326;
            float _Split_e9324c176bf05a809ea8df8c413a826a_R_1 = _Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0[0];
            float _Split_e9324c176bf05a809ea8df8c413a826a_G_2 = _Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0[1];
            float _Split_e9324c176bf05a809ea8df8c413a826a_B_3 = _Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0[2];
            float _Split_e9324c176bf05a809ea8df8c413a826a_A_4 = _Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0[3];
            float3 _RotateAboutAxis_430e3c523bf85e84bdef451ab28beba0_Out_3;
            Unity_Rotate_About_Axis_Degrees_float(IN.WorldSpacePosition, (_Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0.xyz), _Split_e9324c176bf05a809ea8df8c413a826a_A_4, _RotateAboutAxis_430e3c523bf85e84bdef451ab28beba0_Out_3);
            float _Property_84dca49c8958708fac3276b0de15a6da_Out_0 = Vector1_8AAD665C;
            float _Multiply_89f92af49e152081ba549c92ab002e9c_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_84dca49c8958708fac3276b0de15a6da_Out_0, _Multiply_89f92af49e152081ba549c92ab002e9c_Out_2);
            float2 _TilingAndOffset_bd9fc632c3a6c185b226f93212ed8603_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_430e3c523bf85e84bdef451ab28beba0_Out_3.xy), float2 (1, 1), (_Multiply_89f92af49e152081ba549c92ab002e9c_Out_2.xx), _TilingAndOffset_bd9fc632c3a6c185b226f93212ed8603_Out_3);
            float _Property_f7111fce9be08b8c871514ffc219f648_Out_0 = Vector1_8F075DBC;
            float _GradientNoise_de42ec7fdd52ec8fa0b6cb7f34842c13_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_bd9fc632c3a6c185b226f93212ed8603_Out_3, _Property_f7111fce9be08b8c871514ffc219f648_Out_0, _GradientNoise_de42ec7fdd52ec8fa0b6cb7f34842c13_Out_2);
            float2 _TilingAndOffset_aa88c06674f4178889e657a2bb46c454_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_430e3c523bf85e84bdef451ab28beba0_Out_3.xy), float2 (1, 1), float2 (0, 0), _TilingAndOffset_aa88c06674f4178889e657a2bb46c454_Out_3);
            float _GradientNoise_28996fa0f6fbd08c97ed18d0621900b5_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_aa88c06674f4178889e657a2bb46c454_Out_3, _Property_f7111fce9be08b8c871514ffc219f648_Out_0, _GradientNoise_28996fa0f6fbd08c97ed18d0621900b5_Out_2);
            float _Add_caf5f972abacae878d9a6fde10e0986a_Out_2;
            Unity_Add_float(_GradientNoise_de42ec7fdd52ec8fa0b6cb7f34842c13_Out_2, _GradientNoise_28996fa0f6fbd08c97ed18d0621900b5_Out_2, _Add_caf5f972abacae878d9a6fde10e0986a_Out_2);
            float _Divide_27ef561e54cd208ca89512269c1d4d03_Out_2;
            Unity_Divide_float(_Add_caf5f972abacae878d9a6fde10e0986a_Out_2, 2, _Divide_27ef561e54cd208ca89512269c1d4d03_Out_2);
            float _Saturate_c56694103011198486afa78b0e89ec2c_Out_1;
            Unity_Saturate_float(_Divide_27ef561e54cd208ca89512269c1d4d03_Out_2, _Saturate_c56694103011198486afa78b0e89ec2c_Out_1);
            float _Property_8bd1d491d3050588a0b837b4b232170d_Out_0 = Vector1_4CE104D9;
            float _Power_abb6d235206009809ee431a98f2c8247_Out_2;
            Unity_Power_float(_Saturate_c56694103011198486afa78b0e89ec2c_Out_1, _Property_8bd1d491d3050588a0b837b4b232170d_Out_0, _Power_abb6d235206009809ee431a98f2c8247_Out_2);
            float4 _Property_8a81e8a6d963f384bddf6e75ec8e0a1c_Out_0 = Vector4_1696EE66;
            float _Split_f72e1ad87d56df8ba34ec31e2bc432b8_R_1 = _Property_8a81e8a6d963f384bddf6e75ec8e0a1c_Out_0[0];
            float _Split_f72e1ad87d56df8ba34ec31e2bc432b8_G_2 = _Property_8a81e8a6d963f384bddf6e75ec8e0a1c_Out_0[1];
            float _Split_f72e1ad87d56df8ba34ec31e2bc432b8_B_3 = _Property_8a81e8a6d963f384bddf6e75ec8e0a1c_Out_0[2];
            float _Split_f72e1ad87d56df8ba34ec31e2bc432b8_A_4 = _Property_8a81e8a6d963f384bddf6e75ec8e0a1c_Out_0[3];
            float4 _Combine_aeef4bbea8acc688b198e488208172f2_RGBA_4;
            float3 _Combine_aeef4bbea8acc688b198e488208172f2_RGB_5;
            float2 _Combine_aeef4bbea8acc688b198e488208172f2_RG_6;
            Unity_Combine_float(_Split_f72e1ad87d56df8ba34ec31e2bc432b8_R_1, _Split_f72e1ad87d56df8ba34ec31e2bc432b8_G_2, 0, 0, _Combine_aeef4bbea8acc688b198e488208172f2_RGBA_4, _Combine_aeef4bbea8acc688b198e488208172f2_RGB_5, _Combine_aeef4bbea8acc688b198e488208172f2_RG_6);
            float4 _Combine_feabe866dc39388d8ccd72275fb9be09_RGBA_4;
            float3 _Combine_feabe866dc39388d8ccd72275fb9be09_RGB_5;
            float2 _Combine_feabe866dc39388d8ccd72275fb9be09_RG_6;
            Unity_Combine_float(_Split_f72e1ad87d56df8ba34ec31e2bc432b8_B_3, _Split_f72e1ad87d56df8ba34ec31e2bc432b8_A_4, 0, 0, _Combine_feabe866dc39388d8ccd72275fb9be09_RGBA_4, _Combine_feabe866dc39388d8ccd72275fb9be09_RGB_5, _Combine_feabe866dc39388d8ccd72275fb9be09_RG_6);
            float _Remap_ca18d3412979f985809f3426d5282816_Out_3;
            Unity_Remap_float(_Power_abb6d235206009809ee431a98f2c8247_Out_2, _Combine_aeef4bbea8acc688b198e488208172f2_RG_6, _Combine_feabe866dc39388d8ccd72275fb9be09_RG_6, _Remap_ca18d3412979f985809f3426d5282816_Out_3);
            float _Absolute_01d69efb5b6b628b8142004f10302240_Out_1;
            Unity_Absolute_float(_Remap_ca18d3412979f985809f3426d5282816_Out_3, _Absolute_01d69efb5b6b628b8142004f10302240_Out_1);
            float _Smoothstep_5a0282a38f27848e9545f1e89a11f5a2_Out_3;
            Unity_Smoothstep_float(_Property_45fc02a5c65e898c82a51138ee7894c8_Out_0, _Property_423be2625737e5829e3daa7b3cf8389d_Out_0, _Absolute_01d69efb5b6b628b8142004f10302240_Out_1, _Smoothstep_5a0282a38f27848e9545f1e89a11f5a2_Out_3);
            float _Property_91482984669b1c8ab26a0f4a555b3801_Out_0 = Vector1_9058DE8C;
            float _Multiply_ad5811e4c08fae88a363e144af359987_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_91482984669b1c8ab26a0f4a555b3801_Out_0, _Multiply_ad5811e4c08fae88a363e144af359987_Out_2);
            float2 _TilingAndOffset_2345314be014258796bc32f9e66d2397_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_430e3c523bf85e84bdef451ab28beba0_Out_3.xy), float2 (1, 1), (_Multiply_ad5811e4c08fae88a363e144af359987_Out_2.xx), _TilingAndOffset_2345314be014258796bc32f9e66d2397_Out_3);
            float _Property_a13e388a84b18e89afce2f9f3ca9753f_Out_0 = Vector1_5536221E;
            float _GradientNoise_9f2e5d10ed34688f87f30e9a171b1f8b_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_2345314be014258796bc32f9e66d2397_Out_3, _Property_a13e388a84b18e89afce2f9f3ca9753f_Out_0, _GradientNoise_9f2e5d10ed34688f87f30e9a171b1f8b_Out_2);
            float _Property_b64fda08fa35398f9e0f45e316a434f9_Out_0 = Vector1_350643F1;
            float _Multiply_d03d0c5bc6770f8b8fbb46ec0c06b35b_Out_2;
            Unity_Multiply_float(_GradientNoise_9f2e5d10ed34688f87f30e9a171b1f8b_Out_2, _Property_b64fda08fa35398f9e0f45e316a434f9_Out_0, _Multiply_d03d0c5bc6770f8b8fbb46ec0c06b35b_Out_2);
            float _Add_f031b6931be259898e2d889c851d36d5_Out_2;
            Unity_Add_float(_Smoothstep_5a0282a38f27848e9545f1e89a11f5a2_Out_3, _Multiply_d03d0c5bc6770f8b8fbb46ec0c06b35b_Out_2, _Add_f031b6931be259898e2d889c851d36d5_Out_2);
            float _Add_e1b7452d2644ef8e96d652df6def6989_Out_2;
            Unity_Add_float(1, _Property_b64fda08fa35398f9e0f45e316a434f9_Out_0, _Add_e1b7452d2644ef8e96d652df6def6989_Out_2);
            float _Divide_b34aaac0718e8682bb2ab66e45d42421_Out_2;
            Unity_Divide_float(_Add_f031b6931be259898e2d889c851d36d5_Out_2, _Add_e1b7452d2644ef8e96d652df6def6989_Out_2, _Divide_b34aaac0718e8682bb2ab66e45d42421_Out_2);
            float3 _Multiply_a97d25c025f47f8fa4cfe3267dee485e_Out_2;
            Unity_Multiply_float(IN.ObjectSpaceNormal, (_Divide_b34aaac0718e8682bb2ab66e45d42421_Out_2.xxx), _Multiply_a97d25c025f47f8fa4cfe3267dee485e_Out_2);
            float _Property_6f2976fe72816a869d8677a4230164f0_Out_0 = Vector1_E43D3892;
            float3 _Multiply_08ef8c8995ef448a9ab1e43028223a19_Out_2;
            Unity_Multiply_float(_Multiply_a97d25c025f47f8fa4cfe3267dee485e_Out_2, (_Property_6f2976fe72816a869d8677a4230164f0_Out_0.xxx), _Multiply_08ef8c8995ef448a9ab1e43028223a19_Out_2);
            float3 _Add_ec1431816c726e8a827bfd7e7de3d614_Out_2;
            Unity_Add_float3(IN.ObjectSpacePosition, _Multiply_08ef8c8995ef448a9ab1e43028223a19_Out_2, _Add_ec1431816c726e8a827bfd7e7de3d614_Out_2);
            float3 _Add_cbfa9591f076e485a31b7f5b967f99f6_Out_2;
            Unity_Add_float3(_Multiply_3fa32f2d7f56688684a8f5b0a0853be5_Out_2, _Add_ec1431816c726e8a827bfd7e7de3d614_Out_2, _Add_cbfa9591f076e485a31b7f5b967f99f6_Out_2);
            description.Position = _Add_cbfa9591f076e485a31b7f5b967f99f6_Out_2;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }

            // Graph Pixel
            struct SurfaceDescription
        {
            float3 NormalTS;
            float Alpha;
        };

        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            float _SceneDepth_845bf60653d70482b562a739512eeda7_Out_1;
            Unity_SceneDepth_Eye_float(float4(IN.ScreenPosition.xy / IN.ScreenPosition.w, 0, 0), _SceneDepth_845bf60653d70482b562a739512eeda7_Out_1);
            float4 _ScreenPosition_b978995ebe1ba286935416b2a2d5cb85_Out_0 = IN.ScreenPosition;
            float _Split_c66584edb0487b8e8c2e107a89ed8e9f_R_1 = _ScreenPosition_b978995ebe1ba286935416b2a2d5cb85_Out_0[0];
            float _Split_c66584edb0487b8e8c2e107a89ed8e9f_G_2 = _ScreenPosition_b978995ebe1ba286935416b2a2d5cb85_Out_0[1];
            float _Split_c66584edb0487b8e8c2e107a89ed8e9f_B_3 = _ScreenPosition_b978995ebe1ba286935416b2a2d5cb85_Out_0[2];
            float _Split_c66584edb0487b8e8c2e107a89ed8e9f_A_4 = _ScreenPosition_b978995ebe1ba286935416b2a2d5cb85_Out_0[3];
            float _Subtract_39fffd64ebdafb84a6eb8e37e2faaa16_Out_2;
            Unity_Subtract_float(_Split_c66584edb0487b8e8c2e107a89ed8e9f_A_4, 1, _Subtract_39fffd64ebdafb84a6eb8e37e2faaa16_Out_2);
            float _Subtract_d8ff2e79b2fc8386b6172daebbe97366_Out_2;
            Unity_Subtract_float(_SceneDepth_845bf60653d70482b562a739512eeda7_Out_1, _Subtract_39fffd64ebdafb84a6eb8e37e2faaa16_Out_2, _Subtract_d8ff2e79b2fc8386b6172daebbe97366_Out_2);
            float _Property_0a2887e34569358bbc9cbee1a14acebb_Out_0 = Vector1_EED1A887;
            float _Divide_f3ff43869c02038db823cf0d91c23caf_Out_2;
            Unity_Divide_float(_Subtract_d8ff2e79b2fc8386b6172daebbe97366_Out_2, _Property_0a2887e34569358bbc9cbee1a14acebb_Out_0, _Divide_f3ff43869c02038db823cf0d91c23caf_Out_2);
            float _Saturate_676d84ccc0f0b88e9d1fdf263cfcf1d5_Out_1;
            Unity_Saturate_float(_Divide_f3ff43869c02038db823cf0d91c23caf_Out_2, _Saturate_676d84ccc0f0b88e9d1fdf263cfcf1d5_Out_1);
            float _Smoothstep_edf634d16c75cd829225bfca563f83fb_Out_3;
            Unity_Smoothstep_float(0, 1, _Saturate_676d84ccc0f0b88e9d1fdf263cfcf1d5_Out_1, _Smoothstep_edf634d16c75cd829225bfca563f83fb_Out_3);
            surface.NormalTS = IN.TangentSpaceNormal;
            surface.Alpha = _Smoothstep_edf634d16c75cd829225bfca563f83fb_Out_3;
            return surface;
        }

            // --------------------------------------------------
            // Build Graph Inputs

            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);

            output.ObjectSpaceNormal =           input.normalOS;
            output.WorldSpaceNormal =            TransformObjectToWorldNormal(input.normalOS);
            output.ObjectSpaceTangent =          input.tangentOS.xyz;
            output.ObjectSpacePosition =         input.positionOS;
            output.WorldSpacePosition =          TransformObjectToWorld(input.positionOS);
            output.TimeParameters =              _TimeParameters.xyz;

            return output;
        }
            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);



            output.TangentSpaceNormal =          float3(0.0f, 0.0f, 1.0f);


            output.WorldSpacePosition =          input.positionWS;
            output.ScreenPosition =              ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

            return output;
        }

            // --------------------------------------------------
            // Main

            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/DepthNormalsOnlyPass.hlsl"

            ENDHLSL
        }
        Pass
        {
            Name "Meta"
            Tags
            {
                "LightMode" = "Meta"
            }

            // Render State
            Cull Off

            // Debug
            // <None>

            // --------------------------------------------------
            // Pass

            HLSLPROGRAM

            // Pragmas
            #pragma target 2.0
        #pragma only_renderers gles gles3 glcore d3d11
        #pragma vertex vert
        #pragma fragment frag

            // DotsInstancingOptions: <None>
            // HybridV1InjectedBuiltinProperties: <None>

            // Keywords
            #pragma shader_feature _ _SMOOTHNESS_TEXTURE_ALBEDO_CHANNEL_A
            // GraphKeywords: <None>

            // Defines
            #define _SURFACE_TYPE_TRANSPARENT 1
            #define _NORMALMAP 1
            #define _NORMAL_DROPOFF_TS 1
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define ATTRIBUTES_NEED_TEXCOORD1
            #define ATTRIBUTES_NEED_TEXCOORD2
            #define VARYINGS_NEED_POSITION_WS
            #define VARYINGS_NEED_NORMAL_WS
            #define VARYINGS_NEED_VIEWDIRECTION_WS
            #define FEATURES_GRAPH_VERTEX
            /* WARNING: $splice Could not find named fragment 'PassInstancing' */
            #define SHADERPASS SHADERPASS_META
        #define REQUIRE_DEPTH_TEXTURE
            /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/MetaInput.hlsl"

            // --------------------------------------------------
            // Structs and Packing

            struct Attributes
        {
            float3 positionOS : POSITION;
            float3 normalOS : NORMAL;
            float4 tangentOS : TANGENT;
            float4 uv1 : TEXCOORD1;
            float4 uv2 : TEXCOORD2;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
            float4 positionCS : SV_POSITION;
            float3 positionWS;
            float3 normalWS;
            float3 viewDirectionWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
            float3 WorldSpaceNormal;
            float3 WorldSpaceViewDirection;
            float3 WorldSpacePosition;
            float4 ScreenPosition;
            float3 TimeParameters;
        };
        struct VertexDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 WorldSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 ObjectSpacePosition;
            float3 WorldSpacePosition;
            float3 TimeParameters;
        };
        struct PackedVaryings
        {
            float4 positionCS : SV_POSITION;
            float3 interp0 : TEXCOORD0;
            float3 interp1 : TEXCOORD1;
            float3 interp2 : TEXCOORD2;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };

            PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            output.interp1.xyz =  input.normalWS;
            output.interp2.xyz =  input.viewDirectionWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            output.normalWS = input.interp1.xyz;
            output.viewDirectionWS = input.interp2.xyz;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }

            // --------------------------------------------------
            // Graph

            // Graph Properties
            CBUFFER_START(UnityPerMaterial)
        float4 Vector4_484BA326;
        float Vector1_8F075DBC;
        float Vector1_8AAD665C;
        float Vector1_E43D3892;
        float4 Vector4_1696EE66;
        float4 Color_2CFB5E2A;
        float4 Color_58195353;
        float Vector1_FADC0395;
        float Vector1_E505CA4B;
        float Vector1_4CE104D9;
        float Vector1_5536221E;
        float Vector1_9058DE8C;
        float Vector1_350643F1;
        float Vector1_2A80C598;
        float Vector1_A664731F;
        float Vector1_B4ED823D;
        float Vector1_2BA361A8;
        float Vector1_EED1A887;
        CBUFFER_END

        // Object and Global properties

            // Graph Functions
            
        void Unity_Distance_float3(float3 A, float3 B, out float Out)
        {
            Out = distance(A, B);
        }

        void Unity_Divide_float(float A, float B, out float Out)
        {
            Out = A / B;
        }

        void Unity_Power_float(float A, float B, out float Out)
        {
            Out = pow(A, B);
        }

        void Unity_Multiply_float(float3 A, float3 B, out float3 Out)
        {
            Out = A * B;
        }

        void Unity_Rotate_About_Axis_Degrees_float(float3 In, float3 Axis, float Rotation, out float3 Out)
        {
            Rotation = radians(Rotation);

            float s = sin(Rotation);
            float c = cos(Rotation);
            float one_minus_c = 1.0 - c;
            
            Axis = normalize(Axis);

            float3x3 rot_mat = { one_minus_c * Axis.x * Axis.x + c,            one_minus_c * Axis.x * Axis.y - Axis.z * s,     one_minus_c * Axis.z * Axis.x + Axis.y * s,
                                      one_minus_c * Axis.x * Axis.y + Axis.z * s,   one_minus_c * Axis.y * Axis.y + c,              one_minus_c * Axis.y * Axis.z - Axis.x * s,
                                      one_minus_c * Axis.z * Axis.x - Axis.y * s,   one_minus_c * Axis.y * Axis.z + Axis.x * s,     one_minus_c * Axis.z * Axis.z + c
                                    };

            Out = mul(rot_mat,  In);
        }

        void Unity_Multiply_float(float A, float B, out float Out)
        {
            Out = A * B;
        }

        void Unity_TilingAndOffset_float(float2 UV, float2 Tiling, float2 Offset, out float2 Out)
        {
            Out = UV * Tiling + Offset;
        }


        float2 Unity_GradientNoise_Dir_float(float2 p)
        {
            // Permutation and hashing used in webgl-nosie goo.gl/pX7HtC
            p = p % 289;
            // need full precision, otherwise half overflows when p > 1
            float x = float(34 * p.x + 1) * p.x % 289 + p.y;
            x = (34 * x + 1) * x % 289;
            x = frac(x / 41) * 2 - 1;
            return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
        }

        void Unity_GradientNoise_float(float2 UV, float Scale, out float Out)
        { 
            float2 p = UV * Scale;
            float2 ip = floor(p);
            float2 fp = frac(p);
            float d00 = dot(Unity_GradientNoise_Dir_float(ip), fp);
            float d01 = dot(Unity_GradientNoise_Dir_float(ip + float2(0, 1)), fp - float2(0, 1));
            float d10 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 0)), fp - float2(1, 0));
            float d11 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 1)), fp - float2(1, 1));
            fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
            Out = lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x) + 0.5;
        }

        void Unity_Add_float(float A, float B, out float Out)
        {
            Out = A + B;
        }

        void Unity_Saturate_float(float In, out float Out)
        {
            Out = saturate(In);
        }

        void Unity_Combine_float(float R, float G, float B, float A, out float4 RGBA, out float3 RGB, out float2 RG)
        {
            RGBA = float4(R, G, B, A);
            RGB = float3(R, G, B);
            RG = float2(R, G);
        }

        void Unity_Remap_float(float In, float2 InMinMax, float2 OutMinMax, out float Out)
        {
            Out = OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
        }

        void Unity_Absolute_float(float In, out float Out)
        {
            Out = abs(In);
        }

        void Unity_Smoothstep_float(float Edge1, float Edge2, float In, out float Out)
        {
            Out = smoothstep(Edge1, Edge2, In);
        }

        void Unity_Add_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A + B;
        }

        void Unity_Lerp_float4(float4 A, float4 B, float4 T, out float4 Out)
        {
            Out = lerp(A, B, T);
        }

        void Unity_FresnelEffect_float(float3 Normal, float3 ViewDir, float Power, out float Out)
        {
            Out = pow((1.0 - saturate(dot(normalize(Normal), normalize(ViewDir)))), Power);
        }

        void Unity_Add_float4(float4 A, float4 B, out float4 Out)
        {
            Out = A + B;
        }

        void Unity_Multiply_float(float4 A, float4 B, out float4 Out)
        {
            Out = A * B;
        }

        void Unity_SceneDepth_Eye_float(float4 UV, out float Out)
        {
            Out = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH(UV.xy), _ZBufferParams);
        }

        void Unity_Subtract_float(float A, float B, out float Out)
        {
            Out = A - B;
        }

            // Graph Vertex
            struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };

        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            float _Distance_474c9e8e982c878dad2f0d5844b22ee9_Out_2;
            Unity_Distance_float3(SHADERGRAPH_OBJECT_POSITION, IN.WorldSpacePosition, _Distance_474c9e8e982c878dad2f0d5844b22ee9_Out_2);
            float _Property_95b6af28bf5d388fb7809e99d4ea7a10_Out_0 = Vector1_A664731F;
            float _Divide_2022c703e9e6de87965706bd214b7b67_Out_2;
            Unity_Divide_float(_Distance_474c9e8e982c878dad2f0d5844b22ee9_Out_2, _Property_95b6af28bf5d388fb7809e99d4ea7a10_Out_0, _Divide_2022c703e9e6de87965706bd214b7b67_Out_2);
            float _Power_8710b3fb1efe3183a2818b946e662a1e_Out_2;
            Unity_Power_float(_Divide_2022c703e9e6de87965706bd214b7b67_Out_2, 3, _Power_8710b3fb1efe3183a2818b946e662a1e_Out_2);
            float3 _Multiply_3fa32f2d7f56688684a8f5b0a0853be5_Out_2;
            Unity_Multiply_float(IN.WorldSpaceNormal, (_Power_8710b3fb1efe3183a2818b946e662a1e_Out_2.xxx), _Multiply_3fa32f2d7f56688684a8f5b0a0853be5_Out_2);
            float _Property_45fc02a5c65e898c82a51138ee7894c8_Out_0 = Vector1_FADC0395;
            float _Property_423be2625737e5829e3daa7b3cf8389d_Out_0 = Vector1_E505CA4B;
            float4 _Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0 = Vector4_484BA326;
            float _Split_e9324c176bf05a809ea8df8c413a826a_R_1 = _Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0[0];
            float _Split_e9324c176bf05a809ea8df8c413a826a_G_2 = _Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0[1];
            float _Split_e9324c176bf05a809ea8df8c413a826a_B_3 = _Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0[2];
            float _Split_e9324c176bf05a809ea8df8c413a826a_A_4 = _Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0[3];
            float3 _RotateAboutAxis_430e3c523bf85e84bdef451ab28beba0_Out_3;
            Unity_Rotate_About_Axis_Degrees_float(IN.WorldSpacePosition, (_Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0.xyz), _Split_e9324c176bf05a809ea8df8c413a826a_A_4, _RotateAboutAxis_430e3c523bf85e84bdef451ab28beba0_Out_3);
            float _Property_84dca49c8958708fac3276b0de15a6da_Out_0 = Vector1_8AAD665C;
            float _Multiply_89f92af49e152081ba549c92ab002e9c_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_84dca49c8958708fac3276b0de15a6da_Out_0, _Multiply_89f92af49e152081ba549c92ab002e9c_Out_2);
            float2 _TilingAndOffset_bd9fc632c3a6c185b226f93212ed8603_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_430e3c523bf85e84bdef451ab28beba0_Out_3.xy), float2 (1, 1), (_Multiply_89f92af49e152081ba549c92ab002e9c_Out_2.xx), _TilingAndOffset_bd9fc632c3a6c185b226f93212ed8603_Out_3);
            float _Property_f7111fce9be08b8c871514ffc219f648_Out_0 = Vector1_8F075DBC;
            float _GradientNoise_de42ec7fdd52ec8fa0b6cb7f34842c13_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_bd9fc632c3a6c185b226f93212ed8603_Out_3, _Property_f7111fce9be08b8c871514ffc219f648_Out_0, _GradientNoise_de42ec7fdd52ec8fa0b6cb7f34842c13_Out_2);
            float2 _TilingAndOffset_aa88c06674f4178889e657a2bb46c454_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_430e3c523bf85e84bdef451ab28beba0_Out_3.xy), float2 (1, 1), float2 (0, 0), _TilingAndOffset_aa88c06674f4178889e657a2bb46c454_Out_3);
            float _GradientNoise_28996fa0f6fbd08c97ed18d0621900b5_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_aa88c06674f4178889e657a2bb46c454_Out_3, _Property_f7111fce9be08b8c871514ffc219f648_Out_0, _GradientNoise_28996fa0f6fbd08c97ed18d0621900b5_Out_2);
            float _Add_caf5f972abacae878d9a6fde10e0986a_Out_2;
            Unity_Add_float(_GradientNoise_de42ec7fdd52ec8fa0b6cb7f34842c13_Out_2, _GradientNoise_28996fa0f6fbd08c97ed18d0621900b5_Out_2, _Add_caf5f972abacae878d9a6fde10e0986a_Out_2);
            float _Divide_27ef561e54cd208ca89512269c1d4d03_Out_2;
            Unity_Divide_float(_Add_caf5f972abacae878d9a6fde10e0986a_Out_2, 2, _Divide_27ef561e54cd208ca89512269c1d4d03_Out_2);
            float _Saturate_c56694103011198486afa78b0e89ec2c_Out_1;
            Unity_Saturate_float(_Divide_27ef561e54cd208ca89512269c1d4d03_Out_2, _Saturate_c56694103011198486afa78b0e89ec2c_Out_1);
            float _Property_8bd1d491d3050588a0b837b4b232170d_Out_0 = Vector1_4CE104D9;
            float _Power_abb6d235206009809ee431a98f2c8247_Out_2;
            Unity_Power_float(_Saturate_c56694103011198486afa78b0e89ec2c_Out_1, _Property_8bd1d491d3050588a0b837b4b232170d_Out_0, _Power_abb6d235206009809ee431a98f2c8247_Out_2);
            float4 _Property_8a81e8a6d963f384bddf6e75ec8e0a1c_Out_0 = Vector4_1696EE66;
            float _Split_f72e1ad87d56df8ba34ec31e2bc432b8_R_1 = _Property_8a81e8a6d963f384bddf6e75ec8e0a1c_Out_0[0];
            float _Split_f72e1ad87d56df8ba34ec31e2bc432b8_G_2 = _Property_8a81e8a6d963f384bddf6e75ec8e0a1c_Out_0[1];
            float _Split_f72e1ad87d56df8ba34ec31e2bc432b8_B_3 = _Property_8a81e8a6d963f384bddf6e75ec8e0a1c_Out_0[2];
            float _Split_f72e1ad87d56df8ba34ec31e2bc432b8_A_4 = _Property_8a81e8a6d963f384bddf6e75ec8e0a1c_Out_0[3];
            float4 _Combine_aeef4bbea8acc688b198e488208172f2_RGBA_4;
            float3 _Combine_aeef4bbea8acc688b198e488208172f2_RGB_5;
            float2 _Combine_aeef4bbea8acc688b198e488208172f2_RG_6;
            Unity_Combine_float(_Split_f72e1ad87d56df8ba34ec31e2bc432b8_R_1, _Split_f72e1ad87d56df8ba34ec31e2bc432b8_G_2, 0, 0, _Combine_aeef4bbea8acc688b198e488208172f2_RGBA_4, _Combine_aeef4bbea8acc688b198e488208172f2_RGB_5, _Combine_aeef4bbea8acc688b198e488208172f2_RG_6);
            float4 _Combine_feabe866dc39388d8ccd72275fb9be09_RGBA_4;
            float3 _Combine_feabe866dc39388d8ccd72275fb9be09_RGB_5;
            float2 _Combine_feabe866dc39388d8ccd72275fb9be09_RG_6;
            Unity_Combine_float(_Split_f72e1ad87d56df8ba34ec31e2bc432b8_B_3, _Split_f72e1ad87d56df8ba34ec31e2bc432b8_A_4, 0, 0, _Combine_feabe866dc39388d8ccd72275fb9be09_RGBA_4, _Combine_feabe866dc39388d8ccd72275fb9be09_RGB_5, _Combine_feabe866dc39388d8ccd72275fb9be09_RG_6);
            float _Remap_ca18d3412979f985809f3426d5282816_Out_3;
            Unity_Remap_float(_Power_abb6d235206009809ee431a98f2c8247_Out_2, _Combine_aeef4bbea8acc688b198e488208172f2_RG_6, _Combine_feabe866dc39388d8ccd72275fb9be09_RG_6, _Remap_ca18d3412979f985809f3426d5282816_Out_3);
            float _Absolute_01d69efb5b6b628b8142004f10302240_Out_1;
            Unity_Absolute_float(_Remap_ca18d3412979f985809f3426d5282816_Out_3, _Absolute_01d69efb5b6b628b8142004f10302240_Out_1);
            float _Smoothstep_5a0282a38f27848e9545f1e89a11f5a2_Out_3;
            Unity_Smoothstep_float(_Property_45fc02a5c65e898c82a51138ee7894c8_Out_0, _Property_423be2625737e5829e3daa7b3cf8389d_Out_0, _Absolute_01d69efb5b6b628b8142004f10302240_Out_1, _Smoothstep_5a0282a38f27848e9545f1e89a11f5a2_Out_3);
            float _Property_91482984669b1c8ab26a0f4a555b3801_Out_0 = Vector1_9058DE8C;
            float _Multiply_ad5811e4c08fae88a363e144af359987_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_91482984669b1c8ab26a0f4a555b3801_Out_0, _Multiply_ad5811e4c08fae88a363e144af359987_Out_2);
            float2 _TilingAndOffset_2345314be014258796bc32f9e66d2397_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_430e3c523bf85e84bdef451ab28beba0_Out_3.xy), float2 (1, 1), (_Multiply_ad5811e4c08fae88a363e144af359987_Out_2.xx), _TilingAndOffset_2345314be014258796bc32f9e66d2397_Out_3);
            float _Property_a13e388a84b18e89afce2f9f3ca9753f_Out_0 = Vector1_5536221E;
            float _GradientNoise_9f2e5d10ed34688f87f30e9a171b1f8b_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_2345314be014258796bc32f9e66d2397_Out_3, _Property_a13e388a84b18e89afce2f9f3ca9753f_Out_0, _GradientNoise_9f2e5d10ed34688f87f30e9a171b1f8b_Out_2);
            float _Property_b64fda08fa35398f9e0f45e316a434f9_Out_0 = Vector1_350643F1;
            float _Multiply_d03d0c5bc6770f8b8fbb46ec0c06b35b_Out_2;
            Unity_Multiply_float(_GradientNoise_9f2e5d10ed34688f87f30e9a171b1f8b_Out_2, _Property_b64fda08fa35398f9e0f45e316a434f9_Out_0, _Multiply_d03d0c5bc6770f8b8fbb46ec0c06b35b_Out_2);
            float _Add_f031b6931be259898e2d889c851d36d5_Out_2;
            Unity_Add_float(_Smoothstep_5a0282a38f27848e9545f1e89a11f5a2_Out_3, _Multiply_d03d0c5bc6770f8b8fbb46ec0c06b35b_Out_2, _Add_f031b6931be259898e2d889c851d36d5_Out_2);
            float _Add_e1b7452d2644ef8e96d652df6def6989_Out_2;
            Unity_Add_float(1, _Property_b64fda08fa35398f9e0f45e316a434f9_Out_0, _Add_e1b7452d2644ef8e96d652df6def6989_Out_2);
            float _Divide_b34aaac0718e8682bb2ab66e45d42421_Out_2;
            Unity_Divide_float(_Add_f031b6931be259898e2d889c851d36d5_Out_2, _Add_e1b7452d2644ef8e96d652df6def6989_Out_2, _Divide_b34aaac0718e8682bb2ab66e45d42421_Out_2);
            float3 _Multiply_a97d25c025f47f8fa4cfe3267dee485e_Out_2;
            Unity_Multiply_float(IN.ObjectSpaceNormal, (_Divide_b34aaac0718e8682bb2ab66e45d42421_Out_2.xxx), _Multiply_a97d25c025f47f8fa4cfe3267dee485e_Out_2);
            float _Property_6f2976fe72816a869d8677a4230164f0_Out_0 = Vector1_E43D3892;
            float3 _Multiply_08ef8c8995ef448a9ab1e43028223a19_Out_2;
            Unity_Multiply_float(_Multiply_a97d25c025f47f8fa4cfe3267dee485e_Out_2, (_Property_6f2976fe72816a869d8677a4230164f0_Out_0.xxx), _Multiply_08ef8c8995ef448a9ab1e43028223a19_Out_2);
            float3 _Add_ec1431816c726e8a827bfd7e7de3d614_Out_2;
            Unity_Add_float3(IN.ObjectSpacePosition, _Multiply_08ef8c8995ef448a9ab1e43028223a19_Out_2, _Add_ec1431816c726e8a827bfd7e7de3d614_Out_2);
            float3 _Add_cbfa9591f076e485a31b7f5b967f99f6_Out_2;
            Unity_Add_float3(_Multiply_3fa32f2d7f56688684a8f5b0a0853be5_Out_2, _Add_ec1431816c726e8a827bfd7e7de3d614_Out_2, _Add_cbfa9591f076e485a31b7f5b967f99f6_Out_2);
            description.Position = _Add_cbfa9591f076e485a31b7f5b967f99f6_Out_2;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }

            // Graph Pixel
            struct SurfaceDescription
        {
            float3 BaseColor;
            float3 Emission;
            float Alpha;
        };

        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            float4 _Property_8602b260fe5c06829b7738349464dbbc_Out_0 = Color_58195353;
            float4 _Property_db73cd07c4394c82a6cd028523c127f3_Out_0 = Color_2CFB5E2A;
            float _Property_45fc02a5c65e898c82a51138ee7894c8_Out_0 = Vector1_FADC0395;
            float _Property_423be2625737e5829e3daa7b3cf8389d_Out_0 = Vector1_E505CA4B;
            float4 _Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0 = Vector4_484BA326;
            float _Split_e9324c176bf05a809ea8df8c413a826a_R_1 = _Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0[0];
            float _Split_e9324c176bf05a809ea8df8c413a826a_G_2 = _Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0[1];
            float _Split_e9324c176bf05a809ea8df8c413a826a_B_3 = _Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0[2];
            float _Split_e9324c176bf05a809ea8df8c413a826a_A_4 = _Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0[3];
            float3 _RotateAboutAxis_430e3c523bf85e84bdef451ab28beba0_Out_3;
            Unity_Rotate_About_Axis_Degrees_float(IN.WorldSpacePosition, (_Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0.xyz), _Split_e9324c176bf05a809ea8df8c413a826a_A_4, _RotateAboutAxis_430e3c523bf85e84bdef451ab28beba0_Out_3);
            float _Property_84dca49c8958708fac3276b0de15a6da_Out_0 = Vector1_8AAD665C;
            float _Multiply_89f92af49e152081ba549c92ab002e9c_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_84dca49c8958708fac3276b0de15a6da_Out_0, _Multiply_89f92af49e152081ba549c92ab002e9c_Out_2);
            float2 _TilingAndOffset_bd9fc632c3a6c185b226f93212ed8603_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_430e3c523bf85e84bdef451ab28beba0_Out_3.xy), float2 (1, 1), (_Multiply_89f92af49e152081ba549c92ab002e9c_Out_2.xx), _TilingAndOffset_bd9fc632c3a6c185b226f93212ed8603_Out_3);
            float _Property_f7111fce9be08b8c871514ffc219f648_Out_0 = Vector1_8F075DBC;
            float _GradientNoise_de42ec7fdd52ec8fa0b6cb7f34842c13_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_bd9fc632c3a6c185b226f93212ed8603_Out_3, _Property_f7111fce9be08b8c871514ffc219f648_Out_0, _GradientNoise_de42ec7fdd52ec8fa0b6cb7f34842c13_Out_2);
            float2 _TilingAndOffset_aa88c06674f4178889e657a2bb46c454_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_430e3c523bf85e84bdef451ab28beba0_Out_3.xy), float2 (1, 1), float2 (0, 0), _TilingAndOffset_aa88c06674f4178889e657a2bb46c454_Out_3);
            float _GradientNoise_28996fa0f6fbd08c97ed18d0621900b5_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_aa88c06674f4178889e657a2bb46c454_Out_3, _Property_f7111fce9be08b8c871514ffc219f648_Out_0, _GradientNoise_28996fa0f6fbd08c97ed18d0621900b5_Out_2);
            float _Add_caf5f972abacae878d9a6fde10e0986a_Out_2;
            Unity_Add_float(_GradientNoise_de42ec7fdd52ec8fa0b6cb7f34842c13_Out_2, _GradientNoise_28996fa0f6fbd08c97ed18d0621900b5_Out_2, _Add_caf5f972abacae878d9a6fde10e0986a_Out_2);
            float _Divide_27ef561e54cd208ca89512269c1d4d03_Out_2;
            Unity_Divide_float(_Add_caf5f972abacae878d9a6fde10e0986a_Out_2, 2, _Divide_27ef561e54cd208ca89512269c1d4d03_Out_2);
            float _Saturate_c56694103011198486afa78b0e89ec2c_Out_1;
            Unity_Saturate_float(_Divide_27ef561e54cd208ca89512269c1d4d03_Out_2, _Saturate_c56694103011198486afa78b0e89ec2c_Out_1);
            float _Property_8bd1d491d3050588a0b837b4b232170d_Out_0 = Vector1_4CE104D9;
            float _Power_abb6d235206009809ee431a98f2c8247_Out_2;
            Unity_Power_float(_Saturate_c56694103011198486afa78b0e89ec2c_Out_1, _Property_8bd1d491d3050588a0b837b4b232170d_Out_0, _Power_abb6d235206009809ee431a98f2c8247_Out_2);
            float4 _Property_8a81e8a6d963f384bddf6e75ec8e0a1c_Out_0 = Vector4_1696EE66;
            float _Split_f72e1ad87d56df8ba34ec31e2bc432b8_R_1 = _Property_8a81e8a6d963f384bddf6e75ec8e0a1c_Out_0[0];
            float _Split_f72e1ad87d56df8ba34ec31e2bc432b8_G_2 = _Property_8a81e8a6d963f384bddf6e75ec8e0a1c_Out_0[1];
            float _Split_f72e1ad87d56df8ba34ec31e2bc432b8_B_3 = _Property_8a81e8a6d963f384bddf6e75ec8e0a1c_Out_0[2];
            float _Split_f72e1ad87d56df8ba34ec31e2bc432b8_A_4 = _Property_8a81e8a6d963f384bddf6e75ec8e0a1c_Out_0[3];
            float4 _Combine_aeef4bbea8acc688b198e488208172f2_RGBA_4;
            float3 _Combine_aeef4bbea8acc688b198e488208172f2_RGB_5;
            float2 _Combine_aeef4bbea8acc688b198e488208172f2_RG_6;
            Unity_Combine_float(_Split_f72e1ad87d56df8ba34ec31e2bc432b8_R_1, _Split_f72e1ad87d56df8ba34ec31e2bc432b8_G_2, 0, 0, _Combine_aeef4bbea8acc688b198e488208172f2_RGBA_4, _Combine_aeef4bbea8acc688b198e488208172f2_RGB_5, _Combine_aeef4bbea8acc688b198e488208172f2_RG_6);
            float4 _Combine_feabe866dc39388d8ccd72275fb9be09_RGBA_4;
            float3 _Combine_feabe866dc39388d8ccd72275fb9be09_RGB_5;
            float2 _Combine_feabe866dc39388d8ccd72275fb9be09_RG_6;
            Unity_Combine_float(_Split_f72e1ad87d56df8ba34ec31e2bc432b8_B_3, _Split_f72e1ad87d56df8ba34ec31e2bc432b8_A_4, 0, 0, _Combine_feabe866dc39388d8ccd72275fb9be09_RGBA_4, _Combine_feabe866dc39388d8ccd72275fb9be09_RGB_5, _Combine_feabe866dc39388d8ccd72275fb9be09_RG_6);
            float _Remap_ca18d3412979f985809f3426d5282816_Out_3;
            Unity_Remap_float(_Power_abb6d235206009809ee431a98f2c8247_Out_2, _Combine_aeef4bbea8acc688b198e488208172f2_RG_6, _Combine_feabe866dc39388d8ccd72275fb9be09_RG_6, _Remap_ca18d3412979f985809f3426d5282816_Out_3);
            float _Absolute_01d69efb5b6b628b8142004f10302240_Out_1;
            Unity_Absolute_float(_Remap_ca18d3412979f985809f3426d5282816_Out_3, _Absolute_01d69efb5b6b628b8142004f10302240_Out_1);
            float _Smoothstep_5a0282a38f27848e9545f1e89a11f5a2_Out_3;
            Unity_Smoothstep_float(_Property_45fc02a5c65e898c82a51138ee7894c8_Out_0, _Property_423be2625737e5829e3daa7b3cf8389d_Out_0, _Absolute_01d69efb5b6b628b8142004f10302240_Out_1, _Smoothstep_5a0282a38f27848e9545f1e89a11f5a2_Out_3);
            float _Property_91482984669b1c8ab26a0f4a555b3801_Out_0 = Vector1_9058DE8C;
            float _Multiply_ad5811e4c08fae88a363e144af359987_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_91482984669b1c8ab26a0f4a555b3801_Out_0, _Multiply_ad5811e4c08fae88a363e144af359987_Out_2);
            float2 _TilingAndOffset_2345314be014258796bc32f9e66d2397_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_430e3c523bf85e84bdef451ab28beba0_Out_3.xy), float2 (1, 1), (_Multiply_ad5811e4c08fae88a363e144af359987_Out_2.xx), _TilingAndOffset_2345314be014258796bc32f9e66d2397_Out_3);
            float _Property_a13e388a84b18e89afce2f9f3ca9753f_Out_0 = Vector1_5536221E;
            float _GradientNoise_9f2e5d10ed34688f87f30e9a171b1f8b_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_2345314be014258796bc32f9e66d2397_Out_3, _Property_a13e388a84b18e89afce2f9f3ca9753f_Out_0, _GradientNoise_9f2e5d10ed34688f87f30e9a171b1f8b_Out_2);
            float _Property_b64fda08fa35398f9e0f45e316a434f9_Out_0 = Vector1_350643F1;
            float _Multiply_d03d0c5bc6770f8b8fbb46ec0c06b35b_Out_2;
            Unity_Multiply_float(_GradientNoise_9f2e5d10ed34688f87f30e9a171b1f8b_Out_2, _Property_b64fda08fa35398f9e0f45e316a434f9_Out_0, _Multiply_d03d0c5bc6770f8b8fbb46ec0c06b35b_Out_2);
            float _Add_f031b6931be259898e2d889c851d36d5_Out_2;
            Unity_Add_float(_Smoothstep_5a0282a38f27848e9545f1e89a11f5a2_Out_3, _Multiply_d03d0c5bc6770f8b8fbb46ec0c06b35b_Out_2, _Add_f031b6931be259898e2d889c851d36d5_Out_2);
            float _Add_e1b7452d2644ef8e96d652df6def6989_Out_2;
            Unity_Add_float(1, _Property_b64fda08fa35398f9e0f45e316a434f9_Out_0, _Add_e1b7452d2644ef8e96d652df6def6989_Out_2);
            float _Divide_b34aaac0718e8682bb2ab66e45d42421_Out_2;
            Unity_Divide_float(_Add_f031b6931be259898e2d889c851d36d5_Out_2, _Add_e1b7452d2644ef8e96d652df6def6989_Out_2, _Divide_b34aaac0718e8682bb2ab66e45d42421_Out_2);
            float4 _Lerp_0f05ab7309374f869f26c5de63c7685d_Out_3;
            Unity_Lerp_float4(_Property_8602b260fe5c06829b7738349464dbbc_Out_0, _Property_db73cd07c4394c82a6cd028523c127f3_Out_0, (_Divide_b34aaac0718e8682bb2ab66e45d42421_Out_2.xxxx), _Lerp_0f05ab7309374f869f26c5de63c7685d_Out_3);
            float _Property_0e672fb430de1988a91ebab3a6c55a4b_Out_0 = Vector1_B4ED823D;
            float _FresnelEffect_d3463b04b6387381ae221b6b9fda5a55_Out_3;
            Unity_FresnelEffect_float(IN.WorldSpaceNormal, IN.WorldSpaceViewDirection, _Property_0e672fb430de1988a91ebab3a6c55a4b_Out_0, _FresnelEffect_d3463b04b6387381ae221b6b9fda5a55_Out_3);
            float _Multiply_b1b397b5458b168183311fa585ce24cc_Out_2;
            Unity_Multiply_float(_Divide_b34aaac0718e8682bb2ab66e45d42421_Out_2, _FresnelEffect_d3463b04b6387381ae221b6b9fda5a55_Out_3, _Multiply_b1b397b5458b168183311fa585ce24cc_Out_2);
            float _Property_a0d7e69c6b484186aed4c837b9cfdf60_Out_0 = Vector1_2BA361A8;
            float _Multiply_c527b7ae93e59a82a8b685490472d140_Out_2;
            Unity_Multiply_float(_Multiply_b1b397b5458b168183311fa585ce24cc_Out_2, _Property_a0d7e69c6b484186aed4c837b9cfdf60_Out_0, _Multiply_c527b7ae93e59a82a8b685490472d140_Out_2);
            float4 _Add_e90a39812292588185bb8af6f98ac6ed_Out_2;
            Unity_Add_float4(_Lerp_0f05ab7309374f869f26c5de63c7685d_Out_3, (_Multiply_c527b7ae93e59a82a8b685490472d140_Out_2.xxxx), _Add_e90a39812292588185bb8af6f98ac6ed_Out_2);
            float _Property_2b5ded79d5faa287bcd134d3931fddbd_Out_0 = Vector1_2A80C598;
            float4 _Multiply_89abd19f1abd878f9e4e10491d20220d_Out_2;
            Unity_Multiply_float(_Add_e90a39812292588185bb8af6f98ac6ed_Out_2, (_Property_2b5ded79d5faa287bcd134d3931fddbd_Out_0.xxxx), _Multiply_89abd19f1abd878f9e4e10491d20220d_Out_2);
            float _SceneDepth_845bf60653d70482b562a739512eeda7_Out_1;
            Unity_SceneDepth_Eye_float(float4(IN.ScreenPosition.xy / IN.ScreenPosition.w, 0, 0), _SceneDepth_845bf60653d70482b562a739512eeda7_Out_1);
            float4 _ScreenPosition_b978995ebe1ba286935416b2a2d5cb85_Out_0 = IN.ScreenPosition;
            float _Split_c66584edb0487b8e8c2e107a89ed8e9f_R_1 = _ScreenPosition_b978995ebe1ba286935416b2a2d5cb85_Out_0[0];
            float _Split_c66584edb0487b8e8c2e107a89ed8e9f_G_2 = _ScreenPosition_b978995ebe1ba286935416b2a2d5cb85_Out_0[1];
            float _Split_c66584edb0487b8e8c2e107a89ed8e9f_B_3 = _ScreenPosition_b978995ebe1ba286935416b2a2d5cb85_Out_0[2];
            float _Split_c66584edb0487b8e8c2e107a89ed8e9f_A_4 = _ScreenPosition_b978995ebe1ba286935416b2a2d5cb85_Out_0[3];
            float _Subtract_39fffd64ebdafb84a6eb8e37e2faaa16_Out_2;
            Unity_Subtract_float(_Split_c66584edb0487b8e8c2e107a89ed8e9f_A_4, 1, _Subtract_39fffd64ebdafb84a6eb8e37e2faaa16_Out_2);
            float _Subtract_d8ff2e79b2fc8386b6172daebbe97366_Out_2;
            Unity_Subtract_float(_SceneDepth_845bf60653d70482b562a739512eeda7_Out_1, _Subtract_39fffd64ebdafb84a6eb8e37e2faaa16_Out_2, _Subtract_d8ff2e79b2fc8386b6172daebbe97366_Out_2);
            float _Property_0a2887e34569358bbc9cbee1a14acebb_Out_0 = Vector1_EED1A887;
            float _Divide_f3ff43869c02038db823cf0d91c23caf_Out_2;
            Unity_Divide_float(_Subtract_d8ff2e79b2fc8386b6172daebbe97366_Out_2, _Property_0a2887e34569358bbc9cbee1a14acebb_Out_0, _Divide_f3ff43869c02038db823cf0d91c23caf_Out_2);
            float _Saturate_676d84ccc0f0b88e9d1fdf263cfcf1d5_Out_1;
            Unity_Saturate_float(_Divide_f3ff43869c02038db823cf0d91c23caf_Out_2, _Saturate_676d84ccc0f0b88e9d1fdf263cfcf1d5_Out_1);
            float _Smoothstep_edf634d16c75cd829225bfca563f83fb_Out_3;
            Unity_Smoothstep_float(0, 1, _Saturate_676d84ccc0f0b88e9d1fdf263cfcf1d5_Out_1, _Smoothstep_edf634d16c75cd829225bfca563f83fb_Out_3);
            surface.BaseColor = IsGammaSpace() ? float3(0, 0, 0) : SRGBToLinear(float3(0, 0, 0));
            surface.Emission = (_Multiply_89abd19f1abd878f9e4e10491d20220d_Out_2.xyz);
            surface.Alpha = _Smoothstep_edf634d16c75cd829225bfca563f83fb_Out_3;
            return surface;
        }

            // --------------------------------------------------
            // Build Graph Inputs

            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);

            output.ObjectSpaceNormal =           input.normalOS;
            output.WorldSpaceNormal =            TransformObjectToWorldNormal(input.normalOS);
            output.ObjectSpaceTangent =          input.tangentOS.xyz;
            output.ObjectSpacePosition =         input.positionOS;
            output.WorldSpacePosition =          TransformObjectToWorld(input.positionOS);
            output.TimeParameters =              _TimeParameters.xyz;

            return output;
        }
            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);

        	// must use interpolated tangent, bitangent and normal before they are normalized in the pixel shader.
        	float3 unnormalizedNormalWS = input.normalWS;
            const float renormFactor = 1.0 / length(unnormalizedNormalWS);


            output.WorldSpaceNormal =            renormFactor*input.normalWS.xyz;		// we want a unit length Normal Vector node in shader graph


            output.WorldSpaceViewDirection =     input.viewDirectionWS; //TODO: by default normalized in HD, but not in universal
            output.WorldSpacePosition =          input.positionWS;
            output.ScreenPosition =              ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
            output.TimeParameters =              _TimeParameters.xyz; // This is mainly for LW as HD overwrite this value
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

            return output;
        }

            // --------------------------------------------------
            // Main

            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/LightingMetaPass.hlsl"

            ENDHLSL
        }
        Pass
        {
            // Name: <None>
            Tags
            {
                "LightMode" = "Universal2D"
            }

            // Render State
            Cull Back
        Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
        ZTest LEqual
        ZWrite Off

            // Debug
            // <None>

            // --------------------------------------------------
            // Pass

            HLSLPROGRAM

            // Pragmas
            #pragma target 2.0
        #pragma only_renderers gles gles3 glcore d3d11
        #pragma multi_compile_instancing
        #pragma vertex vert
        #pragma fragment frag

            // DotsInstancingOptions: <None>
            // HybridV1InjectedBuiltinProperties: <None>

            // Keywords
            // PassKeywords: <None>
            // GraphKeywords: <None>

            // Defines
            #define _SURFACE_TYPE_TRANSPARENT 1
            #define _NORMALMAP 1
            #define _NORMAL_DROPOFF_TS 1
            #define ATTRIBUTES_NEED_NORMAL
            #define ATTRIBUTES_NEED_TANGENT
            #define VARYINGS_NEED_POSITION_WS
            #define FEATURES_GRAPH_VERTEX
            /* WARNING: $splice Could not find named fragment 'PassInstancing' */
            #define SHADERPASS SHADERPASS_2D
        #define REQUIRE_DEPTH_TEXTURE
            /* WARNING: $splice Could not find named fragment 'DotsInstancingVars' */

            // Includes
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

            // --------------------------------------------------
            // Structs and Packing

            struct Attributes
        {
            float3 positionOS : POSITION;
            float3 normalOS : NORMAL;
            float4 tangentOS : TANGENT;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : INSTANCEID_SEMANTIC;
            #endif
        };
        struct Varyings
        {
            float4 positionCS : SV_POSITION;
            float3 positionWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };
        struct SurfaceDescriptionInputs
        {
            float3 WorldSpacePosition;
            float4 ScreenPosition;
        };
        struct VertexDescriptionInputs
        {
            float3 ObjectSpaceNormal;
            float3 WorldSpaceNormal;
            float3 ObjectSpaceTangent;
            float3 ObjectSpacePosition;
            float3 WorldSpacePosition;
            float3 TimeParameters;
        };
        struct PackedVaryings
        {
            float4 positionCS : SV_POSITION;
            float3 interp0 : TEXCOORD0;
            #if UNITY_ANY_INSTANCING_ENABLED
            uint instanceID : CUSTOM_INSTANCE_ID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            uint stereoTargetEyeIndexAsBlendIdx0 : BLENDINDICES0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            uint stereoTargetEyeIndexAsRTArrayIdx : SV_RenderTargetArrayIndex;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            FRONT_FACE_TYPE cullFace : FRONT_FACE_SEMANTIC;
            #endif
        };

            PackedVaryings PackVaryings (Varyings input)
        {
            PackedVaryings output;
            output.positionCS = input.positionCS;
            output.interp0.xyz =  input.positionWS;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }
        Varyings UnpackVaryings (PackedVaryings input)
        {
            Varyings output;
            output.positionCS = input.positionCS;
            output.positionWS = input.interp0.xyz;
            #if UNITY_ANY_INSTANCING_ENABLED
            output.instanceID = input.instanceID;
            #endif
            #if (defined(UNITY_STEREO_MULTIVIEW_ENABLED)) || (defined(UNITY_STEREO_INSTANCING_ENABLED) && (defined(SHADER_API_GLES3) || defined(SHADER_API_GLCORE)))
            output.stereoTargetEyeIndexAsBlendIdx0 = input.stereoTargetEyeIndexAsBlendIdx0;
            #endif
            #if (defined(UNITY_STEREO_INSTANCING_ENABLED))
            output.stereoTargetEyeIndexAsRTArrayIdx = input.stereoTargetEyeIndexAsRTArrayIdx;
            #endif
            #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
            output.cullFace = input.cullFace;
            #endif
            return output;
        }

            // --------------------------------------------------
            // Graph

            // Graph Properties
            CBUFFER_START(UnityPerMaterial)
        float4 Vector4_484BA326;
        float Vector1_8F075DBC;
        float Vector1_8AAD665C;
        float Vector1_E43D3892;
        float4 Vector4_1696EE66;
        float4 Color_2CFB5E2A;
        float4 Color_58195353;
        float Vector1_FADC0395;
        float Vector1_E505CA4B;
        float Vector1_4CE104D9;
        float Vector1_5536221E;
        float Vector1_9058DE8C;
        float Vector1_350643F1;
        float Vector1_2A80C598;
        float Vector1_A664731F;
        float Vector1_B4ED823D;
        float Vector1_2BA361A8;
        float Vector1_EED1A887;
        CBUFFER_END

        // Object and Global properties

            // Graph Functions
            
        void Unity_Distance_float3(float3 A, float3 B, out float Out)
        {
            Out = distance(A, B);
        }

        void Unity_Divide_float(float A, float B, out float Out)
        {
            Out = A / B;
        }

        void Unity_Power_float(float A, float B, out float Out)
        {
            Out = pow(A, B);
        }

        void Unity_Multiply_float(float3 A, float3 B, out float3 Out)
        {
            Out = A * B;
        }

        void Unity_Rotate_About_Axis_Degrees_float(float3 In, float3 Axis, float Rotation, out float3 Out)
        {
            Rotation = radians(Rotation);

            float s = sin(Rotation);
            float c = cos(Rotation);
            float one_minus_c = 1.0 - c;
            
            Axis = normalize(Axis);

            float3x3 rot_mat = { one_minus_c * Axis.x * Axis.x + c,            one_minus_c * Axis.x * Axis.y - Axis.z * s,     one_minus_c * Axis.z * Axis.x + Axis.y * s,
                                      one_minus_c * Axis.x * Axis.y + Axis.z * s,   one_minus_c * Axis.y * Axis.y + c,              one_minus_c * Axis.y * Axis.z - Axis.x * s,
                                      one_minus_c * Axis.z * Axis.x - Axis.y * s,   one_minus_c * Axis.y * Axis.z + Axis.x * s,     one_minus_c * Axis.z * Axis.z + c
                                    };

            Out = mul(rot_mat,  In);
        }

        void Unity_Multiply_float(float A, float B, out float Out)
        {
            Out = A * B;
        }

        void Unity_TilingAndOffset_float(float2 UV, float2 Tiling, float2 Offset, out float2 Out)
        {
            Out = UV * Tiling + Offset;
        }


        float2 Unity_GradientNoise_Dir_float(float2 p)
        {
            // Permutation and hashing used in webgl-nosie goo.gl/pX7HtC
            p = p % 289;
            // need full precision, otherwise half overflows when p > 1
            float x = float(34 * p.x + 1) * p.x % 289 + p.y;
            x = (34 * x + 1) * x % 289;
            x = frac(x / 41) * 2 - 1;
            return normalize(float2(x - floor(x + 0.5), abs(x) - 0.5));
        }

        void Unity_GradientNoise_float(float2 UV, float Scale, out float Out)
        { 
            float2 p = UV * Scale;
            float2 ip = floor(p);
            float2 fp = frac(p);
            float d00 = dot(Unity_GradientNoise_Dir_float(ip), fp);
            float d01 = dot(Unity_GradientNoise_Dir_float(ip + float2(0, 1)), fp - float2(0, 1));
            float d10 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 0)), fp - float2(1, 0));
            float d11 = dot(Unity_GradientNoise_Dir_float(ip + float2(1, 1)), fp - float2(1, 1));
            fp = fp * fp * fp * (fp * (fp * 6 - 15) + 10);
            Out = lerp(lerp(d00, d01, fp.y), lerp(d10, d11, fp.y), fp.x) + 0.5;
        }

        void Unity_Add_float(float A, float B, out float Out)
        {
            Out = A + B;
        }

        void Unity_Saturate_float(float In, out float Out)
        {
            Out = saturate(In);
        }

        void Unity_Combine_float(float R, float G, float B, float A, out float4 RGBA, out float3 RGB, out float2 RG)
        {
            RGBA = float4(R, G, B, A);
            RGB = float3(R, G, B);
            RG = float2(R, G);
        }

        void Unity_Remap_float(float In, float2 InMinMax, float2 OutMinMax, out float Out)
        {
            Out = OutMinMax.x + (In - InMinMax.x) * (OutMinMax.y - OutMinMax.x) / (InMinMax.y - InMinMax.x);
        }

        void Unity_Absolute_float(float In, out float Out)
        {
            Out = abs(In);
        }

        void Unity_Smoothstep_float(float Edge1, float Edge2, float In, out float Out)
        {
            Out = smoothstep(Edge1, Edge2, In);
        }

        void Unity_Add_float3(float3 A, float3 B, out float3 Out)
        {
            Out = A + B;
        }

        void Unity_SceneDepth_Eye_float(float4 UV, out float Out)
        {
            Out = LinearEyeDepth(SHADERGRAPH_SAMPLE_SCENE_DEPTH(UV.xy), _ZBufferParams);
        }

        void Unity_Subtract_float(float A, float B, out float Out)
        {
            Out = A - B;
        }

            // Graph Vertex
            struct VertexDescription
        {
            float3 Position;
            float3 Normal;
            float3 Tangent;
        };

        VertexDescription VertexDescriptionFunction(VertexDescriptionInputs IN)
        {
            VertexDescription description = (VertexDescription)0;
            float _Distance_474c9e8e982c878dad2f0d5844b22ee9_Out_2;
            Unity_Distance_float3(SHADERGRAPH_OBJECT_POSITION, IN.WorldSpacePosition, _Distance_474c9e8e982c878dad2f0d5844b22ee9_Out_2);
            float _Property_95b6af28bf5d388fb7809e99d4ea7a10_Out_0 = Vector1_A664731F;
            float _Divide_2022c703e9e6de87965706bd214b7b67_Out_2;
            Unity_Divide_float(_Distance_474c9e8e982c878dad2f0d5844b22ee9_Out_2, _Property_95b6af28bf5d388fb7809e99d4ea7a10_Out_0, _Divide_2022c703e9e6de87965706bd214b7b67_Out_2);
            float _Power_8710b3fb1efe3183a2818b946e662a1e_Out_2;
            Unity_Power_float(_Divide_2022c703e9e6de87965706bd214b7b67_Out_2, 3, _Power_8710b3fb1efe3183a2818b946e662a1e_Out_2);
            float3 _Multiply_3fa32f2d7f56688684a8f5b0a0853be5_Out_2;
            Unity_Multiply_float(IN.WorldSpaceNormal, (_Power_8710b3fb1efe3183a2818b946e662a1e_Out_2.xxx), _Multiply_3fa32f2d7f56688684a8f5b0a0853be5_Out_2);
            float _Property_45fc02a5c65e898c82a51138ee7894c8_Out_0 = Vector1_FADC0395;
            float _Property_423be2625737e5829e3daa7b3cf8389d_Out_0 = Vector1_E505CA4B;
            float4 _Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0 = Vector4_484BA326;
            float _Split_e9324c176bf05a809ea8df8c413a826a_R_1 = _Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0[0];
            float _Split_e9324c176bf05a809ea8df8c413a826a_G_2 = _Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0[1];
            float _Split_e9324c176bf05a809ea8df8c413a826a_B_3 = _Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0[2];
            float _Split_e9324c176bf05a809ea8df8c413a826a_A_4 = _Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0[3];
            float3 _RotateAboutAxis_430e3c523bf85e84bdef451ab28beba0_Out_3;
            Unity_Rotate_About_Axis_Degrees_float(IN.WorldSpacePosition, (_Property_79ef7586bc718789ab26b5c26e3d3bf5_Out_0.xyz), _Split_e9324c176bf05a809ea8df8c413a826a_A_4, _RotateAboutAxis_430e3c523bf85e84bdef451ab28beba0_Out_3);
            float _Property_84dca49c8958708fac3276b0de15a6da_Out_0 = Vector1_8AAD665C;
            float _Multiply_89f92af49e152081ba549c92ab002e9c_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_84dca49c8958708fac3276b0de15a6da_Out_0, _Multiply_89f92af49e152081ba549c92ab002e9c_Out_2);
            float2 _TilingAndOffset_bd9fc632c3a6c185b226f93212ed8603_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_430e3c523bf85e84bdef451ab28beba0_Out_3.xy), float2 (1, 1), (_Multiply_89f92af49e152081ba549c92ab002e9c_Out_2.xx), _TilingAndOffset_bd9fc632c3a6c185b226f93212ed8603_Out_3);
            float _Property_f7111fce9be08b8c871514ffc219f648_Out_0 = Vector1_8F075DBC;
            float _GradientNoise_de42ec7fdd52ec8fa0b6cb7f34842c13_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_bd9fc632c3a6c185b226f93212ed8603_Out_3, _Property_f7111fce9be08b8c871514ffc219f648_Out_0, _GradientNoise_de42ec7fdd52ec8fa0b6cb7f34842c13_Out_2);
            float2 _TilingAndOffset_aa88c06674f4178889e657a2bb46c454_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_430e3c523bf85e84bdef451ab28beba0_Out_3.xy), float2 (1, 1), float2 (0, 0), _TilingAndOffset_aa88c06674f4178889e657a2bb46c454_Out_3);
            float _GradientNoise_28996fa0f6fbd08c97ed18d0621900b5_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_aa88c06674f4178889e657a2bb46c454_Out_3, _Property_f7111fce9be08b8c871514ffc219f648_Out_0, _GradientNoise_28996fa0f6fbd08c97ed18d0621900b5_Out_2);
            float _Add_caf5f972abacae878d9a6fde10e0986a_Out_2;
            Unity_Add_float(_GradientNoise_de42ec7fdd52ec8fa0b6cb7f34842c13_Out_2, _GradientNoise_28996fa0f6fbd08c97ed18d0621900b5_Out_2, _Add_caf5f972abacae878d9a6fde10e0986a_Out_2);
            float _Divide_27ef561e54cd208ca89512269c1d4d03_Out_2;
            Unity_Divide_float(_Add_caf5f972abacae878d9a6fde10e0986a_Out_2, 2, _Divide_27ef561e54cd208ca89512269c1d4d03_Out_2);
            float _Saturate_c56694103011198486afa78b0e89ec2c_Out_1;
            Unity_Saturate_float(_Divide_27ef561e54cd208ca89512269c1d4d03_Out_2, _Saturate_c56694103011198486afa78b0e89ec2c_Out_1);
            float _Property_8bd1d491d3050588a0b837b4b232170d_Out_0 = Vector1_4CE104D9;
            float _Power_abb6d235206009809ee431a98f2c8247_Out_2;
            Unity_Power_float(_Saturate_c56694103011198486afa78b0e89ec2c_Out_1, _Property_8bd1d491d3050588a0b837b4b232170d_Out_0, _Power_abb6d235206009809ee431a98f2c8247_Out_2);
            float4 _Property_8a81e8a6d963f384bddf6e75ec8e0a1c_Out_0 = Vector4_1696EE66;
            float _Split_f72e1ad87d56df8ba34ec31e2bc432b8_R_1 = _Property_8a81e8a6d963f384bddf6e75ec8e0a1c_Out_0[0];
            float _Split_f72e1ad87d56df8ba34ec31e2bc432b8_G_2 = _Property_8a81e8a6d963f384bddf6e75ec8e0a1c_Out_0[1];
            float _Split_f72e1ad87d56df8ba34ec31e2bc432b8_B_3 = _Property_8a81e8a6d963f384bddf6e75ec8e0a1c_Out_0[2];
            float _Split_f72e1ad87d56df8ba34ec31e2bc432b8_A_4 = _Property_8a81e8a6d963f384bddf6e75ec8e0a1c_Out_0[3];
            float4 _Combine_aeef4bbea8acc688b198e488208172f2_RGBA_4;
            float3 _Combine_aeef4bbea8acc688b198e488208172f2_RGB_5;
            float2 _Combine_aeef4bbea8acc688b198e488208172f2_RG_6;
            Unity_Combine_float(_Split_f72e1ad87d56df8ba34ec31e2bc432b8_R_1, _Split_f72e1ad87d56df8ba34ec31e2bc432b8_G_2, 0, 0, _Combine_aeef4bbea8acc688b198e488208172f2_RGBA_4, _Combine_aeef4bbea8acc688b198e488208172f2_RGB_5, _Combine_aeef4bbea8acc688b198e488208172f2_RG_6);
            float4 _Combine_feabe866dc39388d8ccd72275fb9be09_RGBA_4;
            float3 _Combine_feabe866dc39388d8ccd72275fb9be09_RGB_5;
            float2 _Combine_feabe866dc39388d8ccd72275fb9be09_RG_6;
            Unity_Combine_float(_Split_f72e1ad87d56df8ba34ec31e2bc432b8_B_3, _Split_f72e1ad87d56df8ba34ec31e2bc432b8_A_4, 0, 0, _Combine_feabe866dc39388d8ccd72275fb9be09_RGBA_4, _Combine_feabe866dc39388d8ccd72275fb9be09_RGB_5, _Combine_feabe866dc39388d8ccd72275fb9be09_RG_6);
            float _Remap_ca18d3412979f985809f3426d5282816_Out_3;
            Unity_Remap_float(_Power_abb6d235206009809ee431a98f2c8247_Out_2, _Combine_aeef4bbea8acc688b198e488208172f2_RG_6, _Combine_feabe866dc39388d8ccd72275fb9be09_RG_6, _Remap_ca18d3412979f985809f3426d5282816_Out_3);
            float _Absolute_01d69efb5b6b628b8142004f10302240_Out_1;
            Unity_Absolute_float(_Remap_ca18d3412979f985809f3426d5282816_Out_3, _Absolute_01d69efb5b6b628b8142004f10302240_Out_1);
            float _Smoothstep_5a0282a38f27848e9545f1e89a11f5a2_Out_3;
            Unity_Smoothstep_float(_Property_45fc02a5c65e898c82a51138ee7894c8_Out_0, _Property_423be2625737e5829e3daa7b3cf8389d_Out_0, _Absolute_01d69efb5b6b628b8142004f10302240_Out_1, _Smoothstep_5a0282a38f27848e9545f1e89a11f5a2_Out_3);
            float _Property_91482984669b1c8ab26a0f4a555b3801_Out_0 = Vector1_9058DE8C;
            float _Multiply_ad5811e4c08fae88a363e144af359987_Out_2;
            Unity_Multiply_float(IN.TimeParameters.x, _Property_91482984669b1c8ab26a0f4a555b3801_Out_0, _Multiply_ad5811e4c08fae88a363e144af359987_Out_2);
            float2 _TilingAndOffset_2345314be014258796bc32f9e66d2397_Out_3;
            Unity_TilingAndOffset_float((_RotateAboutAxis_430e3c523bf85e84bdef451ab28beba0_Out_3.xy), float2 (1, 1), (_Multiply_ad5811e4c08fae88a363e144af359987_Out_2.xx), _TilingAndOffset_2345314be014258796bc32f9e66d2397_Out_3);
            float _Property_a13e388a84b18e89afce2f9f3ca9753f_Out_0 = Vector1_5536221E;
            float _GradientNoise_9f2e5d10ed34688f87f30e9a171b1f8b_Out_2;
            Unity_GradientNoise_float(_TilingAndOffset_2345314be014258796bc32f9e66d2397_Out_3, _Property_a13e388a84b18e89afce2f9f3ca9753f_Out_0, _GradientNoise_9f2e5d10ed34688f87f30e9a171b1f8b_Out_2);
            float _Property_b64fda08fa35398f9e0f45e316a434f9_Out_0 = Vector1_350643F1;
            float _Multiply_d03d0c5bc6770f8b8fbb46ec0c06b35b_Out_2;
            Unity_Multiply_float(_GradientNoise_9f2e5d10ed34688f87f30e9a171b1f8b_Out_2, _Property_b64fda08fa35398f9e0f45e316a434f9_Out_0, _Multiply_d03d0c5bc6770f8b8fbb46ec0c06b35b_Out_2);
            float _Add_f031b6931be259898e2d889c851d36d5_Out_2;
            Unity_Add_float(_Smoothstep_5a0282a38f27848e9545f1e89a11f5a2_Out_3, _Multiply_d03d0c5bc6770f8b8fbb46ec0c06b35b_Out_2, _Add_f031b6931be259898e2d889c851d36d5_Out_2);
            float _Add_e1b7452d2644ef8e96d652df6def6989_Out_2;
            Unity_Add_float(1, _Property_b64fda08fa35398f9e0f45e316a434f9_Out_0, _Add_e1b7452d2644ef8e96d652df6def6989_Out_2);
            float _Divide_b34aaac0718e8682bb2ab66e45d42421_Out_2;
            Unity_Divide_float(_Add_f031b6931be259898e2d889c851d36d5_Out_2, _Add_e1b7452d2644ef8e96d652df6def6989_Out_2, _Divide_b34aaac0718e8682bb2ab66e45d42421_Out_2);
            float3 _Multiply_a97d25c025f47f8fa4cfe3267dee485e_Out_2;
            Unity_Multiply_float(IN.ObjectSpaceNormal, (_Divide_b34aaac0718e8682bb2ab66e45d42421_Out_2.xxx), _Multiply_a97d25c025f47f8fa4cfe3267dee485e_Out_2);
            float _Property_6f2976fe72816a869d8677a4230164f0_Out_0 = Vector1_E43D3892;
            float3 _Multiply_08ef8c8995ef448a9ab1e43028223a19_Out_2;
            Unity_Multiply_float(_Multiply_a97d25c025f47f8fa4cfe3267dee485e_Out_2, (_Property_6f2976fe72816a869d8677a4230164f0_Out_0.xxx), _Multiply_08ef8c8995ef448a9ab1e43028223a19_Out_2);
            float3 _Add_ec1431816c726e8a827bfd7e7de3d614_Out_2;
            Unity_Add_float3(IN.ObjectSpacePosition, _Multiply_08ef8c8995ef448a9ab1e43028223a19_Out_2, _Add_ec1431816c726e8a827bfd7e7de3d614_Out_2);
            float3 _Add_cbfa9591f076e485a31b7f5b967f99f6_Out_2;
            Unity_Add_float3(_Multiply_3fa32f2d7f56688684a8f5b0a0853be5_Out_2, _Add_ec1431816c726e8a827bfd7e7de3d614_Out_2, _Add_cbfa9591f076e485a31b7f5b967f99f6_Out_2);
            description.Position = _Add_cbfa9591f076e485a31b7f5b967f99f6_Out_2;
            description.Normal = IN.ObjectSpaceNormal;
            description.Tangent = IN.ObjectSpaceTangent;
            return description;
        }

            // Graph Pixel
            struct SurfaceDescription
        {
            float3 BaseColor;
            float Alpha;
        };

        SurfaceDescription SurfaceDescriptionFunction(SurfaceDescriptionInputs IN)
        {
            SurfaceDescription surface = (SurfaceDescription)0;
            float _SceneDepth_845bf60653d70482b562a739512eeda7_Out_1;
            Unity_SceneDepth_Eye_float(float4(IN.ScreenPosition.xy / IN.ScreenPosition.w, 0, 0), _SceneDepth_845bf60653d70482b562a739512eeda7_Out_1);
            float4 _ScreenPosition_b978995ebe1ba286935416b2a2d5cb85_Out_0 = IN.ScreenPosition;
            float _Split_c66584edb0487b8e8c2e107a89ed8e9f_R_1 = _ScreenPosition_b978995ebe1ba286935416b2a2d5cb85_Out_0[0];
            float _Split_c66584edb0487b8e8c2e107a89ed8e9f_G_2 = _ScreenPosition_b978995ebe1ba286935416b2a2d5cb85_Out_0[1];
            float _Split_c66584edb0487b8e8c2e107a89ed8e9f_B_3 = _ScreenPosition_b978995ebe1ba286935416b2a2d5cb85_Out_0[2];
            float _Split_c66584edb0487b8e8c2e107a89ed8e9f_A_4 = _ScreenPosition_b978995ebe1ba286935416b2a2d5cb85_Out_0[3];
            float _Subtract_39fffd64ebdafb84a6eb8e37e2faaa16_Out_2;
            Unity_Subtract_float(_Split_c66584edb0487b8e8c2e107a89ed8e9f_A_4, 1, _Subtract_39fffd64ebdafb84a6eb8e37e2faaa16_Out_2);
            float _Subtract_d8ff2e79b2fc8386b6172daebbe97366_Out_2;
            Unity_Subtract_float(_SceneDepth_845bf60653d70482b562a739512eeda7_Out_1, _Subtract_39fffd64ebdafb84a6eb8e37e2faaa16_Out_2, _Subtract_d8ff2e79b2fc8386b6172daebbe97366_Out_2);
            float _Property_0a2887e34569358bbc9cbee1a14acebb_Out_0 = Vector1_EED1A887;
            float _Divide_f3ff43869c02038db823cf0d91c23caf_Out_2;
            Unity_Divide_float(_Subtract_d8ff2e79b2fc8386b6172daebbe97366_Out_2, _Property_0a2887e34569358bbc9cbee1a14acebb_Out_0, _Divide_f3ff43869c02038db823cf0d91c23caf_Out_2);
            float _Saturate_676d84ccc0f0b88e9d1fdf263cfcf1d5_Out_1;
            Unity_Saturate_float(_Divide_f3ff43869c02038db823cf0d91c23caf_Out_2, _Saturate_676d84ccc0f0b88e9d1fdf263cfcf1d5_Out_1);
            float _Smoothstep_edf634d16c75cd829225bfca563f83fb_Out_3;
            Unity_Smoothstep_float(0, 1, _Saturate_676d84ccc0f0b88e9d1fdf263cfcf1d5_Out_1, _Smoothstep_edf634d16c75cd829225bfca563f83fb_Out_3);
            surface.BaseColor = IsGammaSpace() ? float3(0, 0, 0) : SRGBToLinear(float3(0, 0, 0));
            surface.Alpha = _Smoothstep_edf634d16c75cd829225bfca563f83fb_Out_3;
            return surface;
        }

            // --------------------------------------------------
            // Build Graph Inputs

            VertexDescriptionInputs BuildVertexDescriptionInputs(Attributes input)
        {
            VertexDescriptionInputs output;
            ZERO_INITIALIZE(VertexDescriptionInputs, output);

            output.ObjectSpaceNormal =           input.normalOS;
            output.WorldSpaceNormal =            TransformObjectToWorldNormal(input.normalOS);
            output.ObjectSpaceTangent =          input.tangentOS.xyz;
            output.ObjectSpacePosition =         input.positionOS;
            output.WorldSpacePosition =          TransformObjectToWorld(input.positionOS);
            output.TimeParameters =              _TimeParameters.xyz;

            return output;
        }
            SurfaceDescriptionInputs BuildSurfaceDescriptionInputs(Varyings input)
        {
            SurfaceDescriptionInputs output;
            ZERO_INITIALIZE(SurfaceDescriptionInputs, output);





            output.WorldSpacePosition =          input.positionWS;
            output.ScreenPosition =              ComputeScreenPos(TransformWorldToHClip(input.positionWS), _ProjectionParams.x);
        #if defined(SHADER_STAGE_FRAGMENT) && defined(VARYINGS_NEED_CULLFACE)
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN output.FaceSign =                    IS_FRONT_VFACE(input.cullFace, true, false);
        #else
        #define BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN
        #endif
        #undef BUILD_SURFACE_DESCRIPTION_INPUTS_OUTPUT_FACESIGN

            return output;
        }

            // --------------------------------------------------
            // Main

            #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/Varyings.hlsl"
        #include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/PBR2DPass.hlsl"

            ENDHLSL
        }
    }
    CustomEditor "ShaderGraph.PBRMasterGUI"
    FallBack "Hidden/Shader Graph/FallbackError"
}