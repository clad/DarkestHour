//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2016
//==============================================================================

class DH_USPlatoonMG506101st extends DH_US_506PIR;

defaultproperties
{
    MyName="Machine-Gunner"
    AltName="Machine-Gunner"
    Article="a "
    PluralName="Machine-Gunners"
    MenuImage=texture'DHUSCharactersTex.Icons.ABPMG'
    Models(0)="US_506101AB1"
    Models(1)="US_506101AB2"
    Models(2)="US_506101AB3"
    bIsGunner=true
    SleeveTexture=texture'DHUSCharactersTex.Sleeves.USAB_sleeves'
    PrimaryWeapons(0)=(Item=class'DH_Weapons.DH_30calWeapon')
    SecondaryWeapons(0)=(Item=class'DH_Weapons.DH_ColtM1911Weapon')
    Headgear(0)=class'DH_USPlayers.DH_AmericanHelmet506101stEMa'
    Headgear(1)=class'DH_USPlayers.DH_AmericanHelmet506101stEMb'
    PrimaryWeaponType=WT_LMG
    Limit=1
}
