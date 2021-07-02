using System;
using System.Collections.Generic;
using Modules.StarshipTroopers.Battles.BattleCombat.TracerSystems;
using System.Linq;
using UnityEngine;

namespace FogOfWar
{
    public struct FogOfWarData
    {
        public Vector2 Position;
        public float Range;
        public int FactionID;
        public int IsVisible;

        public const int size = ((sizeof(float) * 3) + (sizeof(int) * 2));
    }

    /// <summary>
    /// Responsible for calculating fog of war for soldiers
    /// </summary>
    public class FogOfWarService : MonoBehaviour
    {
        private FogOfWarSettings settings;

        private Dictionary<uint,FogOfWarData> FOWdata = new Dictionary<uint, FogOfWarData>(200); //finda better heuristic instead of 200

        private ComputeShader FOWComputeShader;
        //private ComputeBuffer[] FOWDataBuffer;
        //private int CurrentBuffer = 0;

        //singleton
        private static FogOfWarService _instance;
        public static FogOfWarService Instance
        {
            get
            {
                if (_instance == null)
                {
                    _instance = GameObject.FindObjectOfType<FogOfWarService>();

                    if (_instance == null)
                    {
                        GameObject container = new GameObject("FogOfWarService");
                        _instance = container.AddComponent<FogOfWarService>();
                    }
                }
                return _instance;
            }
        }

        public void RegisterSettings(FogOfWarSettings settings)
        {
            // settings.CellSize; world space size of cell
            // settings.GridSize; number of cells in one dimension
            this.settings = settings;

            InitShader(settings);
        }

        private uint ThreadGroupSizeX = 0;
        private uint ThreadGroupSizeY = 0;
        private uint ThreadGroupSizeZ = 0;
        public void InitShader(FogOfWarSettings settings)
        {
            FOWComputeShader = settings.GPUFOWShader;
            int kernel = FOWComputeShader.FindKernel("FOWMapGenerator");

            FOWComputeShader.SetVector("FactionRedColor", settings.FactionRedColor);
            FOWComputeShader.SetVector("FactionBlueColor", settings.FactioBlueColor);
            FOWComputeShader.SetFloat("_GridSize", settings.GridSize);
            FOWComputeShader.SetFloat("_CellSize", settings.CellSize);

            //FOWComputeShader.SetTexture(kernel, "Result", settings.FOWtex);
            FOWComputeShader.SetTextureFromGlobal(kernel, "_FoWMap", "_FoWMap_Global");


            FOWComputeShader.GetKernelThreadGroupSizes(kernel, out ThreadGroupSizeX, out ThreadGroupSizeY, out ThreadGroupSizeZ);

            //FOWDataBuffer[0] = new ComputeBuffer(FOWdata.Count, FogOfWarData.size, ComputeBufferType.Structured);
            //FOWDataBuffer.SetData(FOWdata.Values.ToArray());
            //FOWComputeShader.SetBuffer(kernel, "_FOWData", FOWDataBuffer);
        }

        public void InitExistingSoldiers(List<SoldierScript> soldiers)
        {
            // Can add soldier init logic here if desired, is called on startup. (but not for new soldiers spawned during play)
        }

        /// <summary>
        /// 
        /// </summary>
        /// <param name="soldiers">The list of soldiers that provide visibility</param>
        /// <param name="outVisibleToFaction">
        /// The output list that should store for each cell, to which factions the cells is visible.
        /// This array is implemented as a flattened list (y*size+x), and the value of each element is a bitmask:
        /// 0 : cell not visible by any faction, will be shown as grey on the map
        /// 1 : cell visible by blue faction, will be shown as blue on the map
        /// 2 : cell visible by red faction, will be shown as red on the map
        /// 3 : cell visible by both factions, will be shown as pink on the map
        ///
        /// Note: This list is the same list every frame, it is not cleared automatically.
        /// </param>
        public void UpdateFogOfWar(List<SoldierScript> soldiers, byte[] outVisibleToFaction, uint size)
        {
            Array.Clear(outVisibleToFaction, 0, (int) size);

            foreach (var entry in FOWdata)
            {
                var ID = entry.Key;
                var data = entry.Value;

                //clean last position
                //Algorithms.MidPointCircle.DrawFullCircle(data.LastPosition, data.Range, settings.GridSize, settings.CellSize, 0, outVisibleToFaction, false);

                if (data.IsVisible > 0)
                {
                    byte value = (byte)(data.FactionID);

                    Algorithms.MidPointCircle.DrawFullCircle(data.Position, data.Range, settings.GridSize, settings.CellSize, value, outVisibleToFaction, size, false);
                }
            }

            FOWdata.Clear();
        }


        public void UpdateFogOfWarGPU(List<SoldierScript> soldiers, byte[] outVisibleToFaction, uint size)
        {
            if (FOWdata.Count == 0)
                return;

            int MapSize = settings.GridSize * settings.GridSize;
            if (MapSize > Mathf.Pow(2, 14)) //can't be greater than 16kb
            {
                Debug.Log("Fog of War map is too big for current buffer, either increase the size or cry when hardware limit has been reached");
                return;
            }

            int kernel = FOWComputeShader.FindKernel("FOWMapGenerator");

            FOWComputeShader.SetInt("_DataCount", FOWdata.Count);

            ComputeBuffer FOWDataBuffer = new ComputeBuffer(FOWdata.Count, FogOfWarData.size, ComputeBufferType.Structured);
            FOWDataBuffer.SetData(FOWdata.Values.ToArray());
            FOWComputeShader.SetBuffer(kernel, "_FoWData", FOWDataBuffer);

            int ThreadCount = Mathf.CeilToInt((float)FOWdata.Count / ThreadGroupSizeX);
            FOWComputeShader.SetInt("_DispatchThreadCount", ThreadCount);
            FOWComputeShader.Dispatch(kernel, 1, 1, 1);


            FOWDataBuffer.Dispose();
            FOWdata.Clear();
        }

            /// <summary>
            /// If settings.mode == FogOfWarSettings.Mode.FactionRed, all soldiers seen by red faction
            /// should be visible, the others invisible.
            /// 
            /// set visibility using SoldierScript.SetVisible
            /// Note that invisible soldiers still show their sunglasses :). This is to make it easier to see whats going on
            /// </summary>
            /// <param name="soldiers"></param>
            /// <param name="visibleToFaction"></param>
            public void UpdateSoldierVisibilities(List<SoldierScript> soldiers, byte[] visibleToFaction, uint size)
        {
            foreach (var s in soldiers)
            {
                if(settings.mode == FogOfWarSettings.Mode.All || s.FactionId == (int) settings.mode)
                {
                    s.SetVisible(true);
                }
                else
                {
                    s.SetVisible(false);
                }
            }
        }

        public void RegisterFOWData(uint ID, FogOfWarData data)
        {
            if (FOWdata.ContainsKey(ID))
                FOWdata[ID] = data;
            else
                FOWdata.Add(ID, data);
        }
    }
}