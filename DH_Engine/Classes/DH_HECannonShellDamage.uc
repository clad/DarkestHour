//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2014
//==============================================================================

class DH_HECannonShellDamage extends ROTankShellExplosionDamage
      abstract;

defaultproperties
{
     TankDamageModifier=0.030000
     APCDamageModifier=1.000000
     VehicleDamageModifier=1.000000
     TreadDamageModifier=0.850000
     bArmorStops=true
     bLocationalHit=true
     KDeathVel=300.000000
     KDeathUpKick=60.000000
     KDeadLinZVelScale=0.002000
     KDeadAngVelScale=0.003000
     HumanObliterationThreshhold=265
}