//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2016
//==============================================================================

class DH_USRifleman502101st extends DH_US_502PIR;

defaultproperties
{
    MyName="Rifleman"
    AltName="Rifleman"
    Article="a "
    PluralName="Riflemen"
    MenuImage=texture'DHUSCharactersTex.Icons.ABRifleman'
    Models(0)="US_502101AB1"
    Models(1)="US_502101AB2"
    Models(2)="US_502101AB3"
    SleeveTexture=texture'DHUSCharactersTex.Sleeves.USAB_sleeves'
    PrimaryWeapons(0)=(Item=class'DH_Weapons.DH_M1GarandWeapon',AssociatedAttachment=class'DH_Weapons.DH_M1GarandAmmoPouch')
    PrimaryWeapons(1)=(Item=class'DH_Weapons.DH_M1CarbineWeapon',AssociatedAttachment=class'DH_Weapons.DH_M1CarbineAmmoPouch')
    SecondaryWeapons(0)=(Item=class'DH_Weapons.DH_ColtM1911Weapon')
    Grenades(0)=(Item=class'DH_Weapons.DH_M1GrenadeWeapon')
    Headgear(0)=class'DH_USPlayers.DH_AmericanHelmet502101stEMa'
    Headgear(1)=class'DH_USPlayers.DH_AmericanHelmet502101stEMb'
    PrimaryWeaponType=WT_SemiAuto
}
