//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2015
//==============================================================================

class DHTankCannonPawn extends ROTankCannonPawn
    abstract;

// General
var     DHTankCannon    Cannon;               // just a reference to the DH cannon actor, for convenience & to avoid lots of casts
var     texture         AltAmmoReloadTexture; // used to show coaxial MG reload progress on the HUD, like the cannon reload

// Position stuff
var     int         InitialPositionIndex;     // initial commander position on entering
var     int         UnbuttonedPositionIndex;  // lowest position number where player is unbuttoned
var()   int         PeriscopePositionIndex;
var     int         GunsightPositions;        // the number of gunsight positions - 1 for normal optics or 2 for dual-magnification optics
var()   bool        bPlayerCollisionBoxMoves; // commander's collision box moves with animations (e.g. raised/lowered on unbuttoning/buttoning), so we need to play anims on server

// Gunsight or periscope overlay
var     bool        bShowRangeRing;       // show range ring (used in German tank sights)
var     bool        bShowRangeText;       // show current range setting text
var     TexRotator  ScopeCenterRotator;
var()   float       ScopeCenterScale;
var()   int         CenterRotationFactor;
var()   float       OverlayCenterSize;    // size of the gunsight overlay, 1.0 means full screen width, 0.5 means half screen width
var     float       OverlayCenterScale;
var     float       OverlayCenterTexStart;
var     float       OverlayCenterTexSize;
var()   float       OverlayCorrectionX;   // scope center correction in pixels, in case an overlay is off-center by pixel or two
var()   float       OverlayCorrectionY;
var()   texture     PeriscopeOverlay;

// Damage modelling stuff
var     bool        bTurretRingDamaged;
var     bool        bGunPivotDamaged;
var     bool        bOpticsDamaged;
var     texture     DestroyedScopeOverlay;

// Manual & powered turret movement
var     bool        bManualTraverseOnly;
var     sound       ManualRotateSound;
var     sound       ManualPitchSound;
var     sound       ManualRotateAndPitchSound;
var     sound       PoweredRotateSound;
var     sound       PoweredPitchSound;
var     sound       PoweredRotateAndPitchSound;
var     float       ManualMinRotateThreshold;
var     float       ManualMaxRotateThreshold;
var     float       PoweredMinRotateThreshold;
var     float       PoweredMaxRotateThreshold;

// NEW DH CODE: Illuminated sights
//var   texture     NormalCannonScopeOverlay;
//var   texture     LitCannonScopeOverlay; // a ClientLightOverlay() server-to-client function was planned
//var   bool        bOpticsLit;
//var   bool        bHasLightedOptics;

// Debugging help
var()   bool        bShowCenter;    // shows centering cross in tank sight for testing purposes
var     bool        bDebuggingText; // on screen messages if damage prevents turret or gun from moving properly
var     bool        bDebugExitPositions;

replication
{
    // Variables the server will replicate to all clients
    reliable if (bNetDirty && Role == ROLE_Authority)
        bTurretRingDamaged, bGunPivotDamaged;
//      UnbuttonedPositionIndex;      // Matt: removed as never changes & doesn't need to be replicated
//      bOpticsDamaged; // bOpticsLit // Matt: removed as not even used clientside

    // Functions a client can call on the server
    reliable if (Role < ROLE_Authority)
        ServerChangeDriverPos, ServerToggleDebugExits, ServerToggleDriverDebug;
//      ServerToggleExtraRoundType // Matt: removed as is pointless - the normal RO ServerToggleRoundType can be called; it's only the functionality in Gun.ToggleRoundType() that changes
//      DamageCannonOverlay        // Matt: removed as isn't called by client

    // Functions the server can call on the client that owns this actor
    reliable if (Role == ROLE_Authority)
        ClientDamageCannonOverlay;
}

// Modified to calculate & set CannonScopeOverlay variables once instead of every DrawHUD
simulated function PostBeginPlay()
{
    super.PostBeginPlay();

    if (Level.NetMode != NM_DedicatedServer && CannonScopeOverlay != none)
    {
        OverlayCenterScale = 0.955 / OverlayCenterSize; // 0.955 factor widens visible FOV to full screen width = OverlaySize 1.0
        OverlayCenterTexStart = (1.0 - OverlayCenterScale) * Float(CannonScopeOverlay.USize) / 2.0;
        OverlayCenterTexSize =  Float(CannonScopeOverlay.USize) * OverlayCenterScale;
    }
}

// Modified to use new, simplified system with exit positions for all vehicle positions included in the vehicle class default properties
function bool PlaceExitingDriver()
{
    local int    i, StartIndex;
    local vector Extent, HitLocation, HitNormal, ZOffset, ExitPosition;

    if (Driver == none)
    {
        return false;
    }

    Extent = Driver.default.CollisionRadius * vect(1.0, 1.0, 0.0);
    Extent.Z = Driver.default.CollisionHeight;
    ZOffset = Driver.default.CollisionHeight * vect(0.0, 0.0, 0.5);

    if (VehicleBase == none)
    {
        return false;
    }

    // Debug exits - uses abstract class default, allowing bDebugExitPositions to be toggled for all MG pawns
    if (class'DHTankCannonPawn'.default.bDebugExitPositions)
    {
        for (i = 0; i < VehicleBase.ExitPositions.Length; ++i)
        {
            ExitPosition = VehicleBase.Location + (VehicleBase.ExitPositions[i] >> VehicleBase.Rotation) + ZOffset;

            Spawn(class'DH_DebugTracer',,, ExitPosition);
        }
    }

    i = Clamp(PositionInArray + 1, 0, VehicleBase.ExitPositions.Length - 1);
    StartIndex = i;

    while (i >= 0 && i < VehicleBase.ExitPositions.Length)
    {
        ExitPosition = VehicleBase.Location + (VehicleBase.ExitPositions[i] >> VehicleBase.Rotation) + ZOffset;

        if (Trace(HitLocation, HitNormal, ExitPosition, VehicleBase.Location + ZOffset, false, Extent) == none &&
            Trace(HitLocation, HitNormal, ExitPosition, ExitPosition + ZOffset, false, Extent) == none &&
            Driver.SetLocation(ExitPosition))
        {
            return true;
        }

        ++i;

        if (i == StartIndex)
        {
            break;
        }
        else if (i == VehicleBase.ExitPositions.Length)
        {
            i = 0;
        }
    }

    return false;
}

