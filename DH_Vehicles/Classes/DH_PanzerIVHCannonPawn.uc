//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2016
//==============================================================================

class DH_PanzerIVHCannonPawn extends DHGermanCannonPawn;

defaultproperties
{
    GunClass=class'DH_Vehicles.DH_PanzerIVHCannon'
    DriverPositions(0)=(ViewLocation=(X=12.0,Y=-27.0,Z=3.0),ViewFOV=28.8,PositionMesh=SkeletalMesh'DH_PanzerIV_anm.Panzer4H_turret_int',ViewPitchUpLimit=3641,ViewPitchDownLimit=64080,ViewPositiveYawLimit=19000,ViewNegativeYawLimit=-20000,bDrawOverlays=true)
    DriverPositions(1)=(ViewFOV=90.0,PositionMesh=SkeletalMesh'DH_PanzerIV_anm.Panzer4H_turret_int',TransitionUpAnim="com_open",DriverTransitionAnim="VKV1_com_close",ViewPitchUpLimit=4000,ViewPitchDownLimit=63500,ViewPositiveYawLimit=6000,ViewNegativeYawLimit=-10000)
    DriverPositions(2)=(ViewFOV=90.0,PositionMesh=SkeletalMesh'DH_PanzerIV_anm.Panzer4H_turret_int',TransitionDownAnim="com_close",DriverTransitionAnim="VKV1_com_open",ViewPitchUpLimit=5000,ViewPitchDownLimit=63500,ViewPositiveYawLimit=10000,ViewNegativeYawLimit=-10000,bExposed=true)
    DriverPositions(3)=(ViewFOV=12.0,PositionMesh=SkeletalMesh'DH_PanzerIV_anm.Panzer4H_turret_int',DriverTransitionAnim="stand_idleiron_binoc",ViewPitchUpLimit=5000,ViewPitchDownLimit=63500,ViewPositiveYawLimit=10000,ViewNegativeYawLimit=-10000,bDrawOverlays=true,bExposed=true)
    DrivePos=(X=-2.0,Y=0.0,Z=-6.0)
    DriveAnim="VKV1_com_idle_close"
    CannonScopeCenter=texture'DH_VehicleOptics_tex.German.PZ3_sight_graticule'
    OverlayCenterSize=0.87
    RangeRingScale=0.635
    RangeRingRotator=TexRotator'DH_VehicleOptics_tex.German.PZ4_sight_Center'
    RangeRingRotationFactor=985
    DestroyedGunsightOverlay=texture'DH_VehicleOpticsDestroyed_tex.German.PZ4_sight_destroyed'
    AmmoShellTexture=texture'InterfaceArt_tex.Tank_Hud.panzer4F2shell'
    AmmoShellReloadTexture=texture'InterfaceArt_tex.Tank_Hud.panzer4F2shell_reload'
    PoweredRotateSound=sound'Vehicle_Weapons.Turret.electric_turret_traverse'
    PoweredPitchSound=sound'Vehicle_Weapons.Turret.manual_turret_elevate'
    PoweredRotateAndPitchSound=sound'Vehicle_Weapons.Turret.electric_turret_traverse'
}
