class JediGoatComponent extends GGAbstractForceGoatComponentImproved;

var ParticleSystem mGoodGoatForceGripParticle;

/**
 * See super.
 */
function AttachToPlayer( GGGoat goat, optional GGMutator owningMutator )
{
	super.AttachToPlayer( goat, owningMutator );

	if( mGoat != none )
	{
		mForceHoldPos.mForceGripPC.SetTemplate( mGoodGoatForceGripParticle );
	}
}

DefaultProperties
{
	Begin Object class=SkeletalMeshComponent Name=capeMesh
		SkeletalMesh=SkeletalMesh'Space_JediGoat.Meshes.JediGoat_Cape'
		PhysicsAsset=PhysicsAsset'Space_FatherGoat.Materials.FatherGoat_Cape_Physics'
		bHasPhysicsAssetInstance=true
	End Object
	mDecorationAttachments( 0 )=(MeshComponent=capeMesh, AttachSocket="CapeSocket", BonesToRagdoll[ 0 ]="Body_Joint")

	Begin Object class=SkeletalMeshComponent Name=braidMesh
		SkeletalMesh=SkeletalMesh'Space_JediGoat.Meshes.JediBraid_Rig'
		PhysicsAsset=PhysicsAsset'Space_JediGoat.Meshes.JediBraid_Physics'
		bHasPhysicsAssetInstance=true
	End Object
	mDecorationAttachments( 1 )=(MeshComponent=braidMesh, AttachSocket="BraidSocket", BonesToRagdoll[ 0 ]="Braid_02")

	mForceConeHalfAngle=0.65 // cirka 37 degrees
	mForceConeRadius=1000.0f
	mForceStrength=4000.0f

	mGoodGoatForceGripParticle=ParticleSystem'Space_Particles.Particles.GoodGoat_ForceGrip_PS'

	mGripVictimMaxCount=1
}