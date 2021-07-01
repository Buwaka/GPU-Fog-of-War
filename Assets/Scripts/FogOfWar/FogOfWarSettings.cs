using System;
using UnityEngine;

namespace FogOfWar
{
    [Serializable]
    public class FogOfWarSettings
    {
        public enum Mode : int
        {
            All,
            FactionBlue = 1,
            FactionRed = 2
        }

        public enum ComputeMethod
        {
            CPU,
            GPU
        }

        /// <summary>
        /// Number of cells in the grid, in one dimension
        /// </summary>
        [Header("Map settings")] public int GridSize = 128;
        public int MapSize = 4096;

        /// <summary>
        /// World space size of a single cell
        /// </summary>
        public float CellSize = 1;

        public int SoldierEdgeClamping = 1;


        [Header("Rendering")] public Mode mode = Mode.All;
        public Color FactionRedColor = Color.red;
        public Color FactioBlueColor = Color.blue;
        public bool DrawRangesEnabled;
        [SerializeField]
        public ComputeMethod ComputeType = ComputeMethod.CPU;
        public ComputeShader GPUFOWShader = null;
        [HideInInspector]
        public RenderTexture FOWtex = null;
        [HideInInspector] //don't forget to change this in the shader and vice versa
        public const int FoWMap_ShaderArray_Size = 512;

        [Header("Simulation")] public bool WanderEnabled;
        public bool ChangeFactionEnabled;
        public int PerformanceTestSoldiersCount = 40;
    }
}