// Matt: modified to call InitializeCannon when we've received both the replicated Gun & VehicleBase actors (just after vehicle spawns via replication), which has 2 benefits:
// 1. Do things that need one or both of those actor refs, controlling common problem of unpredictability of timing of receiving replicated actor references
// 2. To do any extra set up in the cannon classes, which can easily be subclassed for anything that is vehicle specific
simulated function PostNetReceive()
{
    local int i;

    // Player has changed position // Matt: TODO - add fix for driver position problems upon replication
    if (DriverPositionIndex != SavedPositionIndex && Gun != none && bMultiPosition)
    {
        if (Driver == none && DriverPositionIndex > 0 && !IsLocallyControlled() && Level.NetMode == NM_Client)
        {
            // do nothing
        }
        else
        {
            LastPositionIndex = SavedPositionIndex;
            SavedPositionIndex = DriverPositionIndex;
            NextViewPoint();
        }
    }

    // Initialize the cannon (added VehicleBase != none, so we guarantee that VB is available to InitializeCannon)
    if (!bInitializedVehicleGun && Gun != none && VehicleBase != none)
    {
        bInitializedVehicleGun = true;
        InitializeCannon();
    }

    // Initialize the vehicle base
    if (!bInitializedVehicleBase && VehicleBase != none)
    {
        bInitializedVehicleBase = true;

        // On client, this actor is destroyed if becomes net irrelevant - when it respawns, empty WeaponPawns array needs filling again or will cause lots of errors
        if (VehicleBase.WeaponPawns.Length > 0 && VehicleBase.WeaponPawns.Length > PositionInArray &&
            (VehicleBase.WeaponPawns[PositionInArray] == none || VehicleBase.WeaponPawns[PositionInArray].default.Class == none))
        {
            VehicleBase.WeaponPawns[PositionInArray] = self;

            return;
        }

        for (i = 0; i < VehicleBase.WeaponPawns.Length; ++i)
        {
            if (VehicleBase.WeaponPawns[i] != none && (VehicleBase.WeaponPawns[i] == self || VehicleBase.WeaponPawns[i].Class == class))
            {
                return;
            }
        }

        VehicleBase.WeaponPawns[PositionInArray] = self;
    }
}

// Modified to call InitializeCannon to do any extra set up in the cannon classes
// This is where we do it for standalones or servers (note we can't do it in PostNetBeginPlay because VehicleBase isn't set until this function is called)
function AttachToVehicle(ROVehicle VehiclePawn, name WeaponBone)
{
    super.AttachToVehicle(VehiclePawn, WeaponBone);

    if (Role == ROLE_Authority)
    {
        InitializeCannon();
    }
}

// Matt: new function to do any extra set up in the cannon classes (called from PostNetReceive on net client or from AttachToVehicle on standalone or server)
// Crucially, we know that we have VehicleBase & Gun when this function gets called, so we can reliably do stuff that needs those actors
// Using it to reliably initialize the manual/powered turret settings when vehicle spawns, knowing we'll have relevant actors
simulated function InitializeCannon()
{
    Cannon = DHTankCannon(Gun);

    if (Cannon != none)
    {
        Cannon.InitializeCannon(self);
    }
    else
    {
        Warn("ERROR:" @ Tag @ "somehow spawned without an owned DHTankCannon, so lots of things are not going to work!");
    }

    if (DHTreadCraft(VehicleBase) != none)
    {
        SetManualTurret(DHTreadCraft(VehicleBase).bEngineOff);
    }
    else
    {
        SetManualTurret(true);
    }
}

// New function to toggle between manual/powered turret settings - called from PostNetReceive on vehicle clients, instead of constantly checking in Tick()
simulated function SetManualTurret(bool bManual)
{
    if (bManual || bManualTraverseOnly)
    {
        RotateSound = ManualRotateSound;
        PitchSound = ManualPitchSound;
        RotateAndPitchSound = ManualRotateAndPitchSound;
        MinRotateThreshold = ManualMinRotateThreshold;
        MaxRotateThreshold = ManualMaxRotateThreshold;

        if (Cannon != none)
        {
            Cannon.RotationsPerSecond = Cannon.ManualRotationsPerSecond;
        }
    }
    else
    {
        RotateSound = PoweredRotateSound;
        PitchSound = PoweredPitchSound;
        RotateAndPitchSound = PoweredRotateAndPitchSound;
        MinRotateThreshold = PoweredMinRotateThreshold;
        MaxRotateThreshold = PoweredMaxRotateThreshold;

        if (Cannon != none)
        {
            Cannon.RotationsPerSecond = Cannon.PoweredRotationsPerSecond;
        }
    }
}

// New function to damage gunsight optics
function DamageCannonOverlay()
{
    ClientDamageCannonOverlay();
    bOpticsDamaged = true;
}

simulated function ClientDamageCannonOverlay()
{
    CannonScopeOverlay = DestroyedScopeOverlay;
}

// Modified to allow turret traverse or elevation seizure if turret ring or pivot are damaged
function HandleTurretRotation(float DeltaTime, float YawChange, float PitchChange)
{
    if (bTurretRingDamaged)
    {
        if (bGunPivotDamaged)
        {
            if (bDebuggingText && Role == ROLE_Authority)
            {
                Level.Game.Broadcast(self, "Gun & turret disabled");
            }

            super.HandleTurretRotation(DeltaTime, 0.0, 0.0);
        }
        else
        {
            if (bDebuggingText && Role == ROLE_Authority)
            {
                Level.Game.Broadcast(self, "Turret disabled");
            }

            super.HandleTurretRotation(DeltaTime, 0.0, PitchChange);
        }
    }
    else if (bGunPivotDamaged)
    {
        if (bDebuggingText && Role == ROLE_Authority)
        {
            Level.Game.Broadcast(self, "Gun pivot disabled");
        }

        super.HandleTurretRotation(DeltaTime, YawChange, 0.0);
    }
    else // no damage
    {
        super.HandleTurretRotation(DeltaTime, YawChange, PitchChange);
    }
}

