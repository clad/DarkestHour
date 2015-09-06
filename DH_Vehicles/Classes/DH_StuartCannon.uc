//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2015
//==============================================================================

class DH_StuartCannon extends DHVehicleCannon;

defaultproperties
{
    InitialTertiaryAmmo=15
    TertiaryProjectileClass=class'DH_Engine.DHCannonShellCanister'
    TertiarySpread=0.04
    SecondarySpread=0.00145
    ManualRotationsPerSecond=0.04
    PoweredRotationsPerSecond=0.083
    FrontArmorFactor=5.1
    RightArmorFactor=3.2
    LeftArmorFactor=3.2
    RearArmorFactor=3.2
    FrontArmorSlope=10.0
    FrontLeftAngle=323.0
    FrontRightAngle=37.0
    RearRightAngle=143.0
    RearLeftAngle=217.0
    ReloadSoundOne=sound'DH_Vehicle_Reloads.Reloads.reload_01s_01'
    ReloadSoundTwo=sound'DH_Vehicle_Reloads.Reloads.reload_01s_02'
    ReloadSoundThree=sound'DH_Vehicle_Reloads.Reloads.reload_01s_03'
    ReloadSoundFour=sound'DH_Vehicle_Reloads.Reloads.reload_01s_04'
    CannonFireSound(0)=SoundGroup'Inf_Weapons.PTRD.PTRD_fire01'
    CannonFireSound(1)=SoundGroup'Inf_Weapons.PTRD.PTRD_fire02'
    CannonFireSound(2)=SoundGroup'Inf_Weapons.PTRD.PTRD_fire03'
    ProjectileDescriptions(0)="APCBC"
    ProjectileDescriptions(2)="Canister"
    AddedPitch=18
    ReloadSound=sound'Vehicle_reloads.Reloads.MG34_ReloadHidden'
    NumAltMags=6
    AltTracerProjectileClass=class'DH_Weapons.DH_30CalTracerBullet'
    AltFireTracerFrequency=5
    bUsesTracers=true
    bAltFireTracersOnly=true
    hudAltAmmoIcon=texture'InterfaceArt_tex.HUD.mg42_ammo'
    YawBone="Turret"
    PitchBone="Gun"
    PitchUpLimit=15000
    PitchDownLimit=45000
    WeaponFireAttachmentBone="Gun"
    GunnerAttachmentBone="com_attachment"
    WeaponFireOffset=85.0
    AltFireOffset=(X=26.0,Y=7.0,Z=1.0)
    bAmbientAltFireSound=true
    FireInterval=3.0
    AltFireInterval=0.12
    FireSoundVolume=512.0
    AltFireSoundClass=SoundGroup'DH_AlliedVehicleSounds2.3Cal.V30cal_loop01'
    AltFireSoundScaling=3.0
    AltFireEndSound=SoundGroup'DH_AlliedVehicleSounds2.3Cal.V30cal_end01'
    FireForce="Explosion05"
    ProjectileClass=class'DH_Vehicles.DH_StuartCannonShell'
    AltFireProjectileClass=class'DH_Weapons.DH_30CalBullet'
    ShakeRotMag=(Z=50.0)
    ShakeRotRate=(Z=600.0)
    ShakeRotTime=4.0
    ShakeOffsetMag=(Z=5.0)
    ShakeOffsetRate=(Z=100.0)
    ShakeOffsetTime=6.0
    AltShakeRotMag=(X=0.01,Y=0.01,Z=0.01)
    AltShakeRotRate=(X=1000.0,Y=1000.0,Z=1000.0)
    AltShakeRotTime=2.0
    AltShakeOffsetMag=(X=0.01,Y=0.01,Z=0.01)
    AltShakeOffsetRate=(X=1000.0,Y=1000.0,Z=1000.0)
    AltShakeOffsetTime=2.0
    AIInfo(0)=(bLeadTarget=true,WarnTargetPct=0.75,RefireRate=0.5)
    AIInfo(1)=(bLeadTarget=true,WarnTargetPct=0.75,RefireRate=0.015)
    CustomPitchUpLimit=3641
    CustomPitchDownLimit=63352
    BeginningIdleAnim="com_idle_close"
    InitialPrimaryAmmo=64
    InitialSecondaryAmmo=44
    InitialAltAmmo=250
    PrimaryProjectileClass=class'DH_Vehicles.DH_StuartCannonShell'
    SecondaryProjectileClass=class'DH_Vehicles.DH_StuartCannonShellHE'
    Mesh=SkeletalMesh'DH_Stuart_anm.Stuart_turret_ext'
    Skins(0)=texture'DH_VehiclesUS_tex.ext_vehicles.M5_body_ext'
    Skins(1)=texture'DH_VehiclesUS_tex.int_vehicles.M5_turret_int'
    CollisionStaticMesh=StaticMesh'DH_allies_vehicles_stc.M5_Stuart.Stuart_turret_col'
    SoundVolume=80
}
