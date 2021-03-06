//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2016
//==============================================================================

class DHArmoredVehicle extends DHVehicle
    abstract;

#exec OBJ LOAD FILE=..\sounds\Amb_Destruction.uax
#exec OBJ LOAD FILE=..\Textures\DH_VehicleOptics_tex.utx
#exec OBJ LOAD FILE=..\Textures\DH_VehiclesGE_tex2.utx

enum ENewHitPointType
{
    NHP_Normal,
    NHP_GunOptics,
    NHP_PeriscopeOptics,
    NHP_Traverse,
    NHP_GunPitch,
    NHP_Hull,
};

var     ENewHitPointType    NewHitPointType;    // array of new DH special vehicle hit points that may be hit & damaged

struct NewHitpoint
{
    var   float             PointRadius;        // squared radius of the head of the pawn that is vulnerable to headshots
    var   float             PointHeight;        // distance from base of neck to center of head - used for headshot calculation
    var   float             PointScale;         // scale factor for radius & height
    var   name              PointBone;          // bone to reference in offset
    var   vector            PointOffset;        // amount to offset the hitpoint from the bone
    var   bool              bPenetrationPoint;  // this is a penetration point, open hatch, etc
    var   float             DamageMultiplier;   // amount to scale damage to the vehicle if this point is hit
    var   ENewHitPointType  NewHitPointType;    // what type of hit point this is
};

// General
var     int         UnbuttonedPositionIndex;    // lowest DriverPositions index where driver is unbuttoned & exposed
var     bool        bMustUnbuttonToSwitchToRider; // stops driver 'teleporting' outside to rider position if buttoned up
var     vector      OverlayFPCamPos;            // optional camera offset for overlay position, so can snap to exterior view position, avoiding camera anims passing through hull
var     texture     PeriscopeOverlay;           // driver's periscope overlay texture
var     texture     DamagedPeriscopeOverlay;    // gunsight overlay to show if optics have been broken

// Armor penetration
var     float       UFrontArmorFactor, URightArmorFactor, ULeftArmorFactor, URearArmorFactor; // upper hull armor thickness (actually used for whole hull, for now)
var     float       UFrontArmorSlope, URightArmorSlope, ULeftArmorSlope, URearArmorSlope;     // upper hull armor slope
var     bool        bHasAddedSideArmor;         // this vehicle has added side armour skirts (schurzen) that will stop HEAT rounds
var     bool        bProjectilePenetrated;      // shell has passed penetration tests & has entered the vehicle (used in TakeDamage)
var     bool        bTurretPenetration;         // shell has penetrated the turret (used in TakeDamage)
var     bool        bRearHullPenetration;       // shell has penetrated the rear hull (so TakeDamage can tell if an engine hit should stop the round penetrating any further)

// Damage
var     array<NewHitpoint>  NewVehHitpoints;    // an array of possible small points that can be hit. Index zero is always the driver
var     int         GunOpticsHitPointIndex;     // index of any special hit point for exposed gunsight optics, which may be damaged by a bullet
var     float       AmmoIgnitionProbability;    // chance that direct hit on ammo store will ignite it
var     float       TurretDetonationThreshold;  // chance that shrapnel will detonate turret ammo
var     float       DriverKillChance;           // chance that shrapnel will kill driver
var     float       CommanderKillChance;        // chance that shrapnel will kill commander
var     float       GunnerKillChance;           // chance that shrapnel will kill bow gunner
var     float       GunDamageChance;            // chance that shrapnel will damage gun pivot mechanism
var     float       TraverseDamageChance;       // chance that shrapnel will damage gun traverse mechanism or turret ring is jammed
var     float       OpticsDamageChance;         // chance that shrapnel will break gunsight optics
var     float       SpikeTime;                  // saved future time when a disabled vehicle will be automatically blown up, if empty at that time

// Fire stuff- Shurek & Ch!cKeN (modified by Matt)
var     class<DamageType>           VehicleBurningDamType;
var     class<VehicleDamagedEffect> FireEffectClass;
var     VehicleDamagedEffect        DriverHatchFireEffect;
var     name        FireAttachBone;
var     vector      FireEffectOffset;
var     float       HullFireChance;
var     float       HullFireHEATChance;
var     bool        bOnFire;               // the vehicle itself is on fire
var     float       HullFireDamagePer2Secs;
var     float       PlayerFireDamagePer2Secs;
var     float       NextHullFireDamageTime;
var     float       EngineFireChance;
var     float       EngineFireHEATChance;
var     bool        bEngineOnFire;
var     float       EngineFireDamagePer3Secs;
var     float       NextEngineFireDamageTime;
var     bool        bSetHullFireEffects;
var     bool        bDriverHatchFireNeeded;
var     float       DriverHatchFireSpawnTime;
var     bool        bTurretFireNeeded;
var     float       TurretHatchFireSpawnTime;
var     bool        bHullMGFireNeeded;
var     float       HullMGHatchFireSpawnTime;
var     float       FireDetonationChance;   // chance of a fire blowing a vehicle up, runs each time the fire does damage
var     float       EngineToHullFireChance; // chance of an engine fire spreading to the rest of the vehicle, runs each time engine takes fire damage
var     bool        bFirstPenetratingHit;
var     bool        bHEATPenetration;       // a penetrating round is a HEAT round
var     Controller  WhoSetOnFire;
var     int         HullFireStarterTeam;
var     Controller  WhoSetEngineOnFire;
var     int         EngineFireStarterTeam;
var     sound       SmokingEngineSound;

// Debugging
var     bool        bDrawPenetration; // debug lines on screen
var     bool        bPenetrationText; // text on screen
var     bool        bLogPenetration;  // log entries

replication
{
    // Variables the server will replicate to all clients
    reliable if (bNetDirty && Role == ROLE_Authority)
        bOnFire, bEngineOnFire;

    // Functions a client can call on the server
    reliable if (Role < ROLE_Authority)
        ServerHullFire, ServerEngineFire; // these ones in debug mode only
}

///////////////////////////////////////////////////////////////////////////////////////
//  ********************** ACTOR INITIALISATION & DESTRUCTION  ********************  //
///////////////////////////////////////////////////////////////////////////////////////

// Modified to set fire damage properties
simulated function PostBeginPlay()
{
    super.PostBeginPlay();

    if (Role == ROLE_Authority)
    {
        // Set fire damage rates
        HullFireDamagePer2Secs = HealthMax * 0.02;             // so approx 100 seconds from full vehicle health to detonation due to fire
        EngineFireDamagePer3Secs = default.EngineHealth * 0.1; // so approx 30 seconds engine fire until engine destroyed
    }
}

///////////////////////////////////////////////////////////////////////////////////////
//  ***************************** KEY ENGINE EVENTS  ******************************  //
///////////////////////////////////////////////////////////////////////////////////////

// Modified to handle fire effects
simulated function PostNetReceive()
{
    super.PostNetReceive();

    if (bOnFire)
    {
        // Vehicle fire has started
        if (!bSetHullFireEffects && Health > 0)
        {
            SetFireEffects();
        }
    }
    else if (bEngineOnFire)
    {
        // Engine fire has started (DEHFireFactor of 1.0 would flag that the engine fire effect is already on)
        if (DamagedEffectHealthFireFactor != 1.0 && Health > 0)
        {
            SetFireEffects();
        }
    }
    // Engine is dead & engine fire has burned out, so set it to smoke instead of burn
    else if (EngineHealth <= 0 && (DamagedEffectHealthFireFactor != 0.0 || DamagedEffectHealthHeavySmokeFactor != 1.0) && Health > 0)
    {
        SetFireEffects();
    }
}

// Modified to use a system of interwoven timers instead of constantly checking for things in Tick() - fire damage, spiked vehicle timer
simulated function Timer()
{
    local float Now;

    if (Health <= 0)
    {
        return;
    }

    Now = Level.TimeSeconds;

    if (Role == ROLE_Authority)
    {
        // Handle any hull fire damage due
        if (bOnFire && Now >= NextHullFireDamageTime)
        {
            TakeFireDamage();
        }

        // Handle any engine fire damage due
        if (bEngineOnFire && Now >= NextEngineFireDamageTime)
        {
            TakeEngineFireDamage();
        }

        // Check to see if we need to destroy a spiked, abandoned vehicle
        if (bSpikedVehicle && Now >= SpikeTime)
        {
            if (IsVehicleEmpty() && !bOnFire)
            {
                KilledBy(self);
            }
            else
            {
                bSpikedVehicle = false; // cancel spike timer if vehicle is now occupied or burning (just let the fire destroy it)
            }
        }
    }

    // Vehicle is burning, so check if we need to spawn any hatch fire effects
    if (bOnFire && Level.NetMode != NM_DedicatedServer)
    {
        if (bDriverHatchFireNeeded && Now >= DriverHatchFireSpawnTime && DriverHatchFireSpawnTime != 0.0)
        {
            StartDriverHatchFire();
        }

        if (bTurretFireNeeded && Now >= TurretHatchFireSpawnTime && TurretHatchFireSpawnTime != 0.0)
        {
            bTurretFireNeeded = false;

            if (Cannon != none)
            {
                Cannon.StartHatchFire();
            }
        }

        if (bHullMGFireNeeded && Now >= HullMGHatchFireSpawnTime && HullMGHatchFireSpawnTime != 0.0)
        {
            bHullMGFireNeeded = false;

            if (MGun != none)
            {
                MGun.StartHatchFire();
            }
        }
    }

    // Engine is dead, but there's no fire, so make sure it is set to smoke instead of burn
    if (EngineHealth <= 0 && !bEngineOnFire && !bOnFire && (DamagedEffectHealthFireFactor != 0.0 || DamagedEffectHealthHeavySmokeFactor != 1.0))
    {
        SetFireEffects();
    }

    SetNextTimer(Now);
}