// Modified so the player's view rotation turns with the turret, if the vehicle has one
// Also to handle dual-magnification optics (DPI < GunsightPositions), & to apply FPCamPos to all positions not just overlay positions
simulated function SpecialCalcFirstPersonView(PlayerController PC, out actor ViewActor, out vector CameraLocation, out rotator CameraRotation)
{
    local vector  x, y, z, VehicleZ, CamViewOffsetWorld;
    local float   CamViewOffsetZAmount;
    local coords  CamBoneCoords;
    local rotator WeaponAimRot, ViewRelativeRotation;
    local quat    AQuat, BQuat, CQuat;

    GetAxes(CameraRotation, x, y, z);
    ViewActor = self;

    WeaponAimRot = rotator(vector(Gun.CurrentAim) >> Gun.Rotation);
    WeaponAimRot.Roll =  VehicleBase.Rotation.Roll;

    if (ROPlayer(Controller) != none)
    {
        ROPlayer(Controller).WeaponBufferRotation.Yaw = WeaponAimRot.Yaw;
        ROPlayer(Controller).WeaponBufferRotation.Pitch = WeaponAimRot.Pitch;
    }

    // This makes the camera stick to the cannon, but you have no control
    if (DriverPositionIndex < GunsightPositions)
    {
        CameraRotation = WeaponAimRot;
        CameraRotation.Roll = 0; // make the cannon view have no roll
    }
    else if (bPCRelativeFPRotation)
    {
        ViewRelativeRotation = PC.Rotation;

        // If the vehicle has a turret, add turret's yaw to player's relative rotation, so player's view turns with the turret
        if (Cannon.bHasTurret)
        {
            ViewRelativeRotation.Yaw += Cannon.CurrentAim.Yaw;
        }

        // Rotate the headbob by the player's view rotation (looking around)
        AQuat = QuatFromRotator(ViewRelativeRotation);
        BQuat = QuatFromRotator(HeadRotationOffset - ShiftHalf);
        CQuat = QuatProduct(AQuat, BQuat);

        // Then, rotate that by the vehicles rotation to get the final rotation
        AQuat = QuatFromRotator(VehicleBase.Rotation);
        BQuat = QuatProduct(CQuat, AQuat);

        // Finally, make it back into a rotator
        CameraRotation = QuatToRotator(BQuat);
    }
    else
    {
        CameraRotation = PC.Rotation;
    }

    if (IsInState('ViewTransition') && bLockCameraDuringTransition)
    {
        CameraRotation = Gun.GetBoneRotation('Camera_com');
    }

    CamViewOffsetWorld = FPCamViewOffset >> CameraRotation;

    if (CameraBone != '' && Gun != none)
    {
        CamBoneCoords = Gun.GetBoneCoords(CameraBone);

        if (DriverPositions[DriverPositionIndex].bDrawOverlays && DriverPositionIndex < GunsightPositions && !IsInState('ViewTransition'))
        {
            CameraLocation = CamBoneCoords.Origin + (FPCamPos >> WeaponAimRot) + CamViewOffsetWorld;
        }
        else
        {
            CameraLocation = Gun.GetBoneCoords('Camera_com').Origin + (FPCamPos >> WeaponAimRot) + CamViewOffsetWorld;
        }

        if (bFPNoZFromCameraPitch)
        {
            VehicleZ = vect(0.0, 0.0, 1.0) >> WeaponAimRot;
            CamViewOffsetZAmount = CamViewOffsetWorld dot VehicleZ;
            CameraLocation -= CamViewOffsetZAmount * VehicleZ;
        }
    }
    else
    {
        CameraLocation = GetCameraLocationStart() + (FPCamPos >> Rotation) + CamViewOffsetWorld;

        if (bFPNoZFromCameraPitch)
        {
            VehicleZ = vect(0.0, 0.0, 1.0) >> Rotation;
            CamViewOffsetZAmount = CamViewOffsetWorld dot VehicleZ;
            CameraLocation -= CamViewOffsetZAmount * VehicleZ;
        }
    }

    CameraRotation = Normalize(CameraRotation + PC.ShakeRot);
    CameraLocation = CameraLocation + PC.ShakeOffset.X * x + PC.ShakeOffset.Y * y + PC.ShakeOffset.Z * z;
}

// Modified to simply draw the BinocsOverlay, without additional drawing
simulated function DrawBinocsOverlay(Canvas Canvas)
{
    local float ScreenRatio;

    ScreenRatio = Float(Canvas.SizeY) / Float(Canvas.SizeX);
    Canvas.SetPos(0.0, 0.0);
    Canvas.DrawTile(BinocsOverlay, Canvas.SizeX, Canvas.SizeY, 0.0, (1.0 - ScreenRatio) * Float(BinocsOverlay.VSize) / 2.0, BinocsOverlay.USize, Float(BinocsOverlay.VSize) * ScreenRatio);
}

// Modified to remove obsolete stuff & duplication from the Supers, & to use the vehicle's VehicleTeam to determine the team
function bool TryToDrive(Pawn P)
{
    if (VehicleBase != none && P != none)
    {
        // Trying to enter a vehicle that isn't on our team
        if (P.GetTeamNum() != VehicleBase.VehicleTeam) // VehicleTeam reliably gives the team, even if vehicle hasn't yet been entered
        {
            if (VehicleBase.Driver == none)
            {
                return VehicleBase.TryToDrive(P);
            }

            DenyEntry(P, 1); // can't use enemy vehicle

            return false;
        }

        // Bot tries to enter the VehicleBase if it has no driver
        if (VehicleBase.Driver == none && !P.IsHumanControlled())
        {
            return VehicleBase.TryToDrive(P);
        }
    }

    return super(Vehicle).TryToDrive(P); // the Supers in ROVehicleWeaponPawn & VehicleWeaponPawn contain lots of duplication
}

// Recalls that optics are still non-functioning when players jump in and out
function KDriverEnter(Pawn P)
{
    super.KDriverEnter(P);

    if (bOpticsDamaged)
    {
        ClientDamageCannonOverlay();
    }
}

// Modified to handle InitialPositionIndex instead of assuming start in position zero
// Also so cannon retains its aimed direction when player enters & may switch to internal mesh // Matt: TEST
simulated state EnteringVehicle
{
    simulated function HandleEnter()
    {
        SwitchMesh(InitialPositionIndex);

        if (Gun != none && Gun.HasAnim(Gun.BeginningIdleAnim))
        {
            Gun.PlayAnim(Gun.BeginningIdleAnim); // shouldn't actually be necessary, but a reasonable fail-safe
        }

        WeaponFOV = DriverPositions[InitialPositionIndex].ViewFOV;
        PlayerController(Controller).SetFOV(WeaponFOV);

        FPCamPos = DriverPositions[InitialPositionIndex].ViewLocation;
    }
}

// Modified to handle InitialPositionIndex instead of assuming start in position zero, & to consolidate & optimise the Supers
simulated function ClientKDriverEnter(PlayerController PC)
{
    if (bMultiPosition)
    {
        Gotostate('EnteringVehicle');
        PendingPositionIndex = InitialPositionIndex;
        ServerChangeDriverPos();
    }
    else
    {
        PC.SetFOV(WeaponFOV);
    }

    StoredVehicleRotation = VehicleBase.Rotation; // Matt: I don't think this is used anywhere & will probably remove from all functions later

    super(Vehicle).ClientKDriverEnter(PC);
}

