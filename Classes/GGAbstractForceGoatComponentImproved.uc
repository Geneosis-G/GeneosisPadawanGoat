class GGAbstractForceGoatComponentImproved extends GGAbstractForceGoatComponent
	abstract;

var float mInputXThisFrame;
var float mInputYThisFrame;

function Tick( float delta )
{
	if(PlayerController( mGoat.Controller ) != none
	&& GGLocalPlayer(PlayerController( mGoat.Controller ).Player) != none)
	{
		if(GGLocalPlayer(PlayerController( mGoat.Controller ).Player).mIsUsingGamePad)
		{
			mInputXThisFrame = PlayerController( mGoat.Controller ).PlayerInput.aLookUp * -400.f;
			mInputYThisFrame = PlayerController( mGoat.Controller ).PlayerInput.aTurn * 400.f;
		}
		else
		{
			// for some reason X and Y need to be reversed
			mInputXThisFrame = PlayerController( mGoat.Controller ).PlayerInput.aMouseY * 40.f;
			mInputYThisFrame = PlayerController( mGoat.Controller ).PlayerInput.aMouseX * 40.f;
		}
	}
	//mOwningMutator.WorldInfo.Game.Broadcast(mOwningMutator, "mInputXThisFrame=" $ mInputXThisFrame);
	//mOwningMutator.WorldInfo.Game.Broadcast(mOwningMutator, "mInputYThisFrame=" $ mInputYThisFrame);
	//mOwningMutator.WorldInfo.Game.Broadcast(mOwningMutator, "=================================");
}

function SetGripMove( bool enabled )
{
	local int i;
	local float colRad, colHei, objectWheightCounter;
	// Only release grip if left click is pressed when right click is released
	if( !enabled && mGripMoveEnabled && mForceGripEnabled && mGripForwardDirection)
	{
		if( GGGoatSpace( mGoat ) != None )
		{
			GGGoatSpace( mGoat ).GotoState( 'MasterState' );
		}

		for (i = 0; i < mGripVictims.Length; i++)
		{
			mVictimMaterial = GGScoreActorInterface( mGripVictims[i] ).GetPhysMat();

			mGripVictims[i].GetBoundingCylinder( colRad, colHei );
			objectWheightCounter = ( ( colRad^2 ) * pi * colHei ) * mVictimMaterial.density; //Kactor.GetMass()

			mGripVictims[i].TakeDamage( 0, mGoat.Controller, mGripVictims[i].location, ( VSizeSq( mGripVictims[i].Location - mForceHoldPos.Location ) >= 3000.0f**2 ? mGripVictims[i].velocity : Normal( mGripVictims[i].Location - mGoat.Location ) * mNoVelExtraPush ) * objectWheightCounter/50000, mForceDamageClass, , mGoat );

			if( GGNpc( mGripVictims[i] ) != none )
			{
				GGNpc( mGripVictims[i] ).EnableStandUp( class'GGNpc'.const.SOURCE_FORCEGRIP );
			}

			if( GGPhotonSwordAbstract( mGripVictims[i] ) != none )
			{
				GGPhotonSwordAbstract( mGripVictims[i] ).OnDropped( mGoat );
			}
		}

		if( mForcePushSound != none )
		{
			mGoat.PlaySound( mForcePushSound,,,, mGoat.Location );
		}

		mForceHoldPos.ToggleForceGripParticle( false );
		mForceHoldPos.PlayForcePushParticle();

		DisableGrip();
	}
	else if( enabled && !mGripMoveEnabled && mForceGripEnabled )
	{
		mNumberOfGripMoves++;

		if( GGGoatSpace( mGoat ) != None )
		{
			GGGoatSpace( mGoat ).GotoState( 'ForceGripState' );
		}
	}

	//ToggleGripHint( enabled );
	ToggleGripMoveHint( false );

	mGripMoveEnabled = enabled;
}

function ToggleMouseForwardDirection( bool isDirectionForward )
{
	mGripForwardDirection = isDirectionForward;

	if( mGoat != None && mGoat.Controller != None && GGPlayerControllerGameSpace( mGoat.Controller ) != none )
	{
		GGPlayerControllerGameSpace( mGoat.Controller ).ResetSavedInput();
	}
	else
	{
		mInputXThisFrame = 0;
		mInputYThisFrame = 0;
	}
}