// New function as we are using timers for different things in different net modes, so work out which one (if any) is due next
simulated function SetNextTimer(optional float Now)
{
    local float NextTimerTime;

    if (Now == 0.0)
    {
        Now = Level.TimeSeconds;
    }

    if (Role == ROLE_Authority)
    {
        if (bOnFire && NextHullFireDamageTime > Now)
        {
            NextTimerTime = NextHullFireDamageTime;
        }

        if (bEngineOnFire && (NextEngineFireDamageTime < NextTimerTime || NextTimerTime == 0.0) && NextEngineFireDamageTime > Now)
        {
            NextTimerTime = NextEngineFireDamageTime;
        }

        if (bSpikedVehicle && (SpikeTime < NextTimerTime || NextTimerTime == 0.0) && SpikeTime > Now)
        {
            NextTimerTime = SpikeTime;
        }
    }

    if (Level.NetMode != NM_DedicatedServer && bOnFire)
    {
        if (bDriverHatchFireNeeded && (DriverHatchFireSpawnTime < NextTimerTime || NextTimerTime == 0.0) && DriverHatchFireSpawnTime > Now)
        {
            NextTimerTime = DriverHatchFireSpawnTime;
        }

        if (bTurretFireNeeded && (TurretHatchFireSpawnTime < NextTimerTime || NextTimerTime == 0.0) && TurretHatchFireSpawnTime > Now)
        {
            NextTimerTime = TurretHatchFireSpawnTime;
        }

        if (bHullMGFireNeeded && (HullMGHatchFireSpawnTime < NextTimerTime || NextTimerTime == 0.0) && HullMGHatchFireSpawnTime > Now)
        {
            NextTimerTime = HullMGHatchFireSpawnTime;
        }
    }

    // Finally set the next timer, if we need one
    if (NextTimerTime > Now)
    {
        SetTimer(NextTimerTime - Now, false);
    }
}

///////////////////////////////////////////////////////////////////////////////////////
//  *******************************  VIEW/DISPLAY  ********************************  //
///////////////////////////////////////////////////////////////////////////////////////

// Modified to add support for periscope texture overlay
simulated function DrawHUD(Canvas C)
{
    local PlayerController PC;
    local float            SavedOpacity;

    PC = PlayerController(Controller);

    if (PC != none && !PC.bBehindView)
    {
        // Player is in a position where an overlay should be drawn
        if (DriverPositions[DriverPositionIndex].bDrawOverlays && (!IsInState('ViewTransition') || DriverPositions[PreviousPositionIndex].bDrawOverlays))
        {
            if (HUDOverlay == none)
            {
                // Draw periscope overlay
                if (PeriscopeOverlay != none)
                {
                    // Save current HUD opacity & then set up for drawing overlays
                    SavedOpacity = C.ColorModulate.W;
                    C.ColorModulate.W = 1.0;
                    C.DrawColor.A = 255;
                    C.Style = ERenderStyle.STY_Alpha;

                    DrawPeriscopeOverlay(C);

                    C.ColorModulate.W = SavedOpacity; // reset HudOpacity to original value
                }
            }
            // Draw any HUD overlay
            else if (!Level.IsSoftwareRendering())
            {
                HUDOverlay.SetLocation(PC.CalcViewLocation + (HUDOverlayOffset >> PC.CalcViewRotation));
                HUDOverlay.SetRotation(PC.CalcViewRotation);
                C.DrawActor(HUDOverlay, false, true, FClamp(HUDOverlayFOV * (PC.DesiredFOV / PC.DefaultFOV), 1.0, 170.0));
            }
        }

        // Draw vehicle, turret, ammo count, passenger list
        if (ROHud(PC.myHUD) != none)
        {
            ROHud(PC.myHUD).DrawVehicleIcon(C, self);
        }
    }
}

// New function to draw any textured driver's periscope overlay
simulated function DrawPeriscopeOverlay(Canvas C)
{
    local float ScreenRatio;

    ScreenRatio = float(C.SizeY) / float(C.SizeX);
    C.SetPos(0.0, 0.0);
    C.DrawTile(PeriscopeOverlay, C.SizeX, C.SizeY, 0.0, (1.0 - ScreenRatio) * float(PeriscopeOverlay.VSize) / 2.0, PeriscopeOverlay.USize, float(PeriscopeOverlay.VSize) * ScreenRatio);
}

///////////////////////////////////////////////////////////////////////////////////////
//  ******************************** VEHICLE ENTRY  ******************************** //
///////////////////////////////////////////////////////////////////////////////////////

// Modified to add an extra section from deprecated ROTreadCraft class that was commented "code to get the bots using tanks better"
function Vehicle FindEntryVehicle(Pawn P)
{
    local int i;

    if (P != none && Bot(P.Controller) != none && WeaponPawns.Length > 0 && IsVehicleEmpty())
    {
        for (i = WeaponPawns.Length -1; i >= 0; --i)
        {
            if (WeaponPawns[i] != none && WeaponPawns[i].Driver == none)
            {
                return WeaponPawns[i];
            }
        }
    }

    return super.FindEntryVehicle(P);
}

// Modified to prevent entry if either vehicle is on fire
function bool TryToDrive(Pawn P)
{
    // Don't allow entry to burning vehicle (with message)
    if (bOnFire || bEngineOnFire)
    {
        DisplayVehicleMessage(9, P); // vehicle is on fire

        return false;
    }

    return super.TryToDrive(P);
}

// Modified to handle optional camera offset for initial overlay position
simulated function ClientKDriverEnter(PlayerController PC)
{
    super.ClientKDriverEnter(PC);

    // If initial position is an overlay position (e.g. driver's periscope), apply any optional 1st person camera offset for the overlay
    if (DriverPositions[InitialPositionIndex].bDrawOverlays && OverlayFPCamPos != vect(0.0, 0.0, 0.0))
    {
        FPCamPos = OverlayFPCamPos;
    }
}

///////////////////////////////////////////////////////////////////////////////////////
//  ***************************** DRIVER VIEW POINTS  ****************************** //
///////////////////////////////////////////////////////////////////////////////////////

// Modified to handle optional camera offset for initial overlay position
simulated state ViewTransition
{
    simulated function HandleTransition()
    {
        super.HandleTransition();

        if (Level.NetMode != NM_DedicatedServer && OverlayFPCamPos != vect(0.0, 0.0, 0.0) && DriverPositions[PreviousPositionIndex].bDrawOverlays
            && IsHumanControlled() && !PlayerController(Controller).bBehindView)
        {
            FPCamPos = default.FPCamPos; // if moving away from overlay, remove offset immediately
        }
    }

    simulated function EndState()
    {
        super.EndState();

        if (Level.NetMode != NM_DedicatedServer && OverlayFPCamPos != vect(0.0, 0.0, 0.0) && DriverPositions[DriverPositionIndex].bDrawOverlays
            && IsHumanControlled() && !PlayerController(Controller).bBehindView)
        {
            FPCamPos = OverlayFPCamPos; // if moving into overlay, apply offset at end of transition
        }
    }
}

///////////////////////////////////////////////////////////////////////////////////////
//  ******************************** VEHICLE EXIT  ********************************* //
///////////////////////////////////////////////////////////////////////////////////////

// Modified to add clientside check to stop call to server if player selected a rider position but is buttoned up (no 'teleporting' outside to external rider position)
simulated function SwitchWeapon(byte F)
{
    if (Role < ROLE_Authority && StopExitToRiderPosition(F - 2))
    {
        return;
    }

    super.SwitchWeapon(F);
}

// Modified to prevent 'teleporting' outside to external rider position while buttoned up inside vehicle
function ServerChangeDriverPosition(byte F)
{
    if (!StopExitToRiderPosition(F - 2))
    {
        super.ServerChangeDriverPosition(F);
    }
}

// New function to check if player is trying to 'teleport' outside to external rider position while buttoned up (just saves repeating code in different functions)
simulated function bool StopExitToRiderPosition(byte ChosenWeaponPawnIndex)
{
    return ChosenWeaponPawnIndex >= FirstRiderPositionIndex && ChosenWeaponPawnIndex < PassengerWeapons.Length && bMustUnbuttonToSwitchToRider && !CanExit();
}

// Implemented to prevent exit if player is buttoned up, displaying an appropriate "unbutton the hatch" message if he can't
simulated function bool CanExit()
{
    if (DriverPositionIndex < UnbuttonedPositionIndex || (IsInState('ViewTransition') && DriverPositionIndex == UnbuttonedPositionIndex))
    {
        if (DriverPositions.Length > UnbuttonedPositionIndex) // means it is possible to unbutton
        {
            DisplayVehicleMessage(4,, true); // must unbutton the hatch
        }
        else if (MGun != none && MGun.WeaponPawn != none && MGun.WeaponPawn.DriverPositions.Length > MGun.WeaponPawn.UnbuttonedPositionIndex) // means it's possible to exit MG position
        {
            DisplayVehicleMessage(11); // must exit through commander's or MG hatch
        }
        else
        {
            DisplayVehicleMessage(5); // must exit through commander's hatch
        }

        return false;
    }

    return true;
}

///////////////////////////////////////////////////////////////////////////////////////
//  ************************* ENGINE START/STOP & EFFECTS ************************** //
///////////////////////////////////////////////////////////////////////////////////////

// Modified to handle extended vehicle fire system, plus setting manual/powered turret
simulated function SetEngine()
{
    if (bEngineOff || Health <= 0 || EngineHealth <= 0)
    {
        TurnDamping = 0.0;

        if (bOnFire || bEngineOnFire)
        {
            AmbientSound = VehicleBurningSound;
            SoundVolume = 255;
            SoundRadius = 200.0;
        }
        else if (EngineHealth <= 0)
        {
            AmbientSound = SmokingEngineSound;
            SoundVolume = 64;
            SoundRadius = 200.0;
        }
        else
        {
            AmbientSound = none;
        }

        if (bEmittersOn)
        {
            StopEmitters();
        }
    }
    else
    {
        if (IdleSound != none)
        {
            AmbientSound = IdleSound;
            SoundVolume = default.SoundVolume;
            SoundRadius = default.SoundRadius;
        }

        if (!bEmittersOn)
        {
            StartEmitters();
        }
    }

    if (Cannon != none && DHVehicleCannonPawn(Cannon.WeaponPawn) != none)
    {
        DHVehicleCannonPawn(Cannon.WeaponPawn).SetManualTurret(bEngineOff);
    }
}

///////////////////////////////////////////////////////////////////////////////////////
//  ******************************** VEHICLE FIRES  ******************************** //
///////////////////////////////////////////////////////////////////////////////////////

// New function to handle starting a hull fire
function StartHullFire(Pawn InstigatedBy)
{
    bOnFire = true;

    if (bDebuggingText)
    {
        Level.Game.Broadcast(self, "Vehicle set on fire");
    }

    // Record the player responsible for starting fire, so score can be awarded later if results in a kill
    if (InstigatedBy != none)
    {
        WhoSetOnFire = InstigatedBy.Controller;
        DelayedDamageInstigatorController = WhoSetOnFire;
    }

    if (WhoSetOnFire != none)
    {
        HullFireStarterTeam = WhoSetOnFire.GetTeamNum();
    }

    // Set the 1st hull damage due in 2 seconds
    NextHullFireDamageTime = Level.TimeSeconds + 2.0;

    // Fire effects, including timers for delayed hatch fires
    if (Level.NetMode != NM_DedicatedServer)
    {
        SetFireEffects();
    }
    else
    {
        SetNextTimer(); // for damage only on server
    }
}

