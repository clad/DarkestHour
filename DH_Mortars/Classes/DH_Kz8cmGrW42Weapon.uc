//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2016
//==============================================================================

class DH_Kz8cmGrW42Weapon extends DHMortarWeapon;

#exec OBJ LOAD FILE=..\Animations\DH_Mortars_1st.ukx

defaultproperties
{
    VehicleClass=class'DH_Mortars.DH_Kz8cmGrW42Vehicle'
    AttachmentClass=class'DH_Mortars.DH_Kz8cmGrW42Attachment'
    Description="Kurz 8cm Granatwerfer 42"
    ItemName="Kurz 8cm Granatwerfer 42"
    Mesh=SkeletalMesh'DH_Mortars_1st.Kz8cmGrW42'
    HighExplosiveMaximum=16
    HighExplosiveResupplyCount=4
    SmokeMaximum=4
    SmokeResupplyCount=1
}