function DisableGrip()
{
	mGripVictims.Length = 0;

	if( GGGoatSpace( mGoat ) != None )
	{
		GGGoatSpace( mGoat ).GotoState( 'MasterState' );
	}

	ToggleMouseForwardDirection( false );

	mForceGripEnabled = false;
	mGripMoveEnabled = false;

	mSavedGripVertical = 0;
	mSavedGripHorizontal = 0;
	mMouseXSavedOffset = 0;
	mMouseYSavedOffset = 0;
}

simulated event TickMutatorComponent( float delta )
{
	local vector outVector;
	local rotator outRotator;
	local vector forceDirection;

	local vector lastPosition;

	local float newXVal;
	local float newYVal;

	local vector xtmp, ytmp, ztmp;

	local int i;
	//mOwningMutator.WorldInfo.Game.Broadcast(mOwningMutator, "#####################################");
	if( mForceGripEnabled )
	{
		//mOwningMutator.WorldInfo.Game.Broadcast(mOwningMutator, "mInputXThisFrame=" $ mInputXThisFrame);
		//mOwningMutator.WorldInfo.Game.Broadcast(mOwningMutator, "mInputYThisFrame=" $ mInputYThisFrame);
		//mOwningMutator.WorldInfo.Game.Broadcast(mOwningMutator, "#####################################");
		//Use head position to get bitchslap goat!
		//mOwningMutator.WorldInfo.Game.Broadcast(mOwningMutator, "1");
		if( !mGripMoveEnabled )
		{
			//mOwningMutator.WorldInfo.Game.Broadcast(mOwningMutator, "2");
			ToggleMouseForwardDirection( false );

			if( GGPlayerControllerGameSpace( mGoat.Controller ) != none )
			{
				GGPlayerControllerGameSpace( mGoat.Controller ).ResetSavedInput();
			}
			else
			{
				mInputXThisFrame = 0;
				mInputYThisFrame = 0;
			}

			mGoat.mesh.GetSocketWorldLocationAndRotation( 'headSocket', outVector, outRotator );
			outVector += ( outVector - mGoat.location ) * 2;

			mForceHoldPos.SetRotation( mgoat.Rotation );
			mForceHoldPos.SetLocation( outvector );
			// Keep the offset even when grip is inactive
			mForceHoldPos.GetAxes( mForceHoldPos.Rotation, xtmp, ytmp, ztmp );
			mForceHoldPos.SetLocation( mForceHoldPos.Location + ( ( ytmp * mMouseYSavedOffset/20 ) + ( ztmp * mSavedGripVertical/20 ) + ( xtmp * mSavedGripHorizontal/20 ) ) );

		}
		else
		{
			//mOwningMutator.WorldInfo.Game.Broadcast(mOwningMutator, "3");
			if( GGPlayerControllerGameSpace( mGoat.Controller ) != none )
			{
				newXVal = GGPlayerControllerGameSpace( mgoat.Controller ).InputXThisFrame;
				newYVal = GGPlayerControllerGameSpace( mgoat.Controller ).InputYThisFrame;
			}
			else
			{
				newXVal = mInputXThisFrame;
				newYVal = mInputYThisFrame;
			}

			mGoat.mesh.GetSocketWorldLocationAndRotation( 'neckTraceEnd', outVector, outRotator );

			outVector += ( outVector - mGoat.location ) * 1.7;

			mForceHoldPos.SetRotation( mGoat.Rotation );
			mForceHoldPos.SetLocation( outvector );

			lastPosition = mForceHoldPos.Location;

			mForceHoldPos.GetAxes( mForceHoldPos.Rotation, xtmp, ytmp, ztmp );

			if( newYVal != 0 )
			{
				//mOwningMutator.WorldInfo.Game.Broadcast(mOwningMutator, "newYVal=" $ newYVal);
				if( CheckPositionAngle( mgoat.location.x, ( mForceHoldPos.Location + ( ( ytmp * ( mMouseYSavedOffset + newYVal )/20 ) + ( ztmp * mSavedGripVertical/20 ) + ( xtmp * mSavedGripHorizontal/20 ) ) ).x , false ) )
				{
					//mOwningMutator.WorldInfo.Game.Broadcast(mOwningMutator, "mMouseYSavedOffset=" $ mMouseYSavedOffset);
					mMouseYSavedOffset += newYVal;
				}
			}

			mForceHoldPos.SetRotation( mgoat.Rotation );

			if( mGripForwardDirection )
			{
				//mOwningMutator.WorldInfo.Game.Broadcast(mOwningMutator, "newXVal=" $ newXVal);
				if( CheckPositionAngle( mgoat.location.y, ( mForceHoldPos.Location + ( ( ytmp * mMouseYSavedOffset/20 ) + ( ztmp * mSavedGripVertical/20 ) + ( xtmp * ( mSavedGripHorizontal + newXVal )/20 ) ) ).y, false ) )
				{
					//mOwningMutator.WorldInfo.Game.Broadcast(mOwningMutator, "mSavedGripHorizontal=" $ mSavedGripHorizontal);
					mSavedGripHorizontal += newXVal;
				}
			}
			else
			{
				//mOwningMutator.WorldInfo.Game.Broadcast(mOwningMutator, "newXVal=" $ newXVal);
				if( CheckPositionAngle( mgoat.location.z, ( mForceHoldPos.Location + ( ( ytmp * mMouseYSavedOffset/20 ) + ( ztmp * ( mSavedGripVertical + newXVal )/20 ) + ( xtmp * mSavedGripHorizontal/20 ) ) ).z, true) )
				{
					//mOwningMutator.WorldInfo.Game.Broadcast(mOwningMutator, "mSavedGripVertical=" $ mSavedGripVertical);
					mSavedGripVertical += newXVal;
				}
			}

			//mOwningMutator.WorldInfo.Game.Broadcast(mOwningMutator, "LocBefore=" $ mForceHoldPos.Location);
			mForceHoldPos.SetLocation( mForceHoldPos.Location + ( ( ytmp * mMouseYSavedOffset/20 ) + ( ztmp * mSavedGripVertical/20 ) + ( xtmp * mSavedGripHorizontal/20 ) ) );
			//mOwningMutator.WorldInfo.Game.Broadcast(mOwningMutator, "LocAfter=" $ mForceHoldPos.Location);

			mForceHoldPos.UpdateForceGripSoundPitch( delta, VSize( mForceHoldPos.Location - lastPosition ) );

			if( GGGoatSpace( mGoat ) != none )
			{
				GGGoatSpace( mGoat ).UpdateForceGripArms( delta, mForceHoldPos.Location );
			}
		}

		for (i = 0; i < mGripVictims.Length; i++)
		{
			forceDirection = Normal( mGripVictims[i].Location - mForceHoldPos.Location );

			if( VSize( mGripVictims[i].Location - mForceHoldPos.location ) > 50.0f)
			{
				mGripVictims[i].TakeDamage( 0, mGoat.Controller,  mGripVictims[i].Location, mForceStrength * -forceDirection, mForceDamageClass, , mGoat );
			}
			else
			{
				mGripVictims[i].CollisionComponent.SetRBLinearVelocity( vect( 0, 0, 0 ) );
				mGripVictims[i].TakeDamage( 0, mGoat.Controller,  mGripVictims[i].Location, ( mForceStrength ) * -forceDirection, mForceDamageClass, , mGoat );
			}
		}
	}

	if( mGripVictims.Length <= 0 )
	{
		SetGripMove( false );
	}

	CheckIfVictimHasBeenDestroyed();

`if(`notdefined(IS_STEAM_VERSION))
		//@TODO GNG ACHIEVEMENT
		//`log("UNLOCKED ForceChoke ACHIEVEMENT!");
`endif

}

function CheckIfVictimHasBeenDestroyed()
{
	local int i;

	for (i = 0; i < mGripVictims.length; i++)
	{
		if( mGripVictims[i] == none || mGripVictims[i].bPendingDelete || mGripVictims[i].bHidden )
		{
			mGripVictims.RemoveItem( mGripVictims[i] );
		}
	}
}

defaultproperties
{

}