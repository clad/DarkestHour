//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2016
//==============================================================================

class DH_Kar98ScopedMeleeFire extends DHMeleeFire;

defaultproperties
{
    DamageType=class'DH_Weapons.DH_Kar98ScopedBashDamType'
    TraceRange=75.0
    BashBackAnim="bash_pullback"
    BashHoldAnim="bash_hold"
    BashAnim="bash_attack"
    BashFinishAnim="bash_return"
    BotRefireRate=0.25
    aimerror=800.0
}
