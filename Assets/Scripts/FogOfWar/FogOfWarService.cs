using System;
using System.Collections.Generic;
using Modules.StarshipTroopers.Battles.BattleCombat.TracerSystems;
using UnityEngine;

namespace FogOfWar
{
    public struct FogOfWarData
    {
        public Vector2 Position;
        public Vector2 LastPosition;
        public float Range;
        public byte FactionID;
        public bool IsVisible;
    }

    /// <summary>
    /// Responsible for calculating fog of war for soldiers
    /// </summary>
    public class FogOfWarService : MonoBehaviour
    {
        private FogOfWarSettings settings;

        private Dictionary<uint,FogOfWarData> FOWdata = new Dictionary<uint, FogOfWarData>(200); //finda better heuristic instead of 200

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
        public void UpdateFogOfWar(List<SoldierScript> soldiers, byte[] outVisibleToFaction)
        {
            outVisibleToFaction[3 * settings.GridSize + 2] = 0; // set cell (x:2,y:3) is visibile to no faction
            outVisibleToFaction[3 * settings.GridSize + 3] = 1; // set cell (x:3,y:3) is visibile to blue
            outVisibleToFaction[3 * settings.GridSize + 4] = 2; // set cell (x:4,y:3) is visibile to red
            outVisibleToFaction[3 * settings.GridSize + 5] = 3; // set cell (x:5,y:3) is visibile to both

            foreach(var entry in FOWdata)
            {
                var ID = entry.Key;
                var data = entry.Value;

                //clean last position
                Algorithms.MidPointCircle.DrawCircle2(data.LastPosition, data.Range, settings.GridSize, settings.CellSize, 0, outVisibleToFaction);

                if(data.IsVisible)
                {
                    byte value = (byte)(data.FactionID);

                    Algorithms.MidPointCircle.DrawCircle2(data.Position, data.Range, settings.GridSize, settings.CellSize, value, outVisibleToFaction);
                }
            }

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
        public void UpdateSoldierVisibilities(List<SoldierScript> soldiers, byte[] visibleToFaction)
        {
            soldiers[0].SetVisible(true);
            soldiers[1].SetVisible(false);
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