using FogOfWar;
using UnityEngine;

namespace Modules.StarshipTroopers.Battles.BattleCombat.TracerSystems
{
    public class SoldierScript : MonoBehaviour
    {
        /// <summary>
        /// TODO make this 0.1
        /// </summary>
        public int FactionId;

        public Material FactionA;
        public Material FactionB;
        [SerializeField] private MeshRenderer renderer;
        public Vector3 MoveTarget;
        public bool HasMoveTarget;
        public float NextWander;
        public Vector3 Position;

        public float ViewRange = 40;
        public Quaternion Rotation = Quaternion.identity;

        public void Start()
        {
            SetFaction(FactionId);
        }

        public void SetVisible(bool visible)
        {
            renderer.enabled = visible;
        }

        public void SetFaction(int factionId)
        {
            FactionId = factionId;
            if (factionId == 0) renderer.material = FactionA;
            if (factionId == 1) renderer.material = FactionB;
        }
    }
}