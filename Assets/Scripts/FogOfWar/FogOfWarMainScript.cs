using System.Collections.Generic;
using System.Diagnostics;
using System.Linq;
using Assets.Modules.SimpleSoldiers._Move;
using FogOfWar;
using Modules.StarshipTroopers.Battles.BattleCombat.TracerSystems;
using Unity.Profiling;
using UnityEngine;
using UnityEngine.Profiling;
using UnityEngine.UI;
using Debug = UnityEngine.Debug;

namespace DefaultNamespace
{
    public class FogOfWarMainScript : MonoBehaviour
    {
        public FogOfWarSettings Settings;

        [Header("Wiring")]
        public SoldierScript SoldierPrefab;
        public Canvas Canvas;
        public Transform GroundPlane;
     
        public DebugDecalScript Decal;

        private List<SoldierScript> soldiers;
        private FogOfWarService fogOfWarService;
        private Recorder recorder;

        ProfilerMarker fogOfWarMarkerCPU = new ProfilerMarker("Fog Of War - CPU");
        ProfilerMarker fogOfWarMarkerGPU = new ProfilerMarker("Fog Of War - GPU");
        ProfilerMarker visibilityMarker = new ProfilerMarker("Visibility");

        private Stopwatch watch = new Stopwatch();
        
        public void OnEnable()
        {
            visibleToFaction = new byte[Settings.GridSize * Settings.GridSize];
            VisibleToFaction_Size = (uint)Settings.GridSize * (uint)Settings.GridSize;



            GroundPlane.localScale = Settings.CellSize *Settings. GridSize * 0.1f * Vector3.one;
            GroundPlane.position = new Vector3((Settings.GridSize * Settings.CellSize) * 0.5f, 0, (Settings.GridSize * Settings.CellSize) * 0.5f);
            Decal.Initialize(new Vector2(0, 0), Settings.CellSize,Settings. GridSize, Settings);
            soldiers = FindObjectsOfType<SoldierScript>().ToList();
            Random.InitState(0);
            fogOfWarService = FogOfWarService.Instance;
            fogOfWarService.RegisterSettings(Settings);
            fogOfWarService.InitExistingSoldiers(soldiers);
            var sampler = Sampler.Get("Fog Of War");
            recorder = sampler.GetRecorder();
            recorder.enabled = true;
            foreach (var s in soldiers) s.Init();

            Canvas.transform.Find("All").GetComponent<Button>().onClick
                .AddListener(() => Settings.mode = FogOfWarSettings.Mode.All);
            Canvas.transform.Find("Red Faction").GetComponent<Button>().onClick
                .AddListener(() => Settings.mode = FogOfWarSettings.Mode.FactionRed);
            Canvas.transform.Find("Blue Faction").GetComponent<Button>().onClick
                .AddListener(() => Settings.mode = FogOfWarSettings.Mode.FactionBlue);
            
            Canvas.transform.Find("Toggle Wander").GetComponent<Button>().onClick
                .AddListener(() => Settings.WanderEnabled = !Settings.WanderEnabled);
            Canvas.transform.Find("Toggle Faction Changing").GetComponent<Button>().onClick
                .AddListener(() => Settings.ChangeFactionEnabled = !Settings.ChangeFactionEnabled);
            
            Canvas.transform.Find("Spawn").GetComponent<Button>().onClick
                .AddListener(spawnRandomSoldier);
            Canvas.transform.Find("Performance Test").GetComponent<Button>().onClick
                .AddListener(spawnPerformanceTest);
            
        }


        public void Update()
        {
            processKeysInput();

            Wander();
            ChangeRandomFaction();

            double fowTime,visibilityTime;
            if(Settings.ComputeType == FogOfWarSettings.ComputeMethod.CPU)
            {
                using (fogOfWarMarkerCPU.Auto())
                {
                    watch.Restart();
                    fogOfWarService.UpdateFogOfWar(soldiers, visibleToFaction, VisibleToFaction_Size);
                    watch.Stop();
                    fowTime = watch.Elapsed.TotalMilliseconds;
                }
            }
            else
            {
                using (fogOfWarMarkerGPU.Auto())
                {
                    watch.Restart();
                    fogOfWarService.UpdateFogOfWarGPU(soldiers, visibleToFaction, VisibleToFaction_Size);
                    watch.Stop();
                    fowTime = watch.Elapsed.TotalMilliseconds;
                }
            }

            using (visibilityMarker.Auto())
            {
                watch.Restart();
                fogOfWarService.UpdateSoldierVisibilities(soldiers, visibleToFaction, VisibleToFaction_Size);
                watch.Stop();
                visibilityTime = watch.Elapsed.TotalMilliseconds;

            }

            updateFogOfWarRendering(visibleToFaction);
            renderSoldierRanges();
            Debug.Log($"Fog Of War: {fowTime:0.00}ms - " +
                      $"Visibility: {visibilityTime:0.00}ms");
        }