// New function to handle starting an engine fire
function StartEngineFire(Pawn InstigatedBy)
{
    bEngineOnFire = true;

    if (bDebuggingText)
    {
        Level.Game.Broadcast(self, "Engine set on fire");
    }

    // Record the player responsible for starting fire, so score can be awarded later if results in a kill
    if (InstigatedBy != none)
    {
        WhoSetEngineOnFire = InstigatedBy.Controller;

        if (WhoSetEngineOnFire != none)
        {
            EngineFireStarterTeam = WhoSetEngineOnFire.GetTeamNum();

            if (DelayedDamageInstigatorController == none) // don't override DDIC if already set, e.g. someone else may already have set hull on fire
            {
                DelayedDamageInstigatorController = WhoSetEngineOnFire;
            }
        }
    }

    // Set fire damage due immediately & call Timer() directly (it handles damage & setting of next due Timer)
    NextEngineFireDamageTime = Level.TimeSeconds;
    Timer();

    // Engine fire effect
    SetFireEffects();
}

// Set up for spawning various hatch fire effects, but randomise start times to desync them
simulated function SetFireEffects()
{
    if (Level.NetMode != NM_DedicatedServer)
    {
        if (bOnFire || bEngineOnFire)
        {
            // Engine fire effect
            if (DamagedEffectHealthFireFactor != 1.0)
            {
                DamagedEffectHealthFireFactor = 1.0;
                DamagedEffectHealthSmokeFactor = 1.0; // appears necessary to get native code to spawn a DamagedEffect if it doesn't already exist
                                                      // (presumably doesn't check for fire unless vehicle is at least damaged enough to smoke)

                if (DamagedEffect == none && Health == HealthMax) // clientside Health hack to get native code to spawn DamagedEffect (it won't unless vehicle has taken some damage)
                {
                    Health--;
                }
            }

            // Hatch fire effects
            if (bOnFire && !bSetHullFireEffects)
            {
                bSetHullFireEffects = true;

                // If bClientInitialized or we're an authority role (single player or listen server) then this must have been called as the fire breaks out
                // Randomise the fire effect start times (spreading from the engine forwards) & set a timer
                if (bClientInitialized || Role == ROLE_Authority)
                {
                    if (Cannon != none)
                    {
                        bTurretFireNeeded = true;
                        TurretHatchFireSpawnTime = Level.TimeSeconds + 2.0 + (FRand() * 3.0); // turret hatch fire starts 2-5 secs after fire starts in engine
                    }

                    bDriverHatchFireNeeded = true;
                    DriverHatchFireSpawnTime = FMax(TurretHatchFireSpawnTime, Level.TimeSeconds) + 2.0 + (FRand() * 3.0); // driver hatch fire starts 2-5 secs after turret fire

                    if (MGun != none)
                    {
                        bHullMGFireNeeded = true;
                        HullMGHatchFireSpawnTime = DriverHatchFireSpawnTime + 1.0 + (FRand() * 2.0); // MG hatch fire starts 1-3 secs after turret fire
                    }

                    SetNextTimer();
                }
                // Otherwise this must have been called when an already burning vehicle is replicated to a net client
                // Start driver's hatch fire effect immediately, but let VehicleWeapons start their own fires as those actors replicate
                else
                {
                    StartDriverHatchFire();
                }
            }
        }
        // Engine is dead, but there's no fire, so make sure it is set to smoke instead of burn
        else if (EngineHealth <= 0 && (DamagedEffectHealthFireFactor != 0.0 || DamagedEffectHealthHeavySmokeFactor != 1.0))
        {
            DamagedEffectHealthFireFactor = 0.0;
            DamagedEffectHealthHeavySmokeFactor = 1.0;
            DamagedEffectHealthSmokeFactor = 1.0; // appears necessary to get native code to spawn a DamagedEffect if it doesn't already exist
                                                  // (presumably doesn't check for fire or dark smoke unless vehicle is at least damaged enough to lightly smoke)
            if (DamagedEffect != none)
            {
                DamagedEffect.UpdateDamagedEffect(false, 0.0, false, false); // reset existing effect
                DamagedEffect.UpdateDamagedEffect(false, 0.0, false, true);  // then set to dark smoke
            }
            else if (Health == HealthMax) // clientside Health hack to get native code to spawn DamagedEffect (it won't unless vehicle has taken some damage)
            {
                Health--;
            }
        }
    }

    // If engine is off, update sound to burning or smoking sound)
    if (bEngineOff)
    {
        SetEngine();
    }
}

// New function to start a driver's hatch fire effect
simulated function StartDriverHatchFire()
{
    bDriverHatchFireNeeded = false;

    if (DriverHatchFireEffect == none && Level.NetMode != NM_DedicatedServer)
    {
        DriverHatchFireEffect = Spawn(FireEffectClass);
    }

    if (DriverHatchFireEffect != none)
    {
        AttachToBone(DriverHatchFireEffect, FireAttachBone);
        DriverHatchFireEffect.SetRelativeLocation(FireEffectOffset);
        DriverHatchFireEffect.UpdateDamagedEffect(true, 0.0, false, false);

        if (DamagedEffectScale != 1.0)
        {
            DriverHatchFireEffect.SetEffectScale(DamagedEffectScale);
        }
    }
}

///////////////////////////////////////////////////////////////////////////////////////
//  ************************  HIT DETECTION & PENETRATION  ************************  //
///////////////////////////////////////////////////////////////////////////////////////

// New function to check if something hit a certain DH NewVehHitpoints
function bool IsNewPointShot(vector Loc, vector Ray, float AdditionalScale, int Index)
{
    local coords C;
    local vector HeadLoc, B, M, Diff;
    local float  t, DotMM, Distance;

    if (NewVehHitpoints[Index].PointBone == '')
    {
        return false;
    }

    C = GetBoneCoords(NewVehHitpoints[Index].PointBone);

    HeadLoc = C.Origin + (NewVehHitpoints[Index].PointHeight * NewVehHitpoints[Index].PointScale * AdditionalScale * C.XAxis);
    HeadLoc = HeadLoc + (NewVehHitpoints[Index].PointOffset >> rotator(C.XAxis));

    // Express snipe trace line in terms of B + tM
    B = Loc;
    M = Ray * 150.0;

    // Find point-line squared distance
    Diff = HeadLoc - B;
    t = M dot Diff;

    if (t > 0.0)
    {
        DotMM = M dot M;

        if (t < DotMM)
        {
            t = t / DotMM;
            Diff = Diff - (t * M);
        }
        else
        {
            t = 1.0;
            Diff -= M;
        }
    }
    else
    {
        t = 0;
    }

    Distance = Sqrt(Diff dot Diff);

    return (Distance < (NewVehHitpoints[Index].PointRadius * NewVehHitpoints[Index].PointScale * AdditionalScale));
}

