//Hack fix for Link Gun so you can link with RPGWeapons that have LinkGun as their ModifiedWeapon
//TODO still needed?
class RPGLinkGun extends LinkGun
	HideDropDown
	CacheExempt;

var bool bOLTeamGames;

replication
{
	reliable if(Role == ROLE_Authority && bNetInitial)
		bOLTeamGames;
}

simulated event PostBeginPlay()
{
	if(Role == ROLE_Authority)
		bOLTeamGames = Level.Game.IsA('OLTeamGame');

	Super.PostBeginPlay();
}

//OLTeamGames support
simulated event RenderOverlays( Canvas Canvas )
{
	if(bOLTeamGames && ThirdPersonActor != None)
	{
		switch(Instigator.PlayerReplicationInfo.Team.TeamIndex)
		{
			case 0:
				LinkAttachment(ThirdPersonActor).SetLinkColor( LC_Red );
				break;
			case 1:
				LinkAttachment(ThirdPersonActor).SetLinkColor( LC_Blue );
				break;
			case 2:
				LinkAttachment(ThirdPersonActor).SetLinkColor( LC_Green );
				break;
			case 3:
				LinkAttachment(ThirdPersonActor).SetLinkColor( LC_Gold );
				break;
			default:
				LinkAttachment(ThirdPersonActor).SetLinkColor( LC_Green );
				break;
		}

		super(Weapon).RenderOverlays( Canvas );
	}
	else
	{
		Super.RenderOverlays(Canvas);
	}
}

defaultproperties
{
	FireModeClass(0)=Class'RPGLinkAltFire'
	FireModeClass(1)=Class'RPGLinkFire'
	PickupClass=Class'RPGLinkGunPickup'
	AttachmentClass=Class'RPGLinkAttachment'
}