        private void renderSoldierRanges()
        {
            if (!Settings.DrawRangesEnabled) return;
            foreach (var s in soldiers)
            {
                //DebugDrawer.Get.CircleXZ(new Vector3((s.Position.x+0.5f)*CellSize,0,(s.Position.z+0.5f)*CellSize),s.ViewRange,Color.yellow);
                DebugDrawer.Get.CircleXZ(new Vector3(s.Position.x,0,s.Position.z),s.ViewRange,Color.yellow);
            }
        }

        private void processKeysInput()
        {
            if (Input.GetKeyDown(KeyCode.F)) spawnRandomSoldier();
            if (Input.GetKeyDown(KeyCode.K)) spawnPerformanceTest();
        }

        private void spawnPerformanceTest()
        {
            while (soldiers.Count < Settings.PerformanceTestSoldiersCount)
                spawnRandomSoldier();
        }

        private float lastChange = 0;
        private byte[] visibleToFaction;
        private uint VisibleToFaction_Size;

        private void ChangeRandomFaction()
        {
            if (!Settings.ChangeFactionEnabled) return;
            if (lastChange + 1 < Time.timeSinceLevelLoad)
            {
                var s = soldiers[Random.Range(0, soldiers.Count)];
                s.SetFaction(s.FactionId == 0 ? 1 : 2);
                lastChange = Time.timeSinceLevelLoad;
            }
        }

        private void spawnRandomSoldier()
        {
            var pos = new Vector3(
                Random.value * (Settings.GridSize *Settings. CellSize - Settings.SoldierEdgeClamping * 2) + Settings.SoldierEdgeClamping, 0,
                Random.value * (Settings.GridSize * Settings.CellSize - Settings.SoldierEdgeClamping * 2) + Settings.SoldierEdgeClamping);
            var faction = Random.Range(1, 3);
            var s = Instantiate(SoldierPrefab);
            soldiers.Add(s);
            s.SetFaction(faction);
            s.SetPosition(pos);
            s.Init();
        }

        private void updateFogOfWarRendering(byte[] visibleToFaction)
        {
            Decal.UpdateTexture2D(visibleToFaction);
        }


        public void Wander()
        {
            var wanderTimeMin = 5;
            var wanderTimeMax = 10;
            var wanderRange = 16;
            var moveSpeed = 3;
            var rotationSpeed = 90;
            var GridSize = Settings.GridSize;
            var CellSize = Settings.CellSize;
            var SoldierEdgeClamping = Settings.SoldierEdgeClamping;
            foreach (var s in soldiers)
            {
                if (Vector2.Distance(s.MoveTarget, s.Position) < 0.01f) s.HasMoveTarget = false;
                if (s.NextWander < Time.timeSinceLevelLoad && Settings.WanderEnabled)
                {
                    var insideUnitCircle =
                        Random.insideUnitCircle * wanderRange + new Vector2(s.Position.x, s.Position.z);
                    insideUnitCircle.x = Mathf.Clamp(insideUnitCircle.x, SoldierEdgeClamping,
                                                     GridSize * CellSize - SoldierEdgeClamping);
                    insideUnitCircle.y = Mathf.Clamp(insideUnitCircle.y, SoldierEdgeClamping,
                                                     GridSize * CellSize - SoldierEdgeClamping);
                    s.MoveTarget = new Vector3(insideUnitCircle.x, 0, insideUnitCircle.y);
                    s.HasMoveTarget = true;
                    s.NextWander = Time.timeSinceLevelLoad + Random.Range(wanderTimeMin, wanderTimeMax);
                }

                if (s.HasMoveTarget)
                {
                    var toTarget = s.MoveTarget - s.Position;
                    var Position = Vector3.MoveTowards(s.Position, s.MoveTarget, Time.deltaTime * moveSpeed);
                    var Rotation = Quaternion.RotateTowards(s.Rotation, Quaternion.LookRotation(toTarget),
                                                          Time.deltaTime * rotationSpeed);

                    s.SetPosition(Position);
                    s.SetRotation(Rotation);
                }
            }
        }
    }
}