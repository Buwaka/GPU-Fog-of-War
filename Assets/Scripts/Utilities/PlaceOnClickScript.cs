using Modules.StarshipTroopers.Battles.BattleCombat.TracerSystems;
using UnityEngine;
using UnityEngine.EventSystems;

namespace Assets.PathfindingAstarProject
{
    public class PlaceOnClickScript : MonoBehaviour
    {
        public bool Continuous = false;
        public bool RequiresClicking = true;

        public int MouseButton = 1;

        public KeyCode Key;
        public bool UseKey = false;

        private Vector3? point;
        void Update()
        {
            var ray = Camera.main.ScreenPointToRay(Input.mousePosition);
            if (Physics.Raycast(ray, out var hitInfo))
                point = hitInfo.point;
            else
                point = null;

            if (!point.HasValue) return;


            var isPressed = UseKey ? Input.GetKey(Key) : Input.GetMouseButton(MouseButton);
            var isDown = UseKey ? Input.GetKeyDown(Key) : Input.GetMouseButtonDown(MouseButton);

            if (EventSystem.current.IsPointerOverGameObject())
            {
                isPressed = false;
                isDown = false;
            }
            
            var updatePoint = !RequiresClicking
                              || (isPressed && Continuous)
                              || (isDown);

            if (updatePoint)
            {

                GetComponent<SoldierScript>().SetPosition(hitInfo.point);
            }

        }

        private void OnDrawGizmos()
        {
            if (point.HasValue)
                Gizmos.DrawSphere(point.Value, 0.5f);
        }


    }
}