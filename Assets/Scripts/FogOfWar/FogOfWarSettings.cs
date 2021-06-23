using System;
using UnityEngine;

namespace FogOfWar
{
    [Serializable]
    public class FogOfWarSettings
    {
        public enum Mode
        {
            All,
            FactionRed,
            FactionBlue
        }

        /// <summary>
        /// Number of cells in the grid, in one dimension
        /// </summary>
        [Header("Map settings")] public int GridSize = 128;

        /// <summary>
        /// World space size of a single cell
        /// </summary>
        public float CellSize = 1;

        public int SoldierEdgeClamping = 1;


        [Header("Rendering")] public Mode mode = Mode.All;
        public bool DrawRangesEnabled;

        [Header("Simulation")] public bool WanderEnabled;
        public bool ChangeFactionEnabled;
        public int PerformanceTestSoldiersCount = 40;
    }
}