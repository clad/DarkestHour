//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2015
//==============================================================================

class DHExitMovingVehicleDamageType extends DamageType
    abstract;

defaultproperties
{
    DeathString="%o broke his neck jumping from a speeding vehicle."
    FemaleSuicide="%o broke her neck jumping from a speeding vehicle."
    MaleSuicide="%o broke his neck jumping from a speeding vehicle."
    bLocationalHit=false
    bCausedByWorld=true
    GibModifier=0.0
}