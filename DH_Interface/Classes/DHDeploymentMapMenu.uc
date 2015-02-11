//-----------------------------------------------------------
// DHDeploymentMapMenu
//-----------------------------------------------------------
//Theel: ToDo: This class still has a ton of work
//- Remove uneeded shit
//- Fix draw map problems
//- Clean up code
//This will require a black room, but the player will never see or experience it and it is strictly
//to reduce the required number of player starts and allow pawns to start "inside" eachother
//Allowing for smaller cover to protect spawns!!!

class DHDeploymentMapMenu extends MidGamePanel;

const OBJECTIVES_MAX = 16;
const SPAWN_POINTS_MAX = 16;

var()   float                       DeploymentMapCenterX, DeploymentMapCenterY, DeploymentMapRadius;

var     automated GUIFooter         f_Legend;

var     automated GUILabel          l_HelpText, l_HintText, l_TeamText;

var     automated GUIImage          i_Background, i_HintImage, i_Team;

var     automated GUIGFXButton      b_SpawnPoints[SPAWN_POINTS_MAX],b_Objectives[OBJECTIVES_MAX];
var     DHSpawnPoint                SpawnPoints[SPAWN_POINTS_MAX];
var     DHSpawnPoint                DesiredSpawnPoint; //THIS MIGHT NEED TO GO IN DHPlayer instead of here (pretty sure)
var     ROObjective                 Objectives[OBJECTIVES_MAX]; //Not sure if I need these

var     Material                    ObjectiveIcons[3]; //Objective flash modes

var()   localized string            MapPreferenceStrings[3];
var()   localized string            NodeTeleportHelpText,
                                    SetDefaultText,
                                    ChooseSpawnText,
                                    ClearDefaultText,
                                    SetDefaultHint,
                                    ClearDefaultHint,
                                    SpawnText,
                                    TeleportText,
                                    SpawnHint,
                                    TeleportHint,
                                    SelectedHint,
                                    UnderAttackHint,
                                    CoreHint,
                                    NodeHint,
                                    UnclaimedHint,
                                    LockedHint;

var()   localized string            Titles[6];
var()   localized string            NewSelectedHint, NewTeleportHint, EnemyCoreHint;
var     localized string            DefendMsg;

var     color                       TColor[2];
var()   color                       SelectionColor;

// Actor references - these must be cleared at level change
var     DHGameReplicationInfo       GRI;
var     DHPlayerReplicationInfo     PRI;

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
    local int i;

    Super.InitComponent(MyController, MyOwner);

    GRI = DHGameReplicationInfo(PlayerOwner().GameReplicationInfo);

    //Set the level image
    i_Background.Image = GRI.MapImage;

    for (i = 0; i < arraycount(b_SpawnPoints); ++i)
    {
        b_SpawnPoints[i].Graphic = none;
    }

    for (i = 0; i < arraycount(b_Objectives); ++i)
    {
        b_Objectives[i].Graphic = none;
    }
}

event Opened(GUIComponent Sender)
{
    super.Opened(Sender);
}

//Not sure what this does yet.
function ShowPanel(bool bShow)
{
    local string ColorName, Caption;

    super.ShowPanel(bShow);

    if (bShow && PRI != none && PRI.Team != none)
    {
        ColorName = PRI.Team.ColorNames[PRI.Team.TeamIndex];
        Caption = Repl(DefendMsg, "%t", ColorName, false);
        l_TeamText.Caption = Caption;

        i_Team.Image = PRI.Level.GRI.TeamSymbols[PRI.Team.TeamIndex];
        i_Team.ImageColor = TColor[PRI.Team.TeamIndex];
    }
}

function bool InternalOnPreDraw( Canvas C )
{
    return false;
}