// Heavily modified from deprecated ROTreadCraft class for DH's armour penetration system, handling penetration calcs for any shell type
simulated function bool ShouldPenetrate(DHAntiVehicleProjectile P, vector HitLocation, vector HitRotation, float PenetrationNumber)
{
    local float  HitAngleDegrees, Side, InAngle;
    local vector LocDir, HitDir, X, Y, Z;
    local bool   bPenetrated;

    bRearHullPenetration = false; // reset before we start

    // Figure out which side we hit
    LocDir = vector(Rotation);
    LocDir.Z = 0.0;
    HitDir = HitLocation - Location;
    HitDir.Z = 0.0;
    HitAngleDegrees = class'UUnits'.static.RadiansToDegrees(Acos(Normal(LocDir) dot Normal(HitDir)));
    GetAxes(Rotation, X, Y, Z);
    Side = Y dot HitDir;

    if (Side < 0.0)
    {
        HitAngleDegrees = 360.0 - HitAngleDegrees;
    }

    if (bPenetrationText && Role == ROLE_Authority)
    {
        Level.Game.Broadcast(self, "Hull hit angle =" @ HitAngleDegrees @ "degrees");
    }

    // Frontal hit
    if (HitAngleDegrees >= FrontLeftAngle || HitAngleDegrees < FrontRightAngle)
    {
        // Debugging
        if (bDrawPenetration)
        {
            ClearStayingDebugLines();
            DrawStayingDebugLine(HitLocation, HitLocation + 2000.0 * Normal(X), 0, 255, 0);
            DrawStayingDebugLine(HitLocation, HitLocation + 2000.0 * Normal(-HitRotation), 255, 255, 0);
            Spawn(class'DHDebugTracer', self,, HitLocation, rotator(HitRotation));
        }

        if (bLogPenetration)
        {
            Log("Front hull hit: HitAngleDegrees =" @ HitAngleDegrees @ " Side =" @ Side);
        }

        // Calculate the direction the shot came from (in radians, not degrees))
        InAngle = Acos(Normal(-HitRotation) dot Normal(X));

        // InAngle over 90 degrees is impossible, so must be a hit detection bug (opposite side collision detection error) & we need to switch to opposite side
        if (class'UUnits'.static.RadiansToDegrees(InAngle) > 90.0)
        {
            if (bPenetrationText && Role == ROLE_Authority)
            {
                Level.Game.Broadcast(self, "Hit bug - switching from front to REAR hull hit: base armor =" @ URearArmorFactor * 10.0 $ "mm, slope =" @ URearArmorSlope);
            }

            bPenetrated = PenetrationNumber > URearArmorFactor && CheckPenetration(P, URearArmorFactor, GetCompoundAngle(InAngle, URearArmorSlope), PenetrationNumber);
            bRearHullPenetration = bPenetrated; // record that we penetrated the rear of vehicle, which is useful in TakeDamage()

            return bPenetrated;
        }

        if (bPenetrationText && Role == ROLE_Authority)
        {
            Level.Game.Broadcast(self, "Front hull hit: base armor =" @ UFrontArmorFactor * 10.0 $ "mm, slope =" @ UFrontArmorSlope);
        }

        // Check whether or not we penetrated & return true or false accordingly
        // Checking that PenetrationNumber > ArmorFactor 1st is a quick pre-check that it's worth doing more complex calculations in CheckPenetration()
        return PenetrationNumber > UFrontArmorFactor && CheckPenetration(P, UFrontArmorFactor, GetCompoundAngle(InAngle, UFrontArmorSlope), PenetrationNumber);
    }

    // Right side hit
    else if (HitAngleDegrees >= FrontRightAngle && HitAngleDegrees < RearRightAngle)
    {
        // Debugging
        if (bDrawPenetration)
        {
            ClearStayingDebugLines();
            DrawStayingDebugLine(HitLocation, HitLocation + 2000.0 * Normal(-Y), 0, 255, 0);
            DrawStayingDebugLine(HitLocation, HitLocation + 2000.0 * Normal(-HitRotation), 255, 255, 0);
            Spawn(class'DHDebugTracer', self,, HitLocation, rotator(HitRotation));
        }

        if (bLogPenetration)
        {
            Log("Right side hull hit: HitAngleDegrees =" @ HitAngleDegrees @ " Side =" @ Side);
        }

        // Don't penetrate with HEAT if there is added side armor
        if (bHasAddedSideArmor && P.RoundType == RT_HEAT) // using RoundType instead of P.ShellImpactDamage.default.bArmorStops
        {
            return false;
        }

        InAngle = Acos(Normal(-HitRotation) dot Normal(Y));

        // Fix hit detection bug
        if (class'UUnits'.static.RadiansToDegrees(InAngle) > 90.0)
        {
            if (bPenetrationText && Role == ROLE_Authority)
            {
                Level.Game.Broadcast(self, "Hit bug - switching from right to LEFT hull hit: base armor =" @ ULeftArmorFactor * 10.0 $ "mm, slope =" @ ULeftArmorSlope);
            }

            return PenetrationNumber > ULeftArmorFactor && CheckPenetration(P, ULeftArmorFactor, GetCompoundAngle(InAngle, ULeftArmorSlope), PenetrationNumber);
        }

        if (bPenetrationText && Role == ROLE_Authority)
        {
            Level.Game.Broadcast(self, "Right hull hit: base armor =" @ URightArmorFactor * 10.0 $ "mm, slope =" @ URightArmorSlope);
        }

        return PenetrationNumber > URightArmorFactor && CheckPenetration(P, URightArmorFactor, GetCompoundAngle(InAngle, URightArmorSlope), PenetrationNumber);
    }

    // Rear hit
    else if (HitAngleDegrees >= RearRightAngle && HitAngleDegrees < RearLeftAngle)
    {
        // Debugging
        if (bDrawPenetration)
        {
            ClearStayingDebugLines();
            DrawStayingDebugLine(HitLocation, HitLocation + 2000.0 * Normal(-X), 0, 255, 0);
            DrawStayingDebugLine(HitLocation, HitLocation + 2000.0 * Normal(-HitRotation), 255, 255, 0);
            Spawn(class'DHDebugTracer', self,, HitLocation, rotator(HitRotation));
        }

        if (bLogPenetration)
        {
            Log("Rear hull hit: HitAngleDegrees =" @ HitAngleDegrees @ " Side =" @ Side);
        }

        InAngle = Acos(Normal(-HitRotation) dot Normal(-X));

        // Fix hit detection bug
        if (class'UUnits'.static.RadiansToDegrees(InAngle) > 90.0)
        {
            if (bPenetrationText && Role == ROLE_Authority)
            {
                Level.Game.Broadcast(self, "Hit bug - switching from rear to FRONT hull hit: base armor =" @ UFrontArmorFactor * 10.0 $ "mm, slope =" @ UFrontArmorSlope);
            }

            return PenetrationNumber > UFrontArmorFactor && CheckPenetration(P, UFrontArmorFactor, GetCompoundAngle(InAngle, UFrontArmorSlope), PenetrationNumber);
        }

        if (bPenetrationText && Role == ROLE_Authority)
        {
            Level.Game.Broadcast(self, "Rear hull hit: base armor =" @ URearArmorFactor * 10.0 $ "mm, slope =" @ URearArmorSlope);
        }

        bPenetrated = PenetrationNumber > URearArmorFactor && CheckPenetration(P, URearArmorFactor, GetCompoundAngle(InAngle, URearArmorSlope), PenetrationNumber);
        bRearHullPenetration = bPenetrated; // record that we penetrated the rear of vehicle, which is useful in TakeDamage()

        return bPenetrated;
    }

    // Left side hit
    else if (HitAngleDegrees >= RearLeftAngle && HitAngleDegrees < FrontLeftAngle)
    {
        // Debugging
        if (bDrawPenetration)
        {
            ClearStayingDebugLines();
            DrawStayingDebugLine(HitLocation, HitLocation + 2000.0 * Normal(Y), 0, 255, 0);
            DrawStayingDebugLine(HitLocation, HitLocation + 2000.0 * Normal(-HitRotation), 255, 255, 0);
            Spawn(class'DHDebugTracer', self,, HitLocation, rotator(HitRotation));
        }

        if (bLogPenetration)
        {
            Log("Left side hull hit: HitAngleDegrees =" @ HitAngleDegrees @ " Side =" @ Side);
        }

        // Don't penetrate with HEAT if there is added side armor
        if (bHasAddedSideArmor && P.RoundType == RT_HEAT) // using RoundType instead of P.ShellImpactDamage.default.bArmorStops
        {
            return false;
        }

        InAngle = Acos(Normal(-HitRotation) dot Normal(-Y));

        // Fix hit detection bug
        if (class'UUnits'.static.RadiansToDegrees(InAngle) > 90.0)
        {
            if (bPenetrationText && Role == ROLE_Authority)
            {
                Level.Game.Broadcast(self, "Hit bug - switching from left to RIGHT hull hit: base armor =" @ URightArmorFactor * 10.0 $ "mm, slope =" @ URightArmorSlope);
            }

            return PenetrationNumber > URightArmorFactor && CheckPenetration(P, URightArmorFactor, GetCompoundAngle(InAngle, URightArmorSlope), PenetrationNumber);
        }

        if (bPenetrationText && Role == ROLE_Authority)
        {
            Level.Game.Broadcast(self, "Left hull hit: base armor =" @ ULeftArmorFactor * 10.0 $ "mm, slope =" @ ULeftArmorSlope);
        }

        return PenetrationNumber > ULeftArmorFactor && CheckPenetration(P, ULeftArmorFactor, GetCompoundAngle(InAngle, ULeftArmorSlope), PenetrationNumber);
    }

    // Should never happen !
    else
    {
       Log("?!? We shoulda hit something !!!!");
       Level.Game.Broadcast(self, "?!? We shoulda hit something !!!!");

       return false;
    }
}

// New generic function to handle penetration calcs for any shell type
// Replaces PenetrationAPC, PenetrationAPDS, PenetrationHVAP, PenetrationHVAPLarge & PenetrationHEAT from DH 5.1 (also Darkest Orchestra's PenetrationAP & PenetrationAPBC)
simulated function bool CheckPenetration(DHAntiVehicleProjectile P, float ArmorFactor, float CompoundAngle, float PenetrationNumber)
{
    local float CompoundAngleDegrees, OverMatchFactor, SlopeMultiplier, EffectiveArmor, PenetrationRatio;

    // Convert angle back to degrees
    CompoundAngleDegrees = class'UUnits'.static.RadiansToDegrees(CompoundAngle);

    if (CompoundAngleDegrees > 90.0)
    {
        CompoundAngleDegrees = 180.0 - CompoundAngleDegrees;
    }

    // Calculate the SlopeMultiplier & EffectiveArmor, to give us the PenetrationRatio
    OverMatchFactor = ArmorFactor / P.ShellDiameter;
    SlopeMultiplier = GetArmorSlopeMultiplier(P, CompoundAngleDegrees, OverMatchFactor);
    EffectiveArmor = ArmorFactor * SlopeMultiplier;
    PenetrationRatio = PenetrationNumber / EffectiveArmor;

    // Penetration debugging
    if (bPenetrationText && Role == ROLE_Authority)
    {
        Level.Game.Broadcast(self, "Effective armor:" @ EffectiveArmor * 10.0 $ "mm" @ " Shot penetration:" @ PenetrationNumber * 10.0 $ "mm");
        Level.Game.Broadcast(self, "Compound angle:" @ CompoundAngleDegrees @ " Slope multiplier:" @ SlopeMultiplier);
    }

    // Check if round shattered on armor
    P.bRoundShattered = P.bShatterProne && PenetrationRatio >= 1.0 && CheckIfShatters(P, PenetrationRatio, OverMatchFactor);

    // Check if round penetrated the vehicle
    bProjectilePenetrated = PenetrationRatio >= 1.0 && !P.bRoundShattered;

    // Set TakeDamage-related variables
    bTurretPenetration = false;
    bRearHullPenetration = bRearHullPenetration && bProjectilePenetrated;
    bHEATPenetration = P.RoundType == RT_HEAT && bProjectilePenetrated; // would be much better to flag bIsHeatRound in DamageType, but would need new DHWeaponDamageType class

    return bProjectilePenetrated;
}

// Returns the compound hit angle (now we pass AOI to this function in radians, to save unnecessary processing to & from degrees)
simulated function float GetCompoundAngle(float AOI, float ArmorSlopeDegrees)
{
    return Acos(Cos(class'UUnits'.static.DegreesToRadians(Abs(ArmorSlopeDegrees))) * Cos(AOI));
}

