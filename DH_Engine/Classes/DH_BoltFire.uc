//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2014
//==============================================================================

class DH_BoltFire extends DH_ProjectileFire;

// Overriden to support our recoil system
event ModeDoFire()
{
    if (!AllowFire())
        return;

    if (MaxHoldTime > 0.0)
        HoldTime = FMin(HoldTime, MaxHoldTime);

    // server
    if (Weapon.Role == ROLE_Authority)
    {
        Weapon.ConsumeAmmo(ThisModeNum, Load);
        DoFireEffect();
        HoldTime = 0;   // if bot decides to stop firing, HoldTime must be reset first
        if ((Instigator == none) || (Instigator.Controller == none))
            return;

        if (AIController(Instigator.Controller) != none)
            AIController(Instigator.Controller).WeaponFireAgain(BotRefireRate, true);

        Instigator.DeactivateSpawnProtection();
    }

    // client
    if (Instigator.IsLocallyControlled())
    {
        if (!bDelayedRecoil)
            HandleRecoil();
        else
            SetTimer(DelayedRecoilTime, false);


        ShakeView();
        PlayFiring();

        if (!bMeleeMode)
        {
            if (Instigator.IsFirstPerson() && !bAnimNotifiedShellEjects)
                EjectShell();
            FlashMuzzleFlash();
            StartMuzzleSmoke();
        }
    }
    else // server
    {
        ServerPlayFiring();
    }

    Weapon.IncrementFlashCount(ThisModeNum);
    Weapon.PostFire();

    Load = AmmoPerFire;
    HoldTime = 0;

    if (Instigator.PendingWeapon != Weapon && Instigator.PendingWeapon != none)
    {
        bIsFiring = false;
        Weapon.PutDown();
    }
}

defaultproperties
{
     PctRestDeployRecoil=0.650000
     bDelayedRecoil=true
     DelayedRecoilTime=0.050000
     bAnimNotifiedShellEjects=true
}