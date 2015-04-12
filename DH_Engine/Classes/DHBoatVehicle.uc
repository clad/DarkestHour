//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2015
//==============================================================================

class DHBoatVehicle extends DHWheeledVehicle // Matt: originally extended ROWheeledVehicle
    abstract;

var()   name                DriverCameraBoneName;
var     vector              CameraBoneLocation;

var()   sound               WashSound;
var()   name                WashSoundBoneL;
var     ROSoundAttachment   WashSoundAttachL;
var()   name                WashSoundBoneR;
var     ROSoundAttachment   WashSoundAttachR;

var     Material            DestroyedVehicleTexture;
var     name                DestAnimName;
var     float               DestAnimRate;

// Modified to spawn wash sound attachments
simulated function PostBeginPlay()
{
    super.PostBeginPlay();

    if (Level.NetMode != NM_DedicatedServer)
    {
        if (WashSoundAttachL == none)
        {
            WashSoundAttachL = Spawn(class'ROSoundAttachment');
            WashSoundAttachL.AmbientSound = WashSound;
            WashSoundAttachL.SoundVolume = 75;
            WashSoundAttachL.SoundRadius = 300.0;
            AttachToBone(WashSoundAttachL, WashSoundBoneL);
        }

        if (WashSoundAttachR == none)
        {
            WashSoundAttachR = Spawn(class'ROSoundAttachment');
            WashSoundAttachR.AmbientSound = WashSound;
            WashSoundAttachR.SoundVolume = 75;
            WashSoundAttachR.SoundRadius = 300.0;
            AttachToBone(WashSoundAttachR, WashSoundBoneR);
        }
    }
}

// Skip over the Super in DHWheeledVehicle to avoid an engine hint
simulated function ClientKDriverEnter(PlayerController PC)
{
    super(ROWheeledVehicle).ClientKDriverEnter(PC);
}

// Overridden for locking the player to the camerabone // altered slightly to allow change of camera bone name - Fennich
simulated function SpecialCalcFirstPersonView(PlayerController PC, out Actor ViewActor, out vector CameraLocation, out rotator CameraRotation)
{
    local quat   CarQuat, LookQuat, ResultQuat;
    local vector VehicleZ, CamViewOffsetWorld, x, y, z;
    local float  CamViewOffsetZAmount;

    GetAxes(PC.Rotation, x, y, z);
    ViewActor = self;

    if (bPCRelativeFPRotation)
    {
        CarQuat = QuatFromRotator(Rotation);
        CameraRotation = Normalize(PC.Rotation);
        LookQuat = QuatFromRotator(CameraRotation);
        ResultQuat = QuatProduct(LookQuat, CarQuat);
        CameraRotation = QuatToRotator(ResultQuat);
    }
    else
    {
        CameraRotation = PC.Rotation;
    }

    // Camera position is locked to vehicle
    CamViewOffsetWorld = FPCamViewOffset >> CameraRotation;
    CameraBoneLocation = GetBoneCoords(DriverCameraBoneName).Origin;
    CameraLocation = CameraBoneLocation + (FPCamPos >> Rotation) + CamViewOffsetWorld;

    if (bFPNoZFromCameraPitch)
    {
        VehicleZ = vect(0.0, 0.0, 1.0) >> Rotation;
        CamViewOffsetZAmount = CamViewOffsetWorld dot VehicleZ;
        CameraLocation -= CamViewOffsetZAmount * VehicleZ;
    }

    CameraRotation = Normalize(CameraRotation + PC.ShakeRot);
    CameraLocation = CameraLocation + PC.ShakeOffset.X * x + PC.ShakeOffset.Y * y + PC.ShakeOffset.Z * z;
}

// Modified to include wash sound attachments
simulated function Destroyed()
{
    if (WashSoundAttachL != none)
    {
        WashSoundAttachL.Destroy();
    }

    if (WashSoundAttachR != none)
    {
        WashSoundAttachR.Destroy();
    }

    super.Destroyed();
}