function ServerChangeDriverPos()
{
    DriverPositionIndex = InitialPositionIndex;
}

// Modified to prevent players exiting unless unbuttoned
// Also to reset to InitialPositionIndex instead of zero & so that exit stuff only happens if the Super returns true
function bool KDriverLeave(bool bForceLeave)
{
    if (!bForceLeave && !CanExit()) // bForceLeave means so player is trying to exit not just switch position, so no risk of locking someone in one slot
    {
        return false;
    }

    if (super(VehicleWeaponPawn).KDriverLeave(bForceLeave))
    {
        DriverPositionIndex = InitialPositionIndex;
        LastPositionIndex = InitialPositionIndex;

        VehicleBase.MaybeDestroyVehicle();

        return true;
    }

    return false;
}

// Modified to reset to InitialPositionIndex instead of zero & to call DriverLeft() because player death doesn't trigger KDriverLeave/DriverLeft/DrivingStatusChanged
function DriverDied()
{
    DriverPositionIndex = InitialPositionIndex;

    super(Vehicle).DriverDied(); // need to skip over Super in ROVehicleWeaponPawn (& Super in VehicleWeaponPawn adds nothing)

    VehicleBase.MaybeDestroyVehicle();

    if (VehicleBase.Health > 0)
    {
        SetRotatingStatus(0); // kill the rotation sound if the driver dies but the vehicle doesn't
    }

    DriverLeft(); // fix Unreal bug (as done in ROVehicle), as DriverDied should call DriverLeft, the same as KDriverLeave does
}

// Modified to avoid wasting network resources by calling ServerChangeViewPoint on the server when it isn't valid
simulated function NextWeapon()
{
    if (DriverPositionIndex < DriverPositions.Length - 1 && DriverPositionIndex == PendingPositionIndex && !IsInState('ViewTransition') && bMultiPosition)
    {
        PendingPositionIndex = DriverPositionIndex + 1;
        ServerChangeViewPoint(true);
    }
}

simulated function PrevWeapon()
{
    if (DriverPositionIndex > 0 && DriverPositionIndex == PendingPositionIndex && !IsInState('ViewTransition') && bMultiPosition)
    {
        PendingPositionIndex = DriverPositionIndex -1;
        ServerChangeViewPoint(false);
    }
}

// Modified so server goes to state ViewTransition when unbuttoning, preventing player exiting until fully unbuttoned
// Server also plays down animation when buttoning up, if player has moving collision box
function ServerChangeViewPoint(bool bForward)
{
    if (bForward)
    {
        if (DriverPositionIndex < (DriverPositions.Length - 1))
        {
            LastPositionIndex = DriverPositionIndex;
            DriverPositionIndex++;

            if (Level.NetMode == NM_Standalone  || Level.NetMode == NM_ListenServer)
            {
                NextViewPoint();
            }
            else if (Level.NetMode == NM_DedicatedServer)
            {
                if (DriverPositionIndex == UnbuttonedPositionIndex)
                {
                    GoToState('ViewTransition');
                }
                else if (bPlayerCollisionBoxMoves)
                {
                    AnimateTransition();
                }
            }
        }
    }
    else
    {
        if (DriverPositionIndex > 0)
        {
            LastPositionIndex = DriverPositionIndex;
            DriverPositionIndex--;

            if (Level.NetMode == NM_Standalone || Level.NetMode == NM_ListenServer)
            {
                NextViewPoint();
            }
            else if (bPlayerCollisionBoxMoves && Level.NetMode == NM_DedicatedServer) // only if player has moving collision box
            {
                AnimateTransition();
            }
        }
    }
}

// Modified so when player comes up off the gunsight, they stay facing forward, in the direction of the cannon
simulated state ViewTransition
{
    simulated function HandleTransition()
    {
        // Added so when player moves up from gunsight, view rotation is neutralised so he stays facing same direction as cannon (feels more natural to come up from the gun)
        // Note an owning net client will update rotation back to server
        if (LastPositionIndex < GunsightPositions && DriverPositionIndex >= GunsightPositions)
        {
            if (bPCRelativeFPRotation)
            {
                SetRotation(rot(0, 0, 0));
            }
            else
            {
                SetRotation(VehicleBase.Rotation);
            }
        }

        StoredVehicleRotation = VehicleBase.Rotation;

        SwitchMesh(DriverPositionIndex);

        if (Driver != none && Driver.HasAnim(DriverPositions[DriverPositionIndex].DriverTransitionAnim) && Driver.HasAnim(DriverPositions[LastPositionIndex].DriverTransitionAnim))
        {
            Driver.PlayAnim(DriverPositions[DriverPositionIndex].DriverTransitionAnim);
        }

        WeaponFOV = DriverPositions[DriverPositionIndex].ViewFOV;

        FPCamPos = DriverPositions[DriverPositionIndex].ViewLocation;

        if (DriverPositionIndex != 0)
        {
            if (DriverPositions[DriverPositionIndex].bDrawOverlays)
            {
                PlayerController(Controller).SetFOV(WeaponFOV);
            }
            else
            {
                PlayerController(Controller).DesiredFOV = WeaponFOV;
            }
        }

        if (LastPositionIndex < DriverPositionIndex)
        {
            if (Gun.HasAnim(DriverPositions[LastPositionIndex].TransitionUpAnim))
            {
                Gun.PlayAnim(DriverPositions[LastPositionIndex].TransitionUpAnim);
                SetTimer(Gun.GetAnimDuration(DriverPositions[LastPositionIndex].TransitionUpAnim, 1.0), false);
            }
            else
            {
                GotoState('');
            }
        }
        else if (Gun.HasAnim(DriverPositions[LastPositionIndex].TransitionDownAnim))
        {
            Gun.PlayAnim(DriverPositions[LastPositionIndex].TransitionDownAnim);
            SetTimer(Gun.GetAnimDuration(DriverPositions[LastPositionIndex].TransitionDownAnim, 1.0), false);
        }
        else
        {
            GotoState('');
        }
    }

    simulated function Timer()
    {
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
        }
    }

Begin:
    HandleTransition();
    Sleep(0.2);
}

// Modified so mesh rotation is matched in all net modes, not just standalone as in the RO original (not sure why they did that)
// Also to remove playing BeginningIdleAnim as that now gets done for all net modes in DrivingStatusChanged()
simulated state LeavingVehicle
{
    simulated function HandleExit()
    {
        SwitchMesh(-1); // -1 signifies switch to default external mesh
    }
}