// New generic function to work with generic ShouldPenetrate & CheckPenetration functions
simulated function float GetArmorSlopeMultiplier(DHAntiVehicleProjectile P, float CompoundAngleDegrees, optional float OverMatchFactor)
{
    local float CompoundExp, RoundedDownAngleDegrees, ExtraAngleDegrees, BaseSlopeMultiplier, NextSlopeMultiplier, SlopeMultiplierGap;

    if (P.RoundType == RT_HVAP)
    {
        if (P.ShellDiameter >= 9.0) // HVAP rounds of at least 90mm shell diameter, e.g. Jackson's 90mm cannon (instead of using separate RoundType RT_HVAPLarge)
        {
            if (CompoundAngleDegrees <= 30.0)
            {
               CompoundExp = CompoundAngleDegrees ** 1.75;

               return 2.71828 ** (CompoundExp * 0.000662);
            }
            else
            {
               CompoundExp = CompoundAngleDegrees ** 2.2;

               return 0.9043 * (2.71828 ** (CompoundExp * 0.0001987));
            }
        }
        else // smaller HVAP rounds
        {
            if (CompoundAngleDegrees <= 25.0)
            {
               CompoundExp = CompoundAngleDegrees ** 2.2;

               return 2.71828 ** (CompoundExp * 0.0001727);
            }
            else
            {
               CompoundExp = CompoundAngleDegrees ** 1.5;

               return 0.7277 * (2.71828 ** (CompoundExp * 0.003787));
            }
        }
    }
    else if (P.RoundType == RT_APDS)
    {
        CompoundExp = CompoundAngleDegrees ** 2.6;

        return 2.71828 ** (CompoundExp * 0.00003011);
    }
    else if (P.RoundType == RT_HEAT)
    {
        return 1.0 / Cos(class'UUnits'.static.DegreesToRadians(Abs(CompoundAngleDegrees)));
    }
    else // should mean RoundType is RT_APC, RT_HE or RT_Smoke, but treating this as a catch-all default (will also handle DO's AP & APBC shells)
    {
        if (CompoundAngleDegrees < 10.0)
        {
            return CompoundAngleDegrees / 10.0 * ArmorSlopeTable(P, 10.0, OverMatchFactor);
        }
        else
        {
            RoundedDownAngleDegrees = float(int(CompoundAngleDegrees / 5.0)) * 5.0; // to nearest 5 degrees, rounded down
            ExtraAngleDegrees = CompoundAngleDegrees - RoundedDownAngleDegrees;
            BaseSlopeMultiplier = ArmorSlopeTable(P, RoundedDownAngleDegrees, OverMatchFactor);
            NextSlopeMultiplier = ArmorSlopeTable(P, RoundedDownAngleDegrees + 5.0, OverMatchFactor);
            SlopeMultiplierGap = NextSlopeMultiplier - BaseSlopeMultiplier;

            return BaseSlopeMultiplier + (ExtraAngleDegrees / 5.0 * SlopeMultiplierGap);
        }
    }

    return 1.0; // fail-safe neutral return value
}

// New generic function to work with new GetArmorSlopeMultiplier for APC shells (also handles Darkest Orchestra's AP & APBC shells)
simulated function float ArmorSlopeTable(DHAntiVehicleProjectile P, float CompoundAngleDegrees, float OverMatchFactor)
{
    // after Bird & Livingston:
    if (P.RoundType == RT_AP) // from Darkest Orchestra
    {
        if      (CompoundAngleDegrees <= 10.0)  return 0.98  * (OverMatchFactor ** 0.06370); // at 10 degrees
        else if (CompoundAngleDegrees <= 15.0)  return 1.00  * (OverMatchFactor ** 0.09690);
        else if (CompoundAngleDegrees <= 20.0)  return 1.04  * (OverMatchFactor ** 0.13561);
        else if (CompoundAngleDegrees <= 25.0)  return 1.11  * (OverMatchFactor ** 0.16164);
        else if (CompoundAngleDegrees <= 30.0)  return 1.22  * (OverMatchFactor ** 0.19702);
        else if (CompoundAngleDegrees <= 35.0)  return 1.38  * (OverMatchFactor ** 0.22546);
        else if (CompoundAngleDegrees <= 40.0)  return 1.63  * (OverMatchFactor ** 0.26313);
        else if (CompoundAngleDegrees <= 45.0)  return 2.00  * (OverMatchFactor ** 0.34717);
        else if (CompoundAngleDegrees <= 50.0)  return 2.64  * (OverMatchFactor ** 0.57353);
        else if (CompoundAngleDegrees <= 55.0)  return 3.23  * (OverMatchFactor ** 0.69075);
        else if (CompoundAngleDegrees <= 60.0)  return 4.07  * (OverMatchFactor ** 0.81826);
        else if (CompoundAngleDegrees <= 65.0)  return 6.27  * (OverMatchFactor ** 0.91920);
        else if (CompoundAngleDegrees <= 70.0)  return 8.65  * (OverMatchFactor ** 1.00539);
        else if (CompoundAngleDegrees <= 75.0)  return 13.75 * (OverMatchFactor ** 1.07400);
        else if (CompoundAngleDegrees <= 80.0)  return 21.87 * (OverMatchFactor ** 1.17973);
        else                                    return 34.49 * (OverMatchFactor ** 1.28631); // at 85 degrees
    }
    else if (P.RoundType == RT_APBC) // from Darkest Orchestra
    {
        if      (CompoundAngleDegrees <= 10.0)  return 1.04  * (OverMatchFactor ** 0.01555); // at 10 degrees
        else if (CompoundAngleDegrees <= 15.0)  return 1.06  * (OverMatchFactor ** 0.02315);
        else if (CompoundAngleDegrees <= 20.0)  return 1.08  * (OverMatchFactor ** 0.03448);
        else if (CompoundAngleDegrees <= 25.0)  return 1.11  * (OverMatchFactor ** 0.05134);
        else if (CompoundAngleDegrees <= 30.0)  return 1.16  * (OverMatchFactor ** 0.07710);
        else if (CompoundAngleDegrees <= 35.0)  return 1.22  * (OverMatchFactor ** 0.11384);
        else if (CompoundAngleDegrees <= 40.0)  return 1.31  * (OverMatchFactor ** 0.16952);
        else if (CompoundAngleDegrees <= 45.0)  return 1.44  * (OverMatchFactor ** 0.24604);
        else if (CompoundAngleDegrees <= 50.0)  return 1.68  * (OverMatchFactor ** 0.37910);
        else if (CompoundAngleDegrees <= 55.0)  return 2.11  * (OverMatchFactor ** 0.56444);
        else if (CompoundAngleDegrees <= 60.0)  return 3.50  * (OverMatchFactor ** 1.07411);
        else if (CompoundAngleDegrees <= 65.0)  return 5.34  * (OverMatchFactor ** 1.46188);
        else if (CompoundAngleDegrees <= 70.0)  return 9.48  * (OverMatchFactor ** 1.81520);
        else if (CompoundAngleDegrees <= 75.0)  return 20.22 * (OverMatchFactor ** 2.19155);
        else if (CompoundAngleDegrees <= 80.0)  return 56.20 * (OverMatchFactor ** 2.56210);
        else                                    return 221.3 * (OverMatchFactor ** 2.93265); // at 85 degrees
    }
    else // should mean RoundType is RT_APC (also covers APCBC) or RT_HE, but treating this as a catch-all default
    {
        if      (CompoundAngleDegrees <= 10.0)  return 1.01  * (OverMatchFactor ** 0.0225); // at 10 degrees
        else if (CompoundAngleDegrees <= 15.0)  return 1.03  * (OverMatchFactor ** 0.0327);
        else if (CompoundAngleDegrees <= 20.0)  return 1.10  * (OverMatchFactor ** 0.0454);
        else if (CompoundAngleDegrees <= 25.0)  return 1.17  * (OverMatchFactor ** 0.0549);
        else if (CompoundAngleDegrees <= 30.0)  return 1.27  * (OverMatchFactor ** 0.0655);
        else if (CompoundAngleDegrees <= 35.0)  return 1.39  * (OverMatchFactor ** 0.0993);
        else if (CompoundAngleDegrees <= 40.0)  return 1.54  * (OverMatchFactor ** 0.1388);
        else if (CompoundAngleDegrees <= 45.0)  return 1.72  * (OverMatchFactor ** 0.1655);
        else if (CompoundAngleDegrees <= 50.0)  return 1.94  * (OverMatchFactor ** 0.2035);
        else if (CompoundAngleDegrees <= 55.0)  return 2.12  * (OverMatchFactor ** 0.2427);
        else if (CompoundAngleDegrees <= 60.0)  return 2.56  * (OverMatchFactor ** 0.2450);
        else if (CompoundAngleDegrees <= 65.0)  return 3.20  * (OverMatchFactor ** 0.3354);
        else if (CompoundAngleDegrees <= 70.0)  return 3.98  * (OverMatchFactor ** 0.3478);
        else if (CompoundAngleDegrees <= 75.0)  return 5.17  * (OverMatchFactor ** 0.3831);
        else if (CompoundAngleDegrees <= 80.0)  return 8.09  * (OverMatchFactor ** 0.4131);
        else                                    return 11.32 * (OverMatchFactor ** 0.4550); // at 85 degrees
    }

    return 1.0; // fail-safe neutral return value
}

// New generic function to work with new CheckPenetration function - checks if the round should shatter, based on the 'shatter gap' for different round types
simulated function bool CheckIfShatters(DHAntiVehicleProjectile P, float PenetrationRatio, optional float OverMatchFactor)
{
    if (P.RoundType == RT_HVAP)
    {
        if (P.ShellDiameter >= 9.0) // HVAP rounds of at least 90mm shell diameter, e.g. Jackson's 90mm cannon (instead of using separate RoundType RT_HVAPLarge)
        {
            if (PenetrationRatio >= 1.1 && PenetrationRatio <= 1.27)
            {
                return true;
            }
        }
        else // smaller HVAP rounds
        {
            if (PenetrationRatio >= 1.1 && PenetrationRatio <= 1.34)
            {
                return true;
            }
        }
    }
    else if (P.RoundType == RT_APDS)
    {
        if (PenetrationRatio >= 1.06 && PenetrationRatio <= 1.2)
        {
            return true;
        }
    }
    else if (P.RoundType == RT_HEAT) // no chance of shatter for HEAT round
    {
    }
    else // should mean RoundType is RT_APC, RT_HE or RT_Smoke, but treating this as a catch-all default (will also handle DO's AP & APBC shells)
    {
        if (OverMatchFactor > 0.8 && PenetrationRatio >= 1.06 && PenetrationRatio <= 1.19)
        {
            return true;
        }
    }

    return false;
}

///////////////////////////////////////////////////////////////////////////////////////
//  *********************************  DAMAGE  ************************************  //
///////////////////////////////////////////////////////////////////////////////////////

