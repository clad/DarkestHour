//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2015
//==============================================================================

class DH_TankCannonShellCanister extends DH_Bullet
    abstract;

defaultproperties
{
    WhizType=2
    MyVehicleDamage=class'DH_Engine.DH_CanisterShotVehDamType'
    BallisticCoefficient=4.0
    Speed=45988.0
    Damage=120.0
    MyDamageType=class'DH_Engine.DH_CanisterShotDamType'
}