// Modified to play idle animation for all net players, so they see closed hatches & any animated collision boxes are re-set (also server if collision is animated)
simulated event DrivingStatusChanged()
{
    super.DrivingStatusChanged();

    if (!bDriving && (Level.NetMode != NM_DedicatedServer || bPlayerCollisionBoxMoves) && Gun != none && Gun.HasAnim(Gun.BeginningIdleAnim))
    {
        Gun.PlayAnim(Gun.BeginningIdleAnim);
    }
}

// New function, checked by Fire() so we prevent firing while moving between view points or when on periscope or binoculars
function bool CanFire()
{
    return (!IsInState('ViewTransition') && DriverPositionIndex != PeriscopePositionIndex && DriverPositionIndex != BinocPositionIndex) || ROPlayer(Controller) == none;
}

// Modified to use CanFire() & to skip over obsolete RO functionality in ROTankCannonPawn & optimise what remains
function Fire(optional float F)
{
    if (!CanFire())
    {
        return;
    }

    if (Cannon != none)
    {
        if (Cannon.CannonReloadState != CR_ReadyToFire || !Cannon.bClientCanFireCannon)
        {
            if (Cannon.CannonReloadState == CR_Waiting && ROPlayer(Controller) != none && ROPlayer(Controller).bManualTankShellReloading)
            {
                Cannon.ServerManualReload();
            }

            return;
        }
    }

    super(VehicleWeaponPawn).Fire(F);
}

// Modified to check CanFire(), to skip over obsolete RO functionality in ROTankCannonPawn, & to add dry-fire sound if trying to fire empty MG
function AltFire(optional float F)
{
    if (!bHasAltFire || !CanFire() || Gun == none)
    {
        return;
    }

    if (Gun.ReadyToFire(true))
    {
        VehicleFire(true);
        bWeaponIsAltFiring = true;

        if (!bWeaponIsFiring && PlayerController(Controller) != none)
        {
            Gun.ClientStartFire(Controller, true);
        }
    }
    else if (Gun.FireCountdown <= Gun.AltFireInterval) // means that coaxial MG isn't reloading (or at least has virtually completed its reload)
    {
        PlaySound(Cannon.NoMGAmmoSound, SLOT_None, 1.5, , 25.0, , true);
    }
}

// Modified to add clientside checks before sending the function call to the server
simulated function SwitchWeapon(byte F)
{
    local ROVehicleWeaponPawn WeaponPawn;
    local bool                bMustBeTankerToSwitch;
    local byte                ChosenWeaponPawnIndex;

    if (VehicleBase == none)
    {
        return;
    }

    // Trying to switch to driver position
    if (F == 1)
    {
        // Stop call to server as there is already a human driver
        if (VehicleBase.Driver != none && VehicleBase.Driver.IsHumanControlled())
        {
            return;
        }

        if (VehicleBase.bMustBeTankCommander)
        {
            bMustBeTankerToSwitch = true;
        }
    }
    // Trying to switch to non-driver position
    else
    {
        ChosenWeaponPawnIndex = F - 2;

        // Stop call to server if player has selected an invalid weapon position or the current position
        // Note that if player presses 0, which is invalid choice, the byte index will end up as 254 & so will still fail this test (which is what we want)
        if (ChosenWeaponPawnIndex >= VehicleBase.PassengerWeapons.Length || ChosenWeaponPawnIndex == PositionInArray)
        {
            return;
        }

        // Stop call to server if player selected a rider position but is buttoned up (no 'teleporting' outside to external rider position)
        if (StopExitToRiderPosition(ChosenWeaponPawnIndex))
        {
            return;
        }

        // Get weapon pawn
        if (ChosenWeaponPawnIndex < VehicleBase.WeaponPawns.Length)
        {
            WeaponPawn = ROVehicleWeaponPawn(VehicleBase.WeaponPawns[ChosenWeaponPawnIndex]);
        }

        if (WeaponPawn != none)
        {
            // Stop call to server as weapon position already has a human player
            if (WeaponPawn.Driver != none && WeaponPawn.Driver.IsHumanControlled())
            {
                return;
            }

            if (WeaponPawn.bMustBeTankCrew)
            {
                bMustBeTankerToSwitch = true;
            }
        }
        // Stop call to server if weapon pawn doesn't exist, UNLESS PassengerWeapons array lists it as a rider position
        // This is because our new system means rider pawns won't exist on clients unless occupied, so we have to allow this switch through to server
        else if (class<ROPassengerPawn>(VehicleBase.PassengerWeapons[ChosenWeaponPawnIndex].WeaponPawnClass) == none)
        {
            return;
        }
    }

    // Stop call to server if player has selected a tank crew role but isn't a tanker
    if (bMustBeTankerToSwitch && (Controller == none || ROPlayerReplicationInfo(Controller.PlayerReplicationInfo) == none ||
        ROPlayerReplicationInfo(Controller.PlayerReplicationInfo).RoleInfo == none || !ROPlayerReplicationInfo(Controller.PlayerReplicationInfo).RoleInfo.bCanBeTankCrew))
    {
        DenyEntry(self, 0); // not qualified to operate vehicle

        return;
    }

    ServerChangeDriverPosition(F);
}

// Modified to prevent 'teleporting' outside to external rider position while buttoned up inside vehicle
function ServerChangeDriverPosition(byte F)
{
    if (StopExitToRiderPosition(F - 2)) // driver (1) becomes -1, which for byte becomes 255
    {
        return;
    }

    super.ServerChangeDriverPosition(F);
}

// New function to check if player can exit, displaying an "unbutton hatch" message if he can't (just saves repeating code in different functions)
simulated function bool CanExit()
{
    if (DriverPositionIndex < UnbuttonedPositionIndex || (IsInState('ViewTransition') && DriverPositionIndex == UnbuttonedPositionIndex))
    {
        ReceiveLocalizedMessage(class'DH_VehicleMessage', 4); // must unbutton the hatch

        return false;
    }

    return true;
}

// New function to check if player is trying to 'teleport' outside to external rider position while buttoned up (just saves repeating code in different functions)
simulated function bool StopExitToRiderPosition(byte ChosenWeaponPawnIndex)
{
    local DHTreadCraft TreadCraft;

    TreadCraft = DHTreadCraft(VehicleBase);

    return TreadCraft != none && TreadCraft.bMustUnbuttonToSwitchToRider && TreadCraft.bAllowRiders &&
        ChosenWeaponPawnIndex >= TreadCraft.FirstRiderPositionIndex && ChosenWeaponPawnIndex < TreadCraft.PassengerWeapons.Length && !CanExit();
}

