class JediGoat extends GGMutator
	config(Geneosis);

var config bool isJediGoatUnlocked;
var array< JediGoatComponent > mComponents;

/**
 * if the mutator should be selectable in the Custom Game Menu.
 */
static function bool IsUnlocked( optional out array<AchievementDetails> out_CachedAchievements )
{
	return default.isJediGoatUnlocked;
}

/**
 * Unlock the mutator
 */
static function UnlockJediGoat()
{
	if(!default.isJediGoatUnlocked)
	{
		PostJuice( "Unlocked Jedi Goat" );
		default.isJediGoatUnlocked=true;
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
	local JediGoatComponent jediComp;

	super.ModifyPlayer( other );

	goat = GGGoat( other );
	if( goat != none )
	{
		jediComp=JediGoatComponent(GGGameInfo( class'WorldInfo'.static.GetWorldInfo().Game ).FindMutatorComponent(class'JediGoatComponent', goat.mCachedSlotNr));
		//WorldInfo.Game.Broadcast(self, "ghostComp=" $ ghostComp);
		if(jediComp != none && mComponents.Find(jediComp) == INDEX_NONE)
		{
			mComponents.AddItem(jediComp);
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
	mMutatorComponentClass=class'JediGoatComponent'
}