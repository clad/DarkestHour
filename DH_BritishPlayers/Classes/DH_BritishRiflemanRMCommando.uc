//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2016
//==============================================================================

class DH_BritishRiflemanRMCommando extends DH_RoyalMarineCommandos;

defaultproperties
{
    MyName="Rifleman"
    AltName="Rifleman"
    Article="a "
    PluralName="Riflemen"
    MenuImage=texture'DHBritishCharactersTex.Icons.Brit_Rifleman'
    Models(0)="RMC1"
    Models(1)="RMC2"
    Models(2)="RMC3"
    Models(3)="RMC4"
    Models(4)="RMC5"
    Models(5)="RMC6"
    SleeveTexture=texture'DHBritishCharactersTex.Sleeves.brit_sleeves'
    PrimaryWeapons(0)=(Item=class'DH_Weapons.DH_EnfieldNo4Weapon')
    Grenades(0)=(Item=class'DH_Weapons.DH_M1GrenadeWeapon')
    Headgear(0)=class'DH_BritishPlayers.DH_BritishTurtleHelmet'
    Headgear(1)=class'DH_BritishPlayers.DH_BritishTurtleHelmetNet'
    Headgear(2)=class'DH_BritishPlayers.DH_BritishRMCommandoBeret'
}
