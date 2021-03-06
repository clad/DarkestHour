//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2016
//==============================================================================

class DH_SdKfz251_22CannonPawn extends DH_Pak40CannonPawn;

// Modified to remove excess Pak40 AT gun exit positions
simulated function PostBeginPlay()
{
    super.PostBeginPlay();

    ExitPositions.Length = 2;
}

// Modified to skip over the Super in DHATGunCannonPawn, as that prevents any switching position
simulated function SwitchWeapon(byte F)
{
    super(DHVehicleCannonPawn).SwitchWeapon(F);
}

defaultproperties
{
    GunClass=class'DH_Guns.DH_SdKfz251_22Cannon'
    DriverPositions(1)=(DriverTransitionAnim="stand_idlehold_bayo",ViewPositiveYawLimit=2400,ViewNegativeYawLimit=-5100) // anim better positions the standing gunner in a vehicle
    DrivePos=(X=-11.0,Y=-1.0,Z=-57.0)
}
