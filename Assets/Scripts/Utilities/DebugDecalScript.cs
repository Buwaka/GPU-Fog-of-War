using System;
using FogOfWar;
using UnityEngine;
using Vector3 = UnityEngine.Vector3;

namespace Assets.Modules.SimpleSoldiers._Move
{
    public class DebugDecalScript : MonoBehaviour
    {

        public void Initialize(Vector2 lowerLeft, float cellSize, int numCells, FogOfWarSettings fogOfWarSettings)
        {
            this.fogOfWarSettings = fogOfWarSettings;
            var size = fogOfWarSettings.GridSize * cellSize;
            transform.position = new Vector3(size * 0.5f, transform.position.y, size * 0.5f);
            transform.localScale = new Vector3(-size / 10, 1, -size / 10);
            tex2D = new Texture2D(numCells, numCells);
            tex2D.filterMode = FilterMode.Point;

            data = new Color[numCells * numCells];

            //Plane.GetComponent<MeshRenderer>().material.mainTexture = tex2D;

            if (fogOfWarSettings.ComputeType == FogOfWarSettings.ComputeMethod.CPU)
                Plane.GetComponent<MeshRenderer>().material.mainTexture = tex2D;
            else
                SpawnPlanes(fogOfWarSettings);


        }

        void SpawnPlanes(FogOfWarSettings settings)
        {
            int GridCountRow = settings.MapSize / settings.GridSize;
            int GridCountTotal = GridCountRow * GridCountRow;
            int size = settings.GridSize;


            RenderTextureDescriptor d = new RenderTextureDescriptor(settings.GridSize, settings.GridSize, RenderTextureFormat.ARGB32);
            d.dimension = UnityEngine.Rendering.TextureDimension.Tex2DArray;
            d.volumeDepth = GridCountTotal;

            settings.FOWtex = new RenderTexture(d);
            settings.FOWtex.enableRandomWrite = true;
            settings.FOWtex.Create();

            Planes = new GameObject[GridCountTotal];

            for (int i = 0; i < GridCountTotal; i++)
            {
                int left = (i % settings.GridSize);
                int bottom = Mathf.FloorToInt((float)i / settings.GridSize);

                var pl = Instantiate<GameObject>(Plane);
                pl.transform.position = new Vector3(left + (size * 0.5f), Plane.transform.position.y, bottom + (size * 0.5f));
                pl.transform.localScale = new Vector3(-size / 10, 1, -size / 10);
                pl.GetComponent<MeshRenderer>().material.mainTexture = settings.FOWtex;

                Planes[i] = pl;
            }

            settings.FOWtex = tex;

        }

        public GameObject Plane;
        private GameObject[] Planes;
        private Texture2D tex2D;
        private RenderTexture tex;
        private Color[] data;
        private FogOfWarSettings fogOfWarSettings;


        public void UpdateTexture2D(byte[] alliances)
        {
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