//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2016
//==============================================================================

class DH_USAntiTank1st extends DH_US_1st_Infantry;

defaultproperties
{
    bIsATGunner=true
    MyName="Anti-Tank Soldier"
    AltName="Anti-Tank Soldier"
    Article="an "
    PluralName="Anti-Tank Soldiers"
    MenuImage=texture'DHUSCharactersTex.Icons.IconAT'
    Models(0)="US_1Inf1"
    Models(1)="US_1Inf2"
    Models(2)="US_1Inf3"
    Models(3)="US_1Inf4"
    Models(4)="US_1Inf5"
    bIsGunner=true
    SleeveTexture=texture'DHUSCharactersTex.Sleeves.US_sleeves'
    PrimaryWeapons(0)=(Item=class'DH_Weapons.DH_M1CarbineWeapon',AssociatedAttachment=class'DH_Weapons.DH_M1CarbineAmmoPouch')
    PrimaryWeapons(1)=(Item=class'DH_Weapons.DH_GreaseGunWeapon',AssociatedAttachment=class'DH_Weapons.DH_ThompsonAmmoPouch')
    Grenades(0)=(Item=class'DH_Equipment.DH_USSmokeGrenadeWeapon')
    GivenItems(0)="DH_ATWeapons.DH_BazookaWeapon"
    Headgear(0)=class'DH_USPlayers.DH_AmericanHelmet1stEMa'
    Headgear(1)=class'DH_USPlayers.DH_AmericanHelmet1stEMb'
    PrimaryWeaponType=WT_SMG
    Limit=1
}
