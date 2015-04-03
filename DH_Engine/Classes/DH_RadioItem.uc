//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2015
//==============================================================================

class DH_RadioItem extends DHWeapon
    abstract;

var class<DHArtilleryTrigger>   ArtilleryTriggerClass;
var DHArtilleryTrigger          ArtilleryTrigger;
var int                         TeamCanUse;
var name                        AttachBoneName;

simulated function PreBeginPlay()
{
    local DH_Pawn DHP;

    DHP = DH_Pawn(Instigator);

    if (DHP == none || DHP.CarriedRadioTrigger != none)
    {
        Destroy();

        return;
    }

    super.PreBeginPlay();
}

function PickupFunction(Pawn Other)
{
    super.PickupFunction(Other);

    AttachToPawn(Instigator);

    SetTimer(0.1, false);
}

function Timer()
{
    Destroy();
}

function AttachToPawn(Pawn P)
{
    local int i;
    local DarkestHourGame DHG;
    local DHGameReplicationInfo GRI;
    local DH_Pawn DHP;

    DHG = DarkestHourGame(Level.Game);

    if (DHG == none)
    {
        return;
    }

    GRI = DHGameReplicationInfo(DHG.GameReplicationInfo);
    DHP = DH_Pawn(P);

    if (GRI == none || DHP == none)
    {
        return;
    }

    ArtilleryTrigger = Spawn(ArtilleryTriggerClass, P);

    switch (TeamCanUse)
    {
        case AXIS_TEAM_INDEX:
            ArtilleryTrigger.TeamCanUse = AT_Axis;
            break;
        case ALLIES_TEAM_INDEX:
            ArtilleryTrigger.TeamCanUse = AT_Allies;
            break;
        default:
            ArtilleryTrigger.TeamCanUse = AT_Both;
            break;
    }

    ArtilleryTrigger.Carrier = DHP;

    DHP.CarriedRadioTrigger = ArtilleryTrigger;

    if (TeamCanUse == AXIS_TEAM_INDEX || TeamCanUse == NEUTRAL_TEAM_INDEX)
    {
        for (i = 0; i < arraycount(GRI.CarriedAxisRadios); ++i)
        {
            if (GRI.CarriedAxisRadios[i] == none)
            {
                GRI.CarriedAxisRadios[i] = ArtilleryTrigger;
                DHP.GRIRadioPos = i;

                break;
            }
        }
    }

    if (TeamCanUse == ALLIES_TEAM_INDEX || TeamCanUse == NEUTRAL_TEAM_INDEX)
    {
        for (i = 0; i < arraycount(GRI.CarriedAlliedRadios); ++i)
        {
            if (GRI.CarriedAlliedRadios[i] == none)
            {
                GRI.CarriedAlliedRadios[i] = ArtilleryTrigger;
                DHP.GRIRadioPos = i;

                break;
            }
        }
    }

    P.AttachToBone(ArtilleryTrigger, AttachBoneName);
}

defaultproperties
{
    FireModeClass(0)=class'ROInventory.ROEmptyFireclass'
    FireModeClass(1)=class'ROInventory.ROEmptyFireclass'
    InventoryGroup=10
    TeamCanUse=NEUTRAL_TEAM_INDEX
    AttachBoneName='hip'
    ArtilleryTriggerClass=class'DH_Engine.DHArtilleryTrigger'
}
