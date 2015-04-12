//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2015
//==============================================================================

class DHBulletHitEffect extends ROBulletHitEffect;

simulated function PostNetBeginPlay()
{
    local ESurfaceTypes ST;
    local vector HitLoc, HitNormal;
    local Material HitMat;

    if (Level.NetMode == NM_DedicatedServer)
    {
        return;
    }

    //Velocity
    Trace(HitLoc, HitNormal, Location + vector(Rotation) * 16, Location, false,, HitMat);

    ST = EST_Default;

    if (HitMat != none)
    {
        ST = ESurfaceTypes(HitMat.SurfaceType);
    }

    if (HitEffects[ST].HitDecal != none)
    {
        Spawn(HitEffects[ST].HitDecal, self,, Location, Rotation);
    }

    if (HitEffects[ST].HitSound != none)
    {
        PlaySound(HitEffects[ST].HitSound, SLOT_None, 30.0, false, 100.0);
    }

    if (HitEffects[ST].HitEffect != none)
    {
        Spawn(HitEffects[ST].HitEffect,,, HitLoc, rotator(HitNormal));
    }
}

defaultproperties
{
}