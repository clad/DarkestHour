//==============================================================================
// Darkest Hour: Europe '44-'45
// Darklight Games (c) 2008-2016
//==============================================================================

class DH_GreyhoundArmoredCar extends DHArmoredVehicle;

#exec OBJ LOAD FILE=..\Animations\DH_Greyhound_anm.ukx
#exec OBJ LOAD FILE=..\Textures\DH_VehiclesUS_tex4.utx
#exec OBJ LOAD FILE=..\StaticMeshes\DH_allies_vehicles_stc3.usx

defaultproperties
{
    // Properties from the old DHArmoredCar class
    bSpecialTankTurning=false
    PointValue=2.0
    HeavyEngineDamageThreshold=0.25
    DriverKillChance=900.0
    GunnerKillChance=900.0
    CommanderKillChance=600.0
    GunDamageChance=1000.0
    TraverseDamageChance=1250.0

    bHasTreads=false
    bIsApc=true
    MaxCriticalSpeed=1077.0 // 64 kph
    UFrontArmorFactor=1.6
    URightArmorFactor=0.9
    ULeftArmorFactor=0.9
    URearArmorFactor=0.9
    VehicleHudTurret=TexRotator'DH_InterfaceArt_tex.Tank_Hud.Greyhound_turret_rot'
    VehicleHudTurretLook=TexRotator'DH_InterfaceArt_tex.Tank_Hud.Greyhound_turret_look'
    FrontLeftAngle=332.0
    RearLeftAngle=208.0
    WheelPenScale=1.2
    WheelLatSlipFunc=(Points=(,(InVal=30.0,OutVal=0.009),(InVal=45.0),(InVal=10000000000.0)))
    WheelLongFrictionScale=1.1
    WheelLatFrictionScale=1.55
    WheelSuspensionTravel=10.0
    WheelSuspensionMaxRenderTravel=5.0
    ChassisTorqueScale=0.095
    MaxSteerAngleCurve=(Points=((OutVal=20.0),(InVal=500.0,OutVal=20.0),(InVal=600.0,OutVal=15.0),(InVal=1000000000.0,OutVal=10.0)))
    GearRatios(3)=0.6
    GearRatios(4)=0.75
    ChangeUpPoint=1990.0
    ChangeDownPoint=1000.0
    SteerSpeed=75.0
    TurnDamping=100.0
    SteerBoneName="Drive_wheel"
    ExhaustEffectClass=class'ROEffects.ExhaustPetrolEffect'
    ExhaustEffectLowClass=class'ROEffects.ExhaustPetrolEffect_simple'
    ExhaustPipes(0)=(ExhaustPosition=(X=-170.0,Y=34.0,Z=45.0),ExhaustRotation=(Pitch=34000,Yaw=-5000))
    PassengerWeapons(0)=(WeaponPawnClass=class'DH_Vehicles.DH_GreyhoundCannonPawn',WeaponBone="Turret_placement")
    PassengerPawns(0)=(AttachBone="body",DrivePos=(X=-125.0,Y=-70.0,Z=105.0),DriveRot=(Yaw=-16384),DriveAnim="VHalftrack_Rider4_idle")
    PassengerPawns(1)=(AttachBone="body",DrivePos=(X=-165.0,Y=-35.0,Z=105.0),DriveRot=(Yaw=32768),DriveAnim="VHalftrack_Rider4_idle")
    PassengerPawns(2)=(AttachBone="body",DrivePos=(X=-165.0,Y=35.0,Z=105.0),DriveRot=(Yaw=32768),DriveAnim="VHalftrack_Rider5_idle")
    PassengerPawns(3)=(AttachBone="body",DrivePos=(X=-125.0,Y=75.0,Z=105.0),DriveRot=(Yaw=16384),DriveAnim="VHalftrack_Rider5_idle")
    IdleSound=SoundGroup'Vehicle_Engines.sdkfz251.sdkfz251_engine_loop'
    StartUpSound=sound'Vehicle_Engines.sdkfz251.sdkfz251_engine_start'
    ShutDownSound=sound'Vehicle_Engines.sdkfz251.sdkfz251_engine_stop'
    DestroyedVehicleMesh=StaticMesh'DH_allies_vehicles_stc3.M8_Greyhound.M8_Destroyed'
    DisintegrationHealth=-100000.0
    DamagedEffectScale=0.75
    DamagedEffectOffset=(X=-130.0,Y=0.0,Z=100.0)
    FireEffectOffset=(X=5.0,Y=5.0,Z=0.0)
    VehicleTeam=1
    SteeringScaleFactor=2.0
    BeginningIdleAnim="driver_hatch_idle_close"
    DriverPositions(0)=(PositionMesh=SkeletalMesh'DH_Greyhound_anm.Greyhound_body_int',TransitionUpAnim="Overlay_Out",ViewPitchUpLimit=2730,ViewPitchDownLimit=60065,ViewPositiveYawLimit=9500,ViewNegativeYawLimit=-9500,ViewFOV=90.0)
    DriverPositions(1)=(PositionMesh=SkeletalMesh'DH_Greyhound_anm.Greyhound_body_int',TransitionUpAnim="driver_hatch_open",TransitionDownAnim="Overlay_In",DriverTransitionAnim="VBA64_driver_close",ViewPitchUpLimit=9500,ViewPitchDownLimit=60065,ViewPositiveYawLimit=16000,ViewNegativeYawLimit=-16000,ViewFOV=90.0)
    DriverPositions(2)=(PositionMesh=SkeletalMesh'DH_Greyhound_anm.Greyhound_body_int',TransitionDownAnim="driver_hatch_close",DriverTransitionAnim="VBA64_driver_open",ViewPitchUpLimit=9500,ViewPitchDownLimit=62835,ViewPositiveYawLimit=16000,ViewNegativeYawLimit=-16000,bExposed=true,ViewFOV=90.0)
    VehicleHudImage=texture'DH_InterfaceArt_tex.Tank_Hud.greyhound_body'
    VehicleHudOccupantsX(0)=0.45
    VehicleHudOccupantsY(0)=0.35
    VehicleHudOccupantsX(1)=0.5
    VehicleHudOccupantsY(1)=0.5
    VehicleHudOccupantsX(2)=0.375
    VehicleHudOccupantsY(2)=0.75
    VehicleHudOccupantsX(3)=0.45
    VehicleHudOccupantsY(3)=0.8
    VehicleHudOccupantsX(4)=0.55
    VehicleHudOccupantsY(4)=0.8
    VehicleHudOccupantsX(5)=0.625
    VehicleHudOccupantsY(5)=0.75
    VehicleHudEngineX=0.51
    VehHitpoints(0)=(PointBone="Engine",PointOffset=(Z=-10.0)) // engine
    EngineHealth=100
    DriverAttachmentBone="driver_attachment"
    Begin Object Class=SVehicleWheel Name=RFWheel
        SteerType=VST_Steered
        BoneName="wheel_FR"
        BoneRollAxis=AXIS_Y
        BoneOffset=(Y=11.0)
        SupportBoneName="axel_F_R"
        SupportBoneAxis=AXIS_X
    End Object
    Wheels(0)=SVehicleWheel'DH_Vehicles.DH_GreyhoundArmoredCar.RFWheel'
    Begin Object Class=SVehicleWheel Name=LFWheel
        SteerType=VST_Steered
        BoneName="wheel_FL"
        BoneRollAxis=AXIS_Y
        BoneOffset=(Y=-11.0)
        SupportBoneName="axel_F_L"
        SupportBoneAxis=AXIS_X
    End Object
    Wheels(1)=SVehicleWheel'DH_Vehicles.DH_GreyhoundArmoredCar.LFWheel'
    Begin Object Class=SVehicleWheel Name=MRWheel
        bPoweredWheel=true
        BoneName="wheel_MR"
        BoneRollAxis=AXIS_Y
        BoneOffset=(Y=11.0)
        SupportBoneName="axel_M_R"
        SupportBoneAxis=AXIS_X
    End Object
    Wheels(2)=SVehicleWheel'DH_Vehicles.DH_GreyhoundArmoredCar.MRWheel'
    Begin Object Class=SVehicleWheel Name=MLWheel
        bPoweredWheel=true
        BoneName="wheel_ML"
        BoneRollAxis=AXIS_Y
        BoneOffset=(Y=-11.0)
        SupportBoneName="axel_M_L"
        SupportBoneAxis=AXIS_X
    End Object
    Wheels(3)=SVehicleWheel'DH_Vehicles.DH_GreyhoundArmoredCar.MLWheel'
    Begin Object Class=SVehicleWheel Name=RRWheel
        bPoweredWheel=true
        BoneName="wheel_RR"
        BoneRollAxis=AXIS_Y
        BoneOffset=(Y=11.0)
        SupportBoneName="axel_R_R"
        SupportBoneAxis=AXIS_X
    End Object
    Wheels(4)=SVehicleWheel'DH_Vehicles.DH_GreyhoundArmoredCar.RRWheel'
    Begin Object Class=SVehicleWheel Name=LRWheel
        bPoweredWheel=true
        BoneName="wheel_LR"
        BoneRollAxis=AXIS_Y
        BoneOffset=(Y=-11.0)
        SupportBoneName="axel_R_L"
        SupportBoneAxis=AXIS_X
    End Object
    Wheels(5)=SVehicleWheel'DH_Vehicles.DH_GreyhoundArmoredCar.LRWheel'
    VehicleMass=5.0
    DrivePos=(X=10.0,Y=-5.0,Z=2.0)
    DriveAnim="VBA64_driver_idle_close"
    ExitPositions(0)=(X=135.0,Y=-33.0,Z=176.0)  //driver
    ExitPositions(1)=(X=30.0,Y=-5.0,Z=210.0)    //commander
    ExitPositions(2)=(X=-124.0,Y=-161.0,Z=64.0) //passenger (l)
    ExitPositions(3)=(X=-245.0,Y=-42.0,Z=63.0)  //passenger (rl)
    ExitPositions(4)=(X=-249.0,Y=31.0,Z=63.0)   //passenger (rr)
    ExitPositions(5)=(X=-126.0,Y=169.0,Z=64.0)  //passenger (r)
    DriverDamageMult=1.0
    VehicleNameString="M8 Armored Car"
    MaxDesireability=0.1
    PitchUpLimit=500
    PitchDownLimit=58000
    Mesh=SkeletalMesh'DH_Greyhound_anm.Greyhound_body_ext'
    Skins(0)=texture'DH_VehiclesUS_tex4.ext_vehicles.Greyhound_body_ext'
    Skins(1)=texture'DH_VehiclesUS_tex4.ext_vehicles.Greyhound_turret_ext'
    Skins(2)=texture'DH_VehiclesUS_tex4.ext_vehicles.Greyhound_wheels'
    CollisionRadius=175.0
    CollisionHeight=60.0
    Begin Object Class=KarmaParamsRBFull Name=KParams0
        KInertiaTensor(0)=1.3
        KInertiaTensor(3)=3.0
        KInertiaTensor(5)=3.0
        KCOMOffset=(X=0.3,Z=-0.525) // default is X=0.0, Z=-0.5
        KLinearDamping=0.05
        KAngularDamping=0.05
        KStartEnabled=true
        bKNonSphericalInertia=true
        bHighDetailOnly=false
        bClientOnly=false
        bKDoubleTickRate=true
        bDestroyOnWorldPenetrate=true
        bDoSafetime=true
        KFriction=0.5
        KImpactThreshold=700.0
    End Object
    KParams=KarmaParamsRBFull'DH_Vehicles.DH_GreyhoundArmoredCar.KParams0'
    SpawnOverlay(0)=Material'DH_InterfaceArt_tex.Vehicles.m8_greyhound'
}