// Modified to add all the DH vehicle damage stuff
function TakeDamage(int Damage, Pawn InstigatedBy, vector HitLocation, vector Momentum, class<DamageType> DamageType, optional int HitIndex)
{
    local DHVehicleCannonPawn CannonPawn;
    local Controller InstigatorController;
    local float      VehicleDamageMod, TreadDamageMod, HullChanceModifier, TurretChanceModifier;
    local int        InstigatorTeam, i;
    local bool       bEngineStoppedProjectile, bAmmoDetonation;

    // Suicide/self-destruction
    if (DamageType == class'Suicided' || DamageType == class'ROSuicided')
    {
        super(Vehicle).TakeDamage(Damage, InstigatedBy, HitLocation, Momentum, class'ROSuicided');

        ResetTakeDamageVariables();

        return;
    }

    // Quick fix for the vehicle giving itself impact damage
    if (InstigatedBy == self && DamageType != VehicleBurningDamType)
    {
        ResetTakeDamageVariables();

        return;
    }

    // Don't allow your own teammates to destroy vehicles in spawns (& you know some jerks would get off on doing that to their team :))
    if (!bDriverAlreadyEntered)
    {
        if (InstigatedBy != none)
        {
            InstigatorController = InstigatedBy.Controller;
        }

        if (InstigatorController == none && DamageType.default.bDelayedDamage)
        {
            InstigatorController = DelayedDamageInstigatorController;
        }

        if (InstigatorController != none)
        {
            InstigatorTeam = InstigatorController.GetTeamNum();

            if (GetTeamNum() != 255 && InstigatorTeam != 255 && GetTeamNum() == InstigatorTeam)
            {
                ResetTakeDamageVariables();

                return;
            }
        }
    }

    // Set damage modifiers from the DamageType, based on type of vehicle
    if (class<ROWeaponDamageType>(DamageType) != none)
    {
        if (bIsApc)
        {
            VehicleDamageMod = class<ROWeaponDamageType>(DamageType).default.APCDamageModifier;
        }
        else
        {
            VehicleDamageMod = class<ROWeaponDamageType>(DamageType).default.TankDamageModifier;
        }

        if (bHasTreads)
        {
            TreadDamageMod = class<ROWeaponDamageType>(DamageType).default.TreadDamageModifier;
        }
    }
    else if (class<ROVehicleDamageType>(DamageType) != none)
    {
        if (bIsApc)
        {
            VehicleDamageMod  = class<ROVehicleDamageType>(DamageType).default.APCDamageModifier;
        }
        else
        {
            VehicleDamageMod = class<ROVehicleDamageType>(DamageType).default.TankDamageModifier;
        }

        if (bHasTreads)
        {
            TreadDamageMod = class<ROVehicleDamageType>(DamageType).default.TreadDamageModifier;
        }
    }

    // Add in the DamageType's vehicle damage modifier & a little damage randomisation (but not for fire damage as it messes up timings)
    if (DamageType != VehicleBurningDamType)
    {
        Damage *= (VehicleDamageMod * RandRange(0.75, 1.08));
    }
    else
    {
        Damage *= VehicleDamageMod;
    }

    // Exit if no damage
    if (Damage < 1)
    {
        ResetTakeDamageVariables();

        return;
    }

    // Check RO VehHitpoints (engine, ammo)
    // Note driver hit check is deprecated as we use a new player hit detection system, which basically uses normal hit detection as for an infantry player pawn
    if (bProjectilePenetrated)
    {
        for (i = 0; i < VehHitpoints.Length; ++i)
        {
            if (IsPointShot(HitLocation, Momentum, 1.0, i))
            {
                if (bLogPenetration)
                {
                    Log("We hit" @ GetEnum(enum'EHitPointType', VehHitpoints[i].HitPointType) @ "hitpoint");
                }

                // Engine hit
                if (VehHitpoints[i].HitPointType == HP_Engine)
                {
                    if (bDebuggingText)
                    {
                        Level.Game.Broadcast(self, "Hit vehicle engine");
                    }

                    DamageEngine(Damage, InstigatedBy, HitLocation, Momentum, DamageType);
                    Damage *= 0.55; // reduce damage to vehicle itself if hit engine

                    // Shot from the rear that hits engine will stop shell from passing through to cabin, so don't check any more VehHitpoints
                    if (bRearHullPenetration)
                    {
                        bEngineStoppedProjectile = true;
                        break;
                    }
                }
                // Hit ammo store
                else if (VehHitpoints[i].HitPointType == HP_AmmoStore)
                {
                    // Random chance that ammo explodes & vehicle is destroyed
                    if ((bHEATPenetration && FRand() < 0.85) || (!bHEATPenetration && FRand() < AmmoIgnitionProbability))
                    {
                        if (bDebuggingText)
                        {
                            Level.Game.Broadcast(self, "Hit vehicle ammo store - exploded");
                        }

                        Damage *= Health;
                        bAmmoDetonation = true; // stops unnecessary penetration checks, as the vehicle is going to explode anyway
                        break;
                    }
                    // Even if ammo did not explode, increase the chance of a fire breaking out
                    else
                    {
                        if (bDebuggingText)
                        {
                            Level.Game.Broadcast(self, "Hit vehicle ammo store but did not explode");
                        }

                        HullFireChance = FMax(0.75, HullFireChance);
                        HullFireHEATChance = FMax(0.90, HullFireHEATChance);
                    }
                }
            }
        }
    }

    if (!bEngineStoppedProjectile && !bAmmoDetonation) // we can skip lots of checks if either has been flagged true
    {
        if ((bProjectilePenetrated || NewVehHitpoints.Length > 0) && Cannon != none)
        {
            CannonPawn = DHVehicleCannonPawn(Cannon.WeaponPawn);
        }

        // Check additional DH NewVehHitPoints
        for (i = 0; i < NewVehHitpoints.Length; ++i)
        {
            if (IsNewPointShot(HitLocation, Momentum, 1.0, i))
            {
                if (bLogPenetration)
                {
                    Log("We hit" @ GetEnum(enum'ENewHitPointType', NewVehHitpoints[i].NewHitPointType) @ "hitpoint");
                }

                // Hit periscope optics
                if (NewVehHitpoints[i].NewHitPointType == NHP_PeriscopeOptics)
                {
                    // does nothing at present - possibly add in future
                }
                else if (CannonPawn != none)
                {
                    // Hit exposed gunsight optics
                    if (NewVehHitpoints[i].NewHitPointType == NHP_GunOptics)
                    {
                        if (bDebuggingText)
                        {
                            Level.Game.Broadcast(self, "Hit gunsight optics");
                        }

                        CannonPawn.DamageCannonOverlay();
                    }
                    else if (bProjectilePenetrated)
                    {
                        // Hit turret ring or gun traverse mechanism
                        if (NewVehHitpoints[i].NewHitPointType == NHP_Traverse)
                        {
                            if (bDebuggingText)
                            {
                                Level.Game.Broadcast(self, "Hit gun/turret traverse");
                            }

                            CannonPawn.bTurretRingDamaged = true;
                        }
                        // Hit gun pivot mechanism
                        else if (NewVehHitpoints[i].NewHitPointType == NHP_GunPitch)
                        {
                            if (bDebuggingText)
                            {
                                Level.Game.Broadcast(self, "Hit gun pivot");
                            }

                            CannonPawn.bGunPivotDamaged = true;
                        }
                    }
                }
            }
        }

        // Random damage to crew or vehicle components, caused by shrapnel etc flying around inside the vehicle from penetration, regardless of where it hit
        if (bProjectilePenetrated)
        {
            if (Cannon != none)
            {
                // Although shrapnel etc can get everywhere, modify chance of random damage based on whether penetration was to hull or turret
                if (Cannon.bHasTurret)
                {
                    if (bTurretPenetration)
                    {
                        HullChanceModifier = 0.5;   // half usual chance of damage to things in the hull
                        TurretChanceModifier = 1.0;
                    }
                    else
                    {
                        HullChanceModifier = 1.0;
                        TurretChanceModifier = 0.5; // half usual chance of damage to things in the turret
                    }
                }
                else // normal chance of damage to everything in vehicles without a turret (e.g. casemate-style tank destroyers)
                {
                    HullChanceModifier = 1.0;
                    TurretChanceModifier = 1.0;
                }

                if (CannonPawn != none)
                {
                    // Random chance of shrapnel killing commander
                    if (CannonPawn != none && CannonPawn.Driver != none && FRand() < (float(Damage) / CommanderKillChance * TurretChanceModifier))
                    {
                        if (bDebuggingText)
                        {
                            Level.Game.Broadcast(self, "Commander killed by shrapnel");
                        }

                        CannonPawn.Driver.TakeDamage(150, InstigatedBy, Location, vect(0.0, 0.0, 0.0), DamageType);
                    }

                    // Random chance of shrapnel damaging gunsight optics
                    if (FRand() < (float(Damage) / OpticsDamageChance * TurretChanceModifier))
                    {
                        if (bDebuggingText)
                        {
                            Level.Game.Broadcast(self, "Gunsight optics destroyed by shrapnel");
                        }

                        CannonPawn.DamageCannonOverlay();
                    }

                    // Random chance of shrapnel damaging gun pivot mechanism
                    if (FRand() < (float(Damage) / GunDamageChance * TurretChanceModifier))
                    {
                        if (bDebuggingText)
                        {
                            Level.Game.Broadcast(self, "Gun pivot damaged by shrapnel");
                        }

                        CannonPawn.bGunPivotDamaged = true;
                    }

                    // Random chance of shrapnel damaging gun traverse mechanism
                    if (FRand() < (float(Damage) / TraverseDamageChance * TurretChanceModifier))
                    {
                        if (bDebuggingText)
                        {
                            Level.Game.Broadcast(self, "Gun/turret traverse damaged by shrapnel");
                        }

                        CannonPawn.bTurretRingDamaged = true;
                    }
                }
            }

            // Random chance of shrapnel detonating turret ammo & destroying the vehicle
            if (FRand() < (float(Damage) / TurretDetonationThreshold * TurretChanceModifier))
            {
                if (bDebuggingText)
                {
                    Level.Game.Broadcast(self, "Turret ammo detonated by shrapnel");
                }

                Damage *= Health;
                bAmmoDetonation = true; // stops unnecessary penetration checks, as the vehicle is going to explode anyway
            }
            else if (bTurretPenetration)
            {
                Damage *= 0.55; // reduce damage to vehicle itself from a turret hit, if the turret ammo didn't detonate
            }

            // Random chance of shrapnel killing driver
            if (Driver != none && FRand() < (float(Damage) / DriverKillChance * HullChanceModifier))
            {
                if (bDebuggingText)
                {
                    Level.Game.Broadcast(self, "Driver killed by shrapnel");
                }

                Driver.TakeDamage(150, InstigatedBy, Location, vect(0.0, 0.0, 0.0), DamageType);
            }

            // Random chance of shrapnel killing hull machine gunner
            if (MGun != none && MGun.WeaponPawn != none && MGun.WeaponPawn.Driver != none && FRand() < (float(Damage) / GunnerKillChance * HullChanceModifier))
            {
                if (bDebuggingText)
                {
                    Level.Game.Broadcast(self, "Hull gunner killed by shrapnel");
                }

                MGun.WeaponPawn.Driver.TakeDamage(150, InstigatedBy, Location, vect(0.0, 0.0, 0.0), DamageType);
            }
        }

        // Check if we hit & damaged either track
        if (bHasTreads && TreadDamageMod >= TreadDamageThreshold && !bTurretPenetration && !bRearHullPenetration)
        {
            CheckTreadDamage(HitLocation, Momentum);
        }
    }

    // Call the Super from Vehicle (skip over others)
    super(Vehicle).TakeDamage(Damage, InstigatedBy, HitLocation, Momentum, DamageType);

    // Vehicle is still alive, so check for possibility of a fire breaking out
    if (Health > 0)
    {
        if (bProjectilePenetrated && !bEngineStoppedProjectile && !bOnFire)
        {
            // Random chance of penetration causing a hull fire // TODO: relate probability to damage, as currently even tiny damage has a high chance of starting a fire
            if ((bHEATPenetration && FRand() < HullFireHEATChance) || (!bHEATPenetration && FRand() < HullFireChance))
            {
                StartHullFire(InstigatedBy);
            }
            // If we didn't start a fire & this is the 1st time a projectile has penetrated, increase the chance of causing a hull fire for any future penetrations
            else if (bFirstPenetratingHit)
            {
                bFirstPenetratingHit = false;
                HullFireChance = FMax(0.75, HullFireChance);
                HullFireHEATChance = FMax(0.90, HullFireHEATChance);
            }
        }

        // If an APC's health is very low, kill the engine & start a fire
        if (bIsApc && Health <= (HealthMax / 3) && EngineHealth > 0)
        {
            EngineHealth = 0;
            bEngineOff = true;
            StartEngineFire(InstigatedBy);
        }
    }

    ResetTakeDamageVariables();
}

