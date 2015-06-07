//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2015
//==============================================================================

class DH_HigginsBoatMGPawn extends DH_M3A1HalftrackMGPawn;

var     texture     BinocsOverlay;
var     int         BinocsPositionIndex;

// Gunner cannot fire MG when he is in binocs
function bool CanFire()
{
    return DriverPositionIndex != BinocsPositionIndex;
}

// Modified to handle binoculars overlay
simulated function DrawHUD(Canvas Canvas)
{
    local PlayerController PC;
    local vector           CameraLocation, GunOffset;
    local rotator          CameraRotation;
    local Actor            ViewActor;
    local float            SavedOpacity;

    PC = PlayerController(Controller);

    if (PC != none && !PC.bBehindView)
    {
        // Draw vehicle, turret, ammo count, passenger list
        if (ROHud(PC.myHUD) != none && VehicleBase != none)
        {
            ROHud(PC.myHUD).DrawVehicleIcon(Canvas, VehicleBase, self);
        }

        // Draw binoculars overlay
        if (DriverPositionIndex == BinocsPositionIndex)
        {
            SavedOpacity = Canvas.ColorModulate.W; // save current HUD opacity & then remove opacity
            Canvas.ColorModulate.W = 1.0;
            Canvas.DrawColor.A = 255;
            Canvas.Style = ERenderStyle.STY_Alpha;

            DrawBinocsOverlay(Canvas);

            Canvas.ColorModulate.W = SavedOpacity; // reset HudOpacity to original value
        }
        // Draw HUD overlay (MG)
        else if (HUDOverlay != none && !Level.IsSoftwareRendering())
        {
            CameraRotation = PC.Rotation;
            SpecialCalcFirstPersonView(PC, ViewActor, CameraLocation, CameraRotation);
            CameraRotation = Normalize(CameraRotation + PC.ShakeRot);

            // Make the first person gun appear lower when your sticking your head up
            GunOffset += PC.ShakeOffset * FirstPersonGunShakeScale;
            GunOffset.Z += (((Gun.GetBoneCoords(FirstPersonGunRefBone).Origin.Z - CameraLocation.Z) * FirstPersonOffsetZScale));
            GunOffset += HUDOverlayOffset;

            HUDOverlay.SetLocation(CameraLocation + (HUDOverlayOffset >> CameraRotation));
            Canvas.DrawBoundActor(HUDOverlay, false, true, HUDOverlayFOV, CameraRotation, PC.ShakeRot * FirstPersonGunShakeScale, GunOffset * -1.0);
        }
    }
    else if (HUDOverlay != none)
    {
        ActivateOverlay(false);
    }
}

// New function, same as tank cannon pawn
simulated function DrawBinocsOverlay(Canvas Canvas)
{
    local float ScreenRatio;

    ScreenRatio = float(Canvas.SizeY) / float(Canvas.SizeX);
    Canvas.SetPos(0.0, 0.0);
    Canvas.DrawTile(BinocsOverlay, Canvas.SizeX, Canvas.SizeY, 0.0 , (1.0 - ScreenRatio) * float(BinocsOverlay.VSize) / 2.0, BinocsOverlay.USize, float(BinocsOverlay.VSize) * ScreenRatio);
}

defaultproperties
{
    BinocsOverlay=texture'DH_VehicleOptics_tex.Allied.BINOC_overlay_7x50Allied'
    BinocsPositionIndex=2
    DriverPositions(2)=(ViewFOV=12.0,PositionMesh=SkeletalMesh'DH_M3A1Halftrack_anm.m3halftrack_gun_int',ViewPitchUpLimit=5300,ViewPitchDownLimit=63000,ViewPositiveYawLimit=12000,ViewNegativeYawLimit=-12000,bDrawOverlays=true,bExposed=true)
}