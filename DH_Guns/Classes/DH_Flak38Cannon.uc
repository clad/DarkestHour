//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2015
//==============================================================================

class DH_Flak38Cannon extends DH_Sdkfz2341Cannon;

#exec OBJ LOAD FILE=..\Animations\DH_Flak38_anm.ukx

var  name  SightBone;

// Modified to play shoot open or closed firing animation based on DriverPositionIndex, as all DriverPositionsan are always bExposed in an AT gun
simulated function FlashMuzzleFlash(bool bWasAltFire)
{
    if (Role == ROLE_Authority)
    {
        FiringMode = byte(bWasAltFire);
        FlashCount++;
        NetUpdateTime = Level.TimeSeconds - 1.0;
    }
    else
    {
        CalcWeaponFire(bWasAltFire);
    }

    if (Level.NetMode != NM_DedicatedServer && !bWasAltFire)
    {
        if (FlashEmitter != none)
        {
            FlashEmitter.Trigger(self, Instigator);
        }

        if (CannonPawn != none && CannonPawn.DriverPositionIndex >= 2)
        {
            if (HasAnim(TankShootOpenAnim))
            {
                PlayAnim(TankShootOpenAnim);
            }
            else if (HasAnim(TankShootClosedAnim))
            {
                PlayAnim(TankShootClosedAnim);
            }
        }
    }
}

// New function to update sight rotation, called by cannon pawn when gun pitch changes
simulated function UpdateSightRotation()
{
    local rotator SightRotation;

    SightRotation.Pitch = -CurrentAim.Pitch;
    SetBoneRotation(SightBone, SightRotation, 1);
}

// Added the following functions from DHATGunCannon, as parent Sd.Kfz.234/1 armoured car cannon extends DH_ROTankCannon:
simulated function bool DHShouldPenetrate(DHAntiVehicleProjectile P, vector HitLocation, vector HitRotation, float PenetrationNumber)
{
   return true;
}

defaultproperties
{
    NumMags=12
    NumSecMags=4
    NumTertMags=4
    AddedPitch=50
    WeaponFireOffset=64.0
    RotationsPerSecond=0.05
    FireInterval=0.15
    FlashEmitterClass=class'DH_Guns.DH_Flak38MuzzleFlash'
    ProjectileClass=class'DH_Guns.DH_Flak38CannonShellMixed'
    AltFireProjectileClass=none
    CustomPitchUpLimit=15474
    CustomPitchDownLimit=64990
    InitialPrimaryAmmo=40
    InitialSecondaryAmmo=40
    InitialTertiaryAmmo=40
    PrimaryProjectileClass=class'DH_Guns.DH_Flak38CannonShellMixed'
    SecondaryProjectileClass=class'DH_Guns.DH_Flak38CannonShellAP'
    TertiaryProjectileClass=class'DH_Guns.DH_Flak38CannonShellHE'
    SightBone="arm"
    Mesh=SkeletalMesh'DH_Flak38_anm.Flak38_turret'
    Skins(0)=texture'DH_Artillery_tex.Flak38.Flak38_gun'
}
