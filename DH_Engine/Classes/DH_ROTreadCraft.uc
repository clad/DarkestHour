//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2014
//==============================================================================

class DH_ROTreadCraft extends ROTreadCraft
    abstract;

#exec OBJ LOAD FILE=..\Textures\DH_InterfaceArt_tex.utx
#exec OBJ LOAD FILE=..\sounds\Amb_Destruction.uax
#exec OBJ LOAD FILE=..\sounds\DH_AlliedVehicleSounds2.uax
#exec OBJ LOAD FILE=..\Textures\DH_VehicleOptics_tex.utx
#exec OBJ LOAD FILE=..\Textures\DH_VehiclesGE_tex2.utx

struct ExitPositionPair
{
    var int Index;
    var float DistanceSquared;
};

// Set-up for new hitpoint types
enum ENewHitPointType
{
    NHP_Normal,
    NHP_GunOptics,
    NHP_PeriscopeOptics, // should we make the peri-optics replaceable?
    NHP_Traverse,
    NHP_GunPitch,
    NHP_Hull, // all kinds of nasty stuff can happen to driver, bow gunner, components, etc
};

var     ENewHitPointType    NewHitPointType;

struct NewHitpoint
{
    var() float             PointRadius;        // squared radius of the head of the pawn that is vulnerable to headshots
    var() float             PointHeight;        // distance from base of neck to center of head - used for headshot calculation
    var() float             PointScale;
    var() name              PointBone;          // bone to reference in offset
    var() vector            PointOffset;        // amount to offset the hitpoint from the bone
    var() bool              bPenetrationPoint;  // this is a penetration point, open hatch, etc
    var() float             DamageMultiplier;   // amount to scale damage to the vehicle if this point is hit
    var() ENewHitPointType  NewHitPointType;    // what type of hit point this is
};

var()   array<NewHitpoint>  NewVehHitpoints;    // an array of possible small points that can be hit. Index zero is always the driver

// Schurzen
struct SchurzenType
{
    var class<RODummyAttachment> SchurzenClass; // a possible schurzen decorative attachment class, with different degrees of damage
    var byte                     PercentChance; // the % chance of this deco attachment being the one spawned
};

var     SchurzenType        SchurzenTypes[4]; // an array of possible schurzen attachments
var     byte                SchurzenIndex;    // the schurzen index number selected randomly to be spawned for this vehicle
var     RODummyAttachment   Schurzen;         // actor reference to the schurzen deco attachment, so it can be destroyed when the vehicle gets destroyed
var     vector              SchurzenOffset;   // the positional offset from the attachment bone
var     Material            SchurzenTexture;  // the camo skin for the schurzen attachment

// General
var     float       PointValue; // used for scoring - 1 = Jeeps/Trucks; 2 = Light Tank/Recon Vehicle/AT Gun; 3 = Medium Tank; 4 = Medium Heavy (Pz V,JP), 5 = Heavy Tank
var     bool        bEmittersOn;
var     float       MaxCriticalSpeed;
var     float       WaitForCrewTime;
var     float       DriverTraceDistSquared; // CheckReset() variable // Matt: changed to a squared value, as VSizeSquared is more efficient than VSize

// Positions
var     int         UnbuttonedPositionIndex;
var     bool        bSpecialExiting;
var()   bool        bAllowRiders;
var     bool        bMustBeUnbuttonedToBecomePassenger;
var     int         FirstPassengerWeaponPawnIndex;

// Armor penetration
var     bool        bProjectilePenetrated; // shell has passed penetration test and has entered the hull or turret
var     bool        bAssaultWeaponHit;     // used to defeat the Stug/JP bug
var     bool        bIsAssaultGun;         // Matt: this appears unused in this class - check & deprecate later // TEST
var     bool        bRoundShattered;
var     bool        bRearHit;

var     float       UFrontArmorFactor; // upper armor values
var     float       URightArmorFactor;
var     float       ULeftArmorFactor;
var     float       URearArmorFactor;

var     float       UFrontArmorSlope;
var     float       URightArmorSlope;
var     float       ULeftArmorSlope;
var     float       URearArmorSlope;

var     float       GunMantletArmorFactor; // used for assault gun mantlet hits
var     float       GunMantletSlope;

// Damage stuff
var     float       AmmoIgnitionProbability; // allows for tank by tank ammo box ignition probabilities
var     float       DriverKillChance;        // chance that shrapnel will kill driver
var     float       GunnerKillChance;        // chance that shrapnel will kill bow gunner
var     float       TreadDamageThreshold;    // allows for tank by tank adjustment of tread vulnerability
var     bool        bPeriscopeDamaged;
var     texture     PeriscopeOverlay;
var     texture     DamagedPeriscopeOverlay;

// Turret damage stuff
var     bool        bWasTurretHit; // used to prevent lower turret hits from registering as tread hits
var     float       CommanderKillChance;
var     float       OpticsDamageChance;
var     float       GunDamageChance;
var     float       TraverseDamageChance;
var     float       TurretDetonationThreshold; // chance that turret ammo will go up

// Engine stuff
var     bool        bEngineDead; // tank engine is damaged and cannot run or be restarted...ever
var     bool        bEngineOff;  // tank engine is simply switched off
var     bool        bOldEngineOff;
var     float       IgnitionSwitchTime;

// Treads
var     int         LeftTreadIndex;
var     int         RightTreadIndex;
var     rotator     LeftTreadPanDirection;
var     rotator     RightTreadPanDirection;
var()   material    DamagedTreadPanner;

// Fire stuff- Shurek & Ch!cKeN
var     class<DamageType>           VehicleBurningDamType;
var     class<VehicleDamagedEffect> FireEffectClass;
var     VehicleDamagedEffect        DriverHatchFireEffect;
var()   name        FireAttachBone;
var()   vector      FireEffectOffset;
var()   float       FireDamage;
var     float       EngineFireDamagePerSec;
var     float       EngineFireChance;
var     float       EngineFireHEATChance;
var     float       HullFireChance;
var     float       HullFireHEATChance;
var     float       PlayerFireDamagePerSec;
var     float       BurnTime;
var     float       EngineBurnTime;
var     float       FireCheckTime;
//var() float       DamagedHealthFireFactor; // replaces DamagedEffectHealthFireFactor for calculating when a tank should catch fire from lack of health
var()   bool        bFirstHit;
var()   bool        bOnFire;       // hull is on fire
var()   bool        bEngineOnFire; // engine is on fire
var     bool        bWasHEATRound; // whether the round doing damage was a HEAT round or not
var     Controller  WhoSetOnFire;
var     Controller  WhoSetEngineOnFire;
var     int         FireStarterTeam;
var     bool        bTurretFireTriggered;  // to stop multiple calls to the TankCannon
var     bool        bHullMGFireTriggered;
var     float       DriverHatchBurnTime;
var     float       FireDetonationChance;   // chance of a fire blowing a tank up, runs each time the fire does damage
var     float       EngineToHullFireChance; // chance of an engine fire spreading to the rest of the tank, runs each time engine takes fire damage

// New sounds
var     sound       VehicleBurningSound;
var     sound       DestroyedBurningSound;
var     sound       DamagedStartUpSound;
var     sound       DamagedShutDownSound;
var     sound       SmokingEngineSound;

// Debugging help and customizable stuff
var     bool        bDrawPenetration;
var     bool        bDebuggingText;
var     bool        bPenetrationText;
var     bool        bDebugTreadText;
var     bool        bLogPenetration;
var     bool        bDebugExitPositions;

replication
{
    // Variables the server will replicate to clients when this actor is 1st replicated
    reliable if (bNetInitial && bNetDirty && Role == ROLE_Authority)
        SchurzenIndex;
   
    // Variables the server will replicate to the client that owns this actor
    reliable if (bNetDirty && bNetOwner && Role == ROLE_Authority)
        MaxCriticalSpeed; // Matt: this never changes & doesn't need to be replicated - check later & possibly remove

    // Variables the server will replicate to all clients // Matt: should be added to if (bNetDirty) below as "or bNetInitial adds nothing) - move later as part of class review & refactor
    reliable if ((bNetInitial || bNetDirty) && Role == ROLE_Authority)
        bEngineDead, bEngineOff;

    // Variables the server will replicate to all clients
    reliable if (bNetDirty && Role == ROLE_Authority)
//      EngineHealthMax,         // Matt: removed as I have deprecated
        UnbuttonedPositionIndex, // Matt: never changes & doesn't need to be replicated - check later & possibly remove
        bEngineOnFire, bOnFire;

    // Variables the server will replicate to all clients // Matt: should be added to if (bNetDirty) above - do later as part of class review & refactor
    reliable if (Role == ROLE_Authority) // Matt: at a glance, I'm not sure bProjPen or bFirstHit are used clientside (& peri not used at all) - check later & possibly remove
        bProjectilePenetrated, bFirstHit, bRoundShattered, bPeriscopeDamaged;
        
    // Functions a client can call on the server
    reliable if (Role < ROLE_Authority)
        TakeFireDamage, ServerStartEngine, ServerToggleDebugExits; // Matt: I suspect TakeFireDamage doesn't need to be replicated as called from Tick, which server gets anyway (in fact replication may be heinous!)
}


static final operator(24) bool > (ExitPositionPair A, ExitPositionPair B)
{
    return A.DistanceSquared > B.DistanceSquared;
}

//http://wiki.beyondunreal.com/Legacy:Insertion_Sort
static final function InsertSortEPPArray(out array<ExitPositionPair> MyArray, int LowerBound, int UpperBound)
{
    local int InsertIndex, RemovedIndex;

    if (LowerBound < UpperBound)
    {
        for (RemovedIndex = LowerBound + 1; RemovedIndex <= UpperBound; ++RemovedIndex)
        {
            InsertIndex = RemovedIndex;

            while (InsertIndex > LowerBound && MyArray[InsertIndex - 1] > MyArray[RemovedIndex])
            {
                --InsertIndex;
            }

            if (RemovedIndex != InsertIndex)
            {
                MyArray.Insert(InsertIndex, 1);
                MyArray[InsertIndex] = MyArray[RemovedIndex + 1];
                MyArray.Remove(RemovedIndex + 1, 1);
            }
        }
    }
}

function bool PlaceExitingDriver()
{
    local int i;
    local vector Extent, HitLocation, HitNormal, ZOffset, ExitPosition;
    local array<ExitPositionPair> ExitPositionPairs;

    if (Driver == none)
    {
        return false;
    }

    Extent = Driver.default.CollisionRadius * vect(1.0, 1.0, 0.0);
    Extent.Z = Driver.default.CollisionHeight;
    ZOffset = Driver.default.CollisionHeight * vect(0.0, 0.0, 0.5);

    ExitPositionPairs.Length = ExitPositions.Length;

    for (i = 0; i < ExitPositions.Length; ++i)
    {
        ExitPositionPairs[i].Index = i;
        ExitPositionPairs[i].DistanceSquared = VSizeSquared(DrivePos - ExitPositions[i]);
    }

    InsertSortEPPArray(ExitPositionPairs, 0, ExitPositionPairs.Length - 1);

    // Debug exits // Matt: uses abstract class default, allowing bDebugExitPositions to be toggled for all DH_ROTreadCrafts
    if (class'DH_ROTreadCraft'.default.bDebugExitPositions)
    {
        for (i = 0; i < ExitPositionPairs.Length; ++i)
        {
            ExitPosition = Location + (ExitPositions[ExitPositionPairs[i].Index] >> Rotation) + ZOffset;

            Spawn(class'DH_DebugTracer', , , ExitPosition);
        }
    }

    for (i = 0; i < ExitPositionPairs.Length; ++i)
    {
        ExitPosition = Location + (ExitPositions[ExitPositionPairs[i].Index] >> Rotation) + ZOffset;

        if (Trace(HitLocation, HitNormal, ExitPosition, Location + ZOffset, false, Extent) != none ||
            Trace(HitLocation, HitNormal, ExitPosition, ExitPosition + ZOffset, false, Extent) != none)
        {
            continue;
        }

        if (Driver.SetLocation(ExitPosition))
        {
            return true;
        }
    }

    return false;
}

static function StaticPrecache(LevelInfo L)
{
    super.StaticPrecache(L);

    L.AddPrecacheMaterial(Material'DH_VehiclesGE_tex2.ext_vehicles.Alpha');
}

simulated function UpdatePrecacheMaterials()
{
    Level.AddPrecacheMaterial(Material'DH_VehiclesGE_tex2.ext_vehicles.Alpha');

    super.UpdatePrecacheMaterials();
}

// Don't need this in DH
simulated function bool HitPenetrationPoint(vector HitLocation, vector HitRay);