// Modified to avoid switching to static mesh DestroyedVehicleMesh, instead switching the boat skin to a DestroyedVehicleTexture & playing a destroyed animation
simulated event DestroyAppearance()
{
    local int         i;
    local KarmaParams KP;

    bDestroyAppearance = true; // for replication

    // Put brakes on
    Throttle = 0.0;
    Steering = 0.0;
    Rise     = 0.0;

    // Destroy the vehicle weapons
    if (Role == ROLE_Authority)
    {
        for (i = 0; i < WeaponPawns.Length; ++i)
        {
            if (WeaponPawns[i] != none)
            {
                WeaponPawns[i].Destroy();
            }
        }
    }

    WeaponPawns.Length = 0;

    // Destroy the effects
    if (Level.NetMode != NM_DedicatedServer)
    {
        if (bEmittersOn)
        {
            StopEmitters();
        }

        if (DamagedEffect != none)
        {
            DamagedEffect.Kill();
        }
    }

    // Copy linear velocity from actor so it doesn't just stop
    KP = KarmaParams(KParams);

    if (KP != none)
    {
        KP.KStartLinVel = Velocity;
    }

    //Become the dead vehicle mesh // Matt: removed as in this case we aren't switching to a destroyed static mesh
//  SetPhysics(PHYS_None);
//  KSetBlockKarma(false);
//  SetDrawType(DT_Mesh);
//  KSetBlockKarma(true);
//  SetPhysics(PHYS_Karma);
//  Skins.Length = 1;
    NetPriority = 2.0;

    Skins[0] = DestroyedVehicleTexture;
    LoopAnim(DestAnimName, DestAnimRate);
}

defaultproperties
{
    EngineHealth=100 // reinstate default from ROWheeledVehicle
    ChangeUpPoint=1990.0
    ChangeDownPoint=1000.0
    SteerBoneName="steeringwheel"
    DustSlipRate=0.0
    DustSlipThresh=100000.0
    ViewShakeRadius=600.0
    ViewShakeOffsetMag=(X=0.5,Z=2.0)
    ViewShakeOffsetFreq=7.0
    DestructionEffectClass=class'ROEffects.ROVehicleDestroyedEmitter' // reinstate defaults x 3 from ROWheeledVehicle
    DisintegrationEffectClass=class'ROEffects.ROVehicleObliteratedEmitter'
    DisintegrationEffectLowClass=class'ROEffects.ROVehicleObliteratedEmitter_simple'
    DisintegrationHealth=-10000.0
    DestructionLinearMomentum=(Min=100.0,Max=350.0)
    DestructionAngularMomentum=(Max=150.0)
    ExplosionSoundRadius=800.0
    ExplosionDamage=300.0
    ExplosionRadius=600.0
    ImpactDamageThreshold=5000.0 // reinstate default from ROWheeledVehicle
    ImpactDamageMult=0.001
    TimeTilDissapear=15.0
    IdleTimeBeforeReset=30.0
    DriverTraceDistSquared=4000000.0 // Matt: default 2000 from ROWheeledVehicle, but squared for new DistSquared variable
    InitialPositionIndex=0
    VehicleSpikeTime=15.0
    VehHitpoints(0)=(PointBone="Driver")
    VehicleMass=12.0
    bKeyVehicle=true
    bFPNoZFromCameraPitch=true
    CenterSpringForce="SpringONSSRV"
    VehiclePositionString="in a Boat"
    StolenAnnouncement="Shiver me timbers - some buggers gone and nicked me boat'"
    MaxDesireability=0.1
    WaterDamage=0.0
    bCanSwim=true
    GroundSpeed=200.0
    WaterSpeed=200.0
    PitchUpLimit=500
    PitchDownLimit=58000
    bKeepDriverAuxCollision=false // reinstate default from ROWheeledVehicle
    CollisionRadius=300.0
    CollisionHeight=45.0
}