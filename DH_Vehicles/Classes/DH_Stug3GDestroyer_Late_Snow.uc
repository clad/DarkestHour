//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2016
//==============================================================================

class DH_Stug3GDestroyer_Late_Snow extends DH_Stug3GDestroyer_Late;

#exec OBJ LOAD FILE=..\Textures\DH_VehiclesGE_tex3.utx

defaultproperties
{
    DestroyedVehicleMesh=StaticMesh'DH_German_vehicles_stc.Stug3.stug3g_destlate'
    Skins(0)=texture'DH_VehiclesGE_tex3.ext_vehicles.stug3g_body_snow'
    Skins(1)=texture'DH_VehiclesGE_tex3.ext_vehicles.stug3g_armor_snow'
    DestroyedMeshSkins(0)=Combiner'DH_VehiclesGE_tex3.Destroyed.stug3g_snow_dest' // don't have a destroyed mesh for whitewashed late StuG, so just re-skin the summer camo model
    DestroyedMeshSkins(1)=Combiner'DH_VehiclesGE_tex3.Destroyed.stug3g_snowarmor_dest'
    CannonSkins(0)=texture'DH_VehiclesGE_tex3.ext_vehicles.stug3g_body_snow'
}