function bool PreDrawMap(Canvas C)
{
    local float L, T, W, H;

    DeploymentMapRadius = FMin(i_Background.ActualHeight(),i_Background.ActualWidth()) / 2;
    DeploymentMapCenterX = i_Background.Bounds[0] + DeploymentMapRadius;
    DeploymentMapCenterY = i_Background.Bounds[1] + i_Background.ActualHeight() / 2;

    l_HelpText.bBoundToParent = false;
    l_HelpText.bScaleToParent = false;

    l_HintText.bScaleToParent = false;
    l_HintText.bBoundToParent = false;

    i_HintImage.bScaleToParent = false;
    i_HintImage.bBoundToParent = false;

    l_TeamText.bScaleToParent = false;
    l_TeamText.bBoundToParent = false;

    i_Team.bScaleToParent = false;
    i_Team.bBoundToParent = false;

    L = DeploymentMapCenterX + DeploymentMapRadius + (ActualWidth() * 0.05);
    T = DeploymentMapCenterY - DeploymentMapRadius;

    W = ActualLeft() + ActualWidth() - L;
    H = ActualTop() + ActualHeight() - T;

    i_HintImage.WinLeft = L;
    i_HintImage.WinTop = T;

    l_HelpText.WinLeft = i_HintImage.ActualLeft() + i_HintImage.ActualWidth() + 8;
    l_HelpText.WinTop = t;
    l_HelpText.WinHeight = i_HintImage.ActualHeight();
    l_HelpTExt.WinWidth = W - i_HintImage.ActualWidth() - 8;

    t += i_HintImage.ActualHeight() + 8;
    l_HintText.WinLeft = l;
    l_HintText.WinTop= t;
    l_HintText.WinWidth = w;
    l_HintText.WinHeight = H - i_HintImage.ActualHeight() - 8;

    L = DeploymentMapCenterX + DeploymentMapRadius;
    W = ActualLeft() + ActualWidth() - L;

    i_Team.WinLeft = L;
    i_Team.WinWidth = W;
    i_Team.WinHeight = W;
    i_Team.WinTop = i_Background.ActualTop() + i_Background.ActualHeight() - i_Team.ActualHeight();

    l_TeamText.WinLeft = L;
    l_TeamText.WinWidth = W;
    l_TeamText.WinTop = i_Team.ActualTop() - l_TeamText.ActualHeight();

    return false;
}

function GetMapCoords(vector Location, out float X, out float Y)
{
    local float TDistance;
    local float Distance;

    TDistance = Abs(GRI.SouthWestBounds.X) + Abs(GRI.NorthEastBounds.X);
    Distance = Abs(GRI.NorthEastBounds.X - Location.X);
    X = Distance / TDistance;

    TDistance = Abs(GRI.SouthWestBounds.Y) + Abs(GRI.NorthEastBounds.Y);
    Distance = Abs(GRI.SouthWestBounds.Y - Location.Y);
    Y = Distance / TDistance;
}

function PlaceSpawnPointOnMap(DHSpawnPoint SP, int Index)
{
    local float X, Y;

    if (SP != none && Index >= 0 && Index < arraycount(b_SpawnPoints))
    {
        GetMapCoords(SP.Location, X, Y);

        b_SpawnPoints[Index].SetPosition(X, Y, 0.05, 0.05, true);
        b_SpawnPoints[Index].Graphic = texture'InterfaceArt_tex.Tank_Hud.RedDot';
        b_SpawnPoints[Index].Caption = SP.SpawnPointName;

        SpawnPoints[Index] = SP;
    }
}

function PlaceObjectiveOnMap(ROObjective O, int Index)
{
    local float X, Y;

    if (O != none && Index >= 0 && Index < arraycount(b_Objectives))
    {
        GetMapCoords(O.Location, X, Y);

        b_Objectives[Index].SetPosition(X, Y, 0.05, 0.05, true);
        b_Objectives[Index].Graphic = ObjectiveIcons[int(GRI.Objectives[Index].ObjState)];
        b_Objectives[Index].Caption = O.ObjectiveName;

        Objectives[Index] = O;
    }
}

