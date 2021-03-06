//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2016
//==============================================================================

class DH_ParachuteAttachment extends DHWeaponAttachment;

var     name    ChuteDeployAnim;
var name    ChuteIdleAnim;

simulated function PlayIdle()
{
    PlayAnim(ChuteDeployAnim);
}

defaultproperties
{
    CullDistance=0.0 // no cull as it's too big
    ChuteDeployAnim="Deploy"
    ChuteIdleAnim="Idle"
    PA_MovementAnims(0)="stand_jogF_nade"
    PA_MovementAnims(1)="stand_jogB_nade"
    PA_MovementAnims(2)="stand_jogL_nade"
    PA_MovementAnims(3)="stand_jogR_nade"
    PA_MovementAnims(4)="stand_jogFL_nade"
    PA_MovementAnims(5)="stand_jogFR_nade"
    PA_MovementAnims(6)="stand_jogBL_nade"
    PA_MovementAnims(7)="stand_jogBR_nade"
    PA_CrouchAnims(0)="crouch_walkF_nade"
    PA_CrouchAnims(1)="crouch_walkB_nade"
    PA_CrouchAnims(2)="crouch_walkL_nade"
    PA_CrouchAnims(3)="crouch_walkR_nade"
    PA_CrouchAnims(4)="crouch_walkFL_nade"
    PA_CrouchAnims(5)="crouch_walkFR_nade"
    PA_CrouchAnims(6)="crouch_walkBL_nade"
    PA_CrouchAnims(7)="crouch_walkBR_nade"
    PA_ProneAnims(0)="prone_crawlF_nade"
    PA_ProneAnims(1)="prone_crawlB_nade"
    PA_ProneAnims(2)="prone_crawlL_nade"
    PA_ProneAnims(3)="prone_crawlR_nade"
    PA_ProneAnims(4)="prone_crawlFL_nade"
    PA_ProneAnims(5)="prone_crawlFR_nade"
    PA_ProneAnims(6)="prone_crawlBL_nade"
    PA_ProneAnims(7)="prone_crawlBR_nade"
    PA_ProneIronAnims(0)="prone_slowcrawlF_nade"
    PA_ProneIronAnims(1)="prone_slowcrawlB_nade"
    PA_ProneIronAnims(2)="prone_slowcrawlL_nade"
    PA_ProneIronAnims(3)="prone_slowcrawlR_nade"
    PA_ProneIronAnims(4)="prone_slowcrawlL_nade"
    PA_ProneIronAnims(5)="prone_slowcrawlR_nade"
    PA_ProneIronAnims(6)="prone_slowcrawlB_nade"
    PA_ProneIronAnims(7)="prone_slowcrawlB_nade"
    PA_WalkAnims(0)="stand_walkFhip_nade"
    PA_WalkAnims(1)="stand_walkBhip_nade"
    PA_WalkAnims(2)="stand_walkLhip_nade"
    PA_WalkAnims(3)="stand_walkRhip_nade"
    PA_WalkAnims(4)="stand_walkFLhip_nade"
    PA_WalkAnims(5)="stand_walkFRhip_nade"
    PA_WalkAnims(6)="stand_walkBLhip_nade"
    PA_WalkAnims(7)="stand_walkBRhip_nade"
    PA_WalkIronAnims(0)="stand_walkFiron_nade"
    PA_WalkIronAnims(1)="stand_walkBiron_nade"
    PA_WalkIronAnims(2)="stand_walkLiron_nade"
    PA_WalkIronAnims(3)="stand_walkRiron_nade"
    PA_WalkIronAnims(4)="stand_walkFLiron_nade"
    PA_WalkIronAnims(5)="stand_walkFRiron_nade"
    PA_WalkIronAnims(6)="stand_walkBLiron_nade"
    PA_WalkIronAnims(7)="stand_walkBRiron_nade"
    PA_SprintAnims(0)="stand_sprintF_nade"
    PA_SprintAnims(1)="stand_sprintB_nade"
    PA_SprintAnims(2)="stand_sprintL_nade"
    PA_SprintAnims(3)="stand_sprintR_nade"
    PA_SprintAnims(4)="stand_sprintFL_nade"
    PA_SprintAnims(5)="stand_sprintFR_nade"
    PA_SprintAnims(6)="stand_sprintBL_nade"
    PA_SprintAnims(7)="stand_sprintBR_nade"
    PA_SprintCrouchAnims(0)="crouch_sprintF_nade"
    PA_SprintCrouchAnims(1)="crouch_sprintB_nade"
    PA_SprintCrouchAnims(2)="crouch_sprintL_nade"
    PA_SprintCrouchAnims(3)="crouch_sprintR_nade"
    PA_SprintCrouchAnims(4)="crouch_sprintFL_nade"
    PA_SprintCrouchAnims(5)="crouch_sprintFR_nade"
    PA_SprintCrouchAnims(6)="crouch_sprintBL_nade"
    PA_SprintCrouchAnims(7)="crouch_sprintBR_nade"
    PA_LimpAnims(0)="stand_limpFhip_nade"
    PA_LimpAnims(1)="stand_limpBhip_nade"
    PA_LimpAnims(2)="stand_limpLhip_nade"
    PA_LimpAnims(3)="stand_limpRhip_nade"
    PA_LimpAnims(4)="stand_limpFLhip_nade"
    PA_LimpAnims(5)="stand_limpFRhip_nade"
    PA_LimpAnims(6)="stand_limpBLhip_nade"
    PA_LimpAnims(7)="stand_limpBRhip_nade"
    PA_LimpIronAnims(0)="stand_limpFiron_nade"
    PA_LimpIronAnims(1)="stand_limpBiron_nade"
    PA_LimpIronAnims(2)="stand_limpLiron_nade"
    PA_LimpIronAnims(3)="stand_limpRiron_nade"
    PA_LimpIronAnims(4)="stand_limpFLiron_nade"
    PA_LimpIronAnims(5)="stand_limpFRiron_nade"
    PA_LimpIronAnims(6)="stand_limpBLiron_nade"
    PA_LimpIronAnims(7)="stand_limpBRiron_nade"
    PA_TurnRightAnim="stand_turnRhip_binoc"
    PA_TurnLeftAnim="stand_turnLhip_binoc"
    PA_TurnIronRightAnim="stand_turnRiron_nade"
    PA_TurnIronLeftAnim="stand_turnLiron_nade"
    PA_ProneTurnRightAnim="prone_turnR_nade"
    PA_ProneTurnLeftAnim="prone_turnL_nade"
    PA_StandToProneAnim="StandtoProne_nade"
    PA_CrouchToProneAnim="CrouchtoProne_nade"
    PA_ProneToStandAnim="PronetoStand_nade"
    PA_ProneToCrouchAnim="PronetoCrouch_nade"
    PA_DiveToProneStartAnim="prone_diveF_nade"
    PA_DiveToProneEndAnim="prone_diveend_nade"
    PA_CrouchTurnRightAnim="crouch_turnR_nade"
    PA_CrouchTurnLeftAnim="crouch_turnL_nade"
    PA_CrouchIdleRestAnim="crouch_idle_nade"
    PA_IdleCrouchAnim="crouch_idle_nade"
    PA_IdleRestAnim="stand_idlehip_nade"
    PA_IdleWeaponAnim="stand_idlehip_nade"
    PA_IdleIronRestAnim="stand_idleiron_nade"
    PA_IdleIronWeaponAnim="stand_idleiron_nade"
    PA_IdleProneAnim="prone_idle_nade"
    PA_AirStillAnim="Chute_idle"
    PA_AirAnims(0)="Chute_idle"
    PA_AirAnims(1)="Chute_idle"
    PA_AirAnims(2)="chute_left"
    PA_AirAnims(3)="chute_right"
    PA_TakeoffStillAnim="chute_deploy"
    PA_TakeoffAnims(0)="chute_deploy"
    PA_TakeoffAnims(1)="chute_deploy"
    PA_TakeoffAnims(2)="chute_deploy"
    PA_TakeoffAnims(3)="chute_deploy"
    PA_LandAnims(0)="chute_undeploy"
    PA_LandAnims(1)="chute_undeploy"
    PA_LandAnims(2)="chute_undeploy"
    PA_LandAnims(3)="chute_undeploy"
    MenuImage=texture'DH_Sundries_Tex.Parachute.ParachuteIcon'
    AttachmentBone="HIP"
    Mesh=SkeletalMesh'DH_Parachute_anm.Parachute3rd'
    Skins(0)=texture'DH_Sundries_Tex.Parachute.Parachute'
}
