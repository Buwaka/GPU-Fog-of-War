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
            tex = new Texture2D(numCells, numCells);
            tex.filterMode = FilterMode.Point;
            data = new Color[numCells * numCells];
            Plane.GetComponent<MeshRenderer>().material.mainTexture = tex;
        }

        private Texture2D tex;
        private Color[] data;
        private FogOfWarSettings fogOfWarSettings;


        public void UpdateTexture(byte[] alliances)
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

            tex.SetPixels(data);
            tex.Apply();
        }
    }
}