//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2016
//==============================================================================

class DH_MG34Pickup extends DHWeaponPickup
    notplaceable;

defaultproperties
{
    InventoryType=class'DH_Weapons.DH_MG34Weapon'
    StaticMesh=StaticMesh'WeaponPickupSM.Weapons.mg34'
    PrePivot=(Z=3.0)
    CollisionRadius=25.0
    CollisionHeight=3.0
    BarrelSteamEmitterOffset=(X=10.0,Y=-20.0,Z=5.0)
}
