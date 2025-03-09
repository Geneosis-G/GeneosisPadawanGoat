class PadawanGoatComponent extends GGMutatorComponent;

var GGGoat gMe;
var GGMutator myMut;

var bool isAttackPressed;

var bool isAttacking;

var LightSaber sword;

var int mAttacksToUnlockMutator;
var array<GGPawn> mAttackedInnocents;
var array<GGPawn> mAttackedEnemies;

/**
 * See super.
 */
function AttachToPlayer( GGGoat goat, optional GGMutator owningMutator )
{
	super.AttachToPlayer(goat, owningMutator);

	if(mGoat != none)
	{
		gMe=goat;
		myMut=owningMutator;

		sword=gMe.Spawn(class'LightSaber', gMe,,,,, true);
		sword.RegisterComponent(self);
	}
}

function KeyState( name newKey, EKeyState keyState, PlayerController PCOwner )
{
	local GGPlayerInputGame localInput;

	if(PCOwner != gMe.Controller)
		return;

	localInput = GGPlayerInputGame( PCOwner.PlayerInput );

	if( keyState == KS_Down )
	{
		if(localInput.IsKeyIsPressed("LeftMouseButton", string( newKey )) || newKey == 'XboxTypeS_RightTrigger')
		{
			//myMut.WorldInfo.Game.Broadcast(myMut, "LeftMouseButton pressed");
			isAttackPressed = true;
			StartAttacking();
		}

		if(localInput.IsKeyIsPressed("GBA_AbilityBite", string( newKey )))
		{
			if(GGPlayerControllerGame( gMe.Controller ).mFreeLook)
			{
				sword.SetNextSwordColor();
			}
		}
	}
	else if( keyState == KS_Up )
	{
		if(localInput.IsKeyIsPressed("LeftMouseButton", string( newKey )) || newKey == 'XboxTypeS_RightTrigger')
		{
			//myMut.WorldInfo.Game.Broadcast(myMut, "LeftMouseButton released");
			isAttackPressed = false;
			StopAttacking();
		}
	}
}

function StartAttacking()
{
	if(gMe.mIsRagdoll)
		return;

	if(isAttacking)
		return;

	isAttacking	= true;

	sword.ShowSword();
}

function StopAttacking()
{
	if(!isAttacking)
		return;

	isAttacking	= false;

	sword.HideSword();
}

function Tick( float delta )
{
	ManageSword();
	// Don't use sword and shield when driving
	if(gMe.DrivenVehicle != none)
	{
		if(isAttacking)
		{
			isAttackPressed = false;
			StopAttacking();
		}
	}
}

function OnRagdoll( Actor ragdolledActor, bool isRagdoll )
{
	if(ragdolledActor == gMe && isRagdoll)
	{
		StopAttacking();
	}
}

function ManageSword()
{
	local vector camLocation;
	local rotator camRotation, newRot;

	if(gMe.Controller != none)
	{
		GGPlayerControllerGame( gMe.Controller ).PlayerCamera.GetCameraViewPoint( camLocation, camRotation );
	}
	else
	{
		camLocation=gMe.Location;
		camRotation=gMe.Rotation;
	}

	newRot = camRotation;
	newRot.Pitch += 8192;
	sword.SetRotation( newRot );

	sword.SetSwordTranslation(gMe.GetCollisionRadius());

	if(sword.Location != gMe.Location)
	{
		sword.SetLocation(gMe.Location);
		sword.SetBase(gMe);
	}
}

function OnPawnAttacked(GGPawn gpawn)
{
	// Only kills in one category to unlock
	if(mAttackedEnemies.length > 0 && mAttackedInnocents.length > 0)
		return;

	// No controller, attack doesn't count
	if(GGAIController(gpawn.Controller) == none)
		return;

	if(IsEnemyPawn(gpawn))
	{
		if(!class'JediGoat'.static.IsUnlocked())
		{
			if(mAttackedEnemies.Find(gpawn) == INDEX_NONE)
			{
				mAttackedEnemies.AddItem(gpawn);
				if(mAttackedEnemies.length >= mAttacksToUnlockMutator)
				{
					class'JediGoat'.static.UnlockJediGoat();
				}
			}
		}
	}
	else
	{
		if(!class'SithGoat'.static.IsUnlocked())
		{
			if(mAttackedInnocents.Find(gpawn) == INDEX_NONE)
			{
				mAttackedInnocents.AddItem(gpawn);
				if(mAttackedInnocents.length >= mAttacksToUnlockMutator)
				{
					class'SithGoat'.static.UnlockSithGoat();
				}
			}
		}
	}
}

function bool IsEnemyPawn(GGPawn gpawn)
{
	local GGAIController AIContr;

	AIContr=GGAIController(gpawn.Controller);

	return (GGGoat(AIContr.mPawnToAttack) != none
	     || GGAIControllerAgressive(AIContr) != none
		 || GGAIControllerGangMember(AIContr) != none
		 || GGAIControllerMMOEnemy(AIContr) != none
		 || GGChihuahuaTurretAIController(AIContr) != none
		 || GGAIControllerZombieGM(AIContr) != none);
}

defaultproperties
{
	mAttacksToUnlockMutator=20
}