// New function to handle switching between external & internal mesh, including copying cannon's aimed direction to new mesh (just saves code repetition)
simulated function SwitchMesh(int PositionIndex)
{
    local mesh    NewMesh;
    local rotator TurretYaw, TurretPitch;

    if ((Role == ROLE_AutonomousProxy || Level.NetMode == NM_Standalone || Level.NetMode == NM_ListenServer) && Gun != none)
    {
        // If switching to a valid driver position, get its PositionMesh
        if (PositionIndex >= 0 && PositionIndex < DriverPositions.Length)
        {
            if (DriverPositions[PositionIndex].PositionMesh != none)
            {
                NewMesh = DriverPositions[PositionIndex].PositionMesh;
            }
        }
        // Else switch to default external mesh (pass PositionIndex of -1 to signify this, as it's an invalid position)
        else
        {
            NewMesh = Gun.default.Mesh;
        }

        // Only switch mesh if we actually have a different new mesh
        if (NewMesh != Gun.Mesh && NewMesh != none)
        {
            if (bCustomAiming)
            {
                // Save old mesh rotation
                TurretYaw.Yaw = VehicleBase.Rotation.Yaw - CustomAim.Yaw;
                TurretPitch.Pitch = VehicleBase.Rotation.Pitch - CustomAim.Pitch;

                // Switch to the new mesh
                Gun.LinkMesh(NewMesh);

                // Now make the new mesh you swap to have the same rotation as the old one
                Gun.SetBoneRotation(Gun.YawBone, TurretYaw);
                Gun.SetBoneRotation(Gun.PitchBone, TurretPitch);
            }
            else
            {
                Gun.LinkMesh(NewMesh);
            }
        }
    }
}

// Modified so if PC's rotation was relative to vehicle (bPCRelativeFPRotation), it gets set to the correct non-relative rotation on exit, including turret rotation
// Doing this in a more obvious way here avoids the previous workaround in ClientKDriverLeave, which matched the cannon pawn's rotation to the vehicle
simulated function FixPCRotation(PlayerController PC)
{
    local rotator ViewRelativeRotation;

    ViewRelativeRotation = PC.Rotation;

    // If the vehicle has a turret, add turret's yaw to player's relative rotation
    if (Cannon.bHasTurret)
    {
        ViewRelativeRotation.Yaw += Cannon.CurrentAim.Yaw;
    }

    PC.SetRotation(rotator(vector(ViewRelativeRotation) >> VehicleBase.Rotation));
}

// Re-stated here just to make into simulated functions, so modified LeanLeft & LeanRight exec functions in DHPlayer can call this on the client as a pre-check
simulated function IncrementRange()
{
    if (Gun != none)
    {
        Gun.IncrementRange();
    }
}

simulated function DecrementRange()
{
    if (Gun != none)
    {
        Gun.DecrementRange();
    }
}

// Modified to use new ResupplyAmmo() in the VehicleWeapon classes, instead of GiveInitialAmmo()
function bool ResupplyAmmo()
{
    return Cannon != none && Cannon.ResupplyAmmo();
}

// New function, used by HUD to show coaxial MG reload progress, like the cannon reload
function float GetAltAmmoReloadState()
{
    local float ProportionOfReloadRemaining;

    if (Gun == none)
    {
        return 1.0;
    }
    else if (Gun.FireCountdown <= Gun.AltFireInterval)
    {
        return 0.0;
    }
    else
    {
        if (Cannon == none)
        {
            return 1.0;
        }

        ProportionOfReloadRemaining = Gun.FireCountdown / GetSoundDuration(Cannon.ReloadSound);

        if (ProportionOfReloadRemaining >= 0.75)
        {
            return 1.0;
        }
        else if (ProportionOfReloadRemaining >= 0.5)
        {
            return 0.65;
        }
        else if (ProportionOfReloadRemaining >= 0.25)
        {
            return 0.45;
        }
        else
        {
            return 0.25;
        }
    }
}

