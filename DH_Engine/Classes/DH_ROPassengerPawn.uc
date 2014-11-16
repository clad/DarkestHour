//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2014
//==============================================================================

class DH_ROPassengerPawn extends ROPassengerPawn;

/*
Matt UK, November 2014 - added new system to avoid rider pawns needing to exist on net clients unless rider position is occupied
Each rider pawn that exists on a client is a net channel that has to be maintained & updated by the server.
The new system can substantially cut down the number of net channels & associated replication, especially in maps with lots of vehicles.
We toggle the bTearOff flag for each rider pawn when it is unoccupied/occupied, which causes the usual clientside simulated actors to spawn or be destroyed.
When bTearOff is set, the actor stops being net relevant & the server closes the channel, stops replicating the actor & destroys the clientside version.
The trick is to stop the actor from actually being torn off on the client, otherwise that causes us big problems & breaks the system.
There is a built-in delay of 5 seconds before the server decides the actor isn't net relevant, closes the channel & destroys the clientside actor.
If a player switches back to the old rider position within these 5 secs, we need them to re-occupy the existing rider pawn & abort closing the channel.
I've found a way to achieve this is to delay the next NetUpdateTime to be >5 seconds in the future, which delays bTearOff from replicating to clients.
That way the server closes the channel & destroys the clientside actor before bTearOff is sent to the client, so it never actually gets torn off.
And if a player re-enters the rider position during these 5 secs, we just change bTearOff back to false & it becomes net relevant again.
A further complication is when a player exits a rider pawn, we need to introduce a very short delay before setting bTearOff on server, so a 0.5 sec timer is used.
This is necessary to allow properties updated on exit (e.g. Owner, Driver & PRI all none) to replicate to clients before shutting down all net traffic.
Changes in other classes: slight modifications to functions NumPassengers in DH_ROTreadCraft & DrawVehicleIcon in DHHud, to work with new system & avoid errors.
*/

struct ExitPositionPair
{
    var int Index;
    var float DistanceSquared;
};

var bool bDebugExitPositions;

static final operator(24) bool > (ExitPositionPair A, ExitPositionPair B)
{
    return A.DistanceSquared > B.DistanceSquared;
}

//http://wiki.beyondunreal.com/Legacy:Insertion_Sort
static final function InsertSortEPPArray(out array<ExitPositionPair> MyArray, int LowerBound, int UpperBound)
{
    local int InsertIndex, RemovedIndex;

    if (LowerBound < UpperBound)
    {
        for (RemovedIndex = LowerBound + 1; RemovedIndex <= UpperBound; ++RemovedIndex)
        {
            InsertIndex = RemovedIndex;

            while (InsertIndex > LowerBound && MyArray[InsertIndex - 1] > MyArray[RemovedIndex])
            {
                --InsertIndex;
            }

            if ( RemovedIndex != InsertIndex )
            {
                MyArray.Insert(InsertIndex, 1);
                MyArray[InsertIndex] = MyArray[RemovedIndex + 1];
                MyArray.Remove(RemovedIndex + 1, 1);
            }
        }
    }
}

// Modified to set bTearOff to true on a server, which stops this rider pawn being replicated to clients (until entered, when we unset bTearOff)
simulated function PostBeginPlay()
{
	super.PostBeginPlay();

	if (Level.NetMode == NM_DedicatedServer || Level.NetMode == NM_ListenServer)
	{
		bTearOff = true;
	}
}

