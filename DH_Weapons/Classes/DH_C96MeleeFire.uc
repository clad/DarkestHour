//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2016
//==============================================================================

class DH_C96MeleeFire extends DHMeleeFire;

defaultproperties
{
    DamageType=class'DH_Weapons.DH_C96BashDamType'
    TraceRange=75.0
    GroundBashSound=SoundGroup'Inf_Weapons_Foley.melee.pistol_hit_ground'
    BashBackAnim="bash_pullback"
    BashHoldAnim="bash_hold"
    BashAnim="bash_attack"
    BashFinishAnim="bash_return"
    BotRefireRate=0.25
    aimerror=800.0
}