// Modified to remove irrelevant stuff about driver weapon crosshair & to optimise
simulated function DrawHUD(Canvas Canvas)
{
    local PlayerController PC;
    local vector           CameraLocation;
    local rotator          CameraRotation;
    local Actor            ViewActor;
    local float            SavedOpacity, posx, posy, ScreenRatio, XL, YL, MapX, MapY;
    local int              RotationFactor;
    local color            SavedColor, WhiteColor;

    PC = PlayerController(Controller);

    if (PC != none && !PC.bBehindView)
    {
        // Player is in a position where an overlay should be drawn
        if (DriverPositions[DriverPositionIndex].bDrawOverlays && (!IsInState('ViewTransition') || DriverPositions[LastPositionIndex].bDrawOverlays))
        {
            if (HUDOverlay == none)
            {
                // Save current HUD opacity & then set up for drawing overlays
                SavedOpacity = Canvas.ColorModulate.W;
                Canvas.ColorModulate.W = 1.0;
                Canvas.DrawColor.A = 255;
                Canvas.Style = ERenderStyle.STY_Alpha;

                // Draw gunsights
                if (DriverPositionIndex < GunsightPositions)
                {
                    // Debug - draw cross on the center of the screen
                    if (bShowCenter)
                    {
                        posx = Canvas.SizeX / 2.0;
                        posy = Canvas.SizeY / 2.0;
                        Canvas.SetPos(0.0, 0.0);
                        Canvas.DrawVertical(posx - 1.0, posy - 3.0);
                        Canvas.DrawVertical(posx, posy - 3.0);
                        Canvas.SetPos(0.0, posy + 3.0);
                        Canvas.DrawVertical(posx - 1.0, posy - 3.0);
                        Canvas.DrawVertical(posx, posy - 3.0);
                        Canvas.SetPos(0.0, 0.0);
                        Canvas.DrawHorizontal(posy - 1.0, posx - 3.0);
                        Canvas.DrawHorizontal(posy, posx - 3.0);
                        Canvas.SetPos(posx + 3.0, 0.0);
                        Canvas.DrawHorizontal(posy - 1.0, posx - 3.0);
                        Canvas.DrawHorizontal(posy, posx - 3.0);
                    }

                    // Draw the gunsight overlays
                    if (CannonScopeOverlay != none)
                    {
                        ScreenRatio = float(Canvas.SizeY) / float(Canvas.SizeX);
                        Canvas.SetPos(0.0, 0.0);

                        Canvas.DrawTile(CannonScopeOverlay, Canvas.SizeX, Canvas.SizeY, OverlayCenterTexStart - OverlayCorrectionX,
                            OverlayCenterTexStart - OverlayCorrectionY + (1.0 - ScreenRatio) * OverlayCenterTexSize / 2.0, OverlayCenterTexSize, OverlayCenterTexSize * ScreenRatio);
                    }

                    if (CannonScopeCenter != none)
                    {
                        if (Gun != none && Gun.ProjectileClass != none)
                        {
                            Canvas.SetPos(0.0, Gun.ProjectileClass.static.GetYAdjustForRange(Gun.GetRange()) * Canvas.ClipY);
                        }
                        else
                        {
                            Canvas.SetPos(ScopePositionX * Canvas.ClipY / ScreenRatio / OverlayCenterScale - (Canvas.ClipX / OverlayCenterScale - Canvas.ClipX) / 2.0,
                                ScopePositionY * Canvas.ClipY / ScreenRatio / OverlayCenterScale - Canvas.ClipY * (1.0 / ScreenRatio / OverlayCenterScale - 1.0) / 2.0);
                        }

                        Canvas.DrawTile(CannonScopeCenter, Canvas.SizeX, Canvas.SizeY, OverlayCenterTexStart - OverlayCorrectionX,
                            OverlayCenterTexStart - OverlayCorrectionY + (1.0 - ScreenRatio) * OverlayCenterTexSize / 2.0, OverlayCenterTexSize, OverlayCenterTexSize * ScreenRatio);
                    }

                    Canvas.SetPos(0.0, Gun.ProjectileClass.static.GetYAdjustForRange(Gun.GetRange()) * Canvas.ClipY);

                    if (bShowRangeRing && Gun != none)
                    {
                        // Draw the range ring
                        posx = (float(Canvas.SizeX) - float(Canvas.SizeY) * 4.0 / OverlayCenterScale / 3.0) / 2.0;
                        posy = (float(Canvas.SizeY) - float(Canvas.SizeY) * 4.0 / OverlayCenterScale / 3.0) / 2.0;

                        Canvas.SetPos(OverlayCorrectionX + Posx + (Canvas.SizeY * (1.0 - ScopeCenterScale) * 4.0 / OverlayCenterScale / 3.0 / 2.0),
                            OverlayCorrectionY + Canvas.SizeY * (1.0 - ScopeCenterScale * 4.0 / OverlayCenterScale / 3.0) / 2.0);

                        if (Gun.CurrentRangeIndex < 20)
                        {
                           RotationFactor = Gun.CurrentRangeIndex * CenterRotationFactor;
                        }
                        else
                        {
                           RotationFactor = (CenterRotationFactor * 20) + (((Gun.CurrentRangeIndex - 20) * 2) * CenterRotationFactor);
                        }

                        ScopeCenterRotator.Rotation.Yaw = RotationFactor;

                        Canvas.DrawTileScaled(ScopeCenterRotator, Canvas.SizeY / 512.0 * ScopeCenterScale * 4.0 / OverlayCenterScale / 3.0,
                            Canvas.SizeY / 512.0 * ScopeCenterScale * 4.0 / OverlayCenterScale / 3.0);
                    }

                    // Draw the range setting
                    if (bShowRangeText && Gun != none)
                    {
                        Canvas.Style = ERenderStyle.STY_Normal;
                        SavedColor = Canvas.DrawColor;
                        WhiteColor = class'Canvas'.static.MakeColor(255, 255, 255, 175);
                        Canvas.DrawColor = WhiteColor;
                        MapX = RangePositionX * Canvas.ClipX;
                        MapY = RangePositionY * Canvas.ClipY;
                        Canvas.SetPos(MapX, MapY);
                        Canvas.Font = class'ROHUD'.static.GetSmallMenuFont(Canvas);
                        Canvas.StrLen(Gun.GetRange() @ RangeText, XL, YL);
                        Canvas.DrawTextJustified(Gun.GetRange() @ RangeText, 2, MapX, MapY, MapX + XL, MapY + YL);
                        Canvas.DrawColor = SavedColor;
                    }
                }
                // Draw periscope overlay
                else if (DriverPositionIndex == PeriscopePositionIndex)
                {
                    DrawPeriscopeOverlay(Canvas);
                }
                // Draw binoculars overlay
                else if (DriverPositionIndex == BinocPositionIndex)
                {
                    DrawBinocsOverlay(Canvas);
                }

                Canvas.ColorModulate.W = SavedOpacity; // reset HUD opacity to original value
            }
            // Draw any HUD overlay
            else if (!Level.IsSoftwareRendering())
            {
                CameraRotation = PC.Rotation;
                SpecialCalcFirstPersonView(PC, ViewActor, CameraLocation, CameraRotation);
                HUDOverlay.SetLocation(CameraLocation + (HUDOverlayOffset >> CameraRotation));
                HUDOverlay.SetRotation(CameraRotation);
                Canvas.DrawActor(HUDOverlay, false, false, FClamp(HUDOverlayFOV * (PC.DesiredFOV / PC.DefaultFOV), 1.0, 170.0));
            }
        }

        // Draw vehicle, turret, ammo count, passenger list
        if (ROHud(PC.myHUD) != none && VehicleBase != none)
        {
            ROHud(PC.myHUD).DrawVehicleIcon(Canvas, VehicleBase, self);
        }
    }
    else if (HUDOverlay != none)
    {
        ActivateOverlay(false);
    }
}

simulated function DrawPeriscopeOverlay(Canvas Canvas)
{
    local float ScreenRatio;

    ScreenRatio = float(Canvas.SizeY) / float(Canvas.SizeX);
    Canvas.SetPos(0.0, 0.0);

    Canvas.DrawTile(PeriscopeOverlay, Canvas.SizeX, Canvas.SizeY, 0.0, (1.0 - ScreenRatio) * float(PeriscopeOverlay.VSize) / 2.0,
        PeriscopeOverlay.USize, float(PeriscopeOverlay.VSize) * ScreenRatio);
}

// Modified to call same function on VehicleWeapon class so it pre-caches its Skins array (the RO class missed calling the Super to do that), & also to add extra material properties
static function StaticPrecache(LevelInfo L)
{
    L.AddPrecacheMaterial(default.CannonScopeOverlay);
    L.AddPrecacheMaterial(default.CannonScopeCenter);
    L.AddPrecacheMaterial(default.BinocsOverlay);
    L.AddPrecacheMaterial(default.AmmoShellTexture);
    L.AddPrecacheMaterial(default.AmmoShellReloadTexture);
    L.AddPrecacheMaterial(default.AltAmmoReloadTexture);

    default.GunClass.static.StaticPrecache(L);
}