function bool DrawMapComponents(Canvas C)
{
    local int i;
    //local vector vBoundaryScale, vMapScaleCenter;
    //local float fMapScale;
    //local DHSpawnPoint SP;
    local array<DHSpawnPoint> ActiveSpawnPoints;

    //Get/Draw Spawn Points for Current Team
    GRI.GetActiveSpawnPointsForTeam(ActiveSpawnPoints, PlayerOwner().PlayerReplicationInfo.Team.TeamIndex);

    for(i = 0; i < ActiveSpawnPoints.Length; ++i)
    {
        PlaceSpawnPointOnMap(ActiveSpawnPoints[i], i);
    }

    l_TeamText.Caption = "SpawnPoints.Length =" @ ActiveSpawnPoints.Length;

    //Draw objectives
    for (i = 0; i < arraycount(GRI.Objectives); i++)
    {
        if (GRI.Objectives[i] == none || !GRI.Objectives[i].bActive)
        {
            continue;
        }

        PlaceObjectiveOnMap(GRI.Objectives[i], i);
    }

    return false;
}

//After initial drawing is complete this is ran?
//Needs repurposed, this I guess actually shows the panel once it's rendered
function InternalOnPostDraw(Canvas Canvas)
{
    PRI = DHPlayerReplicationInfo(PlayerOwner().PlayerReplicationInfo);

    if (PRI != none)
    {
        bInit = false;
        OnRendered = None;

        ShowPanel(true);
    }
}

//This is how the player is selecting a core to spawn at I think!
function SetSelectedSpawn()
{
    /*
    local ONSPowerCore Core;

    Core = ONSHudOnslaught(PlayerOwner().myHUD).LocatePowerCore(Controller.MouseX - OnslaughtMapCenterX, Controller.MouseY - OnslaughtMapCenterY, OnslaughtMapRadius);
    if ( ValidSpawnPoint(Core) )
        SelectedCore = Core;
    else SelectedCore = None;
    */
}

//Hehe this is a good function that handles either spawning or teleporting
function bool SpawnClick(int Index)
{
    local DHPlayer PC;

    //Log("Trying to call server restart player!!!");

    if (bInit || PRI == none || PRI.bOnlySpectator)
    {
        return true;
    }

    if (SpawnPoints[Index] == none)
    {
        Log("No spawn point found! Error!");

        return true;
    }

    PC = DHPlayer(PlayerOwner());

    //TODO: Need a check here to make sure player has role & stuff selected!

    //Set the deisred spawn point
    DesiredSpawnPoint = SpawnPoints[Index];

    //Player already has a pawn, so lets close entire deploymenu
    if (PC.Pawn != none)
    {
        Controller.CloseMenu(false);
    }

    //Player isn't ready to respawn, as the redeploy timer hasn't reached 0?

    //Spawn the player, teleport to spawn point, and send ammo % so it can be known to game
    PC.CurrentRedeployTime = PC.RedeployTime; //This make it so the player can't adjust Redeploytime post spawning

    if (PC.bReadyToSpawn && PC.Pawn == none)
    {
        PC.ServerDeployPlayer(SpawnPoints[Index], true);
        Controller.CloseMenu(false); //DeployPlayer needs to return true/false if succesful and this needs to be in an if statement
    }
}

function bool InternalOnClick(GUIComponent Sender)
{
    local GUIButton Selected;
    local int i;

    if (GUIButton(Sender) != none)
    {
        Selected = GUIButton(Sender);
    }

    if (Selected == none)
    {
        return false;
    }

    for (i = 0; i < arraycount(b_SpawnPoints); ++i)
    {
        if (Selected == b_SpawnPoints[i])
        {
            SpawnClick(i);

            break;

        }
    }

    return false;
}

