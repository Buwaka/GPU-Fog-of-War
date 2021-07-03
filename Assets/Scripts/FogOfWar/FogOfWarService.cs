using System;
using System.Collections;
using System.Collections.Generic;
using Modules.StarshipTroopers.Battles.BattleCombat.TracerSystems;
using System.Linq;
using UnityEngine;

namespace FogOfWar
{

    //public class FogOfWarSortByMapID : IComparer<FogOfWarData>
    //{
    //    // Call CaseInsensitiveComparer.Compare with the parameters reversed.
    //    public int Compare(FogOfWarData left, FogOfWarData right)
    //    {
    //        return (int)left.MapID - (int)right.MapID;
    //    }
    //}

    public struct FogOfWarDataInter
    {
        public uint MapID;
        public FogOfWarData Data;

        public FogOfWarDataInter(uint ID, FogOfWarData data)
        {
            MapID = ID; Data = data;
        }
    }

    public struct FogOfWarData
    {
        public Vector2 Position;
        public float Range;
        public int FactionID;


        public const int size = ((sizeof(float) * 3) + (sizeof(int) * 1));
    }

    public struct FogOfWarIndex
    {
        public uint index;
        public uint count;

        public FogOfWarIndex(uint index, uint count)
        {
            this.index = index;
            this.count = count;
        }

        public static FogOfWarIndex operator ++(FogOfWarIndex left)
        {
            return new FogOfWarIndex(left.index, left.count + 1);
        }

        public const int size = sizeof(int) * 2;
    }

    /// <summary>
    /// Responsible for calculating fog of war for soldiers
    /// </summary>
    public class FogOfWarService : MonoBehaviour
    {
        private FogOfWarSettings settings;

        private SortedList<uint, FogOfWarDataInter> FoWData = new SortedList<uint, FogOfWarDataInter>(200); //finda better heuristic instead of 200
        private List<FogOfWarData> FoWDataBuffer = new List<FogOfWarData>(200);
        //private List<FogOfWarData> FOWdata = new List<FogOfWarData>(200);

        //array index is mapID
        private List<FogOfWarIndex> FoWData_Indieces;
        //private Tuple<uint, uint>[] FoWData_Indieces;

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

        void Start()
        {

        }

        public void RegisterSettings(FogOfWarSettings settings)
        {
            // settings.CellSize; world space size of cell
            // settings.GridSize; number of cells in one dimension
            this.settings = settings;

            FoWData_Indieces = new List<FogOfWarIndex>(settings.GridCountTotal);
            FogOfWarIndex temp;
            temp.index = 0;
            temp.count = 0;
            for (int i = 0; i < settings.GridCountTotal; i++)
            {
                FoWData_Indieces.Add(temp);
            }
                

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
            FOWComputeShader.SetFloat("_MapSize", settings.MapSize);

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

            foreach (var entry in FoWData)
            {

                var data = entry.Value;

                //clean last position
                //Algorithms.MidPointCircle.DrawFullCircle(data.LastPosition, data.Range, settings.GridSize, settings.CellSize, 0, outVisibleToFaction, false);


                byte value = (byte)(data.Data.FactionID);

                Algorithms.MidPointCircle.DrawFullCircle(data.Data.Position, data.Data.Range, settings.GridSize, settings.CellSize, value, outVisibleToFaction, size, false);
            }

            //FOWdata.Clear();
        }

        private void GPUCleanup()
        {
            //zero out the index array
            FogOfWarIndex temp;
            temp.index = 0;
            temp.count = 0;
            for (int i = 0; i < FoWData_Indieces.Count; i++)
            {
                FoWData_Indieces[i] = temp;
            }

            FoWDataBuffer.Clear();
        }

        public void UpdateFogOfWarGPU(List<SoldierScript> soldiers, byte[] outVisibleToFaction, uint size)
        {
            if (FoWData.Count == 0)
                return;

            int MapSize = settings.GridSize * settings.GridSize;
            if (MapSize > Mathf.Pow(2, 14)) //can't be greater than 16kb
            {
                Debug.Log("Fog of War map is too big for current buffer, either increase the size or cry when hardware limit has been reached");
                return;
            }

            //here we would sort the FoWData, but it is already sorted

            uint lastID = uint.MaxValue;
            uint index = 0;
            foreach (var item in FoWData.OrderBy(p => p.Value.MapID))
            {
                uint MapID = item.Value.MapID;

                if(lastID != MapID)
                {
                    FoWData_Indieces[(int)MapID] = new FogOfWarIndex(index, 1);
                    lastID = MapID;
                }
                else
                {
                    FoWData_Indieces[(int)MapID]++;
                }

                FoWDataBuffer.Add(item.Value.Data);
                index++;
            }


            //uint i = 0;
            //while (i < FoWDataBuffer.Count)
            //{
            //    var data = FoWDataBuffer[(int)i];

            //    uint count = FoWData_Indieces[(int)data.MapID].count;

            //    FoWData_Indieces[(int)data.MapID] = new FogOfWarIndex(i, count);
            //    i += count;
            //}


            int kernel = FOWComputeShader.FindKernel("FOWMapGenerator");

            ComputeBuffer FOWDataBuffer = new ComputeBuffer(FoWDataBuffer.Count, FogOfWarData.size, ComputeBufferType.Structured);
            FOWDataBuffer.SetData(FoWDataBuffer);
            FOWComputeShader.SetBuffer(kernel, "_FoWData", FOWDataBuffer);

            ComputeBuffer FOWIndexBuffer = new ComputeBuffer(settings.GridCountTotal, FogOfWarIndex.size, ComputeBufferType.Structured);
            FOWIndexBuffer.SetData(FoWData_Indieces);
            FOWComputeShader.SetBuffer(kernel, "_DataCountPerMap", FOWIndexBuffer);

            FOWComputeShader.Dispatch(kernel, settings.GridCountTotal, 1, 1);


            FOWDataBuffer.Dispose();
            FOWIndexBuffer.Dispose();

            GPUCleanup();
            //FOWdata.Clear();
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
                //foreach (var s in soldiers)
                //{
                //    if(settings.mode == FogOfWarSettings.Mode.All || s.FactionId == (int) settings.mode)
                //    {
                //        s.SetVisible(true);
                //    }
                //    else
                //    {
                //        s.SetVisible(false);
                //    }
                //}
            }

        private uint CalculateMapID(Vector2 position)
        {
            Vector2 TilePosition = position / settings.CellSize / settings.GridSize;
            return (uint)((Mathf.Floor(TilePosition.y) * settings.GridCountRow) + Mathf.FloorToInt(TilePosition.x));
        }

        public void RegisterFOWData(uint ID, FogOfWarData data)
        {
            uint MapID = CalculateMapID(data.Position);

            if(MapID > settings.GridCountTotal)
            {
                Debug.Log("Failed to register FoW Data, unit is outside of the FoW area");
                return;
            }

            //Debug.Log("soldier on MapID " + MapID.ToString());

            FogOfWarDataInter temp = new FogOfWarDataInter(MapID, data);


            if (FoWData.ContainsKey(ID))
            {
                FoWData[ID] = temp;
            }
            else
            {
                FoWData.Add(ID, temp);
            }
        }
    }
}