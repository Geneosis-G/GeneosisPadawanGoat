class LightSaber extends GGPhotonSword;

var PadawanGoatComponent mPadawanComp;

var bool mIsActive;

var array<StaticMesh> mSwordMeshes;
var int mSwordColorIndex;
var vector mBaseTraceOffsetStart;
var vector mBaseTraceOffsetEnd;

simulated event PostBeginPlay()
{
	Super.PostBeginPlay();
	mBaseTraceOffsetStart=mTraceOffsetStart;
	mBaseTraceOffsetEnd=mTraceOffsetEnd;
	// Sword start hidden
	mIsActive = false;
	SetPhysics(PHYS_None);
	SetHidden(true);
	SetCollision(false, false);
	SetCollisionType(COLLIDE_NoCollision);
	StaticMeshComponent.SetLightEnvironment( GGGoat(Owner).mesh.LightEnvironment );
	StaticMeshComponent.SetActorCollision(false, false);
	StaticMeshComponent.SetBlockRigidBody(false);
	StaticMeshComponent.SetNotifyRigidBodyCollision(false);
	// No burn when invisible
	mBurnVelocityThreshold=1000000000;
}

function RegisterComponent(PadawanGoatComponent pgComp)
{
	mPadawanComp = pgComp;
}

function ShowSword()
{
	if(mIsActive)
		return;

	SetHidden(false);
	SetCollision(true, true);
	SetCollisionType(COLLIDE_BlockAll);
	StaticMeshComponent.SetActorCollision(true, true);
	StaticMeshComponent.SetBlockRigidBody(true);
	StaticMeshComponent.SetNotifyRigidBodyCollision(true);
	// Burn when visible
	mBurnVelocityThreshold=-1;

	if( !mSwordHumAC.IsPlaying() )
	{
		mSwordHumAC.FadeIn( 0.7f, 1.0f );

		if( mSwordTurnOnSound != none )
		{
			mSwordTurnOnSound.PitchMultiplier = mSwordHumAC.PitchMultiplier;

			PlaySound( mSwordTurnOnSound );
		}
	}
	mIsActive = true;
}

function HideSword(optional bool hideEffects = true)
{
	if(!mIsActive)
		return;

	SetHidden(true);
	SetCollision(false, false);
	SetCollisionType(COLLIDE_NoCollision);
	StaticMeshComponent.SetActorCollision(false, false);
	StaticMeshComponent.SetBlockRigidBody(false);
	StaticMeshComponent.SetNotifyRigidBodyCollision(false);
	// No burn when invisible
	mBurnVelocityThreshold=1000000000;

	if( mSwordHumAC.IsPlaying() )
	{
		mSwordHumAC.FadeOut( 0.2f, 0.0f );

		if( mSwordTurnOffSound != none )
		{
			mSwordTurnOffSound.PitchMultiplier = mSwordHumAC.PitchMultiplier;

			PlaySound( mSwordTurnOffSound );
		}
	}
	mIsActive = false;
}

function SetSwordTranslation(float radius)
{
	local vector newTrans;//, traceStart, traceEnd;

	newTrans=StaticMeshComponent.default.Translation;
	newTrans.X = newTrans.X + radius;
	StaticMeshComponent.SetTranslation(newTrans);

	mTraceOffsetStart=vect(0, 0, 0);
	mTraceOffsetEnd=vect(0, 0, 0);
	mTraceOffsetStart.X=mBaseTraceOffsetStart.Z + StaticMeshComponent.Translation.X;
	mTraceOffsetEnd.X=mBaseTraceOffsetEnd.Z + StaticMeshComponent.Translation.X;

	//traceStart = Location + (mTraceOffsetStart >> Rotation);
	//traceEnd = Location + (mTraceOffsetEnd >> Rotation);
 	//DrawDebugSphere( traceStart, 5.0f, 16, 255, 0, 0, false );
 	//DrawDebugSphere( traceEnd, 5.0f, 16, 0, 0, 255, false );
}