simulated function SetupTreads()
{
    LeftTreadPanner = VariableTexPanner(Level.ObjectPool.AllocateObject(class'VariableTexPanner'));

    if (LeftTreadPanner != none)
    {
        LeftTreadPanner.Material = Skins[LeftTreadIndex];
        LeftTreadPanner.PanDirection = LeftTreadPanDirection;
        LeftTreadPanner.PanRate = 0.0;
        Skins[LeftTreadIndex] = LeftTreadPanner;
    }

    RightTreadPanner = VariableTexPanner(Level.ObjectPool.AllocateObject(class'VariableTexPanner'));

    if (RightTreadPanner != none)
    {
        RightTreadPanner.Material = Skins[RightTreadIndex];
        RightTreadPanner.PanDirection = RightTreadPanDirection;
        RightTreadPanner.PanRate = 0.0;
        Skins[RightTreadIndex] = RightTreadPanner;
    }
}

// Modified to fix RO bug where players can't get into a rider position on a driven tank if 1st rider position is already occupied
// Original often returned MG as ClosestWeaponPawn, which infantry cannot use, so we now check player can use weapon pawn & it's available)
function Vehicle FindEntryVehicle(Pawn P)
{
    local  float              DistSquared, ClosestDistSquared, BackupDistSquared; // use distance squared to compare to VSizeSquared (faster than VSize)
    local  int                x;
    local  VehicleWeaponPawn  ClosestWeaponPawn, BackupWeaponPawn;
    local  Bot                B;
    local  Vehicle            VehicleGoal;
    local  bool               bPlayerIsTankCrew;

    B = Bot(P.Controller);

    // Bots know what they want
    if (B != none)
    {
        // This is what's added in ROTreadCraft, worked into main function from ROVehicle ("code to get the bots using tanks better")
        if (WeaponPawns.Length != 0 && IsVehicleEmpty())
        {
            for (x = WeaponPawns.Length -1; x >= 0; x--)
            {
                if (WeaponPawns[x].Driver == none)
                {
                    return WeaponPawns[x];
                }
            }
        }

        VehicleGoal = Vehicle(B.RouteGoal);

        if (VehicleGoal == none)
        {
            return none;
        }

        if (VehicleGoal == self)
        {
            if (Driver == none)
            {
                return self;
            }

            return none;
        }

        for (x = 0; x < WeaponPawns.Length; x++)
        {
            if (VehicleGoal == WeaponPawns[x])
            {
                if (WeaponPawns[x].Driver == none)
                {
                    return WeaponPawns[x];
                }

                if (Driver == none)
                {
                    return self;
                }

                return none;
            }
        }

        return none;
    }

    // Always go with driver's seat if no driver (even if player isn't tank crew, TryToDrive puts them in any available rider slot)
    if (Driver == none)
    {
        DistSquared = VSizeSquared(P.Location - (Location + (EntryPosition >> Rotation)));

        if (DistSquared < Square(EntryRadius))
        {
            return self;
        }

        for (x = 0; x < WeaponPawns.Length; x++)
        {
            DistSquared = VSizeSquared(P.Location - (WeaponPawns[x].Location + (WeaponPawns[x].EntryPosition >> Rotation)));

            if (DistSquared < Square(WeaponPawns[x].EntryRadius))
            {
                return self;
            }
        }

        return none;
    }

    // Record if player is allowed to use tanks
    if (P.IsHumanControlled() && ROPlayerReplicationInfo(P.Controller.PlayerReplicationInfo) != none &&
        ROPlayerReplicationInfo(P.Controller.PlayerReplicationInfo).RoleInfo != none && ROPlayerReplicationInfo(P.Controller.PlayerReplicationInfo).RoleInfo.bCanBeTankCrew)
    {
        bPlayerIsTankCrew = true;
    }

    // Set some high starting values so we can record when we find a closer weapon pawn (squared distances are equivalent to 1,000 units or 16.5m)
    ClosestDistSquared = 1000000.0;
    BackupDistSquared = 1000000.0; // added so we can check the closest weapon pawn player could occupy, even though it may be out of range (vehicle itself may be in range)

    // Loop through weapon pawns to check if we are in entry range
    for (x = 0; x < WeaponPawns.Length; x++)
    {
        // Ignore this weapon pawn if it's already occupied by another player
        if (WeaponPawns[x] == none || (WeaponPawns[x].Driver != none && WeaponPawns[x].Driver.IsHumanControlled()))
        {
            continue;
        }

        // Stop non-tanker from trying to enter a tank crew position (cannon or MG), which would be unsuccessful & stop them reaching a valid rider slot
        if (!bPlayerIsTankCrew && WeaponPawns[x].IsA('ROVehicleWeaponPawn') && ROVehicleWeaponPawn(WeaponPawns[x]).bMustBeTankCrew)
        {
            continue;
        }

        // Calculate player's distance from this weapon pawn
        DistSquared = VSizeSquared(P.Location - (WeaponPawns[x].Location + (WeaponPawns[x].EntryPosition >> Rotation)));

        // Check if this weapon pawn is currently the closest one within range that the player can use
        if (DistSquared < ClosestDistSquared && DistSquared < Square(WeaponPawns[x].EntryRadius))
        {
            ClosestDistSquared = DistSquared;
            ClosestWeaponPawn = WeaponPawns[x];
        }
        // If not, check if this is closest 'backup' weapon pawn player could occupy (used below if vehicle itself in range but no weapon pawn in range)
        else if (ClosestWeaponPawn == none && DistSquared < BackupDistSquared)
        {
            BackupDistSquared = DistSquared;
            BackupWeaponPawn = WeaponPawns[x];
        }
    }

    // If we have a weapon pawn in range, return the closest recorded
    if (ClosestWeaponPawn != none)
    {
        return ClosestWeaponPawn;
    }
    // Or if we have a backup weapon pawn & the vehicle itself is in range, return the backup weapon pawn
    else if (BackupWeaponPawn != none && VSizeSquared(P.Location - (Location + (EntryPosition >> Rotation))) < Square(EntryRadius))
    {
        return BackupWeaponPawn;
    }
    // No valid slots in range
    else
    {
        return none;
    }
}

function KDriverEnter(Pawn p)
{
    local int x;

    DriverPositionIndex = InitialPositionIndex;
    PreviousPositionIndex = InitialPositionIndex;

    // lets bots start vehicle
    if (!p.IsHumanControlled())
       bEngineOff = false;

    //check to see if Engine is already on when entering
    if (bEngineOff)
    {
        if (IdleSound != none)
        {
            AmbientSound = none;
        }
    }
    else if (bEngineDead)
    {
        if (IdleSound != none)
        {
            AmbientSound = VehicleBurningSound;
        }
    }
    else
    {
        if (IdleSound != none)
        {
            AmbientSound = IdleSound;
        }
    }

    ResetTime = Level.TimeSeconds - 1.0;
    Instigator = self;

    super(Vehicle).KDriverEnter(P);

    if (Weapons.Length > 0)
    {
        Weapons[ActiveWeapon].bActive = true;
    }

    Driver.bSetPCRotOnPossess = false; // so when driver gets out he'll be facing the same direction as he was inside the vehicle

    for (x = 0; x < Weapons.Length; x++)
    {
        if (Weapons[x] == none)
        {
            Weapons.Remove(x, 1);
            x--;
        }
        else
        {
            Weapons[x].NetUpdateFrequency = 20.0;
            ClientRegisterVehicleWeapon(Weapons[x], x);
        }
    }
}

// Overriding here because we don't want exhaust/dust to start up until engine starts
simulated event DrivingStatusChanged()
{
    local PlayerController PC;

    PC = Level.GetLocalPlayerController();

    if (!bDriving || bEngineOff || bEngineDead)
    {
        if (LeftTreadPanner != none)
            LeftTreadPanner.PanRate = 0.0;

        if (RightTreadPanner != none)
            RightTreadPanner.PanRate = 0.0;

        // Not moving, so no motion sound
        MotionSoundVolume = 0.0;
        UpdateMovementSound();
    }

    if (bDriving && PC != none && (PC.ViewTarget == none || !(PC.ViewTarget.IsJoinedTo(self))))
    {
        bDropDetail = (Level.bDropDetail || (Level.DetailMode == DM_Low));
    }
    else
    {
        bDropDetail = false;
    }

    // We want the fire code to continue running even if no one is in the vehicle
    if (bDriving || bOnFire || bEngineOnFire)
    {
        Enable('Tick');
    }
    else
    {
        Disable('Tick');
    }

    super(ROVehicle).DrivingStatusChanged();

    // Moved exhaust and dust spawning to StartEngineFunction
}

// Overridden to add hint
simulated function ClientKDriverEnter(PlayerController PC)
{
    super.ClientKDriverEnter(PC);

    // Engine start/stop hint
    DHPlayer(PC).QueueHint(40, true);
}

function Fire(optional float F)
{
    if (Level.NetMode != NM_DedicatedServer)
    {
        ServerStartEngine();
    }
}

simulated function StopEmitters()
{
    local int i;

    if (Level.NetMode != NM_DedicatedServer && !bDropDetail)
    {
        for (i = 0; i < Dust.Length; i++)
        {
            if (Dust[i] != none)
            {
                Dust[i].Kill();
            }
        }

        Dust.Length = 0;

        for (i = 0; i < ExhaustPipes.Length; i++)
        {
            if (ExhaustPipes[i].ExhaustEffect != none)
            {
                ExhaustPipes[i].ExhaustEffect.Kill();
            }
        }
    }

    bEmittersOn = false;
}

simulated function StartEmitters()
{
    local int    i;
    local coords WheelCoords;

    if (Level.NetMode != NM_DedicatedServer && !bDropDetail)
    {
        Dust.Length = Wheels.Length;

        for (i = 0; i < Wheels.Length; i++)
        {
            if (Dust[i] != none)
            {
                Dust[i].Destroy();
            }

            // Create wheel dust emitters
            WheelCoords = GetBoneCoords(Wheels[i].BoneName);
            Dust[i] = Spawn(class'VehicleWheelDustEffect', self,, WheelCoords.Origin + ((vect(0.0, 0.0, -1.0) * Wheels[i].WheelRadius) >> Rotation));

            if (Level.bDropDetail || Level.DetailMode == DM_Low)
            {
                Dust[i].MaxSpritePPS = 3;
                Dust[i].MaxMeshPPS = 3;
            }

            Dust[i].SetBase(self);
            Dust[i].SetDirtColor(Level.DustColor);
        }

        for (i = 0; i < ExhaustPipes.Length; i++)
        {
            if (ExhaustPipes[i].ExhaustEffect != none)
            {
                ExhaustPipes[i].ExhaustEffect.Destroy();
            }

            // Create exhaust emitters
            if (Level.bDropDetail || Level.DetailMode == DM_Low)
            {
                ExhaustPipes[i].ExhaustEffect = Spawn(ExhaustEffectLowClass, self,, Location + (ExhaustPipes[i].ExhaustPosition >> Rotation), ExhaustPipes[i].ExhaustRotation + Rotation);
            }
            else
            {
                ExhaustPipes[i].ExhaustEffect = Spawn(ExhaustEffectClass, self,, Location + (ExhaustPipes[i].ExhaustPosition >> Rotation), ExhaustPipes[i].ExhaustRotation + Rotation);
            }

            ExhaustPipes[i].ExhaustEffect.SetBase(self);
        }
    }

    bEmittersOn = true;
}

// Server side function called to switch engine
function ServerStartEngine()
{
    if (bEngineDead)
    {
        return; // can't turn Engine on or off if it's dead
    }

    if (!bEngineOff)
    {
        // So that people can't spam the ignition switch and turn on/off while moving
        if ((Level.TimeSeconds - IgnitionSwitchTime) > 4.0 && Throttle == 0.0)
        {
            IgnitionSwitchTime = Level.TimeSeconds;

            if (AmbientSound != none)
            {
                AmbientSound = none;
            }

            if (ShutDownSound != none)
            {
                PlaySound(ShutDownSound, SLOT_None, 1.0);
            }

            Throttle = 0.0;
            ThrottleAmount = 0.0;
            bDisableThrottle = true;
            bWantsToThrottle = false;
            bEngineOff = true;
            TurnDamping = 0.0;

            if (WeaponPawns[0] != none && DH_ROTankCannon(WeaponPawns[0].Gun) != none)
            {
                DH_ROTankCannon(WeaponPawns[0].Gun).bManualTurret = true;
            }
        }
    }
    else
    {
        if (Level.TimeSeconds - IgnitionSwitchTime > 4.0)
        {
            IgnitionSwitchTime = Level.TimeSeconds;

            if (StartUpSound != none)
            {
                PlaySound(StartUpSound, SLOT_None, 1.0);
            }

            if (IdleSound != none)
            {
                AmbientSound = IdleSound;
            }

            Throttle = 0.0;
            bDisableThrottle = false;
            bWantsToThrottle = true;
            bEngineOff = false;

            if (WeaponPawns[0] != none && DH_ROTankCannon(WeaponPawns[0].Gun) != none)
            {
                DH_ROTankCannon(WeaponPawns[0].Gun).bManualTurret = false;
            }
        }
    }
}

