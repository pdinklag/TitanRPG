class RPGTransFire extends TransFire;

var float TossForceScale;

function Projectile SpawnProjectile(Vector Start, Rotator Dir)
{
    local Projectile TransBeacon;

	if(Weapon.IsA('OLTeamsTranslauncher') && TransLauncher(Weapon).TransBeacon == None)
	{
		//OLTeamGames support
        if((Instigator == None) || (Instigator.PlayerReplicationInfo == None) || (Instigator.PlayerReplicationInfo.Team == None))
            TransBeacon = Weapon.Spawn(class'TransBeacon',,, Start, Dir);
        else if(Instigator.PlayerReplicationInfo.Team.TeamIndex == 0)
            TransBeacon = Weapon.Spawn(class'RedBeacon',,, Start, Dir);
        else if(Instigator.PlayerReplicationInfo.Team.TeamIndex == 1)
            TransBeacon = Weapon.Spawn(class'BlueBeacon',,, Start, Dir);
        else if(Instigator.PlayerReplicationInfo.Team.TeamIndex == 2)
            TransBeacon = Weapon.Spawn(class<Projectile>(DynamicLoadObject("OLTeamGames.OLTeamsGreenBeacon", class'Class')),,, Start, Dir);
        else if(Instigator.PlayerReplicationInfo.Team.TeamIndex == 3)
            TransBeacon = Weapon.Spawn(class<Projectile>(DynamicLoadObject("OLTeamGames.OLTeamsGoldBeacon", class'Class')),,, Start, Dir);
		
        TransLauncher(Weapon).TransBeacon = TransBeacon(TransBeacon);
        Weapon.PlaySound(TransFireSound, SLOT_Interact,,,,, false);
	}
	else
	{
		TransBeacon = Super.SpawnProjectile(Start, Dir);
	}
	
	if(TransBeacon != None)
		TransBeacon.Velocity *= class'MutTitanRPG'.static.Instance(Level).GameSettings.TransTossForceScale * TossForceScale;
	
    return TransBeacon;
}

//Preserve the spawn protection
event ModeDoFire()
{
	local xPawn xInstigator;
	
	local bool bInstigatorSpawnDone;
	local bool bInstigatorSpawnIn;
	local float InstigatorSpawnTime;
	
	if(Weapon.Role == ROLE_Authority && xPawn(Instigator) != None)
	{
		xInstigator = xPawn(Instigator);
	
		bInstigatorSpawnDone = xInstigator.bSpawnDone;
		bInstigatorSpawnIn = xInstigator.bSpawnIn;
		InstigatorSpawnTime = xInstigator.SpawnTime;
	}
	
	Super.ModeDoFire();
	
    if(Weapon.Role == ROLE_Authority &&
		xInstigator != None &&
		!bInstigatorSpawnDone &&
		Level.TimeSeconds - InstigatorSpawnTime < DeathMatch(Level.Game).SpawnProtectionTime)
	{
		xInstigator.SpawnTime = InstigatorSpawnTime;
		xInstigator.bSpawnIn = bInstigatorSpawnIn;
		xInstigator.bSpawnDone = false;
		
		xInstigator.SetOverlayMaterial(
			xInstigator.ShieldHitMat,
			DeathMatch(Level.Game).SpawnProtectionTime - (Level.TimeSeconds - xInstigator.SpawnTime),
			true);
	}
}

defaultproperties
{
	TossForceScale=1.000000
}
