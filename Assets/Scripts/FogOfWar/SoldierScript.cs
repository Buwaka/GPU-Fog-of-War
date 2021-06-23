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
        public Vector3 LastPosition;

        public float ViewRange = 40;
        public Quaternion Rotation = Quaternion.identity;

        public void Start()
        {
            SetFaction(FactionId);
        }

        public void Init()
        {
            Position = LastPosition = transform.position;
            RegisterFOW();
        }

        public void SetPosition(Vector3 position)
        {
            Position = transform.position = position;
            RegisterFOW();
        }

        public void SetRotation(Quaternion rotation)
        {
            Rotation = transform.rotation = rotation;
        }

        private void RegisterFOW()
        {
            FogOfWarData Data;
            Data.Position = new Vector2(Position.x, Position.z);
            Data.LastPosition = new Vector2(LastPosition.x, LastPosition.z);
            Data.Range = ViewRange;
            Data.FactionID = (byte)FactionId;
            Data.IsVisible = renderer.enabled;

            FogOfWarService.Instance.RegisterFOWData(Data);
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