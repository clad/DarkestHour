//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2016
//==============================================================================

class DH_OrangeSmokeWeapon extends DHExplosiveWeapon;

function bool CanDeadThrow()
{
    return false;
}

simulated function BringUp(optional Weapon PrevWeapon)
{
    super.BringUp(PrevWeapon);

    if (Instigator != none && DHPlayer(Instigator.Controller) != none)
    {
        DHPlayer(Instigator.Controller).QueueHint(3, false);
    }
}

defaultproperties
{
    FireModeClass(0)=class'DH_Equipment.DH_OrangeSmokeFire'
    FireModeClass(1)=class'DH_Equipment.DH_OrangeSmokeTossFire'
    PickupClass=class'DH_Equipment.DH_OrangeSmokePickup'
    AttachmentClass=class'DH_Equipment.DH_OrangeSmokeAttachment'
    ItemName="RauchSichtzeichen Orange 160"
    Mesh=SkeletalMesh'DH_GermanSmokeGrenade_1st.OrangeSmokeGrenade'
    InventoryGroup=8
}