// Overridden here to force the server to go to state "ViewTransition", used to prevent players exiting before the unbutton anim has finished
function ServerChangeViewPoint(bool bForward)
{
    if (bForward)
    {
        if (DriverPositionIndex < (DriverPositions.Length - 1))
        {
            PreviousPositionIndex = DriverPositionIndex;
            DriverPositionIndex++;

            if (Level.Netmode == NM_Standalone  || Level.NetMode == NM_ListenServer)
            {
                NextViewPoint();
            }
            else if (Level.NetMode == NM_DedicatedServer)
            {
                if (DriverPositionIndex == UnbuttonedPositionIndex)
                {
                    GoToState('ViewTransition');
                }
            }
        }
    }
    else
    {
        if (DriverPositionIndex > 0)
        {
            PreviousPositionIndex = DriverPositionIndex;
            DriverPositionIndex--;

            if (Level.Netmode == NM_Standalone  || Level.NetMode == NM_ListenServer)
            {
                NextViewPoint();
            }
        }
    }
}

// Overridden to prevent players exiting unless unbuttoned first
function bool KDriverLeave(bool bForceLeave)
{

    // If player is not unbuttoned and is trying to exit rather than switch positions, don't let them out
    // bForceLeave is always true for position switch, so checking against false means no risk of locking someone in one slot
    if (!bForceLeave && !bSpecialExiting && (DriverPositionIndex < UnbuttonedPositionIndex || Instigator.IsInState('ViewTransition')))
    {
        DenyEntry(Instigator, 4); // I realise that this is actually denying EXIT, but the function does the exact same thing - Ch!cken

        return false;
    }
    else if (!bForceLeave && bSpecialExiting)
    {
        DenyEntry(Instigator, 5); // Stug, JP, and Panzer III drivers must exit through commander's hatch

        return false;
    }
    else
    {
        super.KDriverLeave(bForceLeave);
    }
}

// DriverLeft() called by KDriverLeave()
function DriverLeft()
{
    MotionSoundVolume = 0.0;
    UpdateMovementSound();

    if (ActiveWeapon < Weapons.Length)
    {
        Weapons[ActiveWeapon].bActive = false;
        Weapons[ActiveWeapon].AmbientSound = none;
    }

    // Matt: changed from VSize > 5000 to VSizeSquared > 25000000, as is more efficient processing & does same thing
    if (!bNeverReset && ParentFactory != none && (VSizeSquared(Location - ParentFactory.Location) > 25000000.0 || !FastTrace(ParentFactory.Location, Location)))
    {
        if (bKeyVehicle)
        {
            ResetTime = Level.TimeSeconds + IdleTimeBeforeReset;
        }
        else
        {
            ResetTime = Level.TimeSeconds + IdleTimeBeforeReset;
        }
    }

    super(Vehicle).DriverLeft();
}

// Vehicle has been in the middle of nowhere with no driver for a while, so consider resetting it called after ResetTime has passed since driver left
// Overridden so we can control the time it takes for the vehicle to disappear - Ramm
event CheckReset()
{
    local Pawn P;

    if (bKeyVehicle && IsVehicleEmpty())
    {
        Died(none, class'DamageType', Location);
 
        return;
    }

    if (!IsVehicleEmpty())
    {
        ResetTime = Level.TimeSeconds + IdleTimeBeforeReset;

        return;
    }

    foreach CollidingActors(class'Pawn', P, 4000.0)
    {
        if (P != self && P.Controller != none && P.GetTeamNum() == GetTeamNum()) // traces only work on friendly players nearby
        {
            if (ROPawn(P) != none && (VSizeSquared(P.Location - Location) < DriverTraceDistSquared)) // Matt: changed so compare squared values, as VSizeSquared is more efficient
            {
                if (bDebuggingText)
                {
                    Level.Game.Broadcast(self, "Initiating collision reset check ...");
                }

                ResetTime = Level.TimeSeconds + IdleTimeBeforeReset;

                return;
            }
            else if (FastTrace(P.Location + P.CollisionHeight * vect(0.0, 0.0, 1.0), Location + CollisionHeight * vect(0.0, 0.0, 1.0)))
            {
                if (bDebuggingText)
                {
                    Level.Game.Broadcast(self, "Initiating FastTrace reset check ...");
                }

                ResetTime = Level.TimeSeconds + IdleTimeBeforeReset;

                return;
            }
        }
    }

    // If factory is active, we want it to spawn new vehicle NOW
    if (ParentFactory != none)
    {
        if (bDebuggingText)
        {
            Level.Game.Broadcast(self, "Player not found - respawn");
        }

        ParentFactory.VehicleDestroyed(self);
        ParentFactory.Timer();
        ParentFactory = none; // so doesn't call ParentFactory.VehicleDestroyed() again in Destroyed()
    }

    Destroy();
}

simulated state ViewTransition
{
    simulated function HandleTransition()
    {
        if (Role == ROLE_AutonomousProxy || Level.Netmode == NM_Standalone || Level.Netmode == NM_ListenServer)
        {
            if (DriverPositions[DriverPositionIndex].PositionMesh != none && !bDontUsePositionMesh)
            {
                LinkMesh(DriverPositions[DriverPositionIndex].PositionMesh);
            }
        }

        if (PreviousPositionIndex < DriverPositionIndex && HasAnim(DriverPositions[PreviousPositionIndex].TransitionUpAnim))
        {
            SetTimer(GetAnimDuration(DriverPositions[PreviousPositionIndex].TransitionUpAnim, 1.0), false);
            PlayAnim(DriverPositions[PreviousPositionIndex].TransitionUpAnim);
        }
        else if (HasAnim(DriverPositions[PreviousPositionIndex].TransitionDownAnim))
        {
            SetTimer(GetAnimDuration(DriverPositions[PreviousPositionIndex].TransitionDownAnim, 1.0), false);
            PlayAnim(DriverPositions[PreviousPositionIndex].TransitionDownAnim);
        }

        if (Driver != none && Driver.HasAnim(DriverPositions[DriverPositionIndex].DriverTransitionAnim))
        {
            Driver.PlayAnim(DriverPositions[DriverPositionIndex].DriverTransitionAnim);
        }
    }

    simulated function Timer()
    {
        SetTimer(1.0, false);
        GotoState('');
    }

    simulated function AnimEnd(int channel)
    {
        if (IsLocallyControlled())
        {
            GotoState('');
        }
    }

    simulated function EndState()
    {
        if (PlayerController(Controller) != none)
        {
            PlayerController(Controller).SetFOV(DriverPositions[DriverPositionIndex].ViewFOV);
            PlayerController(Controller).SetRotation(rot(0, 0, 0));
        }
    }

Begin:
    HandleTransition();
    Sleep(0.2);
}

function bool TryToDrive(Pawn P)
{
    local int x;

    if (DH_Pawn(P).bOnFire)
    {
        return false;
    }

    if (bOnFire || bEngineOnFire)
    {
        DenyEntry(P, 9);

        return false;
    }

    // Don't allow vehicle to be stolen when somebody is in a turret
    if (!bTeamLocked && P.GetTeamNum() != VehicleTeam)
    {
        for (x = 0; x < WeaponPawns.Length; x++)
        {
            if (WeaponPawns[x].Driver != none)
            {
                DenyEntry(P, 2);

                return false;
            }
        }
    }

    if (P.bIsCrouched || bNonHumanControl || (P.Controller == none) || (Driver != none) || (P.DrivenVehicle != none) || !P.Controller.bIsPlayer || P.IsA('Vehicle') || Health <= 0)
    {
        return false;
    }

    if (!Level.Game.CanEnterVehicle(self, P))
    {
        return false;
    }

    // Check vehicle locking
    if (bTeamLocked && (P.GetTeamNum() != VehicleTeam))
    {
        DenyEntry(P, 1);

        return false;
    }
    // They must be a non-tanker role so let's go through the available rider positions and find a place for them to sit
    else if (bMustBeTankCommander && !ROPlayerReplicationInfo(P.Controller.PlayerReplicationInfo).RoleInfo.bCanBeTankCrew && P.IsHumanControlled())
    {
        // Check first to ensure riders are allowed
        if (!bAllowRiders)
        {
            DenyEntry(P, 3);

            return false;
        }

        // Cycle through the available passenger positions (check the class type to see if it is ROPassengerPawn) // Matt: refactor later for new FirstPassengerWeaponPawnIndex variable
        for (x = 1; x < WeaponPawns.Length; x++) // skip over the turret
        {
            // If riders are allowed, the WeaponPawn is free and it is a passenger pawn class then climb aboard
            if (WeaponPawns[x].Driver == none && WeaponPawns[x].IsA('ROPassengerPawn'))
            {
                WeaponPawns[x].KDriverEnter(P);

                return true;
            }
        }

        DenyEntry(P, 8);

        return false;
    }
    else
    {
        if (bEnterringUnlocks && bTeamLocked)
        {
            bTeamLocked = false;
        }

        KDriverEnter(P);

        return true;
    }
}

// Send a message on why they can't get in the vehicle
function DenyEntry(Pawn P, int MessageNum)
{
    P.ReceiveLocalizedMessage(class'DH_VehicleMessage', MessageNum);
}

// Returns true if this tank is disabled
simulated function bool IsDisabled()
{
    return ((EngineHealth <= 0) || (bLeftTrackDamaged && bRightTrackDamaged));
}

// Cheating here to always spawn exiting players above their exit hatch, regardless of tank, without having to set it individually
simulated function PostBeginPlay()
{
    local byte RandomNumber, CumulativeChance, i;

    super.PostBeginPlay();

    // Engine starting and stopping stuff
    //bEngineOff = true;
    //bEngineDead = false;
    //bDisableThrottle = true;
    //bFirstHit = true;

    EngineFireDamagePerSec = default.EngineHealth * 0.10;  // Damage is dealt every 3 seconds, so this value is triple the intended per second amount
    DamagedEffectFireDamagePerSec = HealthMax * 0.02; // ~100 seconds from regular tank fire threshold to detonation from full health, damage is every 2 seconds, so double intended

    // If vehicle has schurzen (tex != none is flag) then randomise model selection (different degrees of damage, or maybe none at all)
    if (Role == ROLE_Authority && SchurzenTexture != none)
    {
        RandomNumber = RAND(100);

        for (i = 0; i < ArrayCount(SchurzenTypes); i++)
        {
            CumulativeChance += SchurzenTypes[i].PercentChance;

            if (RandomNumber < CumulativeChance)
            {
                SchurzenIndex = i; // set replicated variable so clients know which schurzen to spawn
                break;
            }
        }
    }
}

simulated function PostNetBeginPlay()
{
    super.PostNetBeginPlay();

    if (!bEngineOff)
    {
        bEngineOff = false;
    }

    // Only spawn schurzen if a valid attachment class has been selected
    if (Level.NetMode != NM_DedicatedServer && SchurzenIndex < ArrayCount(SchurzenTypes) && SchurzenTypes[SchurzenIndex].SchurzenClass != none && SchurzenTexture != none)
    {
        Schurzen = Spawn(SchurzenTypes[SchurzenIndex].SchurzenClass);

        if (Schurzen != none)
        {
            Schurzen.Skins[0] = SchurzenTexture; // set the deco attachment's camo skin
            AttachToBone(Schurzen, 'body');
            Schurzen.SetRelativeLocation(SchurzenOffset);
        }
    }

}