// Overridden to stop the game playing silly buggers with exit positions while moving and breaking my damage code
function bool PlaceExitingDriver()
{
    local int i;
    local vector Extent, HitLocation, HitNormal, ZOffset, ExitPosition;
    local array<ExitPositionPair> ExitPositionPairs;

    if (Driver == none)
    {
        return false;
    }

    Extent = Driver.default.CollisionRadius * vect(1, 1, 0);
    Extent.Z = Driver.default.CollisionHeight;
    ZOffset = Driver.default.CollisionHeight * vect(0, 0, 0.5);

    if (VehicleBase == none)
    {
        return false;
    }

    ExitPositionPairs.Length = VehicleBase.ExitPositions.Length;

    for (i = 0; i < VehicleBase.ExitPositions.Length; ++i)
    {
        ExitPositionPairs[i].Index = i;
        ExitPositionPairs[i].DistanceSquared = VSizeSquared(DrivePos - VehicleBase.ExitPositions[i]);
    }

    InsertSortEPPArray(ExitPositionPairs, 0, ExitPositionPairs.Length - 1);

    if (bDebugExitPositions)
    {
        for (i = 0; i < ExitPositionPairs.Length; ++i)
        {
            ExitPosition = VehicleBase.Location + (VehicleBase.ExitPositions[ExitPositionPairs[i].Index] >> VehicleBase.Rotation) + ZOffset;

            Spawn(class'RODebugTracer',,,ExitPosition);
        }
    }

    for (i = 0; i < ExitPositionPairs.Length; ++i)
    {
        ExitPosition = VehicleBase.Location + (VehicleBase.ExitPositions[ExitPositionPairs[i].Index] >> VehicleBase.Rotation) + ZOffset;

        if (Trace(HitLocation, HitNormal, ExitPosition, VehicleBase.Location + ZOffset, false, Extent) != none ||
            Trace(HitLocation, HitNormal, ExitPosition, ExitPosition + ZOffset, false, Extent) != none)
        {
            continue;
        }

        if (Driver.SetLocation(ExitPosition))
        {
            Level.Game.Broadcast(self, ExitPosition);

            return true;
        }
    }

    return false;
}

// Overridden to set passenger exit rotation to be the same as when they were in the vehicle - looks a bit silly otherwise
simulated function ClientKDriverLeave(PlayerController PC)
{
    local rotator NewRot;

    NewRot = GetVehicleBase().Rotation;
    NewRot.Pitch = LimitPitch(NewRot.Pitch);
    SetRotation(NewRot);

    super.ClientKDriverLeave(PC);
}

// Modified to unset bTearOff on a server, which makes this rider pawn potentially relevant to clients & always to the one entering the rider position
function KDriverEnter(Pawn P)
{
    if (Level.NetMode == NM_DedicatedServer || Level.NetMode == NM_ListenServer)
    {
        SetTimer(0.0, false); // clear any timer, so we don't risk setting bTearOff to true again just after we enter
        bTearOff = false;     // don't need to do quick net update as normal entering sequence already does it
    }

    super.KDriverEnter(P);
}

// Overridden to give players the same momentum as their vehicle had when exiting
// Adds a little height kick to allow for hacked in damage system
function bool KDriverLeave(bool bForceLeave)
{
    local vector OldVel;
    local bool   bSuperDriverLeave;

    if (!bForceLeave)
    {
        OldVel = VehicleBase.Velocity;

        bSuperDriverLeave = super.KDriverLeave(bForceLeave);

        OldVel.Z += 50;
        Instigator.Velocity = OldVel;
    }
    else
    {
        bSuperDriverLeave = super.KDriverLeave(bForceLeave);
    }

    return bSuperDriverLeave;
}

// Modified to call DriverLeft (which calls DrivingStatusChanged) because player death doesn't trigger KDriverLeave-DriverLeft
function DriverDied()
{
    super.DriverDied();

    if (Health > 0) // means player has died but the vehicle hasn't been destroyed (ROVehicle adds the same for vehicles)
    {
        DriverLeft();
    }
}

// Modified to set bTearOff to true (after a short timer) on a server when player exits, which kills off the clientside actor & closes the net channel
// Need to use timer to add short delay, to allow properties updated on exit (e.g. Owner, Driver & PRI all none) to replicate to client before shutting down all net traffic
simulated event DrivingStatusChanged()
{
    super.DrivingStatusChanged();

    if (!bDriving && (Level.NetMode == NM_DedicatedServer || Level.NetMode == NM_ListenServer))
    {
        SetTimer(0.5, false);
    }
}

