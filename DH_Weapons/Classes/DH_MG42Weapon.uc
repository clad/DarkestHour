//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2016
//==============================================================================

class DH_MG42Weapon extends DHMGWeapon;

#exec OBJ LOAD FILE=..\Animations\Axis_Mg42_1st.ukx

// Overridden so we do faster net updated when we're down to the last few rounds
simulated function bool ConsumeAmmo(int Mode, float Load, optional bool bAmountNeededIsMax)
{
    if (AmmoAmount(0) < 11)
    {
        NetUpdateTime = Level.TimeSeconds - 1.0;
    }

    return super.ConsumeAmmo(Mode, Load, bAmountNeededIsMax);
}

defaultproperties
{
    MGBeltBones(0)="Case09"
    MGBeltBones(1)="Case08"
    MGBeltBones(2)="Case07"
    MGBeltBones(3)="Case06"
    MGBeltBones(4)="Case05"
    MGBeltBones(5)="Case04"
    MGBeltBones(6)="Case03"
    MGBeltBones(7)="Case02"
    MGBeltBones(8)="Case01"
    MGBeltBones(9)="Case"
    BeltBulletClass=class'ROInventory.MG42BeltRound'
    bCanFireFromHip=false
    InitialBarrels=2
    BarrelClass=class'DH_Weapons.DH_MG42Barrel'
    BarrelSteamBone="Barrel_Switch"
    BarrelChangeAnim="Bipod_Barrel_Change"
    IdleToBipodDeploy="Rest_2_Bipod"
    BipodDeployToIdle="Bipod_2_Rest"
    MagEmptyReloadAnim="Reload"
    MagPartialReloadAnim="Reload"
    IronIdleAnim="Bipod_Idle"
    IronBringUp="Rest_2_Bipod"
    IronPutDown="Bipod_2_Rest"
    MaxNumPrimaryMags=2
    InitialNumPrimaryMags=2
    bPlusOneLoading=true
    SprintStartAnim="Rest_Sprint_Start"
    SprintLoopAnim="Rest_Sprint_Middle"
    SprintEndAnim="Rest_Sprint_End"
    CrawlForwardAnim="crawlF"
    CrawlBackwardAnim="crawlB"
    CrawlStartAnim="crawl_in"
    CrawlEndAnim="crawl_out"
    IronSightDisplayFOV=40.0
    ZoomInTime=0.4
    ZoomOutTime=0.2
    Handtex=texture'Weapons1st_tex.Arms.hands_gergloves'
    FireModeClass(0)=class'DH_Weapons.DH_MG42Fire'
    IdleAnim="Rest_Idle"
    SelectAnim="Draw"
    PutDownAnim="putaway"
    SelectAnimRate=1.0
    PutDownAnimRate=1.0
    AIRating=0.4
    CurrentRating=0.4
    bSniping=true
    DisplayFOV=70.0
    PickupClass=class'DH_Weapons.DH_MG42Pickup'
    BobDamping=1.6
    AttachmentClass=class'DH_Weapons.DH_MG42Attachment'
    ItemName="Maschinengewehr 42"
    Mesh=SkeletalMesh'Axis_Mg42_1st.MG42_Mesh'
}