// New function to reset all variables used in TakeDamage, ready for next time
function ResetTakeDamageVariables()
{
    bProjectilePenetrated = false;
    bTurretPenetration = false;
    bRearHullPenetration = false;
    bHEATPenetration = false;
}

// Modified to add random chance of engine fire breaking out
function DamageEngine(int Damage, Pawn InstigatedBy, vector HitLocation, vector Momentum, class<DamageType> DamageType)
{
    // Apply new damage
    if (EngineHealth > 0)
    {
        if (DamageType != VehicleBurningDamType)
        {
            Damage = Level.Game.ReduceDamage(Damage, self, InstigatedBy, HitLocation, Momentum, DamageType);
        }

        EngineHealth -= Damage;
    }

    // Kill the engine if its health has now fallen to zero
    if (EngineHealth <= 0)
    {
        if (bDebuggingText)
        {
            Level.Game.Broadcast(self, "Engine is dead");
        }

        if (!bEngineOff)
        {
            bEngineOff = true;
            PlaySound(DamagedShutDownSound, SLOT_None, FClamp(Abs(Throttle), 0.3, 0.75));
        }

        SetEngine();
    }
    // Or if engine still alive, a random chance of engine fire breaking out // TODO: relate probability to damage, as currently even tiny damage has a high chance of starting a fire
    else if (DamageType != VehicleBurningDamType && !bEngineOnFire && Damage > 0 && Health > 0)
    {
        if ((bHEATPenetration && FRand() < EngineFireHEATChance) || (!bHEATPenetration && FRand() < EngineFireChance))
        {
            if (bDebuggingText)
            {
                Level.Game.Broadcast(self, "Engine fire started");
            }

            StartEngineFire(InstigatedBy);
        }
    }
}

// New function to handle hull fire damage
function TakeFireDamage()
{
    local Pawn PawnWhoSetOnFire;
    local int  i;

    if (Role == ROLE_Authority)
    {
        if (WhoSetOnFire != none)
        {
            // If the instigator gets teamswapped before a burning vehicle dies, make sure they don't get friendly kills for it
            if (WhoSetOnFire.GetTeamNum() != HullFireStarterTeam)
            {
                WhoSetOnFire = none;
                DelayedDamageInstigatorController = none;
            }
            else
            {
                PawnWhoSetOnFire = WhoSetOnFire.Pawn;
            }
        }

        // Burn the driver
        if (Driver != none)
        {
            Driver.TakeDamage(PlayerFireDamagePer2Secs, PawnWhoSetOnFire, Location, vect(0.0, 0.0, 0.0), VehicleBurningDamType);
        }

        // Burn any other vehicle occupants
        for (i = 0; i < WeaponPawns.Length; ++i)
        {
            if (WeaponPawns[i] != none && WeaponPawns[i].Driver != none)
            {
                WeaponPawns[i].Driver.TakeDamage(PlayerFireDamagePer2Secs, PawnWhoSetOnFire, Location, vect(0.0, 0.0, 0.0), VehicleBurningDamType);
            }
        }

        // Chance of cooking off ammo before health runs out
        if (FRand() < FireDetonationChance)
        {
            if (bDebuggingText)
            {
                Level.Game.Broadcast(self, "Fire detonated ammo");
            }

            TakeDamage(Health, PawnWhoSetOnFire, vect(0.0, 0.0, 0.0), vect(0.0, 0.0, 0.0), VehicleBurningDamType);
        }
        // Otherwise the vehicle takes normal fire damage
        else
        {
            TakeDamage(HullFireDamagePer2Secs, PawnWhoSetOnFire, vect(0.0, 0.0, 0.0), vect(0.0, 0.0, 0.0), VehicleBurningDamType);
        }

        // Set next hull damage due in another 2 seconds, unless vehicle is now dead
        if (Health > 0)
        {
            NextHullFireDamageTime += 2.0;
        }
    }
}

// New function to handle engine fire damage
function TakeEngineFireDamage()
{
    local Pawn PawnWhoSetOnFire;

    if (Role == ROLE_Authority)
    {
        // Damage engine if not already dead
        if (EngineHealth > 0)
        {
            if (WhoSetEngineOnFire != none)
            {
                // If the instigator gets teamswapped before a burning vehicle dies, make sure they don't get friendly kills for it
                if (WhoSetEngineOnFire.GetTeamNum() != EngineFireStarterTeam)
                {
                    WhoSetEngineOnFire = none;
                    DelayedDamageInstigatorController = none;
                }
                else
                {
                    PawnWhoSetOnFire = WhoSetEngineOnFire.Pawn;
                }
            }

            DamageEngine(EngineFireDamagePer3Secs, PawnWhoSetOnFire, vect(0.0, 0.0, 0.0), vect(0.0, 0.0, 0.0), VehicleBurningDamType);

            // Small chance each time of engine fire spreading & setting whole vehicle on fire
            if (!bOnFire && FRand() < EngineToHullFireChance)
            {
                StartHullFire(PawnWhoSetOnFire);
            }

            // Engine not dead, so set next engine damage due in the normal 3 seconds
            if (EngineHealth > 0)
            {
                NextEngineFireDamageTime += 3.0;
            }
            // Engine is dead, but use NextEngineFireDamageTime to set next timer so engine fire dies down 30 secs after engine health hits zero (unless hull has caught fire)
            else if (!bOnFire)
            {
                NextEngineFireDamageTime += 30.0;
            }
        }
        // Engine fire dies down 30 seconds after engine health hits zero, unless hull has caught fire
        else if (!bOnFire)
        {
            bEngineOnFire = false;
        }
    }
}

///////////////////////////////////////////////////////////////////////////////////////
//  *************************  SETUP, UPDATE, CLEAN UP  ***************************  //
///////////////////////////////////////////////////////////////////////////////////////

// Modified to add periscope materials
static function StaticPrecache(LevelInfo L)
{
    super.StaticPrecache(L);

    L.AddPrecacheMaterial(default.PeriscopeOverlay);
    L.AddPrecacheMaterial(default.DamagedPeriscopeOverlay);
}

// Modified to add periscope materials
simulated function UpdatePrecacheMaterials()
{
    super.UpdatePrecacheMaterials();

    Level.AddPrecacheMaterial(PeriscopeOverlay);
    Level.AddPrecacheMaterial(DamagedPeriscopeOverlay);
}

// Modified to include extra attachment
simulated function DestroyAttachments()
{
    super. DestroyAttachments();

    if (DriverHatchFireEffect != none)
    {
        DriverHatchFireEffect.Kill();
    }
}

///////////////////////////////////////////////////////////////////////////////////////
//  *******************************  MISCELLANEOUS ********************************  //
///////////////////////////////////////////////////////////////////////////////////////

// Modified to stop vehicle from prematurely destroying itself when on fire, & to record a future SpikeTime for a spiked, disabled vehicle (to work with interwoven Timer system)
function MaybeDestroyVehicle()
{
    if (!bNeverReset && IsVehicleEmpty() && !bOnFire && !bEngineOnFire)
    {
        if (IsDisabled())
        {
            bSpikedVehicle = true;
            SpikeTime = Level.TimeSeconds + VehicleSpikeTime; // record SpikeTime due & call SetNextTimer(), instead of directly setting a timer for VehicleSpikeTime
            SetNextTimer();

            if (bDebuggingText)
            {
                Level.Game.Broadcast(self, "Initiating" @ VehicleSpikeTime @ "sec spike timer for disabled vehicle" @ Tag);
            }
        }

        // If vehicle is now empty & some way from its spawn point (> 83m or out of sight), set a time for CheckReset() to maybe re-spawn the vehicle after a certain period
        if (ParentFactory != none && (VSizeSquared(Location - ParentFactory.Location) > 25000000.0 || !FastTrace(ParentFactory.Location, Location)))
        {
            ResetTime = Level.TimeSeconds + IdleTimeBeforeReset;
        }
    }
}

// Bot functions from deprecated ROTreadCraft class
function bool RecommendLongRangedAttack()
{
    return true;
}

function bool StronglyRecommended(Actor S, int TeamIndex, Actor Objective)
{
    return true;
}

function float ModifyThreat(float Current, Pawn Threat)
{
    local vector to, t;
    local float  r;

    if (Vehicle(Threat) != none)
    {
        Current += 0.2;

        if (DHArmoredVehicle(Threat) != none)
        {
            Current += 0.2;

            // Big bonus points for perpendicular tank targets
            to = Normal(Threat.Location - Location);
            to.z = 0.0;
            t = Normal(vector(Threat.Rotation));
            t.z = 0.0;
            r = to dot t;

            if ((r >= 0.90630 && r < -0.73135) || (r >= -0.73135 && r < 0.90630))
            {
                Current += 0.3;
            }
        }
        else if (ROWheeledVehicle(Threat) != none && ROWheeledVehicle(Threat).bIsAPC)
        {
            Current += 0.1;
        }
    }
    else
    {
        Current += 0.25;
    }

    return Current;
}