simulated function Tick(float DeltaTime)
{
    local KRigidBodyState BodyState;
    local float MotionSoundTemp, MySpeed;
    local int   i;

    KGetRigidBodyState(BodyState);
    LinTurnSpeed = 0.5 * BodyState.AngVel.Z;

    // Damaged treads cause vehicle to swerve and turn without control
    if (Controller != none)
    {
        if (bLeftTrackDamaged)
        {
            Throttle = FClamp(Throttle, -0.50, 0.50);

            if (Controller.IsA('ROPlayer'))
            {
                ROPlayer(Controller).aStrafe = -32768.0;
            }
            else if (Controller.IsA('ROBot'))
            {
                Steering = 1.0;
            }
        }
        else if (bRightTrackDamaged)
        {
            Throttle = FClamp(Throttle, -0.50, 0.50);

            if (Controller.IsA('ROPlayer'))
            {
                ROPlayer(Controller).aStrafe = 32768.0;
            }
            else if (Controller.IsA('ROBot'))
            {
                Steering = -1.0;
            }
        }
    }

    // Only need these effects client side
    if (Level.Netmode != NM_DedicatedServer)
    {
        if (bDisableThrottle)
        {
            if (bWantsToThrottle)
            {
                IntendedThrottle = 1.0;
            }
            else if (IntendedThrottle > 0.0)
            {
                IntendedThrottle -= (DeltaTime * 0.5);
            }
            else
            {
                IntendedThrottle = 0.0;
            }
        }
        else
        {
            if (bLeftTrackDamaged)
            {
                if (LeftTreadSoundAttach.AmbientSound != TrackDamagedSound)
                {
                    LeftTreadSoundAttach.AmbientSound = TrackDamagedSound;
                }

                LeftTreadSoundAttach.SoundVolume = IntendedThrottle * 255;
            }

            if (bRightTrackDamaged)
            {
                if (RightTreadSoundAttach.AmbientSound != TrackDamagedSound)
                {
                    RightTreadSoundAttach.AmbientSound = TrackDamagedSound;
                }

                RightTreadSoundAttach.SoundVolume = IntendedThrottle * 255;
            }

            SoundVolume = FMax(255.0 * 0.3, IntendedThrottle * 255.0);

            if (SoundVolume != default.SoundVolume)
            {
                SoundVolume = default.SoundVolume;
            }

            if (bLeftTrackDamaged && Skins[LeftTreadIndex] != DamagedTreadPanner)
            {
                Skins[LeftTreadIndex]=DamagedTreadPanner;
            }

            if (bRightTrackDamaged && Skins[RightTreadIndex] != DamagedTreadPanner)
            {
                Skins[RightTreadIndex]=DamagedTreadPanner;
            }
        }

        // Shame on you Psyonix, for calling VSize() 3 times every tick, when it only needed to be called once, as VSize() is very CPU intensive - Ramm
        MySpeed = VSize(Velocity);

        // Setup sounds that are dependent on velocity
        MotionSoundTemp =  MySpeed / MaxPitchSpeed * 255.0;

        if (MySpeed > 0.1)
        {
            MotionSoundVolume = FClamp(MotionSoundTemp, 0.0, 255.0);
        }
        else
        {
            MotionSoundVolume = 0.0;
        }

        UpdateMovementSound();

        if (LeftTreadPanner != none)
        {
            LeftTreadPanner.PanRate = MySpeed / TreadVelocityScale;

            if (Velocity dot vector(Rotation) < 0.0)
            {
                LeftTreadPanner.PanRate = -1.0 * LeftTreadPanner.PanRate;
            }

            LeftTreadPanner.PanRate += LinTurnSpeed;
        }

        if (RightTreadPanner != none)
        {
            RightTreadPanner.PanRate = MySpeed / TreadVelocityScale;

            if (Velocity dot vector(Rotation) < 0.0)
            {
                RightTreadPanner.PanRate = -1.0 * RightTreadPanner.PanRate;
            }

            RightTreadPanner.PanRate -= LinTurnSpeed;
        }

        // Animate the tank wheels
        LeftWheelRot.pitch += LeftTreadPanner.PanRate * WheelRotationScale;
        RightWheelRot.pitch += RightTreadPanner.PanRate * WheelRotationScale;

        for (i = 0; i < LeftWheelBones.Length; i++)
        {
            SetBoneRotation(LeftWheelBones[i], LeftWheelRot);
        }

        for (i = 0; i < RightWheelBones.Length; i++)
        {
            SetBoneRotation(RightWheelBones[i], RightWheelRot);
        }

        if (MySpeed >= MaxCriticalSpeed && ROPlayer(Controller) != none)
        {
            ROPlayer(Controller).aForward = -32768.0; // forces player to pull back on throttle
        }
    }

    // This will slow the tank way down when it tries to turn at high speeds
    if (ForwardVel > 0.0)
    {
        WheelLatFrictionScale = InterpCurveEval(AddedLatFriction, ForwardVel);
    }
    else
    {
        WheelLatFrictionScale = default.WheelLatFrictionScale;
    }

    if (bEngineOnFire || (bOnFire && Health > 0) && DamagedEffect != none)
    {
        if (DamagedEffectHealthFireFactor != 1.0)
        {
            DamagedEffectHealthFireFactor = 1.0;
            DamagedEffect.UpdateDamagedEffect(true, 0.0, false, false);
        }

        if (bOnFire && DriverHatchFireEffect == none)
        {
            // Lets randomise the fire start times to desync them with the turret and engine ones
            if (Level.TimeSeconds - DriverHatchBurnTime > 0.2)
            {
                if (FRand() < 0.1)
                {
                    DriverHatchFireEffect = Spawn(FireEffectClass);
                    AttachToBone(DriverHatchFireEffect, FireAttachBone);
                    DriverHatchFireEffect.SetRelativeLocation(FireEffectOffset);
                    DriverHatchFireEffect.SetEffectScale(DamagedEffectScale);
                    DriverHatchFireEffect.UpdateDamagedEffect(true, 0.0, false, false);
                }

                DriverHatchBurnTime = Level.TimeSeconds;
            }
            else if (!bTurretFireTriggered && WeaponPawns.Length > 0 && WeaponPawns[0] != none && DH_ROTankCannon(WeaponPawns[0].Gun) != none)
            {
                DH_ROTankCannon(WeaponPawns[0].Gun).bOnFire = true;
                bTurretFireTriggered = true;
            }
            else if (!bHullMGFireTriggered && WeaponPawns.Length > 1 && WeaponPawns[1] != none && DH_ROMountedTankMG(WeaponPawns[1].Gun) != none)
            {
                DH_ROMountedTankMG(WeaponPawns[1].Gun).bOnFire = true;
                bHullMGFireTriggered = true;
            }
        }

        TakeFireDamage(DeltaTime);
    }
    else if (EngineHealth <= 0 && Health > 0)
    {
        if (DamagedEffectHealthFireFactor != 0.0)
        {
            DamagedEffectHealthFireFactor = 0.0;
            DamagedEffectHealthHeavySmokeFactor = 1.0;
            DamagedEffect.UpdateDamagedEffect(false, 0.0, false, false); // reset fire effects
            DamagedEffect.UpdateDamagedEffect(false, 0.0, false, true);  // set the tank to smoke instead of burn
        }
    }

    super(ROWheeledVehicle).Tick(DeltaTime);

    if (bEngineDead || bEngineOff || (bLeftTrackDamaged && bRightTrackDamaged))
    {
        velocity = vect(0.0, 0.0, 0.0);
        Throttle = 0.0;
        ThrottleAmount = 0.0;
        bWantsToThrottle = false;
        bDisableThrottle = true;
        Steering = 0.0;
    }

    if (Level.NetMode != NM_DedicatedServer)
    {
        CheckEmitters();
    }
}

simulated function CheckEmitters()
{
    if (Level.NetMode == NM_DedicatedServer)
    {
        return;
    }

    if (bEmittersOn && (bEngineDead || bEngineOff))
    {
        StopEmitters();
    }
    else if (!bEmittersOn && !bEngineDead && !bEngineOff)
    {
        StartEmitters();
    }
}

// TakeFireDamage() called every tick when vehicle is burning
event TakeFireDamage(float DeltaTime)
{
    // Engine fire damage
    if (Level.TimeSeconds - EngineBurnTime > 3.0)
    {
        if (bEngineOnFire && EngineHealth > 0)
        {
            // If the instigator gets teamswapped before a burning tank dies, make sure they don't get friendly kills for it
            if (WhoSetEngineOnFire.GetTeamNum() != FireStarterTeam)
            {
                WhoSetEngineOnFire = none;
                DelayedDamageInstigatorController = none;
            }

            DamageEngine(EngineFireDamagePerSec, WhoSetEngineOnFire.Pawn, vect(0.0, 0.0, 0.0), vect(0.0, 0.0, 0.0), VehicleBurningDamType);
            EngineBurnTime = Level.TimeSeconds;
        }

        // Small chance of engine fire setting whole tank on fire, runs every time the fire does damage
        if (Level.TimeSeconds - FireCheckTime > 3 && !bOnFire && bEngineOnFire)
        {
            // If the instigator gets teamswapped before a burning tank dies, make sure they don't get friendly kills for it
            if (WhoSetOnFire.GetTeamNum() != FireStarterTeam)
            {
                WhoSetOnFire = none;
                DelayedDamageInstigatorController = none;
            }

            if (FRand() < EngineToHullFireChance)
            {
                TakeDamage(DamagedEffectFireDamagePerSec, WhoSetOnFire.Pawn, vect(0.0, 0.0, 0.0), vect(0.0, 0.0, 0.0), VehicleBurningDamType); // this will set bOnFire the first time it runs
            }

            FireCheckTime = Level.TimeSeconds;
        }
    }

    // Engine fire dies down 30 seconds after engine health hits zero
    if (Level.TimeSeconds - EngineBurnTime > 30.0 && bEngineOnFire && !bOnFire)
    {
        bEngineOnFire = false;
        bDisableThrottle = true;
        bEngineDead = true;
        DH_ROTankCannon(WeaponPawns[0].Gun).bManualTurret = true;

        if (!bOnFire)
        {
            AmbientSound = SmokingEngineSound;
        }
    }

    // Hull fire damage
    if ((Level.TimeSeconds - BurnTime) > 2.0 && bOnFire)
    {
        // Lets avoid having the tank blow up the instant it's hit (i.e. the 1st run through the function) as it gives false impression that hit itself was critical when it's not
        if (BurnTime == 0.0)
        {
            BurnTime = Level.TimeSeconds + 3.0;
            return;
        }

        // If the instigator gets teamswapped before a burning tank dies, make sure they don't get friendly kills for it
        if (WhoSetOnFire != none && WhoSetOnFire.GetTeamNum() != FireStarterTeam)
        {
            WhoSetOnFire = none;
            DelayedDamageInstigatorController = none;
        }

        if (Driver != none) // afflict the driver
        {
            Driver.TakeDamage(PlayerFireDamagePerSec, WhoSetOnFire.Pawn, Location, vect(0.0, 0.0, 0.0), VehicleBurningDamType);
        }
        else if (WeaponPawns[0] != none && WeaponPawns[0].Driver != none && bTurretFireTriggered == true) // afflict the commander
        {
            WeaponPawns[0].Driver.TakeDamage(PlayerFireDamagePerSec, WhoSetOnFire.Pawn, Location, vect(0.0, 0.0, 0.0), VehicleBurningDamType);
        }
        else if (WeaponPawns[1] != none && WeaponPawns[1].Driver != none && bHullMGFireTriggered == true) // afflict the hull gunner
        {
            WeaponPawns[1].Driver.TakeDamage(PlayerFireDamagePerSec, WhoSetOnFire.Pawn, Location, vect(0.0, 0.0, 0.0), VehicleBurningDamType);
        }

        if (FRand() < FireDetonationChance) // Chance of cooking off ammo/igniting fuel before health runs out
        {
            TakeDamage(Health, WhoSetOnFire.Pawn, vect(0.0, 0.0, 0.0), vect(0.0, 0.0, 0.0), VehicleBurningDamType);
        }
        else
        {
            TakeDamage(DamagedEffectFireDamagePerSec, WhoSetOnFire.Pawn, vect(0.0, 0.0, 0.0), vect(0.0, 0.0, 0.0), VehicleBurningDamType);
        }

        BurnTime = Level.TimeSeconds;
    }
}

function DamageTrack(bool bLeftTrack)
{
    if (bLeftTrack)
    {
        bDisableThrottle = false;
        bLeftTrackDamaged = true;
    }
    else
    {
        bDisableThrottle = false;
        bRightTrackDamaged = true;
    }
}

// Check to see if something hit a certain Hitpoint
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
    HeadLoc = HeadLoc + (NewVehHitpoints[Index].PointOffset >> rotator(C.Xaxis));

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

