//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2016
//==============================================================================

class DH_RedSmokeProjectile extends DHGrenadeProjectile_Smoke;

defaultproperties
{
    MyDamageType=class'DH_Equipment.DH_RedSmokeDamType'
    StaticMesh=StaticMesh'DH_WeaponPickups.Ammo.US_RedSmokeGrenade_throw'
    SmokeEmitterClass=class'DH_Effects.DHSmokeEffect_Red'
}
