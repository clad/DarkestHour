//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2016
//==============================================================================

class DH_WSSFireteamLeader_Autumn extends DH_WaffenSSAutumn;

defaultproperties
{
    MyName="Corporal"
    AltName="Rottenführer"
    Article="a "
    PluralName="Corporals"
    MenuImage=texture'DHGermanCharactersTex.Icons.WSS_Semi'
    Models(0)="WHAu_1"
    Models(1)="WHAu_2"
    Models(2)="WHAu_3"
    Models(3)="WHAu_4"
    Models(4)="WHAu_5"
    Models(5)="WHAu_6"
    SleeveTexture=texture'DHGermanCharactersTex.GerSleeves.Dot44Sleeve'
    PrimaryWeapons(0)=(Item=class'DH_Weapons.DH_STG44Weapon',AssociatedAttachment=class'ROInventory.ROSTG44AmmoPouch')
    PrimaryWeapons(1)=(Item=class'DH_Weapons.DH_MP40Weapon',AssociatedAttachment=class'ROInventory.ROMP40AmmoPouch')
    SecondaryWeapons(0)=(Item=class'DH_Weapons.DH_P38Weapon')
    SecondaryWeapons(1)=(Item=class'DH_Weapons.DH_P08LugerWeapon')
    Grenades(0)=(Item=class'DH_Weapons.DH_StielGranateWeapon')
    Headgear(0)=class'DH_GerPlayers.DH_SSHelmetOne'
    Headgear(1)=class'DH_GerPlayers.DH_SSHelmetTwo'
    PrimaryWeaponType=WT_SMG
    bEnhancedAutomaticControl=true
    Limit=1
    Limit33to44=2
    LimitOver44=2
}