// Matt: new generic function to handle 'should penetrate' calcs for any shell type
// Replaces DHShouldPenetrateAPC, DHShouldPenetrateAPDS, DHShouldPenetrateHVAP, DHShouldPenetrateHVAPLarge, DHShouldPenetrateHEAT (also DO's DHShouldPenetrateAP & DHShouldPenetrateAPBC)
simulated function bool DHShouldPenetrate(class<DH_ROAntiVehicleProjectile> P, vector HitLocation, vector HitRotation, float PenetrationNumber)
{
    local float   HitAngleDegrees, Side, InAngle, InAngleDegrees;
    local vector  LocDir, HitDir, X, Y, Z;
    local rotator AimRot;

    if (bAssaultWeaponHit) // big fat HACK to defeat Stug/JP bug
    {
        bAssaultWeaponHit = false;

        return CheckPenetration(P, GunMantletArmorFactor, GunMantletSlope, PenetrationNumber);
    }

    // Figure out which side we hit
    LocDir = vector(Rotation);
    LocDir.Z = 0.0;
    HitDir =  Hitlocation - Location;
    HitDir.Z = 0.0;
    HitAngleDegrees = (Acos(Normal(LocDir) dot Normal(HitDir))) * 57.2957795131; // final multiplier converts the angle into degrees from radians
    GetAxes(Rotation, X, Y, Z);
    Side = Y dot HitDir;

    if (Side < 0.0)
    {
        HitAngleDegrees = 360.0 - HitAngleDegrees;
    }

    // Penetration debugging
    if (bLogPenetration)
    {
        Log("Hit angle =" @ HitAngleDegrees @ "degrees, Side =" @ Side);
    }

    if (bDebuggingText && Role == ROLE_Authority)
    {
        Level.Game.Broadcast(self, "Hit angle:" @ HitAngleDegrees @ "degrees");
    }

    if (bDrawPenetration)
    {
        ClearStayingDebugLines();
        AimRot = Rotation;
        AimRot.Yaw += (FrontLeftAngle / 360.0) * 65536;
        DrawStayingDebugLine(Location, Location + 2000.0 * vector(AimRot), 0, 255, 0);

        AimRot = Rotation;
        AimRot.Yaw += (FrontRightAngle / 360.0) * 65536;
        DrawStayingDebugLine(Location, Location + 2000.0 * vector(AimRot), 255, 255, 0);

        AimRot = Rotation;
        AimRot.Yaw += (RearRightAngle / 360.0) * 65536;
        DrawStayingDebugLine(Location, Location + 2000.0 * vector(AimRot), 0, 0, 255);

        AimRot = Rotation;
        AimRot.Yaw += (RearLeftAngle / 360.0) * 65536;
        DrawStayingDebugLine(Location, Location + 2000.0 * vector(AimRot), 0, 0, 0);
    }

    // Frontal hit
    if (HitAngleDegrees >= FrontLeftAngle || HitAngleDegrees < FrontRightAngle)
    {
        InAngle = Acos(Normal(-HitRotation) dot Normal(X));
        InAngleDegrees = InAngle * 57.2957795131;

        // Penetration debugging
        if (bDrawPenetration)
        {
            ClearStayingDebugLines();
            DrawStayingDebugLine(HitLocation, HitLocation + 2000.0 * Normal(X), 0, 255, 0);
            DrawStayingDebugLine(HitLocation, HitLocation + 2000.0 * Normal(-HitRotation), 255, 255, 0);
            Spawn(class'DH_DebugTracer', self, , HitLocation, rotator(HitRotation));
            Log("We hit the front of the vehicle");
        }

        // Fix hit detection bug
        if (InAngleDegrees > 90.0)
        {
            if (bPenetrationText && Role == ROLE_Authority)
            {
                Level.Game.Broadcast(self, "Hit bug: switching from front to REAR hull hit: base armor =" @ URearArmorFactor * 10.0 $ "mm");
            }

            // Run a pre-check
            if (URearArmorFactor > PenetrationNumber)
            {
                return false;
            }

            bRearHit = true;

            return CheckPenetration(P, URearArmorFactor, GetCompoundAngle(InAngle, URearArmorSlope), PenetrationNumber);
        }

        if (bPenetrationText && Role == ROLE_Authority)
        {
            Level.Game.Broadcast(self, "Front hull hit, base armor =" @ UFrontArmorFactor * 10.0 $ "mm");
        }

        // Run a pre-check
        if (UFrontArmorFactor > PenetrationNumber)
        {
            return false;
        }

        return CheckPenetration(P, UFrontArmorFactor, GetCompoundAngle(InAngle, UFrontArmorSlope), PenetrationNumber);
    }
    
    // Right side hit
    else if (HitAngleDegrees >= FrontRightAngle && HitAngleDegrees < RearRightAngle)
    {
        // Don't penetrate with HEAT if there is added side armor
        if (bHasAddedSideArmor && P.default.RoundType == RT_HEAT) // Matt: using RoundType (was P.default.ShellImpactDamage != none && P.default.ShellImpactDamage.default.bArmorStops)
        {
            return false;
        }

        InAngle = Acos(Normal(-HitRotation) dot Normal(Y));
        InAngleDegrees = InAngle * 57.2957795131;

        // Penetration Debugging
        if (bDrawPenetration)
        {
            ClearStayingDebugLines();
            DrawStayingDebugLine(HitLocation, HitLocation + 2000.0 * Normal(-Y), 0, 255, 0);
            DrawStayingDebugLine(HitLocation, HitLocation + 2000.0 * Normal(-HitRotation), 255, 255, 0);
            Spawn(class'DH_DebugTracer', self, , HitLocation, rotator(HitRotation));
            Log("We hit the right side of the vehicle");
        }

        // Fix hit detection bug
        if (InAngleDegrees > 90.0)
        {
            if (bPenetrationText && Role == ROLE_Authority)
            {
                Level.Game.Broadcast(self, "Hit bug: switching from right to LEFT hull hit: base armor =" @ ULeftArmorFactor * 10.0 $ "mm");
            }

            // Run a pre-check
            if (ULeftArmorFactor > PenetrationNumber)
            {
                return false;
            }

            return CheckPenetration(P, ULeftArmorFactor, GetCompoundAngle(InAngle, ULeftArmorSlope), PenetrationNumber);
        }

        if (bPenetrationText && Role == ROLE_Authority)
        {
            Level.Game.Broadcast(self, "Right turret hit: base armor =" @ URightArmorFactor * 10.0 $ "mm");;
        }

        // Run a pre-check
        if (URightArmorFactor > PenetrationNumber)
        {
            return false;
        }

        return CheckPenetration(P, URightArmorFactor, GetCompoundAngle(InAngle, URightArmorSlope), PenetrationNumber);
    }

    // Rear hit
    else if (HitAngleDegrees >= RearRightAngle && HitAngleDegrees < RearLeftAngle)
    {
        InAngle = Acos(Normal(-HitRotation) dot Normal(-X));
        InAngleDegrees = InAngle * 57.2957795131;

        //  Penetration debugging
        if (bDrawPenetration)
        {
            ClearStayingDebugLines();
            DrawStayingDebugLine(HitLocation, HitLocation + 2000.0 * Normal(-X), 0, 255, 0);
            DrawStayingDebugLine(HitLocation, HitLocation + 2000.0 * Normal(-HitRotation), 255, 255, 0);
            Spawn(class'DH_DebugTracer', self, , HitLocation, rotator(HitRotation));
            Log ("We hit the back of the vehicle");
        }

        // Fix hit detection bug
        if (InAngleDegrees > 90.0)
        {
            if (bPenetrationText && Role == ROLE_Authority)
            {
                Level.Game.Broadcast(self, "Hit bug: switching from rear to FRONT hull hit: base armor =" @ UFrontArmorFactor * 10.0 $ "mm");;
            }

            // Run a pre-check
            if (UFrontArmorFactor > PenetrationNumber)
            {
                return false;
            }

            return CheckPenetration(P, UFrontArmorFactor, GetCompoundAngle(InAngle, UFrontArmorSlope), PenetrationNumber);
        }

        if (bPenetrationText && Role == ROLE_Authority)
        {
            Level.Game.Broadcast(self, "Rear hull hit: base armor =" @ URearArmorFactor * 10.0 $ "mm");;
        }

        // Run a pre-check
        if (URearArmorFactor > PenetrationNumber)
        {
            return false;
        }

        return CheckPenetration(P, URearArmorFactor, GetCompoundAngle(InAngle, URearArmorSlope), PenetrationNumber);
    }

    // Left side hit
    else if (HitAngleDegrees >= RearLeftAngle && HitAngleDegrees < FrontLeftAngle)
    {
        // Don't penetrate with HEAT if there is added side armor
        if (bHasAddedSideArmor && P.default.RoundType == RT_HEAT) // Matt: using RoundType (was P.default.ShellImpactDamage != none && P.default.ShellImpactDamage.default.bArmorStops)
        {
            return false;
        }

        InAngle = Acos(Normal(-HitRotation) dot Normal(-Y));
        InAngleDegrees = InAngle * 57.2957795131;

        //  Penetration debugging
        if (bDrawPenetration)
        {
            ClearStayingDebugLines();
            DrawStayingDebugLine(HitLocation, HitLocation + 2000.0 * Normal(Y), 0, 255, 0);
            DrawStayingDebugLine(HitLocation, HitLocation + 2000.0 * Normal(-HitRotation), 255, 255, 0);
            Spawn(class'DH_DebugTracer', self, , HitLocation, rotator(HitRotation));
            Log("We hit the left side of the vehicle");
        }

        // Fix hit detection bug
        if (InAngleDegrees > 90.0)
        {
            if (bPenetrationText && Role == ROLE_Authority)
            {
                Level.Game.Broadcast(self, "Hit bug: switching from left to RIGHT hull hit: base armor =" @ URightArmorFactor * 10.0 $ "mm");;
            }

            // Run a pre-check
            if (URightArmorFactor > PenetrationNumber)
            {
                return false;
            }

            return CheckPenetration(P, URightArmorFactor, GetCompoundAngle(InAngle, URightArmorSlope), PenetrationNumber);
        }

        if (bPenetrationText && Role == ROLE_Authority)
        {
            Level.Game.Broadcast(self, "Left hull hit: base armor =" @ ULeftArmorFactor * 10.0 $ "mm");;
        }

        // Run a pre-check
        if (ULeftArmorFactor > PenetrationNumber)
        {
            return false;
        }

        return CheckPenetration(P, ULeftArmorFactor, GetCompoundAngle(InAngle, ULeftArmorSlope), PenetrationNumber);
    }

    // Should never happen !
    else
    {
       Log ("?!? We shoulda hit something !!!!");
       Level.Game.Broadcast(self, "?!? We shoulda hit something !!!!");

       return false;
    }
}

// Matt: new generic function to handle penetration calcs for any shell type
// Replaces PenetrationAPC, PenetrationAPDS, PenetrationHVAP, PenetrationHVAPLarge & PenetrationHEAT (also Darkest Orchestra's PenetrationAP & PenetrationAPBC)
simulated function bool CheckPenetration(class<DH_ROAntiVehicleProjectile> P, float ArmorFactor, float CompoundAngle, float PenetrationNumber)
{
    local float CompoundAngleDegrees, OverMatchFactor, SlopeMultiplier, EffectiveArmor, PenetrationRatio;

    // Convert angle back to degrees
    CompoundAngleDegrees = CompoundAngle * 57.2957795131;

    if (CompoundAngleDegrees > 90.0)
    {
        CompoundAngleDegrees = 180.0 - CompoundAngleDegrees;
    }

    // Calculate the SlopeMultiplier & EffectiveArmor, to give us the PenetrationRatio
    OverMatchFactor = ArmorFactor / P.default.ShellDiameter;
    SlopeMultiplier = GetArmorSlopeMultiplier(P, CompoundAngleDegrees, OverMatchFactor);
    EffectiveArmor = ArmorFactor * SlopeMultiplier;
    PenetrationRatio = PenetrationNumber / EffectiveArmor;

    // Penetration debugging
    if (Role == ROLE_Authority)
    {
        if (bDebuggingText)
        {
            Level.Game.Broadcast(self, "CompoundAngle:" @ CompoundAngleDegrees @ "SlopeMultiplier:" @ SlopeMultiplier);
        }

        if (bPenetrationText)
        {
            Level.Game.Broadcast(self, "Effective armor:" @ EffectiveArmor * 10.0 $ "mm" @ "Shot penetration:" @ PenetrationNumber * 10.0 $ "mm");
        }
    }

    // Now we have the necessary factors, check whether the round penetrates the armor
    if (PenetrationRatio >= 1.0)
    {
        // Check if the round should shatter on the armor
        if (P.default.bShatterProne)
        {
            bRoundShattered = CheckIfShatters(P, PenetrationRatio, OverMatchFactor);
        }

        if (!bRoundShattered)
        {
            bProjectilePenetrated = true;
            bWasTurretHit = true;
            bWasHEATRound = (P.default.RoundType == RT_HEAT);

            return true;
        }
    }

    bProjectilePenetrated = false;
    bWasTurretHit = false;

    return false;
}

// Returns the compound hit angle
simulated function float GetCompoundAngle(float AOI, float ArmorSlopeDegrees)
{
    local float ArmorSlope, CompoundAngle;

//  AOI = Abs(AOI * 0.01745329252); // Matt: now we pass AOI to this function in radians, to save unnecessary processing to and from degrees
    ArmorSlope = Abs(ArmorSlopeDegrees * 0.01745329252); // convert the angle degrees to radians
    CompoundAngle = Acos(Cos(ArmorSlope) * Cos(AOI));

    return CompoundAngle;
}

