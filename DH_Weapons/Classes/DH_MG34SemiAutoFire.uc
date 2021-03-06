//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2016
//==============================================================================

class DH_MG34SemiAutoFire extends DHMGSingleFire;

defaultproperties
{
    PctHipMGPenalty=0.6
    ProjSpawnOffset=(X=25.0)
    FAProjSpawnOffset=(X=-20.0)
    bUsesTracers=true
    TracerFrequency=6
    TracerProjectileClass=class'DH_MG34TracerBullet'
    FireIronAnim="Shoot_Loop"
    FireIronLoopAnim="Bipod_shoot_single"
    FireIronEndAnim="Bipod_Shoot_End"
    FireSounds(0)=SoundGroup'Inf_Weapons.mg34.mg34_fire_single'
    MaxVerticalRecoilAngle=600
    MaxHorizontalRecoilAngle=250
    RecoilRate=0.04
    ShellEjectClass=class'ROAmmo.ShellEject1st762x54mm'
    ShellIronSightOffset=(X=25.0,Z=-10.0)
    ShellRotOffsetIron=(Pitch=0)
    FireAnim="Bipod_shoot_single"
    FireLoopAnim="Shoot_Loop"
    FireEndAnim="Shoot_End"
    TweenTime=0.0
    FireForce="RocketLauncherFire"
    FireRate=0.2
    AmmoClass=class'ROAmmo.MG50Rd792x57DrumAmmo'
    ShakeRotMag=(X=50.0,Y=50.0,Z=50.0)
    ShakeRotRate=(X=10000.0,Y=10000.0,Z=10000.0)
    ShakeRotTime=2.0
    ShakeOffsetMag=(X=3.0,Y=1.0,Z=3.0)
    ShakeOffsetRate=(X=1000.0,Y=1000.0,Z=1000.0)
    ShakeOffsetTime=2.0
    ProjectileClass=class'DH_Weapons.DH_MG34Bullet'
    BotRefireRate=0.5
    WarnTargetPct=0.9
    FlashEmitterClass=class'ROEffects.MuzzleFlash1stMG'
    SmokeEmitterClass=class'ROEffects.ROMuzzleSmoke'
    aimerror=1800.0
    Spread=125.0
    SpreadStyle=SS_Random
}
