using System;
using FogOfWar;
using UnityEngine;
using Vector3 = UnityEngine.Vector3;

namespace Assets.Modules.SimpleSoldiers._Move
{
    public class DebugDecalScript : MonoBehaviour
    {
        public Material FoWMapMaterial;
        public GameObject Plane;
        public GameObject PlaneCPU;
        private GameObject[] Planes;
        private Texture2D tex2D;
        private RenderTexture tex;
        private Color[] data;
        private FogOfWarSettings fogOfWarSettings;


        public void Initialize(Vector2 lowerLeft, float cellSize, int numCells, FogOfWarSettings fogOfWarSettings)
        {
            this.fogOfWarSettings = fogOfWarSettings;
            var size = fogOfWarSettings.GridSize * cellSize;


            data = new Color[numCells * numCells];

            //Plane.GetComponent<MeshRenderer>().material.mainTexture = tex2D;

            if (fogOfWarSettings.ComputeType == FogOfWarSettings.ComputeMethod.CPU)
            {
                PlaneCPU = Instantiate<GameObject>(PlaneCPU);

                PlaneCPU.transform.position = new Vector3(size * 0.5f, transform.position.y, size * 0.5f);
                PlaneCPU.transform.localScale = new Vector3(-size / 10, 1, -size / 10);
                tex2D = new Texture2D(numCells, numCells);
                tex2D.filterMode = FilterMode.Point;

                PlaneCPU.GetComponent<MeshRenderer>().sharedMaterial.mainTexture = tex2D;
            }
            else
                SpawnPlanes(fogOfWarSettings);


        }

        void SpawnPlanes(FogOfWarSettings settings)
        {
            int GridCountRow = settings.GridCountRow;
            int GridCountTotal = settings.GridCountTotal;
            float size = settings.GridSize * settings.CellSize;


            RenderTextureDescriptor d = new RenderTextureDescriptor(settings.GridSize, settings.GridSize, RenderTextureFormat.ARGB32);
            d.dimension = UnityEngine.Rendering.TextureDimension.Tex2DArray;
            d.volumeDepth = GridCountTotal; // how many maps we want
            d.enableRandomWrite = true;
            

            settings.FOWtex = new RenderTexture(d);
            settings.FOWtex.name = "FoWMap";
            settings.FOWtex.enableRandomWrite = true;
            settings.FOWtex.Create();

            Shader.SetGlobalTexture("_FoWMap_Global", settings.FOWtex, UnityEngine.Rendering.RenderTextureSubElement.Default);

            Planes = new GameObject[GridCountTotal];

            for (int i = 0; i < GridCountTotal; i++)
            {
                float left = (i % GridCountRow) * size;
                float bottom = Mathf.Floor((float)i / GridCountRow) * size;

                var pl = Instantiate<GameObject>(Plane);
                pl.transform.position = new Vector3(left + (size * 0.5f), Plane.transform.position.y, bottom + (size * 0.5f));
                pl.transform.localScale = new Vector3(-size / 10, 1, -size / 10);
                //pl.GetComponent<MeshRenderer>().material = Instantiate(FoWMapMaterial);
                pl.GetComponent<MeshRenderer>().material.SetInt("_FoWMapID",i);
                //pl.GetComponent<MeshRenderer>().material.s

                Planes[i] = pl;
            }
        }



        public void UpdateTexture2D(byte[] alliances)
        {
            if (fogOfWarSettings.ComputeType != FogOfWarSettings.ComputeMethod.CPU)
                return;

            var ma1 = (fogOfWarSettings.mode == FogOfWarSettings.Mode.All ||
                      fogOfWarSettings.mode == FogOfWarSettings.Mode.FactionBlue) ? 1 : 0;
            var ma2 = (fogOfWarSettings.mode == FogOfWarSettings.Mode.All ||
                      fogOfWarSettings.mode == FogOfWarSettings.Mode.FactionRed) ? 2 : 0;
            for (int i = 0; i < alliances.Length; i++)
            {
                var a1 = (alliances[i] & ma1);
                var a2 = (alliances[i] & ma2) /2;
                data[i] = new Color(a2, 0, a1, a1+a2 == 0 ? 0.5f : 0.2f);
            }

            tex2D.SetPixels(data);
            tex2D.Apply();
        }

        public void UpdateTexture(RenderTexture tex)
        {

            //tex.Apply();
        }
    }
}