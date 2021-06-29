using System;
using FogOfWar;
using UnityEngine;
using Vector3 = UnityEngine.Vector3;

namespace Assets.Modules.SimpleSoldiers._Move
{
    public class DebugDecalScript : MonoBehaviour
    {
        public Transform Plane;

        public void Initialize(Vector2 lowerLeft, float cellSize, int numCells,FogOfWarSettings fogOfWarSettings)
        {
            this.fogOfWarSettings = fogOfWarSettings;
            var size = numCells * cellSize;
            transform.position = new Vector3(size * 0.5f, transform.position.y, size * 0.5f);
            transform.localScale = new Vector3(-size / 10, 1, -size / 10);
            tex2D = new Texture2D(numCells, numCells);
            tex2D.filterMode = FilterMode.Point;

            tex = new RenderTexture(numCells, numCells,24);
            tex.enableRandomWrite = true;
            tex.Create();
            fogOfWarSettings.FOWtex = tex;

            data = new Color[numCells * numCells];

            //Plane.GetComponent<MeshRenderer>().material.mainTexture = tex2D;

            if (fogOfWarSettings.ComputeType == FogOfWarSettings.ComputeMethod.CPU)
                Plane.GetComponent<MeshRenderer>().material.mainTexture = tex2D;
            else
                Plane.GetComponent<MeshRenderer>().material.mainTexture = fogOfWarSettings.FOWtex;


        }

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