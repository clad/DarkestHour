//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2016
//==============================================================================

class DH_USMortarman506101st extends DH_US_506PIR;

defaultproperties
{
    bCanUseMortars=true
    MyName="Mortar Operator"
    AltName="Mortar Operator"
    Article="a "
    PluralName="Mortar Operators"
    MenuImage=texture'DHUSCharactersTex.Icons.ABMortarOperator'
    Models(0)="US_506101AB1"
    Models(1)="US_506101AB2"
    Models(2)="US_506101AB3"
    SleeveTexture=texture'DHUSCharactersTex.Sleeves.USAB_sleeves'
    PrimaryWeapons(0)=(Item=class'DH_Weapons.DH_M1CarbineWeapon',AssociatedAttachment=class'DH_Weapons.DH_M1CarbineAmmoPouch')
    SecondaryWeapons(0)=(Item=class'DH_Weapons.DH_ColtM1911Weapon')
    GivenItems(0)="DH_Mortars.DH_M2MortarWeapon"
    GivenItems(1)="DH_Equipment.DHBinocularsItem"
    Headgear(0)=class'DH_USPlayers.DH_AmericanHelmet506101stEMa'
    Headgear(1)=class'DH_USPlayers.DH_AmericanHelmet506101stEMb'
    PrimaryWeaponType=WT_SemiAuto
    Limit=1
}