// Sets bTearOff to true on a server when player exits, purely so server decides the actor is no longer net relevant, kills off the clientside actor & closes the net channel
// But we don't want the clientside actor to actually get torn off, as that would cause us big problems, so we have to stop bTearOff from reaching the client
// So we delay the next update to the client for longer than the server's 5 second delay before it kills a clientside actor after it becomes net irrelevant
function Timer()
{
    if (!bDriving && !bTearOff && (Level.NetMode == NM_DedicatedServer || Level.NetMode == NM_ListenServer))
    {
        NetUpdateTime = Level.TimeSeconds + (6.0 * Level.Game.GameSpeed);
        bTearOff = true;
    }
}

function bool TryToDrive(Pawn P)
{
    if (VehicleBase != none)
    {
        if (VehicleBase.NeedsFlip())
        {
            VehicleBase.Flip(vector(P.Rotation), 1);

            return false;
        }

        if (P.GetTeamNum() != VehicleBase.VehicleTeam)
        {
            if (VehicleBase.Driver == none)
            {
                return VehicleBase.TryToDrive(P);
            }

            DenyEntry( P, 1 );

            return false;
        }

        if (VehicleBase.Driver == none && !P.IsHumanControlled())
        {
            return VehicleBase.TryToDrive(P);
        }
    }

    return super(Vehicle).TryToDrive(P);
}

// Modified to add clientside checks before sending the function call to the server
// Optimises network performance generally & specifically avoids a rider camera bug when unsuccessfully trying to switch to another vehicle position
simulated function SwitchWeapon(byte F)
{
    local  ROVehicleWeaponPawn  WeaponPawn;
    local  bool                 bMustBeTankerToSwitch;
    local  byte                 ChosenWeaponPawnIndex;

    if (VehicleBase != none)
    {
        if (F == 1)
        {
            // Stop call to server as driver position already has a human player
            if (VehicleBase.Driver != none && VehicleBase.Driver.IsHumanControlled())
            {
                return;
            }

            if (VehicleBase.bMustBeTankCommander)
            {
                bMustBeTankerToSwitch = true;
            }
        }
        else
        {
            ChosenWeaponPawnIndex = F - 2;

            // Stop call to server if player has selected an invalid weapon position or the current position
            if (ChosenWeaponPawnIndex >= VehicleBase.PassengerWeapons.Length || ChosenWeaponPawnIndex == PositionInArray)
            {
                return;
            }

            if (ChosenWeaponPawnIndex < VehicleBase.WeaponPawns.Length)
            {
                WeaponPawn = ROVehicleWeaponPawn(VehicleBase.WeaponPawns[ChosenWeaponPawnIndex]);
            }

            if (WeaponPawn != none)
            {
                // Stop call to server as weapon position already has a human player
                if (WeaponPawn.Driver != none && WeaponPawn.Driver.IsHumanControlled())
                {
                    return;
                }

                if (WeaponPawn.bMustBeTankCrew)
                {
                    bMustBeTankerToSwitch = true;
                }
            }
            // Stop call to server if weapon pawn doesn't exist, UNLESS PassengerWeapons array lists it as a rider position
            // This is because our new system means rider pawns won't exist on clients unless occupied, so we have to allow this switch through to server
            else if (class<ROPassengerPawn>(VehicleBase.PassengerWeapons[ChosenWeaponPawnIndex].WeaponPawnClass) == none)
            {
                return;
            }
        }

        // Stop call to server if player has selected a tank crew role but isn't a tanker
        if (bMustBeTankerToSwitch && (Controller == none || ROPlayerReplicationInfo(Controller.PlayerReplicationInfo) == none || 
            ROPlayerReplicationInfo(Controller.PlayerReplicationInfo).RoleInfo == none || !ROPlayerReplicationInfo(Controller.PlayerReplicationInfo).RoleInfo.bCanBeTankCrew))
        {
            ReceiveLocalizedMessage(class'DH_VehicleMessage', 0);
            return;
        }

        ServerChangeDriverPosition(F);
    }
}

defaultproperties
{
    WeaponFov=80.000000
    bSinglePositionExposed=true
    bAllowViewChange=false
    bDesiredBehindView=false
    DriverDamageMult=1.000000
    bKeepDriverAuxCollision=true
    bDebugExitPositions=true
}