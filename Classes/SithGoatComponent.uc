class SithGoatComponent extends GGAbstractForceGoatComponentImproved;

/** Replacement sound for goats baa */
var SoundCue mFatherGoatBaaSound;

var SoundCue mFatherGoatBreathingSound;
var AudioComponent mFatherGoatBreatingAC;

/**
 * See super.
 */
function AttachToPlayer( GGGoat goat, optional GGMutator owningMutator )
{
	super.AttachToPlayer( goat, owningMutator );

	if( mGoat != none )
	{
		mGoat.mBaaSoundCue = mFatherGoatBaaSound;

		mFatherGoatBreatingAC = mGoat.CreateAudioComponent( mFatherGoatBreathingSound, false );

		if( GGGoatSpace( mGoat ) != none )
		{
			GGGoatSpace( mGoat ).mCanAttachSpaceHelmet = false;
			GGGoatSpace( mGoat ).ToggleSpaceHelmet( false );

			GGGoatSpace( mGoat ).mShouldPlayDialogueBaa = false;
		}
	}
}

function SetGripMove( bool enabled )
{
	super.SetGripMove( enabled );

	if( !enabled && !mForceGripEnabled)
	{
		if( mFatherGoatBreatingAC != none && mFatherGoatBreatingAC.IsPlaying() && !mFatherGoatBreatingAC.IsFadingOut() )
		{
			mFatherGoatBreatingAC.FadeOut( 1.5f, 0.0f);
		}
	}
	else if( enabled && mForceGripEnabled )
	{
		if( mFatherGoatBreatingAC != none )
		{
			if( mFatherGoatBreatingAC.IsFadingOut() )
			{
				mFatherGoatBreatingAC.Stop();
			}

			if( !mFatherGoatBreatingAC.IsPlaying() )
			{
				mFatherGoatBreatingAC.Play();
			}
		}
	}
}

DefaultProperties
{
	Begin Object class=StaticMeshComponent name=helmetMesh
		StaticMesh=StaticMesh'Space_FatherGoat.Meshes.FatherGoat_Helmet'
		Translation=(X=0, Y=3.9f, Z=2.15f)
	End Object
	mDecorationAttachments( 0 )=(MeshComponent=helmetMesh, AttachSocket="hairSocket")

	Begin Object class=SkeletalMeshComponent Name=capeMesh
		SkeletalMesh=SkeletalMesh'Space_FatherGoat.Meshes.FatherGoat_Cape'
		PhysicsAsset=PhysicsAsset'Space_FatherGoat.Materials.FatherGoat_Cape_Physics'
		bHasPhysicsAssetInstance=true
	End Object
	mDecorationAttachments( 1 )=(MeshComponent=capeMesh, AttachSocket="CapeSocket", BonesToRagdoll[ 0 ]="Body_Joint")

	mFatherGoatBaaSound=SoundCue'Space_FatherGoat_Sounds.Baa.FatherGoat_Baa_Cue'
	mFatherGoatBreathingSound=SoundCue'Space_FatherGoat_Sounds.Breathing.FatherGoat_Breathing_Loop_Cue'

	mGripVictimMaxCount=0
}