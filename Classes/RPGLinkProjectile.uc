//OLTeamGames support
class RPGLinkProjectile extends LinkProjectile;

var bool bOLTeamGames;
var int TeamIndex;

replication
{
	reliable if (bNetInitial && Role == ROLE_Authority)
		bOLTeamGames;

    unreliable if (bNetInitial && Role == ROLE_Authority)
        TeamIndex;
}

simulated function TeamAdjust()
{
    if (bOLTeamGames && TeamIndex < 4)
    {
        if ( Trail != None )
            RPGLinkTrail(Trail).TeamColorAdjust(TeamIndex);
        switch(TeamIndex)
        {
            case 0:
                Skins[0] = FinalBlend(DynamicLoadObject("OLTeamGamesTex.LinkGun.LinkProjRedFB", class'FinalBlend'));
                LightHue = 0;
                break;
            case 1:
                Skins[0] = FinalBlend(DynamicLoadObject("OLTeamGamesTex.LinkGun.LinkProjBlueFB", class'FinalBlend'));
                LightHue = 169;
                break;
            case 2:
                Skins[0] = FinalBlend'XEffectMat.LinkProjGreenFB';
                break;
            case 3:
                Skins[0] = FinalBlend'XEffectMat.LinkProjYellowFB';
                LightHue = 40;
                break;
        }
    }
}

simulated function LinkAdjust()
{
    if (bOLTeamGames && Links > 0)
    {
        MaxSpeed = default.MaxSpeed + 350*Links;
    }
	else
	{
		Super.LinkAdjust();
	}
}

simulated event PostNetBeginPlay()
{
    local float dist;
    local PlayerController PC;
	
	if(bOLTeamGames)
	{
		Acceleration = Normal(Velocity) * 3000.0;

		if ( (Level.NetMode != NM_DedicatedServer) && (Level.DetailMode != DM_Low) )
			Trail = Spawn(class'RPGLinkTrail',self);
		if ( (Trail != None) && (Instigator != None) && Instigator.IsLocallyControlled() )
		{
			if ( Role == ROLE_Authority )
				Trail.Delay(0.1);
			else
			{
				dist = VSize(Location - Instigator.Location);
				if ( dist < 100 )
					Trail.Delay(0.1 - dist/1000);
			}
		}

		if (Role < ROLE_Authority)
		{
			LinkAdjust();
			TeamAdjust();
		}
		if ( Level.NetMode == NM_DedicatedServer )
			return;
		if ( Level.bDropDetail || (Level.DetailMode == DM_Low) )
		{
			bDynamicLight = false;
			LightType = LT_None;
		}
		else
		{
			PC = Level.GetLocalPlayerController();
			if ( (PC == None) || (Instigator == None) || (PC != Instigator.Controller) )
			{
				bDynamicLight = false;
				LightType = LT_None;
			}
		}
	}
	else
	{
		Super.PostNetBeginPlay();
	}
}

simulated function Explode(vector HitLocation, vector HitNormal)
{
	if(bOLTeamGames)
	{
		if ( EffectIsRelevant(Location,false) )
		{
			switch(TeamIndex)
			{
				case 0:
					Spawn(class<Actor>(DynamicLoadObject("OLTeamGames.OLTeamsLinkProjSparksRed", class'Class')),,, HitLocation, rotator(HitNormal));
					break;
				case 1:
					Spawn(class<Actor>(DynamicLoadObject("OLTeamGames.OLTeamsLinkProjSparksBlue", class'Class')),,, HitLocation, rotator(HitNormal));
					break;
				case 2:
					Spawn(class'LinkProjSparks',,, HitLocation, rotator(HitNormal));
					break;
				case 3:
					Spawn(class<Actor>(DynamicLoadObject("OLTeamGames.OLTeamsLinkProjSparksGold", class'Class')),,, HitLocation, rotator(HitNormal));
					break;
			}
		}
		PlaySound(Sound'WeaponSounds.BioRifle.BioRifleGoo2');
		Destroy();
	}
	else
	{
		Super.Explode(HitLocation, HitNormal);
	}
}

defaultproperties
{
}
