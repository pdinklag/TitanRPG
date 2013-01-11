class RPGLinkAttachment extends LinkAttachment;

simulated function UpdateLinkColor()
{
	local RPGLinkGun LinkGun;
	
	LinkGun = RPGLinkGun(Instigator.Weapon);

	if(LinkGun != None && LinkGun.bOLTeamGames)
	{
		LinkGun.UpdateLinkColor(LinkColor);

		if (MuzFlash != None)
		{
			switch (LinkColor)
			{
				//OLTeamGames support
				case LC_Red:
					MuzFlash.Skins[0] = FinalBlend(DynamicLoadObject("OLTeamGamesTex.LinkGun.LinkMuzProjRedFB", class'FinalBlend'));
					break;
					
				case LC_Blue:
					MuzFlash.Skins[0] = FinalBlend(DynamicLoadObject("OLTeamGamesTex.LinkGun.LinkMuzProjBlueFB", class'FinalBlend'));
					break;
			
				case LC_Gold:
					MuzFlash.Skins[0] = FinalBlend'XEffectMat.LinkMuzProjYellowFB';
					break;
					
				case LC_Green:
				default:
					MuzFlash.Skins[0] = FinalBlend'XEffectMat.LinkMuzProjGreenFB';
					break;
			}
		}
	}
	else
	{
		Super.UpdateLinkColor();
	}
}

//OLTeamGames support
simulated event ThirdPersonEffects()
{
	local RPGLinkGun LinkGun;
    local rotator R;
	
	LinkGun = RPGLinkGun(Instigator.Weapon);
	if(LinkGun != None && LinkGun.bOLTeamGames)
	{
		if ( Level.NetMode != NM_DedicatedServer && FlashCount > 0 )
		{
			if (FiringMode == 0)
			{
				if (MuzFlash == None)
				{
					MuzFlash = Spawn(class'LinkMuzFlashProj3rd');
					AttachToBone(MuzFlash, 'tip');
					UpdateLinkColor();
				}
				if (MuzFlash != None)
				{
					MuzFlash.mSizeRange[0] = MuzFlash.default.mSizeRange[0] * (class'LinkFire'.default.LinkScale[Min(Links,5)]+1); // (1.0 + 0.3*float(Links));
					MuzFlash.mSizeRange[1] = MuzFlash.mSizeRange[0];

					switch (Instigator.PlayerReplicationInfo.Team.TeamIndex)
					{
						case 0  : SetLinkColor( LC_Red );   break;
						case 1  : SetLinkColor( LC_Blue );  break;
						case 2  : SetLinkColor( LC_Green ); break;
						case 3  : SetLinkColor( LC_Gold );  break;
					}

					MuzFlash.Trigger(self, None);
					R.Roll = Rand(65536);
					SetBoneRotation('bone flashA', R, 0, 1.0);
				}
			}
		}

		super(xWeaponAttachment).ThirdPersonEffects();
	}
	else
	{
		Super.ThirdPersonEffects();
	}
}

defaultproperties
{
}