// Modified to add extra material properties
simulated function UpdatePrecacheMaterials()
{
    Level.AddPrecacheMaterial(default.CannonScopeOverlay);
    Level.AddPrecacheMaterial(default.CannonScopeCenter);
    Level.AddPrecacheMaterial(default.BinocsOverlay);
    Level.AddPrecacheMaterial(default.AmmoShellTexture);
    Level.AddPrecacheMaterial(default.AmmoShellReloadTexture);
    Level.AddPrecacheMaterial(default.AltAmmoReloadTexture);
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
                PC.SetRotation(rotator(vector(PC.Rotation) >> Gun.Rotation));
            }

            if (bMultiPosition)
            {
                for (i = 0; i < DriverPositions.Length; ++i)
                {
                    DriverPositions[i].PositionMesh = Gun.default.Mesh;
                    DriverPositions[i].ViewFOV = PC.DefaultFOV;
                    DriverPositions[i].ViewPitchUpLimit = 65535;
                    DriverPositions[i].ViewPitchDownLimit = 1;
                }

                SwitchMesh(DriverPositionIndex);

                PC.SetFOV(DriverPositions[DriverPositionIndex].ViewFOV);
            }
            else
            {
                PC.SetFOV(PC.DefaultFOV);
                Gun.PitchUpLimit = 65535;
                Gun.PitchDownLimit = 1;
            }

            Gun.bLimitYaw = false;
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
            PC.SetRotation(rotator(vector(PC.Rotation) << Gun.Rotation));
        }

        if (bBehindViewChanged)
        {
            if (bMultiPosition)
            {
                for (i = 0; i < DriverPositions.Length; ++i)
                {
                    DriverPositions[i].PositionMesh = default.DriverPositions[i].PositionMesh;
                    DriverPositions[i].ViewFOV = default.DriverPositions[i].ViewFOV;
                    DriverPositions[i].ViewPitchUpLimit = default.DriverPositions[i].ViewPitchUpLimit;
                    DriverPositions[i].ViewPitchDownLimit = default.DriverPositions[i].ViewPitchDownLimit;
                }

                SwitchMesh(DriverPositionIndex);

                PC.SetFOV(DriverPositions[DriverPositionIndex].ViewFOV);
                FPCamPos = DriverPositions[DriverPositionIndex].ViewLocation;
            }
            else
            {
                PC.SetFOV(WeaponFOV);
                Gun.PitchUpLimit = Gun.default.PitchUpLimit;
                Gun.PitchDownLimit = Gun.default.PitchDownLimit;
            }

            Gun.bLimitYaw = Gun.default.bLimitYaw;
        }

        bOwnerNoSee = !bDrawMeshInFP;

        if (Driver != none)
        {
            Driver.bOwnerNoSee = Driver.default.bOwnerNoSee;
        }

        if (bDriving && PC == Controller)
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
        if (Gun.Mesh == default.DriverPositions[DriverPositionIndex].PositionMesh)
        {
            for (i = 0; i < DriverPositions.Length; ++i)
            {
                DriverPositions[i].PositionMesh = Gun.default.Mesh;
            }
        }
        else
        {
            for (i = 0; i < DriverPositions.Length; ++i)
            {
                DriverPositions[i].PositionMesh = default.DriverPositions[i].PositionMesh;
            }
        }

        SwitchMesh(DriverPositionIndex);
    }
}

// Matt: DH version but keeping it just to view limits & nothing to do with behind view (which is handled by exec functions BehindView & ToggleBehindView)
exec function ToggleViewLimit()
{
    local int i;

    if (class'DH_LevelInfo'.static.DHDebugMode() && Gun != none) // removed requirement to be in single player mode, as valid in multi-player if in DHDebugMode
    {
        if (Gun.bLimitYaw == Gun.default.bLimitYaw && Gun.PitchUpLimit == Gun.default.PitchUpLimit && Gun.PitchDownLimit == Gun.default.PitchDownLimit)
        {
            Gun.bLimitYaw = false;
            Gun.PitchUpLimit = 65535;
            Gun.PitchDownLimit = 1;

            for (i = 0; i < DriverPositions.Length; ++i)
            {
                DriverPositions[i].ViewPitchUpLimit = 65535;
                DriverPositions[i].ViewPitchDownLimit = 1;
            }
        }
        else
        {
            Gun.bLimitYaw = Gun.default.bLimitYaw;
            Gun.PitchUpLimit = Gun.default.PitchUpLimit;
            Gun.PitchDownLimit = Gun.default.PitchDownLimit;

            for (i = 0; i < DriverPositions.Length; ++i)
            {
                DriverPositions[i].ViewPitchUpLimit = default.DriverPositions[i].ViewPitchUpLimit;
                DriverPositions[i].ViewPitchDownLimit = default.DriverPositions[i].ViewPitchDownLimit;
            }
        }
    }
}

// Allows 'Driver' (commander) debugging to be toggled for all cannon pawns
exec function ToggleDriverDebug()
{
    if (class'DH_LevelInfo'.static.DHDebugMode())
    {
        ServerToggleDriverDebug();
    }
}

function ServerToggleDriverDebug()
{
    if (class'DH_LevelInfo'.static.DHDebugMode())
    {
        class'DHTankCannon'.default.bDriverDebugging = !class'DHTankCannon'.default.bDriverDebugging;
        Log("DHTankCannon.bDriverDebugging =" @ class'DHTankCannon'.default.bDriverDebugging);
    }
}

// Allows debugging exit positions to be toggled for all cannon pawns
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
        class'DHTankCannonPawn'.default.bDebugExitPositions = !class'DHTankCannonPawn'.default.bDebugExitPositions;
        Log("DHTankCannonPawn.bDebugExitPositions =" @ class'DHTankCannonPawn'.default.bDebugExitPositions);
    }
}

defaultproperties
{
    bShowRangeText=true
    GunsightPositions=1
    UnbuttonedPositionIndex=2
    ManualRotateSound=sound'Vehicle_Weapons.Turret.manual_turret_traverse2'
    ManualPitchSound=sound'Vehicle_Weapons.Turret.manual_turret_elevate'
    ManualRotateAndPitchSound=sound'Vehicle_Weapons.Turret.manual_turret_traverse'
    ManualMinRotateThreshold=0.25
    ManualMaxRotateThreshold=2.5
    PoweredMinRotateThreshold=0.15
    PoweredMaxRotateThreshold=1.75
    MaxRotateThreshold=1.5
    bPCRelativeFPRotation=true
    bFPNoZFromCameraPitch=true
    bDesiredBehindView=false
    PeriscopePositionIndex=-1
    AltAmmoReloadTexture=texture'DH_InterfaceArt_tex.Tank_Hud.MG42_ammo_reload'
}