// Matt: new generic function to work with generic DHShouldPenetrate & CheckPenetration functions
simulated function float GetArmorSlopeMultiplier(class<DH_ROAntiVehicleProjectile> P, float CompoundAngleDegrees, optional float OverMatchFactor)
{
    local float CompoundExp, CompoundAngleFixed;
    local float RoundedDownAngleDegrees, ExtraAngleDegrees, BaseSlopeMultiplier, NextSlopeMultiplier, SlopeMultiplierGap;

    if (P.default.RoundType == RT_HVAP)
    {
        if (P.default.ShellDiameter >= 9.0) // HVAP rounds of at least 90mm shell diameter, e.g. Jackson's 90mm cannon (instead of using separate RoundType RT_HVAPLarge)
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
    else if (P.default.RoundType == RT_APDS)
    {
        CompoundExp = CompoundAngleDegrees ** 2.6;

        return 2.71828 ** (CompoundExp * 0.00003011);
    }
    else if (P.default.RoundType == RT_HEAT)
    {
        CompoundAngleFixed = Abs(CompoundAngleDegrees * 0.01745329252); // convert angle back to radians

        return 1.0 / Cos(CompoundAngleFixed);
    }
    else // should mean RoundType is RT_APC, RT_HE or RT_Smoke, but treating this as a catch-all default (will also handle DO's AP & APBC shells)
    {
        if (CompoundAngleDegrees < 10.0)
        {
            return CompoundAngleDegrees / 10.0 * ArmorSlopeTable(P, 10.0, OverMatchFactor);
        }
        else
        {
            RoundedDownAngleDegrees = Float(Int(CompoundAngleDegrees / 5.0)) * 5.0; // to nearest 5 degrees, rounded down
            ExtraAngleDegrees = CompoundAngleDegrees - RoundedDownAngleDegrees;
            BaseSlopeMultiplier = ArmorSlopeTable(P, RoundedDownAngleDegrees, OverMatchFactor);
            NextSlopeMultiplier = ArmorSlopeTable(P, RoundedDownAngleDegrees + 5.0, OverMatchFactor);
            SlopeMultiplierGap = NextSlopeMultiplier - BaseSlopeMultiplier;

            return BaseSlopeMultiplier + (ExtraAngleDegrees / 5.0 * SlopeMultiplierGap);
        }
    }

    return 1.0; // fail-safe neutral return value
}

// Matt: new generic function to work with new GetArmorSlopeMultiplier for APC shells (also handles Darkest Orchestra's AP & APBC shells)
simulated function float ArmorSlopeTable(class<DH_ROAntiVehicleProjectile> P, float CompoundAngleDegrees, float OverMatchFactor)
{
    // after Bird & Livingston:
    if (P.default.RoundType == RT_AP) // from Darkest Orchestra
    {
        if      (CompoundAngleDegrees <= 10.0)  return 0.98  * (OverMatchFactor ** 0.0637); // at 10 degrees
        else if (CompoundAngleDegrees <= 15.0)  return 1.00  * (OverMatchFactor ** 0.0969);
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
        else if (CompoundAngleDegrees <= 75.0)  return 13.75 * (OverMatchFactor ** 1.074);
        else if (CompoundAngleDegrees <= 80.0)  return 21.87 * (OverMatchFactor ** 1.17973);
        else                                    return 34.49 * (OverMatchFactor ** 1.28631); // at 85 degrees
    }
    else if (P.default.RoundType == RT_APBC) // from Darkest Orchestra
    {
        if      (CompoundAngleDegrees <= 10.0)  return 1.04 * (OverMatchFactor ** 0.01555); // at 10 degrees
        else if (CompoundAngleDegrees <= 15.0)  return 1.06 * (OverMatchFactor ** 0.02315);
        else if (CompoundAngleDegrees <= 20.0)  return 1.08 * (OverMatchFactor ** 0.03448);
        else if (CompoundAngleDegrees <= 25.0)  return 1.11 * (OverMatchFactor ** 0.05134);
        else if (CompoundAngleDegrees <= 30.0)  return 1.16 * (OverMatchFactor ** 0.07710);
        else if (CompoundAngleDegrees <= 35.0)  return 1.22 * (OverMatchFactor ** 0.11384);
        else if (CompoundAngleDegrees <= 40.0)  return 1.31 * (OverMatchFactor ** 0.16952);
        else if (CompoundAngleDegrees <= 45.0)  return 1.44 * (OverMatchFactor ** 0.24604);
        else if (CompoundAngleDegrees <= 50.0)  return 1.68 * (OverMatchFactor ** 0.37910);
        else if (CompoundAngleDegrees <= 55.0)  return 2.11 * (OverMatchFactor ** 0.56444);
        else if (CompoundAngleDegrees <= 60.0)  return 3.50 * (OverMatchFactor ** 1.07411);
        else if (CompoundAngleDegrees <= 65.0)  return 5.34 * (OverMatchFactor ** 1.46188);
        else if (CompoundAngleDegrees <= 70.0)  return 9.48 * (OverMatchFactor ** 1.81520);
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

// Matt: new generic function to work with new CheckPenetration function - checks if the round should shatter, based on the 'shatter gap' for different round types
simulated function bool CheckIfShatters(class<DH_ROAntiVehicleProjectile> P, float PenetrationRatio, optional float OverMatchFactor)
{
    if (P.default.RoundType == RT_HVAP)
    {
        if (P.default.ShellDiameter >= 9.0) // HVAP rounds of at least 90mm shell diameter, e.g. Jackson's 90mm cannon (instead of using separate RoundType RT_HVAPLarge)
        {
            if (PenetrationRatio >= 1.10 && PenetrationRatio <= 1.27)
            {
                return true;
            }
        }
        else // smaller HVAP rounds
        {
            if (PenetrationRatio >= 1.10 && PenetrationRatio <= 1.34)
            {
                return true;
            }
        }
    }
    else if (P.default.RoundType == RT_APDS)
    {
        if (PenetrationRatio >= 1.06 && PenetrationRatio <= 1.20)
        {
            return true;
        }
    }
    else if (P.default.RoundType == RT_HEAT) // no chance of shatter for HEAT round
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

function TakeDamage(int Damage, Pawn InstigatedBy, vector HitLocation, vector Momentum, class<DamageType> DamageType, optional int HitIndex)
{
    local Controller InstigatorController;
    local vector     LocDir, HitDir, X, Y, Z;
    local float      HitAngle, Side, InAngle, VehicleDamageMod;
    local int        HitPointDamage, InstigatorTeam, i;


    // Fix for suicide death messages
    if (DamageType == class'Suicided')
    {
        DamageType = class'ROSuicided';

        super(ROVehicle).TakeDamage(Damage, InstigatedBy, Hitlocation, Momentum, DamageType);
    }
    else if (DamageType == class'ROSuicided')
    {
        super(ROVehicle).TakeDamage(Damage, InstigatedBy, Hitlocation, Momentum, DamageType);
    }

    // Quick fix for the thing giving itself impact damage
    if (InstigatedBy == self && DamageType != VehicleBurningDamType)
    {
        return;
    }

    // Don't allow your own teammates to destroy vehicles in spawns (and you know some jerks would get off on doing that to their team :))
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
                return;
            }
        }
    }

    // Modify the damage based on what it should do to the vehicle; overloaded here so tank cannot take any bullet/bash/bayo damage
    if (class<ROWeaponDamageType>(DamageType) != none)
    {
        VehicleDamageMod = class<ROWeaponDamageType>(DamageType).default.TankDamageModifier;
    }
    else if (class<ROVehicleDamageType>(DamageType) != none)
    {
        VehicleDamageMod = class<ROVehicleDamageType>(DamageType).default.TankDamageModifier;
    }

    for (i = 0; i < VehHitpoints.Length; i++)
    {
        HitPointDamage=Damage;

        if (VehHitpoints[i].HitPointType == HP_Driver)
        {
            // Damage for large weapons
            if (class<ROWeaponDamageType>(DamageType) != none && class<ROWeaponDamageType>(DamageType).default.VehicleDamageModifier > 0.25)
            {
                if (Driver != none && DriverPositions[DriverPositionIndex].bExposed && IsPointShot(Hitlocation,Momentum, 1.0, i))
                {
                    Driver.TakeDamage(Damage, InstigatedBy, Hitlocation, Momentum, DamageType);
                }
            }
            // Damage for small (non penetrating) arms
            else
            {
                if (Driver != none && DriverPositions[DriverPositionIndex].bExposed && IsPointShot(Hitlocation,Momentum, 1.0, i, DriverHitCheckDist))
                {
                    Driver.TakeDamage(150, InstigatedBy, Hitlocation, Momentum, DamageType);
                }
            }
        }
        else if (IsPointShot(Hitlocation,Momentum, 1.0, i))
        {
            HitPointDamage *= VehHitpoints[i].DamageMultiplier;
            HitPointDamage *= VehicleDamageMod;

            if (bLogPenetration)
            {
                Log(" We hit" @ GetEnum(enum'EHitPointType',VehHitpoints[i].HitPointType) @ "hitpoint.");
            }

            if (VehHitpoints[i].HitPointType == HP_Engine)
            {
                // Extra check here prevents splashing HE/HEAT from triggering engine fires
                if (DamageType != none && (class<ROWeaponDamageType>(DamageType) != none && class<ROWeaponDamageType>(DamageType).default.TankDamageModifier > 0.5) && bProjectilePenetrated == true)
                {
                    if (bDebuggingText)
                    {
                        Level.Game.Broadcast(self, "Engine hit effective");
                    }

                    DamageEngine(HitPointDamage, InstigatedBy, Hitlocation, Momentum, DamageType);
                    Damage *= 0.55; // hitting the engine shouldn't blow up the tank automatically!
                }
            }
            else if (VehHitpoints[i].HitPointType == HP_AmmoStore)
            {
                // Extra check here prevents splashing HE/HEAT from triggering ammo detonation or fires; Engine hit will stop shell from passing through to cabin
                if (bProjectilePenetrated == true && bRearHit == false)
                {
                    if (class<ROWeaponDamageType>(DamageType) != none && class<ROWeaponDamageType>(DamageType).default.TankDamageModifier > 0.5 && 
                        (FRand() <= AmmoIgnitionProbability || (bWasHEATRound && FRand() < 0.85)))
                    {
                        if (bDebuggingText)
                        {
                            Level.Game.Broadcast(self, "Ammo hit effective");
                        }

                        Damage *= Health;
                        break;
                    }
                    else // either detonate above - or - set the sucker on fire!
                    {
                       HullFireChance=0.75;
                       HullFireHEATChance=0.90;
                    }
                }
            }
        }
    }

    for (i = 0; i < NewVehHitpoints.Length; i++)
    {
        HitPointDamage=Damage;

        if (bLogPenetration)
        {
            Log("We hit" @ GetEnum(enum'ENewHitPointType', NewVehHitpoints[i].NewHitPointType) @ "hitpoint");
        }

        if (IsNewPointShot(Hitlocation,Momentum, 1.0, i))
        {
            HitPointDamage *= VehicleDamageMod;

            if  (NewVehHitpoints[i].NewHitPointType == NHP_GunOptics) // can be useful for Stug and JP
            {
                if (bDebuggingText)
                {
                    Level.Game.Broadcast(self, "Optics hit");
                }

                DH_ROTankCannonPawn(WeaponPawns[0]).DamageCannonOverlay();
            }
            else if (NewVehHitpoints[i].NewHitPointType == NHP_PeriscopeOptics)
            {
            }
            else if (NewVehHitpoints[i].NewHitPointType == NHP_Traverse && bProjectilePenetrated == true) // useful for assault guns
            {
                if (bDebuggingText)
                {
                    Level.Game.Broadcast(self, "Turret ring hit");
                }

                DH_ROTankCannonPawn(WeaponPawns[0]).bTurretRingDamaged = true;
            }
            else if (NewVehHitpoints[i].NewHitPointType == NHP_GunPitch && bProjectilePenetrated == true) // useful for assault guns
            {
                if (bDebuggingText)
                {
                    Level.Game.Broadcast(self, "Gun pivot hit");
                }

                DH_ROTankCannonPawn(WeaponPawns[0]).bGunPivotDamaged = true;
            }
        }
    }

    if (bProjectilePenetrated == true)
    {
        if (bWasTurretHit == false)
        {
            if (bRearHit == false && Driver != none && FRand() < Damage/DriverKillChance)
            {
                if (bDebuggingText)
                {
                    Level.Game.Broadcast(self, "Driver killed");
                }

                Driver.TakeDamage(150, InstigatedBy, Location, vect(0.0, 0.0, 0.0), DamageType);
            }

            if (bRearHit == false && WeaponPawns[1] != none && WeaponPawns[1].Driver != none && FRand() < Damage/GunnerKillChance)
            {
                if (bDebuggingText)
                {
                    Level.Game.Broadcast(self, "Hull gunner killed");
                }

                WeaponPawns[1].Driver.TakeDamage(150, InstigatedBy, Location, vect(0.0, 0.0, 0.0), DamageType);
            }
        }
        else
        {
            if (WeaponPawns[0] != none)
            {
                if (WeaponPawns[0].Driver != none && FRand() < Damage/CommanderKillChance)
                {
                    if (bDebuggingText)
                    {
                        Level.Game.Broadcast(self, "Commander killed");
                    }

                    WeaponPawns[0].Driver.TakeDamage(150, InstigatedBy, Location, vect(0.0, 0.0, 0.0), DamageType);
                }

                if (FRand() < Damage/OpticsDamageChance)
                {
                    if (bDebuggingText)
                    {
                        Level.Game.Broadcast(self, "Optics destroyed");
                    }

                    DH_ROTankCannonPawn(WeaponPawns[0]).DamageCannonOverlay();
                }

                if (FRand() < Damage/GunDamageChance)
                {
                    if (bDebuggingText)
                    Level.Game.Broadcast(self, "Gun Pivot Damaged");
                    DH_ROTankCannonPawn(WeaponPawns[0]).bGunPivotDamaged = true;
                }

                if (FRand() < Damage/TraverseDamageChance)
                {
                    if (bDebuggingText)
                    {
                        Level.Game.Broadcast(self, "Traverse Damaged");
                    }

                    DH_ROTankCannonPawn(WeaponPawns[0]).bTurretRingDamaged = true;
                }
            }

            if (FRand() < Damage/TurretDetonationThreshold)
            {
                if (bDebuggingText)
                {
                    Level.Game.Broadcast(self, "Turret ammo detonated");
                }

                Damage *= Health;
            }
            else
            {
                Damage *= 0.55;
            }
        }

        if (!bFirstHit)
        {
            HullFireChance = 0.75;
            HullFireHEATChance = 0.90;
        }
    }

    // Tread damage calculations
    LocDir = vector(Rotation);
    LocDir.Z = 0.0;
    HitDir =  Hitlocation - Location;
    HitDir.Z = 0.0;
    HitAngle = Acos(Normal(LocDir) dot Normal(HitDir));

    // Convert the angle into degrees from radians
    HitAngle *= 57.2957795131;

    GetAxes(Rotation, X, Y, Z);
    Side = Y dot HitDir;

    if (Side >= 0.0)
    {
       HitAngle = 360.0 - HitAngle;
    }

    // Left side hit
    if ((HitAngle >= FrontRightAngle && HitAngle < RearRightAngle) && !bWasTurretHit) 
    {
        HitDir = Hitlocation - Location;
        InAngle= Acos(Normal(HitDir) dot Normal(Z));

        if (InAngle > TreadHitMinAngle)
        {
            if (class<ROWeaponDamageType>(DamageType) != none && class<ROWeaponDamageType>(DamageType).default.TreadDamageModifier >= TreadDamageThreshold)
            {
                if (!bDriving)
                {
                    Enable('Tick');
                }

                DamageTrack(true);

                if (bDebugTreadText && Role == ROLE_Authority)
                {
                    Level.Game.Broadcast(self, "Left track damaged");
                }
            }
        }
    }
    //Right side hit
    else if ((HitAngle >= RearLeftAngle && HitAngle < FrontLeftAngle) && !bWasTurretHit)
    {
        HitDir = Hitlocation - Location;
        InAngle= Acos(Normal(HitDir) dot Normal(Z));

        if (InAngle > TreadHitMinAngle)
        {
            if (class<ROWeaponDamageType>(DamageType) != none && class<ROWeaponDamageType>(DamageType).default.TreadDamageModifier >= TreadDamageThreshold)
            {
                if (!bDriving)
                {
                    Enable('Tick');
                }

                DamageTrack(false);

                if (bDebugTreadText && Role == ROLE_Authority)
                {
                    Level.Game.Broadcast(self, "Right track damaged");
                }
            }
        }
    }

    // If I allow randomised damage then things break once the hull catches fire
    if (DamageType != VehicleBurningDamType)
    {
        Damage *= RandRange(0.75, 1.08);
    }

    // Add in the vehicle damage modifier for the actual damage to the vehicle itself
    Damage *= VehicleDamageMod;

    super(ROVehicle).TakeDamage(Damage, InstigatedBy, Hitlocation, Momentum, DamageType);

    // This starts the hull fire; extra check added below to prevent HE splash from triggering Hull Fire Chance function
    if (!bOnFire && Damage > 0 && Health > 0 && class<ROWeaponDamageType>(DamageType) != none && 
        class<ROWeaponDamageType>(DamageType).default.TankDamageModifier > 0.50 && bProjectilePenetrated == true)
    {
        if ((DamageType != VehicleBurningDamType && FRand() < HullFireChance) || (bWasHEATRound && FRand() < HullFireHEATChance))
        {
            if (bDebuggingText)
            {
                Level.Game.Broadcast(self, "Vehicle on fire");
            }

            if (!bDriving)
            {
                Enable('Tick');
            }

            bOnFire = true;
            WhoSetOnFire = InstigatedBy.Controller;
            DelayedDamageInstigatorController = WhoSetOnFire;
            FireStarterTeam = WhoSetOnFire.GetTeamNum();
        }
        else if (DamageType == VehicleBurningDamType)
        {
            bOnFire = true;
            WhoSetOnFire = WhoSetEngineOnFire;
            FireStarterTeam = WhoSetOnFire.GetTeamNum();
        }
    }

    // Reset everything
    bWasHEATRound = false;
    bRearHit = false;
    bFirstHit = false;
    bProjectilePenetrated = false;
    bRoundShattered = false;
    bWasTurretHit = false;
}

// Handle the engine damage
function DamageEngine(int Damage, Pawn InstigatedBy, vector Hitlocation, vector Momentum, class<DamageType> DamageType)
{
    local int ActualDamage;

    if (DamageType != VehicleBurningDamType)
    {
        ActualDamage = Level.Game.ReduceDamage(Damage, self, InstigatedBy, HitLocation, Momentum, DamageType);
    }
    else
    {
        ActualDamage = Damage;
    }

    EngineHealth -= ActualDamage;

    // This indicates chances for an Engine fire breaking out
    if (DamageType != VehicleBurningDamType && !bEngineOnFire && ActualDamage > 0 && EngineHealth > 0 && Health > 0)
    {
        if ((bWasHEATRound && FRand() < EngineFireHEATChance) || FRand() < EngineFireChance)
        {
            if (bDebuggingText)
            {
                Level.Game.Broadcast(self, "Engine on fire");
            }

            bEngineOnFire = true;
            WhoSetEngineOnFire = InstigatedBy.Controller;
            DelayedDamageInstigatorController = WhoSetEngineOnFire;
            FireStarterTeam = WhoSetEngineOnFire.GetTeamNum();
        }
    }

    // If engine health drops below a certain level, slow the tank way down
    if (EngineHealth > 0 && EngineHealth <= (default.EngineHealth * 0.50))
    {
        Throttle = FClamp(Throttle, -0.50, 0.50);
    }
    else if (EngineHealth <= 0)
    {
        if (bDebuggingText && Role == ROLE_Authority)
        {
            Level.Game.Broadcast(self, "Engine is dead");
        }

        bDisableThrottle = true;
        bEngineOff = true;
        bEngineDead = true;
        DH_ROTankCannon(WeaponPawns[0].Gun).bManualTurret = true;

        TurnDamping = 0.0;

        IdleSound = VehicleBurningSound;
        StartUpSound = none;
        ShutDownSound = none;
        AmbientSound = VehicleBurningSound;
        SoundVolume = 255;
        SoundRadius = 600.0;
    }
}

// Matt: modified so will pass radius damage on to each VehicleWeaponPawn, as originally lack of vehicle driver caused early exit
function DriverRadiusDamage(float DamageAmount, float DamageRadius, Controller EventInstigator, class<DamageType> DamageType, float Momentum, vector HitLocation)
{
    local vector Direction;
    local float  DamageScale, Distance;
    local int    i;

    // Damage the Driver, not if he has collision as whatever is causing the radius damage will hit the Driver by itself
    if (Driver != none && !Driver.bCollideActors && DriverPositions[DriverPositionIndex].bExposed && EventInstigator != none && !bRemoteControlled)
    {
        Direction = Driver.Location - HitLocation;
        Distance = FMax(1.0, VSize(Direction));
        Direction = Direction / Distance;
        DamageScale = 1.0 - FMax(0.0, (Distance - Driver.CollisionRadius) / DamageRadius);

        if (DamageScale > 0.0)
        {
            Driver.SetDelayedDamageInstigatorController(EventInstigator);
            Driver.TakeDamage(DamageScale * DamageAmount, EventInstigator.Pawn, Driver.Location - (0.5 * (Driver.CollisionHeight + Driver.CollisionRadius)) * Direction, 
                DamageScale * Momentum * Direction, DamageType);
        }
    }

    // Pass on to each VehicleWeaponPawn, but not if it has collision as whatever is causing the radius damage will hit the VWP by itself
    for (i = 0; i < WeaponPawns.Length; i++)
    {
        if (!WeaponPawns[i].bCollideActors)
        {
            WeaponPawns[i].DriverRadiusDamage(DamageAmount, DamageRadius, EventInstigator, DamageType, Momentum, HitLocation);
        }
    }
}

// Check to see if vehicle should destroy itself - stops vehicle from premature detonation when on fire
function MaybeDestroyVehicle()
{
    if (IsDisabled() && IsVehicleEmpty() && !bNeverReset && !bOnFire && !bEngineOnFire)
    {
        bSpikedVehicle = true;
        SetTimer(VehicleSpikeTime, false);

        if (bDebuggingText)
        {
            Level.Game.Broadcast(self, "Initiating vehicle SpikeTimer");
        }
    }
}

simulated function Destroyed()
{
    if (Level.NetMode != NM_DedicatedServer)
    {
        if (DriverHatchFireEffect != none)
        {
            DriverHatchFireEffect.Destroy();
            DriverHatchFireEffect = none;
        }
    }

    super.Destroyed();

    if (Schurzen != none)
    {
        Schurzen.Destroy();
    }
}

simulated event DestroyAppearance()
{
    local int         i;
    local KarmaParams KP;

    // For replication
    bDestroyAppearance = true;

    // Put brakes on
    Throttle = 0.0;
    Steering = 0.0;
    Rise     = 0.0;

    // Destroy the weapons
    if (Role == ROLE_Authority)
    {
        for (i = 0; i < Weapons.Length; i++)
        {
            if (Weapons[i] != none)
            {
                Weapons[i].Destroy();
            }
        }

        for (i = 0; i < WeaponPawns.Length; i++)
        {
            WeaponPawns[i].Destroy();
        }
    }

    Weapons.Length = 0;
    WeaponPawns.Length = 0;

    // Destroy the effects
    if (Level.NetMode != NM_DedicatedServer)
    {
        bNoTeamBeacon = true;

        for (i = 0; i < HeadlightCorona.Length; i++)
        {
            if (HeadlightCorona[i] != none)
            {
                HeadlightCorona[i].Destroy();
            }
        }

        HeadlightCorona.Length = 0;

        if (HeadlightProjector != none)
        {
            HeadlightProjector.Destroy();
        }

        for (i = 0; i < Dust.Length; i++)
        {
            if (Dust[i] != none)
            {
                Dust[i].Kill();
            }
        }

        Dust.Length = 0;

        for (i = 0; i < ExhaustPipes.Length; i++)
        {
            if (ExhaustPipes[i].ExhaustEffect != none)
            {
                ExhaustPipes[i].ExhaustEffect.Kill();
            }
        }
    }

    // Copy linear velocity from actor so it doesn't just stop
    KP = KarmaParams(KParams);

    if (KP != none)
    {
        KP.KStartLinVel = Velocity;
    }

    if (DamagedEffect != none)
    {
        DamagedEffect.Kill();
    }

    if (DriverHatchFireEffect != none)
    {
        DriverHatchFireEffect.Kill();
    }

    // Become the dead vehicle mesh
    SetPhysics(PHYS_None);
    KSetBlockKarma(false);
    SetDrawType(DT_StaticMesh);
    SetStaticMesh(DestroyedVehicleMesh);
    KSetBlockKarma(true);
    SetPhysics(PHYS_Karma);
    Skins.Length = 0;
    NetPriority = 2.0;

    if (Schurzen != none)
    {
        Schurzen.Destroy();
    }
}

function VehicleExplosion(vector MomentumNormal, float PercentMomentum)
{
    local vector LinearImpulse, AngularImpulse;
    local float  RandomExplModifier;

    RandomExplModifier = FRand();

    // Don't hurt us when we are destroying our own vehicle // borrowed from AB
    HurtRadius(ExplosionDamage * RandomExplModifier, ExplosionRadius * RandomExplModifier, ExplosionDamageType, ExplosionMomentum, Location);

    AmbientSound = DestroyedBurningSound;
    SoundVolume = 255.0;
    SoundRadius = 600.0;

    if (!bDisintegrateVehicle)
    {
        ExplosionCount++;

        if (Level.NetMode != NM_DedicatedServer)
        {
            ClientVehicleExplosion(false);
        }

        LinearImpulse = PercentMomentum * RandRange(DestructionLinearMomentum.Min, DestructionLinearMomentum.Max) * MomentumNormal;
        AngularImpulse = PercentMomentum * RandRange(DestructionAngularMomentum.Min, DestructionAngularMomentum.Max) * VRand();

        NetUpdateTime = Level.TimeSeconds - 1.0;
        KAddImpulse(LinearImpulse, vect(0.0, 0.0, 0.0));
        KAddAngularImpulse(AngularImpulse);
    }
}

function Died(Controller Killer, class<DamageType> DamageType, vector HitLocation)
{
    super.Died(Killer, DamageType, HitLocation);

    if (Killer == none)
    {
        return;
    }

    DarkestHourGame(Level.Game).ScoreVehicleKill(Killer, self, PointValue);
}

function ServerChangeDriverPosition(byte F)
{
    if (IsInState('ViewTransition'))
    {
        return;
    }

    if (F >= FirstPassengerWeaponPawnIndex && bMustBeUnbuttonedToBecomePassenger && DriverPositionIndex >= UnbuttonedPositionIndex)
    {
        Instigator.ReceiveLocalizedMessage(class'DH_VehicleMessage', 4); // "You must unbutton the hatch to exit"

        return;
    }

    super.ServerChangeDriverPosition(F);
}

// Modified to optimise & to avoid accessed none errors
simulated function UpdateTurretReferences()
{
    local int i;

    for (i = 0; i < WeaponPawns.Length; i++)
    {
        if (WeaponPawns[i] != none && WeaponPawns[i].Gun != none)
        {
            if (CannonTurret == none && WeaponPawns[i].Gun.IsA('ROTankCannon'))
            {
                CannonTurret = ROTankCannon(WeaponPawns[i].Gun);
            }
            else if (HullMG == none && WeaponPawns[i].Gun.IsA('ROMountedTankMG'))
            {
                HullMG = WeaponPawns[i].Gun;
            }

            if (CannonTurret != none && HullMG != none)
            {
                break;
            }
        }
    }
}

// Modified to add WeaponPawns != none check to avoid "accessed none" errors, now rider pawns won't exist on client unless occupied
simulated function int NumPassengers()
{
    local  int  i, num;

    if (Driver != none)
    {
        num = 1;
    }

    for (i = 0; i < WeaponPawns.Length; i++)
    {
        if (WeaponPawns[i] != none && WeaponPawns[i].Driver != none)
        {
            num++;
        }
    }

    return num;
}

// Matt: added as when player is in a vehicle, the HUD keybinds to GrowHUD & ShrinkHUD will now call these same named functions in the vehicle classes
// When player is in a vehicle, these functions do nothing to the HUD, but they can be used to add useful vehicle functionality in subclasses, especially as keys are -/+ by default
simulated function GrowHUD();
simulated function ShrinkHUD();

// Matt: modified to switch to external mesh & default FOV for behind view
simulated function POVChanged(PlayerController PC, bool bBehindViewChanged)
{
    local int i;

    if (PC.bBehindView)
    {
        if (bBehindViewChanged)
        {
            if (bPCRelativeFPRotation)
            {
                PC.SetRotation(rotator(vector(PC.Rotation) >> Rotation));
            }

            for (i = 0; i < DriverPositions.Length; i++)
            {
                DriverPositions[i].PositionMesh = default.Mesh;
                DriverPositions[i].ViewFOV = PC.DefaultFOV;
            }

            bDontUsePositionMesh = true;

            if ((Role == ROLE_AutonomousProxy || Level.Netmode == NM_Standalone || Level.Netmode == NM_ListenServer) && DriverPositions[DriverPositionIndex].PositionMesh != none)
            {
                LinkMesh(DriverPositions[DriverPositionIndex].PositionMesh);
            }

            PC.SetFOV(DriverPositions[DriverPositionIndex].ViewFOV);

            bLimitYaw = false;
            bLimitPitch = false;
        }

        bOwnerNoSee = false;

        if (Driver != none)
        {
            Driver.bOwnerNoSee = !bDrawDriverInTP;
        }

        if (PC == Controller) // no overlays for spectators
        {
            ActivateOverlay(false);
        }
    }
    else
    {
        if (bPCRelativeFPRotation)
        {
            PC.SetRotation(rotator(vector(PC.Rotation) << Rotation));
        }

        if (bBehindViewChanged)
        {
            for (i = 0; i < DriverPositions.Length; i++)
            {
                DriverPositions[i].PositionMesh = default.DriverPositions[i].PositionMesh;
                DriverPositions[i].ViewFOV = default.DriverPositions[i].ViewFOV;
            }

            bDontUsePositionMesh = default.bDontUsePositionMesh;

            if ((Role == ROLE_AutonomousProxy || Level.Netmode == NM_Standalone || Level.Netmode == NM_ListenServer) && DriverPositions[DriverPositionIndex].PositionMesh != none)
            {
                LinkMesh(DriverPositions[DriverPositionIndex].PositionMesh);
            }

            PC.SetFOV(DriverPositions[DriverPositionIndex].ViewFOV);

            bLimitYaw = default.bLimitYaw;
            bLimitPitch = default.bLimitPitch;
        }

        bOwnerNoSee = !bDrawMeshInFP;

        if (Driver != none)
        {
            Driver.bOwnerNoSee = Driver.default.bOwnerNoSee;
        }

        if (bDriving && PC == Controller) // no overlays for spectators
        {
            ActivateOverlay(true);
        }
    }
}

// Matt: toggles between external & internal meshes (mostly useful with behind view if want to see internal mesh)
exec function ToggleMesh()
{
    local int i;

    if ((Level.NetMode == NM_Standalone || class'DH_LevelInfo'.static.DHDebugMode()) && bMultiPosition)
    {
        if (Mesh == default.DriverPositions[DriverPositionIndex].PositionMesh)
        {
            for (i = 0; i < DriverPositions.Length; i++)
            {
                DriverPositions[i].PositionMesh = default.Mesh;
            }
        }
        else
        {
            for (i = 0; i < DriverPositions.Length; i++)
            {
                DriverPositions[i].PositionMesh = default.DriverPositions[i].PositionMesh;
            }
        }

        LinkMesh(DriverPositions[DriverPositionIndex].PositionMesh);
    }
}

// Matt: DH version but keeping it just to view limits & nothing to do with behind view (which is handled by exec functions BehindView & ToggleBehindView)
exec function ToggleViewLimit()
{
    if (class'DH_LevelInfo'.static.DHDebugMode()) // removed requirement to be in single player mode, as valid in multi-player if in DHDebugMode
    {
        if (bLimitYaw == default.bLimitYaw && bLimitPitch == default.bLimitPitch)
        {
            bLimitYaw = false;
            bLimitPitch = false;
        }
        else
        {
            bLimitYaw = default.bLimitYaw;
            bLimitPitch = default.bLimitPitch;
        }
    }
}

// Matt: allows debugging exit positions to be toggled for all DH_ROTreadCrafts
exec function ToggleDebugExits()
{
    if (class'DH_LevelInfo'.static.DHDebugMode())
    {
        ServerToggleDebugExits();
    }
}

function ServerToggleDebugExits()
{
    if (class'DH_LevelInfo'.static.DHDebugMode())
    {
        class'DH_ROTreadCraft'.default.bDebugExitPositions = !class'DH_ROTreadCraft'.default.bDebugExitPositions;
        Log("DH_ROTreadCraft.bDebugExitPositions =" @ class'DH_ROTreadCraft'.default.bDebugExitPositions);
    }
}

simulated function DrawHUD(Canvas Canvas)
{
    local PlayerController PC;
    local Actor            ViewActor;
    local vector           CameraLocation;
    local rotator          CameraRotation;
    local float            SavedOpacity; // to keep players from seeing outside the periscope overlay

    if (IsLocallyControlled() && ActiveWeapon < Weapons.Length && Weapons[ActiveWeapon] != none && Weapons[ActiveWeapon].bShowAimCrosshair && Weapons[ActiveWeapon].bCorrectAim)
    {
        Canvas.DrawColor = CrosshairColor;
        Canvas.DrawColor.A = 255;
        Canvas.Style = ERenderStyle.STY_Alpha;

        Canvas.SetPos(Canvas.SizeX * 0.5 - CrosshairX, Canvas.SizeY * 0.5 - CrosshairY);
        Canvas.DrawTile(CrosshairTexture, CrosshairX * 2.0 + 1.0, CrosshairY * 2.0 + 1.0, 0.0, 0.0, CrosshairTexture.USize, CrosshairTexture.VSize);
    }

    PC = PlayerController(Controller);

    if (PC == none)
    {
        super.RenderOverlays(Canvas);

        return;
    }
    else if (!PC.bBehindView)
    {
        SavedOpacity = Canvas.ColorModulate.W;
        Canvas.ColorModulate.W = 1.0;

        if (DriverPositions[DriverPositionIndex].bDrawOverlays && HUDOverlay == none && DriverPositionIndex == 0 && !IsInState('ViewTransition'))
        {
            DrawPeriscopeOverlay(Canvas);
        }

        Canvas.ColorModulate.W = SavedOpacity; // reset HudOpacity to original value
        DrawVehicle(Canvas);
        DrawPassengers(Canvas);
    }

    if (!PC.bBehindView && HUDOverlay != none && DriverPositions[DriverPositionIndex].bDrawOverlays)
    {
        if (!Level.IsSoftwareRendering())
        {
            CameraRotation = PC.Rotation;
            SpecialCalcFirstPersonView(PC, ViewActor, CameraLocation, CameraRotation);
            HUDOverlay.SetLocation(CameraLocation + (HUDOverlayOffset >> CameraRotation));
            HUDOverlay.SetRotation(CameraRotation);
            Canvas.DrawActor(HUDOverlay, false, true, FClamp(HUDOverlayFOV * (PC.DesiredFOV / PC.DefaultFOV), 1.0, 170.0));
        }
    }
    else
    {
        ActivateOverlay(false);
    }
}

simulated function DrawPeriscopeOverlay(Canvas Canvas)
{
    local float ScreenRatio;

    ScreenRatio = Float(Canvas.SizeY) / Float(Canvas.SizeX);
    Canvas.SetPos(0.0, 0.0);
    Canvas.DrawTile(PeriscopeOverlay, Canvas.SizeX, Canvas.SizeY, 0.0 , (1.0 - ScreenRatio) * Float(PeriscopeOverlay.VSize) / 2.0, PeriscopeOverlay.USize, Float(PeriscopeOverlay.VSize) * ScreenRatio);
}

// Overridden to eliminate "Waiting for Additional Crewmembers" message
function bool CheckForCrew()
{
    return true;
}

defaultproperties
{
    bEnterringUnlocks=false
    bAllowRiders=true
    UnbuttonedPositionIndex=2
    DamagedTreadPanner=texture'DH_VehiclesGE_tex2.ext_vehicles.Alpha'
    LeftTreadIndex=1
    RightTreadIndex=2
    MaxCriticalSpeed=700.0
    AmmoIgnitionProbability=0.75
    TreadDamageThreshold=0.50
    DriverKillChance=1150.0
    GunnerKillChance=1150.0
    CommanderKillChance=950.0
    OpticsDamageChance=3000.0
    GunDamageChance=1250.0
    TraverseDamageChance=2000.0
    TurretDetonationThreshold=1750.0
    FireAttachBone="driver_player"
    FireEffectOffset=(Z=-10.0)
    EngineFireChance=0.50
    EngineFireHEATChance=0.85
    HullFireChance=0.25
    HullFireHEATChance=0.50
    VehicleBurningDamType=class'DH_VehicleBurningDamType'
    PlayerFireDamagePerSec=15.0
    bFirstHit=true
    FireDetonationChance=0.07
    EngineToHullFireChance=0.05
    PeriscopeOverlay=texture'DH_VehicleOptics_tex.Allied.PERISCOPE_overlay_Allied'
    DamagedPeriscopeOverlay=texture'DH_VehicleOptics_tex.Allied.Destroyed'
    VehicleBurningSound=sound'Amb_Destruction.Fire.Krasnyi_Fire_House02'
    DestroyedBurningSound=sound'Amb_Destruction.Fire.Kessel_Fire_Small_Barrel'
    DamagedStartUpSound=sound'DH_AlliedVehicleSounds2.Damaged.engine_start_damaged'
    DamagedShutDownSound=sound'DH_AlliedVehicleSounds2.Damaged.engine_stop_damaged'
    SmokingEngineSound=sound'Amb_Constructions.steam.Krasnyi_Steam_Deep'
    FireEffectClass=class'ROEngine.VehicleDamagedEffect'
    bEngineOff=true
    DriverTraceDistSquared=20250000.0 // Matt: increased from 4500 as made variable into a squared value (VSizeSquared is more efficient than VSize)
    GunMantletArmorFactor=10.0
    GunMantletSlope=10.0
    WaitForCrewTime=7.0
    ChassisTorqueScale=0.9
    ChangeUpPoint=2050.0
    ChangeDownPoint=1100.0
    ViewShakeRadius=50.0
    ViewShakeOffsetMag=(X=0.0,Z=0.0)
    ViewShakeOffsetFreq=0.0
    ExplosionSoundRadius=1000.0
    ExplosionDamage=575.0
    ExplosionRadius=900.0
    DamagedEffectHealthSmokeFactor=0.85
    DamagedEffectHealthMediumSmokeFactor=0.65
    DamagedEffectHealthHeavySmokeFactor=0.35
    DamagedEffectHealthFireFactor=0.0
    TimeTilDissapear=90.0
    IdleTimeBeforeReset=200.0
    VehicleSpikeTime=60.0
    EngineHealth=300
    bMustBeUnbuttonedToBecomePassenger=true
    FirstPassengerWeaponPawnIndex=255
    LeftTreadPanDirection=(Pitch=0,Yaw=0,Roll=16384)
    RightTreadPanDirection=(Pitch=0,Yaw=0,Roll=16384)
}