// No grab for this special sword
function OnGrabbed( Actor grabbedByActor );
function OnDropped( Actor droppedByActor );

function SetNextSwordColor()
{
	if(!mIsActive)
		return;

	mSwordColorIndex++;
	if(mSwordColorIndex >= mSwordMeshes.length)
	{
		mSwordColorIndex = 0;
	}
	SetSwordColor(mSwordColorIndex);
}

function SetSwordColor(int index)
{
	if(!mIsActive)
		return;

	mSwordColorIndex = index;
	SetStaticMesh(mSwordMeshes[mSwordColorIndex], StaticMeshComponent.Translation, StaticMeshComponent.Rotation, StaticMeshComponent.Scale3D);
}

simulated event Tick( float delta )
{
	local GGPawn gpawn;

	// Try to prevent pawns from walking on it
	foreach BasedActors(class'GGPawn', gpawn)
	{
		gpawn.Velocity.Z=0;
		ApplySwordDamages(gpawn, gpawn.Location - (vect(0, 0, 1) * gpawn.GetCollisionHeight()), vect(0, 0, 1));
	}
	// Set physics back to none if actor walked on it
	SetPhysics(PHYS_None);

	//Override parent tick
	BurnActors();
}

function BurnActors()
{
	local Actor hitActor;
	local bool burntSomething;
	local vector hitLocation, hitNormal, traceEnd, traceStart;

	if( `TimeSince( mBurnTimestamp ) > mBurnDelay && (VSizeSq( Velocity ) > mBurnVelocityThreshold) )
	{
		traceStart = Location + (mTraceOffsetStart >> Rotation);
		traceEnd = Location + (mTraceOffsetEnd >> Rotation);

		foreach TraceActors( class'Actor', hitActor, hitLocation, hitNormal, traceEnd, traceStart )
		{
			if( hitActor != none && hitActor != self && hitActor != Owner && !hitActor.bHidden)
			{
				ApplySwordDamages(hitActor, hitLocation, hitNormal);
				burntSomething = true;
			}
		}

		// Since it's possible multiple things can be burned the same frame, make sure to only do some effects once
		if( burntSomething )
		{
			PlaySound( mBurnSoundCue );
			WorldInfo.MyEmitterPool.SpawnEmitter( mBurnParticle, hitLocation, rotator( -hitNormal ) );
		}

		mBurnTimestamp = WorldInfo.TimeSeconds;
	}
}

function ApplySwordDamages(Actor hitActor, vector hitLocation, vector hitNormal)
{
	local GGPawn gpawn;
	local GGNPCMMOEnemy mmoEnemy;
	local GGNpcZombieGameModeAbstract zombieEnemy;
	local GGKactor kActor;
	local GGSVehicle vehicle;
	local GGApexDestructibleActor apexActor;

	WorldInfo.MyDecalManager.SpawnDecal( mBurnDecalMaterial,
									 hitLocation - hitNormal * 30.f,
									 rotator( -hitNormal ),
									 mBurnDecalSize,
									 mBurnDecalSize,
									 mBurnDecalThickness,
									 false,//bNoClip
									 ,//DecalRotation
									 GetMainComponent(hitActor),//HitComponent
									 ,//bProjectOnTerrain
									 true,//bProjectOnSkeletalMeshes
									 ,//HitBone
									 ,//HitNodeIndex
									 ,//HitLevelIndex
									 30,//DecalLifeSpan
									 ,//InFracturedStaticMeshComponentIndex
									 -0.000001f //InDepthBias
									 );

	gpawn = GGPawn(hitActor);
	mmoEnemy = GGNPCMMOEnemy(hitActor);
	zombieEnemy = GGNpcZombieGameModeAbstract(hitActor);
	kActor = GGKActor(hitActor);
	vehicle = GGSVehicle(hitActor);
	apexActor=GGApexDestructibleActor(hitActor);
	if(gpawn != none)
	{
		//Damage MMO enemies
		if(mmoEnemy != none)
		{
			mmoEnemy.TakeDamageFrom( 100, Owner, class'GGDamageTypeExplosiveActor');
		}
		//Damage zombies
		else if(zombieEnemy != none)
		{
			zombieEnemy.TakeDamage( 100, GGGoat(Owner).Controller, hitLocation, hitNormal * 500.f, class'GGDamageTypeZombieSurvivalMode' );
		}
		else
		{
			gpawn.TakeDamage( 100, GGGoat(Owner).Controller, hitLocation, hitNormal * 500.f, mBurnDamageType,, Owner);
		}
		if(!gpawn.mIsRagdoll)
		{
			gpawn.SetRagdoll(true);
		}
		mPadawanComp.OnPawnAttacked(gpawn);
	}
	if(kActor != none)
	{
		kActor.TakeDamage( 100, GGGoat(Owner).Controller, hitLocation, hitNormal * 500.f, mBurnDamageType,, Owner);
	}
	else if(vehicle != none)
	{
		vehicle.TakeDamage( 100, GGGoat(Owner).Controller, hitLocation, hitNormal * 500.f, mBurnDamageType,, Owner);
	}
	else if(apexActor != none)
	{
		if(!apexActor.mIsFractured)
		{
			apexActor.Fracture(0, none, hitLocation, hitNormal * 500.f, class'GGDamageTypeAbility');
		}
	}
}

function PrimitiveComponent GetMainComponent(Actor targetAct)
{
	local PrimitiveComponent mainComponent;
	local GGKAsset targetKA;
	local StaticMeshActor targetSMA;
	local DynamicSMActor targetDSMA;
	local ApexDestructibleActor targetADA;
	local Pawn targetPawn;

	if(targetAct == none)
	{
		return none;
	}

	mainComponent = targetAct.CollisionComponent;
	targetSMA = StaticMeshActor(targetAct);
	targetDSMA = DynamicSMActor(targetAct);
	targetADA = ApexDestructibleActor(targetAct);
	targetPawn = Pawn(targetAct);
	targetKA = GGKAsset(targetAct);

	if(targetSMA != none)
	{
		mainComponent=targetSMA.StaticMeshComponent;
	}
	else if(targetDSMA != none)
	{
		mainComponent=targetDSMA.StaticMeshComponent;
	}
	else if(targetADA != none)
	{
		mainComponent=targetADA.StaticDestructibleComponent;
	}
	else if(targetPawn != none)
	{
		mainComponent=targetPawn.mesh;
	}
	else if(targetKA != none)
	{
		mainComponent=targetKA.SkeletalMeshComponent;
	}

	return mainComponent;
}

DefaultProperties
{
	bNoDelete=false
	bStatic=false
	bIgnoreBaseRotation=true
	mBlockCamera=false

	Begin Object name=StaticMeshComponent0
		StaticMesh=StaticMesh'Space_Props.Meshes.Lightsaber_02_OnlyHandleCollision'
		bNotifyRigidBodyCollision = true
		ScriptRigidBodyCollisionThreshold = 1
        CollideActors = true
        BlockActors = true
		Rotation=(Pitch=-16384, Yaw=0, Roll=0)
		Translation=(X=100, Y=0, Z=0)
	End Object

	mSwordMeshes.Add(StaticMesh'Space_Props.Meshes.Lightsaber_02_OnlyHandleCollision')
	mSwordMeshes.Add(StaticMesh'Space_Props.Meshes.Lightsaber_03')
	mSwordMeshes.Add(StaticMesh'Space_Props.Meshes.Lightsaber_04')
	mSwordMeshes.Add(StaticMesh'Space_Props.Meshes.Lightsaber_05')
	mSwordMeshes.Add(StaticMesh'Space_Props.Meshes.Lightsaber_06')
	mSwordMeshes.Add(StaticMesh'Space_Props.Meshes.Lightsaber_01')
}