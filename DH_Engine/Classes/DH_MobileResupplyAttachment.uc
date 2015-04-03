//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2015
//==============================================================================

class DH_MobileResupplyAttachment extends RODummyAttachment
    abstract;

//Hack in AmmoResupplyVolume code
enum EOwningTeam
{
    OWNER_Axis,
    OWNER_Allies,
    OWNER_Neutral,
};

var()   EOwningTeam     Team;           //Team this volume resupplies
var()   float           UpdateTime;     //How often this thing needs to do it's business

enum EResupplyType
{
    RT_Players,
    RT_Vehicles,
    RT_All,
    RT_Mortars
};

var()   EResupplyType       ResupplyType; //Who this volume will resupply

var     array<Pawn>         ResupplyActors;

simulated function PostBeginPlay()
{
    super(Actor).PostBeginPlay();

    SetTimer(1, true);
}

function ProcessActorLeave()
{
    local int i;
    local Pawn P;
    local bool bFound;
    local Pawn R;

    if (ResupplyActors.Length == 0)
        return;

    for (i = 0; i < ResupplyActors.Length; ++i)
    {
        if (ResupplyActors[i] == none)
            continue;

        R = ResupplyActors[i];

        foreach VisibleCollidingActors(class'Pawn', P, 300.0)
        {
            // This stops us from the vehicle resupplying itself.
            if (Base != none && Base == P)
                continue;

            bFound = false;

            if (P == R)
            {
                bFound = true;
                break;
            }
        }

        if (!bFound)
        {
            if (DH_Pawn(R) != none)
                DH_Pawn(R).bTouchingResupply = false;
            else if (Vehicle(R) != none)
                Vehicle(R).LeftResupply();
        }
    }
}

function Timer()
{
    local Pawn recvr;
    local inventory recvr_inv;
    local ROWeapon recvr_weapon;
    local bool bResupplied;
//  local bool bEnemyGrenadeFound, bEnemySmokeFound; // not used
    local DH_Pawn P;
    local Vehicle V;
    local DH_RoleInfo DHRI;

    ProcessActorLeave();

    ResupplyActors.Remove(0, ResupplyActors.Length);

    foreach VisibleCollidingActors(class'Pawn', recvr, 300.0)
    {
        // This stops us from the vehicle resupplying itself.
        if (Base != none && Base == P)
            continue;

        if (Team==OWNER_Neutral || recvr.GetTeamNum()==Team)
        {
            bResupplied = false;
            P = DH_Pawn(recvr);
            V = Vehicle(recvr);

            if (P != none && (ResupplyType == RT_Players || ResupplyType == RT_All))
            {
                //Add him into our resupply list.
                ResupplyActors[ResupplyActors.Length] = P;

                if (!P.bTouchingResupply)
                    P.bTouchingResupply = true;
            }
            else if (V != none && (ResupplyType == RT_Vehicles || ResupplyType == RT_All))
            {
                ResupplyActors[ResupplyActors.Length] = V;

                if (!V.bTouchingResupply)
                    V.bTouchingResupply = true;
            }

            if (Level.TimeSeconds - recvr.LastResupplyTime >= UpdateTime)
            {
                if (P != none)
                    DHRI = P.GetRoleInfo();

                if (P != none && (ResupplyType == RT_Players || ResupplyType == RT_All))
                {
                    //Resupply weapons
                    for (recvr_inv = P.Inventory; recvr_inv != none; recvr_inv = recvr_inv.Inventory)
                    {
                        recvr_weapon = ROWeapon(recvr_inv);

                        if (recvr_weapon.IsGrenade())
                        {
                            continue;
                        }

                        if (recvr_weapon != none && recvr_weapon.FillAmmo())
                        {
                            bResupplied = true;
                        }
                    }

                    if (DHRI != none)
                    {
                        if (!P.bHasMGAmmo && DHRI.bCarriesMGAmmo)
                        {
                            P.bHasMGAmmo = true;
                            bResupplied = true;
                        }

                        if (!P.bHasATAmmo && DHRI.bCarriesATAmmo)
                        {
                            P.bHasATAmmo = true;

                            bResupplied = true;
                        }
                    }
                }

                if (V != none && (ResupplyType == RT_Vehicles || ResupplyType == RT_All))
                {

                    // Resupply vehicles
                    if (V.ResupplyAmmo())
                        bResupplied = true;
                }

                //Mortar specific resupplying.
                if (P != none && (ResupplyType == RT_Mortars || ResupplyType == RT_All) && DHRI != none)
                {
                    if (DHRI.bCanUseMortars)
                    {
                        P.FillMortarAmmunition();
                        bResupplied = true;
                    }

                    if (!P.bHasMortarAmmo && DHRI.bCarriesMortarAmmo)
                    {
                        P.bHasMortarAmmo = true;
                        bResupplied = true;
                    }
                }

                //Play sound if applicable
                if (bResupplied)
                {
                    recvr.LastResupplyTime = Level.TimeSeconds;
                    recvr.ClientResupplied();
                }
            }
        }
    }
}

event Destroyed()
{
    local int i;
    local Pawn P;

    super.Destroyed();

    for (i = 0; i < ResupplyActors.Length; ++i)
    {
        if (ResupplyActors[i] == none)
            continue;

        P = ResupplyActors[i];

        if (DH_Pawn(P) != none)
            DH_Pawn(P).bTouchingResupply = false;
        else if (Vehicle(P) != none)
            Vehicle(P).LeftResupply();
    }
}

event Touch(Actor Other)
{
    local ROPawn ROP;
    local Vehicle V;

    ROP = ROPawn(Other);
    V = Vehicle(Other);

    // This stops us from the vehicle resupplying itself.
    if (Base != none && Base == Other)
        return;

    if (ROP != none)
    {
        if (Team == OWNER_Neutral ||
           (ROP.PlayerReplicationInfo != none && ROP.PlayerReplicationInfo.Team != none
           && ((ROP.PlayerReplicationInfo.Team.TeamIndex == AXIS_TEAM_INDEX && Team == OWNER_Axis) ||
               (ROP.PlayerReplicationInfo.Team.TeamIndex == ALLIES_TEAM_INDEX && Team == OWNER_Allies))))
        {
            ROP.bTouchingResupply = true;
        }
    }

    if (V != none)
    {
        if (Team == OWNER_Neutral ||
           ((V.GetTeamNum() == AXIS_TEAM_INDEX && Team == OWNER_Axis) ||
            (V.GetTeamNum() == ALLIES_TEAM_INDEX && Team == OWNER_Allies)))
        {
            V.EnteredResupply();
        }
    }
}

event UnTouch(Actor Other)
{
    local ROPawn ROP;
    local Vehicle V;

    ROP = ROPawn(Other);
    V = Vehicle(Other);

    // This stops us from the vehicle resupplying itself.
    if (Base != none && Base == Other)
        return;

    if (ROP != none)
    {
        ROP.bTouchingResupply = false;
    }

    if (V != none)
    {
        V.LeftResupply();
    }
}

defaultproperties
{
    Team=OWNER_Neutral
    UpdateTime=5.0
    ResupplyType=RT_All
    bDramaticLighting=true
    CollisionRadius=300
    CollisionHeight=100
}