//Hmmm wtf is this
function Timer()
{
    local PlayerController PC;

    PC = PlayerOwner();
    PC.ServerRestartPlayer();
    PC.bFire = 0;
    PC.bAltFire = 0;
    Controller.CloseMenu(false);
}

//Menu was closed, do stuff
/* BOINK
function Closed(GUIComponent Sender, bool bCancelled)
{
    local ONSPlayerReplicationInfo.EMapPreference Pref;

    if (PRI != None)
    {
        Pref = EMapPreference(co_MenuOptions.GetIndex());
        if ( Pref != PRI.ShowMapOnDeath )
        {
            PRI.ShowMapOnDeath = Pref;
            PRI.SaveConfig();
        }
    }

    Super.Closed(Sender,bCancelled);
}

//This is sorta like a reset, releases the PRI and selected spawn point and also unlocks
function Free()
{
    Super.Free();

    PRI = None;
    SelectedCore = None;
}

//WTF? why not just call free?
function LevelChanged()
{
    Super.LevelChanged();

    PRI = None;
    SelectedCore = None;
}
*/

defaultproperties
{
    //Background=Texture'DH_GUI_Tex.Menu.DHBox'

    ObjectiveIcons(0)=Texture'DH_GUI_Tex.GUI.GerCross'
    ObjectiveIcons(1)=Texture'DH_GUI_Tex.GUI.AlliedStar'
    ObjectiveIcons(2)=Texture'DH_GUI_Tex.GUI.PlayerIcon'

    //These might need repurposed to support 512x512 and 1024x1024!
    DeploymentMapCenterX=0.650000
    DeploymentMapCenterY=0.400000
    DeploymentMapRadius=0.300000

//Defined objects need repurposed to support class and package changes
     Begin Object Class=GUILabel Name=HelpText
         TextColor=(B=255,G=255,R=255)
         StyleName="TextLabel"
         WinTop=0.035141
         WinLeft=0.719388
         WinWidth=0.274188
     End Object
     l_HelpText=GUILabel'DH_Interface.DHDeploymentMapMenu.HelpText'

     Begin Object Class=GUILabel Name=HintLabel
         bMultiLine=True
         FontScale=FNS_Small
         StyleName="TextLabel"
         WinTop=0.117390
         WinLeft=0.669020
         WinWidth=0.323888
         WinHeight=0.742797
         RenderWeight=0.520000
     End Object
     l_HintText=GUILabel'DH_Interface.DHDeploymentMapMenu.HintLabel'

     Begin Object Class=GUILabel Name=TeamLabel
         Caption="Defend the Red Core"
         TextAlign=TXTA_Center
         bMultiLine=True
         FontScale=FNS_Small
         StyleName="TextLabel"
         WinTop=0.391063
         WinLeft=0.597081
         WinWidth=0.385550
         WinHeight=0.043963
         RenderWeight=0.520000
     End Object
     l_TeamText=GUILabel'DH_Interface.DHDeploymentMapMenu.TeamLabel'

     Begin Object Class=GUIImage Name=BackgroundImage
         Image=Texture'DH_GUI_Tex.Menu.DHBox'
         ImageStyle=ISTY_Justified
        WinWidth=1.0
        WinHeight=1.0
        WinLeft=0.0
        WinTop=0.0
         bAcceptsInput=false
         OnPreDraw=DHDeploymentMapMenu.PreDrawMap
         OnDraw=DHDeploymentMapMenu.DrawMapComponents
         //OnClick=DHDeploymentMapMenu.SpawnClick
         //OnRightClick=DHDeploymentMapMenu.SelectClick
     End Object
     i_Background=GUIImage'DH_Interface.DHDeploymentMapMenu.BackgroundImage'


    Begin Object Class=GUIGFXButton Name=SpawnPointButton
        Graphic=texture'InterfaceArt_tex.Tank_Hud.RedDot'
        Position=ICP_Justified
        bClientBound=true
        StyleName="DHGripButtonNB"
        WinWidth=0.1
        WinHeight=0.1
        TabOrder=1 //wtf is this? was 21
        bTabStop=true
        OnClick=DHDeploymentMapMenu.InternalOnClick
        //OnKeyEvent=EquipButton0.InternalOnKeyEvent
    End Object
    b_SpawnPoints(0)=GUIGFXButton'DH_Interface.DHDeploymentMapMenu.SpawnPointButton'
    b_SpawnPoints(1)=GUIGFXButton'DH_Interface.DHDeploymentMapMenu.SpawnPointButton'
    b_SpawnPoints(2)=GUIGFXButton'DH_Interface.DHDeploymentMapMenu.SpawnPointButton'
    b_SpawnPoints(3)=GUIGFXButton'DH_Interface.DHDeploymentMapMenu.SpawnPointButton'
    b_SpawnPoints(4)=GUIGFXButton'DH_Interface.DHDeploymentMapMenu.SpawnPointButton'
    b_SpawnPoints(5)=GUIGFXButton'DH_Interface.DHDeploymentMapMenu.SpawnPointButton'
    b_SpawnPoints(6)=GUIGFXButton'DH_Interface.DHDeploymentMapMenu.SpawnPointButton'
    b_SpawnPoints(7)=GUIGFXButton'DH_Interface.DHDeploymentMapMenu.SpawnPointButton'
    b_SpawnPoints(8)=GUIGFXButton'DH_Interface.DHDeploymentMapMenu.SpawnPointButton'
    b_SpawnPoints(9)=GUIGFXButton'DH_Interface.DHDeploymentMapMenu.SpawnPointButton'
    b_SpawnPoints(10)=GUIGFXButton'DH_Interface.DHDeploymentMapMenu.SpawnPointButton'
    b_SpawnPoints(11)=GUIGFXButton'DH_Interface.DHDeploymentMapMenu.SpawnPointButton'
    b_SpawnPoints(12)=GUIGFXButton'DH_Interface.DHDeploymentMapMenu.SpawnPointButton'
    b_SpawnPoints(13)=GUIGFXButton'DH_Interface.DHDeploymentMapMenu.SpawnPointButton'
    b_SpawnPoints(14)=GUIGFXButton'DH_Interface.DHDeploymentMapMenu.SpawnPointButton'
    b_SpawnPoints(15)=GUIGFXButton'DH_Interface.DHDeploymentMapMenu.SpawnPointButton'



    Begin Object Class=GUIGFXButton Name=ObjectiveButton
        Graphic=texture'InterfaceArt_tex.Tank_Hud.RedDot'
        Position=ICP_Justified
        bClientBound=true
        StyleName="DHGripButtonNB"
        WinWidth=0.1
        WinHeight=0.1
        TabOrder=1 //wtf is this? was 21
        bTabStop=true
        //OnClick=DHDeploymentMapMenu.InternalOnClick
    End Object
    b_Objectives(0)=GUIGFXButton'DH_Interface.DHDeploymentMapMenu.ObjectiveButton'
    b_Objectives(1)=GUIGFXButton'DH_Interface.DHDeploymentMapMenu.ObjectiveButton'
    b_Objectives(2)=GUIGFXButton'DH_Interface.DHDeploymentMapMenu.ObjectiveButton'
    b_Objectives(3)=GUIGFXButton'DH_Interface.DHDeploymentMapMenu.ObjectiveButton'
    b_Objectives(4)=GUIGFXButton'DH_Interface.DHDeploymentMapMenu.ObjectiveButton'
    b_Objectives(5)=GUIGFXButton'DH_Interface.DHDeploymentMapMenu.ObjectiveButton'
    b_Objectives(6)=GUIGFXButton'DH_Interface.DHDeploymentMapMenu.ObjectiveButton'
    b_Objectives(7)=GUIGFXButton'DH_Interface.DHDeploymentMapMenu.ObjectiveButton'
    b_Objectives(8)=GUIGFXButton'DH_Interface.DHDeploymentMapMenu.ObjectiveButton'
    b_Objectives(9)=GUIGFXButton'DH_Interface.DHDeploymentMapMenu.ObjectiveButton'
    b_Objectives(10)=GUIGFXButton'DH_Interface.DHDeploymentMapMenu.ObjectiveButton'
    b_Objectives(11)=GUIGFXButton'DH_Interface.DHDeploymentMapMenu.ObjectiveButton'
    b_Objectives(12)=GUIGFXButton'DH_Interface.DHDeploymentMapMenu.ObjectiveButton'
    b_Objectives(13)=GUIGFXButton'DH_Interface.DHDeploymentMapMenu.ObjectiveButton'
    b_Objectives(14)=GUIGFXButton'DH_Interface.DHDeploymentMapMenu.ObjectiveButton'
    b_Objectives(15)=GUIGFXButton'DH_Interface.DHDeploymentMapMenu.ObjectiveButton'




     Begin Object Class=GUIImage Name=IconHintImage
         //Image=Texture'ONSInterface-TX.NewHUDicons'
         ImageStyle=ISTY_Scaled
         WinTop=0.033996
         WinLeft=0.671639
         WinWidth=0.043667
         WinHeight=0.049502
         RenderWeight=0.510000
     End Object
     i_HintImage=GUIImage'DH_Interface.DHDeploymentMapMenu.IconHintImage'

     Begin Object Class=GUIImage Name=iTeam
         ImageColor=(G=128,R=0,A=90)
         ImageStyle=ISTY_Scaled
         WinTop=0.400000
         WinLeft=0.619446
         WinWidth=0.338338
         WinHeight=0.405539
         TabOrder=10
     End Object
     i_Team=GUIImage'DH_Interface.DHDeploymentMapMenu.iTeam'


//Worry about these as I continue to work on variables

     MapPreferenceStrings(0)="Never"
     MapPreferenceStrings(1)="When Body is Still"
     MapPreferenceStrings(2)="Immediately"
     NodeTeleportHelpText="Choose Node Teleport Destination"
     SetDefaultText="Set Default"
     ChooseSpawnText="Choose Your Spawn Point"
     ClearDefaultText="Clear Default"
     SetDefaultHint="Set the currently selected node as your preferred spawn location"
     ClearDefaultHint="Allow the game to choose the most appropriate spawn location"
     SpawnText="Spawn Here"
     TeleportText="Teleport Here"
     SpawnHint="Spawn at the currently selected node"
     TeleportHint="Teleport to the currently selected node"
     SelectedHint="Preferred spawn location"
     UnderAttackHint="Node is currently under attack"
     CoreHint="Main power core"
     NodeHint="Node is currently vulnerable to enemy attack"
     UnclaimedHint="Node is currently neutral and may be taken by either team"
     LockedHint="Node is currently unlinked and may not be attacked by the enemy"
     Titles(0)="Core (Under Attack)"
     Titles(1)="Preferred Node"
     Titles(2)="Core"
     Titles(3)="Node (Unclaimed)"
     Titles(4)="Node (Locked)"
     Titles(5)="Node (Attackable)"
     NewSelectedHint="||Right-Click on this node to select it as the preferred spawn location."
     NewTeleportHint="||Left-Click on this node to teleport to it"
     EnemyCoreHint="Enemy Core||Connect the nodes until you can reach this core"
     DefendMsg="Defend the %t core"
     TColor(0)=(B=100,G=100,R=255,A=128)
     TColor(1)=(B=255,G=128,A=128)
     //NodeImage=Texture'ONSInterface-TX.NewHUDicons'
     SelectionColor=(B=255,G=255,R=255,A=255)
     OnPreDraw=DHDeploymentMapMenu.InternalOnPreDraw
     OnRendered=DHDeploymentMapMenu.InternalOnPostDraw
}
