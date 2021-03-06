//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2016
//==============================================================================

class DH_MP40Weapon extends DHAutoWeapon;

#exec OBJ LOAD FILE=..\Animations\DH_Mp40_1st.ukx

defaultproperties
{
    MagEmptyReloadAnim="reload_empty"
    MagPartialReloadAnim="reload_half"
    IronIdleAnim="Iron_idle"
    IronBringUp="iron_in"
    IronPutDown="iron_out"
    MaxNumPrimaryMags=7
    InitialNumPrimaryMags=7
    bPlusOneLoading=true
    PlayerIronsightFOV=65.0
    CrawlForwardAnim="crawlF"
    CrawlBackwardAnim="crawlB"
    CrawlStartAnim="crawl_in"
    CrawlEndAnim="crawl_out"
    IronSightDisplayFOV=35.0
    ZoomInTime=0.4
    ZoomOutTime=0.15
    FireModeClass(0)=class'DH_Weapons.DH_MP40Fire'
    FireModeClass(1)=class'DH_Weapons.DH_MP40MeleeFire'
    SelectAnim="Draw"
    PutDownAnim="Put_away"
    SelectAnimRate=1.0
    PutDownAnimRate=1.0
    AIRating=0.7
    CurrentRating=0.7
    DisplayFOV=70.0
    bCanRestDeploy=true
    PickupClass=class'DH_Weapons.DH_MP40Pickup'
    BobDamping=1.6
    AttachmentClass=class'DH_Weapons.DH_MP40Attachment'
    ItemName="Maschinenpistole 40"
    Mesh=SkeletalMesh'DH_Mp40_1st.mp40-mesh'
    HighDetailOverlay=Shader'Weapons1st_tex.SMG.MP40_s'
    bUseHighDetailOverlayIndex=true
    HighDetailOverlayIndex=2
}
