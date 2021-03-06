//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2016
//==============================================================================

class DH_USSmokeGrenadeWeapon extends DHExplosiveWeapon;

defaultproperties
{
    FireModeClass(0)=class'DH_Equipment.DH_USSmokeGrenadeFire'
    FireModeClass(1)=class'DH_Equipment.DH_USSmokeGrenadeTossFire'
    PickupClass=class'DH_Equipment.DH_USSmokeGrenadePickup'
    AttachmentClass=class'DH_Equipment.DH_USSmokeGrenadeAttachment'
    ItemName="M8 Smoke Grenade"
    Mesh=SkeletalMesh'DH_USSmokeGrenade_1st.smokegrenade'
    InventoryGroup=7
}
