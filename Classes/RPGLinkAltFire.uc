class RPGLinkAltFire extends LinkAltFire;

function Projectile SpawnProjectile(Vector Start, Rotator Dir)
{
    local RPGLinkProjectile Proj;
	
	//TAM support
    if(Level.Game.IsA('Team_GameBase') && !LinkGun(Weapon).Linking)
		class'Util'.static.IncreaseTAMWeaponFireStats(Weapon.Instigator.PlayerReplicationInfo, "Link", "Primary");

    Start += Vector(Dir) * 10.0 * LinkGun(Weapon).Links;
    Proj = RPGLinkProjectile(Weapon.Spawn(ProjectileClass,,, Start, Dir)); //~pd
    if ( Proj != None )
    {
		Proj.Links = LinkGun(Weapon).Links;
		Proj.LinkAdjust();
		
		Proj.bOLTeamGames = RPGLinkGun(Weapon).bOLTeamGames;
		
		if(Proj.bOLTeamGames)
		{
			Proj.TeamIndex = Weapon.Instigator.PlayerReplicationInfo.Team.TeamIndex;
			Proj.TeamAdjust();
		}
	}
    return Proj;
}

function FlashMuzzleFlash()
{
	if(RPGLinkGun(Weapon).bOLTeamGames)
	{
		if (FlashEmitter != None)
		{
			switch(Weapon.Instigator.PlayerReplicationInfo.Team.TeamIndex)
			{
				case 0:
					FlashEmitter.Skins[0] = FinalBlend(DynamicLoadObject("OLTeamGamesTex.LinkGun.LinkMuzProjRedFB", class'FinalBlend'));
					break;
				case 1:
					FlashEmitter.Skins[0] = FinalBlend(DynamicLoadObject("OLTeamGamesTex.LinkGun.LinkMuzProjBlueFB", class'FinalBlend'));;
					break;
				case 2:
					FlashEmitter.Skins[0] = FinalBlend'XEffectMat.LinkMuzProjGreenFB';
					break;
				case 3:
					FlashEmitter.Skins[0] = FinalBlend'XEffectMat.LinkMuzProjYellowFB';
					break;
			}
		}
		Super(ProjectileFire).FlashMuzzleFlash();
	}
	else
	{
		Super.FlashMuzzleFlash();
	}
}

defaultproperties
{
	ProjectileClass=Class'RPGLinkProjectile'
}
