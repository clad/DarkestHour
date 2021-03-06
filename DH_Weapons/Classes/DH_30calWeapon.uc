//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2016
//==============================================================================

class DH_30calWeapon extends DHMGWeapon;

#exec OBJ LOAD FILE=..\Animations\DH_30Cal_1st.ukx

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
    BeltBulletClass=class'DH_Weapons.DH_30calBeltRound'
    bCanFireFromHip=false
    InitialBarrels=1
    BarrelClass=class'DH_Weapons.DH_30CalBarrel'
    BarrelSteamBone="bipod"
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
    IronSightDisplayFOV=35.0
    ZoomInTime=0.4
    ZoomOutTime=0.2
    FireModeClass(0)=class'DH_Weapons.DH_30calFire'
    FireModeClass(1)=class'ROInventory.ROEmptyFireclass'
    IdleAnim="Rest_Idle"
    SelectAnim="Draw"
    PutDownAnim="putaway"
    SelectAnimRate=1.0
    PutDownAnimRate=1.0
    AIRating=0.4
    CurrentRating=0.4
    bSniping=true
    DisplayFOV=70.0
    PickupClass=class'DH_Weapons.DH_30calPickup'
    BobDamping=1.6
    AttachmentClass=class'DH_Weapons.DH_30calAttachment'
    ItemName="M1919A4 Browning Machine Gun"
    Mesh=SkeletalMesh'DH_30Cal_1st.30Cal'
}

