//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2016
//==============================================================================

class DH_M1CarbineDamType extends DHWeaponProjectileDamageType
    abstract;

defaultproperties
{
    HUDIcon=texture'InterfaceArt_tex.deathicons.b792mm'
    WeaponClass=class'DH_Weapons.DH_M1CarbineWeapon'
    KDamageImpulse=1500.0
    KDeathVel=110.0
    KDeathUpKick=2.0
}
