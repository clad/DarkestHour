//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2014
//==============================================================================

class DH_Flak38CannonShellDamageHE extends DH_Sdkfz2341CannonShellDamageHE;

#exec OBJ LOAD FILE=..\Textures\DH_Flak38_tex.utx

defaultproperties
{
    HUDIcon=texture'DH_Flakvierling38_tex.flak.flakv38_icon'
    DeathString="%o was killed by %k's Flak 38 HE shell."
}