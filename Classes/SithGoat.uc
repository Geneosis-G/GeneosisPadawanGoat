class SithGoat extends GGMutator
	config(Geneosis);

var config bool isSithGoatUnlocked;
var array< SithGoatComponent > mComponents;

/**
 * if the mutator should be selectable in the Custom Game Menu.
 */
static function bool IsUnlocked( optional out array<AchievementDetails> out_CachedAchievements )
{
	return default.isSithGoatUnlocked;
}

/**
 * Unlock the mutator
 */
static function UnlockSithGoat()
{
	if(!default.isSithGoatUnlocked)
	{
		PostJuice( "Unlocked Sith Goat" );
		default.isSithGoatUnlocked=true;
		static.StaticSaveConfig();
	}
}

function static PostJuice( string text )
{
	local GGGameInfo GGGI;
	local GGPlayerControllerGame GGPCG;
	local GGHUD localHUD;

	GGGI = GGGameInfo( class'WorldInfo'.static.GetWorldInfo().Game );
	GGPCG = GGPlayerControllerGame( GGGI.GetALocalPlayerController() );

	localHUD = GGHUD( GGPCG.myHUD );

	if( localHUD != none && localHUD.mHUDMovie != none )
	{
		localHUD.mHUDMovie.AddJuice( text );
	}
}


/**
 * See super.
 */
function ModifyPlayer(Pawn Other)
{
	local GGGoat goat;
	local SithGoatComponent sithComp;

	super.ModifyPlayer( other );

	goat = GGGoat( other );
	if( goat != none )
	{
		sithComp=SithGoatComponent(GGGameInfo( class'WorldInfo'.static.GetWorldInfo().Game ).FindMutatorComponent(class'SithGoatComponent', goat.mCachedSlotNr));
		//WorldInfo.Game.Broadcast(self, "ghostComp=" $ ghostComp);
		if(sithComp != none && mComponents.Find(sithComp) == INDEX_NONE)
		{
			mComponents.AddItem(sithComp);
		}
	}
}

simulated event Tick( float delta )
{
	local int i;

	for( i = 0; i < mComponents.Length; i++ )
	{
		mComponents[ i ].Tick( delta );
	}
	super.Tick( delta );
}

DefaultProperties
{
	mMutatorComponentClass=class'SithGoatComponent'
}