///////////////////////////////////////////////////////////////////////////////////////
//  *************************** DEBUG EXEC FUNCTIONS  *****************************  //
///////////////////////////////////////////////////////////////////////////////////////

// New debug exec for testing hull fire damage & effects
exec function HullFire()
{
    if (Level.NetMode == NM_Standalone || class'DH_LevelInfo'.static.DHDebugMode())
    {
        ServerHullFire();
    }
}

function ServerHullFire()
{
    if (!bOnFire)
    {
        StartHullFire(none);
    }
}

// New debug exec for testing engine fire damage & effects
exec function EngineFire()
{
    if (Level.NetMode == NM_Standalone || class'DH_LevelInfo'.static.DHDebugMode())
    {
        ServerEngineFire();
    }
}

function ServerEngineFire()
{
    if (!bEngineOnFire)
    {
        StartEngineFire(none);
    }
}

// New debug exec to adjust location of driver's hatch fire position
exec function SetFEOffset(int NewX, int NewY, int NewZ)
{
    if (Level.NetMode == NM_Standalone || class'DH_LevelInfo'.static.DHDebugMode())
    {
        if (NewX != 0 || NewY != 0 || NewZ != 0)
        {
            FireEffectOffset.X = NewX;
            FireEffectOffset.Y = NewY;
            FireEffectOffset.Z = NewZ;
        }

        StartDriverHatchFire();
        Log(Tag @ "FireEffectOffset =" @ FireEffectOffset);
    }
}

defaultproperties
{
    // Driver & positions
    bMustBeTankCommander=true
    UnbuttonedPositionIndex=2
    FirstRiderPositionIndex=255 // unless overridden in subclass, 255 means the value is set automatically when PassengerPawns array is added to the PassengerWeapons
    bMustUnbuttonToSwitchToRider=true
    PeriscopeOverlay=texture'DH_VehicleOptics_tex.Allied.PERISCOPE_overlay_Allied'
    DamagedPeriscopeOverlay=texture'DH_VehicleOptics_tex.Allied.Destroyed'

    // Treads & track wheels
    bHasTreads=true
    LeftTreadIndex=1
    RightTreadIndex=2
    LeftTreadPanDirection=(Pitch=0,Yaw=0,Roll=16384)
    RightTreadPanDirection=(Pitch=0,Yaw=0,Roll=16384)
    TreadVelocityScale=450.0
    WheelRotationScale=500
    TreadHitMinAngle=2.0

    // Damage
    Health=300
    HealthMax=300.0
    EngineHealth=300
    VehHitpoints(0)=(PointBone="Body") // default engine hit point bone
    GunOpticsHitPointIndex=-1 // set in subclass if vehicle has exposed gunsight optics
    TreadDamageThreshold=0.5
    DriverKillChance=1150.0
    GunnerKillChance=1150.0
    CommanderKillChance=950.0
    OpticsDamageChance=3000.0
    GunDamageChance=1250.0
    TraverseDamageChance=2000.0
    TurretDetonationThreshold=1750.0
    AmmoIgnitionProbability=0.75
    HullFireChance=0.25
    HullFireHEATChance=0.5
    EngineFireChance=0.5
    EngineFireHEATChance=0.85
    EngineToHullFireChance=0.05
    PlayerFireDamagePer2Secs=15.0
    FireDetonationChance=0.07
    bFirstPenetratingHit=true
    ImpactDamageMult=0.001
    ImpactDamageThreshold=5000.0

    // Vehicle fires
    DamagedEffectOffset=(X=-40.0,Y=10.0,Z=10.0) // position of engine smoke or fire
    HeavyEngineDamageThreshold=0.5
    DamagedEffectHealthSmokeFactor=0.85
    DamagedEffectHealthMediumSmokeFactor=0.65
    DamagedEffectHealthHeavySmokeFactor=0.35
    DamagedEffectHealthFireFactor=0.0
    FireEffectClass=class'ROEngine.VehicleDamagedEffect' // driver's hatch fire
    FireAttachBone="driver_player"
    FireEffectOffset=(X=0.0,Y=0.0,Z=-10.0)
    VehicleBurningDamType=class'DHVehicleBurningDamageType'

    // Vehicle destruction
    DestructionEffectClass=class'ROEffects.ROVehicleDestroyedEmitter'
    DestructionEffectLowClass=class'ROEffects.ROVehicleDestroyedEmitter_simple'
    DisintegrationEffectClass=class'ROEffects.ROVehicleObliteratedEmitter'
    DisintegrationEffectLowClass=class'ROEffects.ROVehicleObliteratedEmitter_simple'
    DisintegrationHealth=-10000.0 // -10000 default to make classes enable disintegration
    DestructionLinearMomentum=(Min=100.0,Max=350.0)
    DestructionAngularMomentum=(Min=50.0,Max=150.0)
    ExplosionDamage=575.0
    ExplosionRadius=900.0
    ExplosionSoundRadius=1000.0

    // Sounds
    SoundRadius=650.0
    TransientSoundRadius=700.0
    SmokingEngineSound=sound'Amb_Constructions.steam.Krasnyi_Steam_Deep'
    TrackDamagedSound=sound'Vehicle_Engines.track_broken'
    RumbleSoundVolumeModifier=1.0

    // Vehicle reset/respawn
    VehicleSpikeTime=60.0     // if disabled
    TimeTilDissapear=90.0     // after destroyed
    IdleTimeBeforeReset=200.0 // if empty & no friendlies nearby

    // Camera
    PlayerCameraBone="Camera_driver"
    TPCamDistance=375.0
    TPCamLookat=(X=0.0,Y=0.0,Z=0.0)
    TPCamWorldOffset=(X=0.0,Y=0.0,Z=100.0)

    // Entry & exit
    ExitPositions(0)=(X=0.0,Y=-165.0,Z=40.0)
    ExitPositions(1)=(X=0.0,Y=165.0,Z=40.0)
    ExitPositions(2)=(X=0.0,Y=-165.0,Z=-40.0)
    ExitPositions(3)=(X=0.0,Y=165.0,Z=-40.0)

    // Physics and movement
    bSpecialTankTurning=true
    CollisionRadius=100.0
    CollisionHeight=400.0
    VehicleMass=12.5
    MaxCriticalSpeed=700.0 // approx 42 kph
    GroundSpeed=325.0
    bHasHandbrake=true
    WheelSoftness=0.025
    WheelPenScale=2.0
    WheelPenOffset=0.01
    WheelRestitution=0.1
    WheelInertia=0.1
    WheelLongFrictionFunc=(Points=(,(InVal=100.0,OutVal=1.0),(InVal=200.0,OutVal=0.9),(InVal=10000000000.0,OutVal=0.9)))
    WheelLongSlip=0.001
    WheelLatSlipFunc=(Points=((InVal=0.0,OutVal=0.0),(InVal=30.0,OutVal=0.009),(InVal=10000000000.0,OutVal=0.00)))
    WheelLongFrictionScale=1.5
    WheelLatFrictionScale=3.0
    WheelHandbrakeSlip=0.01
    WheelHandbrakeFriction=0.1
    WheelSuspensionTravel=15.0
    WheelSuspensionMaxRenderTravel=15.0
    FTScale=0.03
    ChassisTorqueScale=0.9 // was 0.25 in RO
    MinBrakeFriction=4.0
    MaxSteerAngleCurve=(Points=((OutVal=35.0),(InVal=1500.0,OutVal=20.0),(InVal=1000000000.0,OutVal=15.0)))
    TorqueCurve=(Points=((InVal=0,OutVal=12.0),(InVal=200,OutVal=3.0),(InVal=1500,OutVal=4.0),(InVal=2200,OutVal=0.0)))
    GearRatios(0)=-0.2
    GearRatios(1)=0.2
    GearRatios(2)=0.35
    GearRatios(3)=0.55
    GearRatios(4)=0.6
    TransRatio=0.12
    ChangeUpPoint=2050.0   // was 2000 in RO
    ChangeDownPoint=1100.0 // was 1000 in RO
    LSDFactor=1.0
    EngineBrakeFactor=0.0001
    EngineBrakeRPMScale=0.1
    MaxBrakeTorque=20.0
    SteerSpeed=160.0
    TurnDamping=50
    StopThreshold=100.0
    HandbrakeThresh=200.0
    EngineInertia=0.1
    IdleRPM=500.0
    EngineRPMSoundRange=5000
    RevMeterScale=4000.0

    // Karma properties
    Begin Object Class=KarmaParamsRBFull Name=KParams0
        KInertiaTensor(0)=1.0
        KInertiaTensor(3)=3.0
        KInertiaTensor(5)=3.0
        KCOMOffset=(X=-0.0,Y=0.0,Z=-0.5)
        KLinearDamping=0.05
        KAngularDamping=0.05
        KStartEnabled=true
        bKNonSphericalInertia=true
        bHighDetailOnly=false
        bClientOnly=false
        bKDoubleTickRate=true
        bDestroyOnWorldPenetrate=true
        bDoSafetime=true
        KFriction=0.5
        KImpactThreshold=700.0
        KMaxAngularSpeed=1.0 // slow down the angular velocity so the tank feels "heavier"
    End Object
    KParams=KarmaParamsRBFull'DH_Engine.DHArmoredVehicle.KParams0'

    // Proximity view shake
    bEnableProximityViewShake=false // TODO - this is default false anyway, but interesting to test enabling this, as could be a good feature for heavy vehicles
    ViewShakeRadius=50.0   // was 600 in RO
    ViewShakeOffsetMag=(X=0.0,Y=0.0,Z=0.0) // was X=0.5,Z=2 in RO
    ViewShakeOffsetFreq=0.0 // was 7 in RO

    // Force feedback
    StartUpForce="TankStartUp"
    ShutDownForce="TankShutDown"
    CenterSpringForce="SpringONSSRV"

    // Miscellaneous
    PointValue=3.0
    MaxDesireability=1.4
    SteerBoneAxis=AXIS_X
    SparkEffectClass=class'ROEngine.VehicleImpactSparks' // reinstate from ROVehicle (removed for non-armoured DHVehicles)
}
