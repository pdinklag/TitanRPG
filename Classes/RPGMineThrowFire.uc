class RPGMineThrowFire extends ONSMineThrowFire;

var string TeamProjectileClassName[4];

function projectile SpawnProjectile(Vector Start, Rotator Dir)
{
	local Inventory Inv;
	local ONSMineLayer MineLayer;
	local Projectile DestroyedMine;
	local RPGPlayerReplicationInfo RPRI;
    local Projectile p;
    local int x;
	
	RPRI = class'RPGPlayerReplicationInfo'.static.GetFor(Weapon.Instigator.Controller);
	if(RPRI != None)
	{
		ProjectileClass = class<Projectile>(DynamicLoadObject(TeamProjectileClassName[Weapon.Instigator.GetTeamNum()], class'Class'));

		if( ProjectileClass != None )
			p = Weapon.Spawn(ProjectileClass, Weapon,, Start, Dir);

		if( p == None )
			return None;

		p.Damage *= DamageAtten;
		
		if(RPRI.NumMines >= RPRI.MaxMines && RPRI.NumMines > 0)
		{
			DestroyedMine = RPRI.Mines[0];
			
			//remove from all mine layers
			for(Inv = Weapon.Instigator.Inventory; Inv != None; Inv = Inv.Inventory)
			{
				MineLayer = ONSMineLayer(Inv);
				if(MineLayer != None)
				{
					x = 0;
					while(x < MineLayer.Mines.Length)
					{
						if(MineLayer.Mines[x] == DestroyedMine)
						{
							MineLayer.Mines.Remove(x, 1);
							MineLayer.CurrentMines--;
						}
						else if(MineLayer.Mines[x] == None)
						{
							MineLayer.Mines.Remove(x, 1); //cleanup
						}
						else
						{
							x++;
						}
					}
				}
			}
			
			DestroyedMine.Destroy();
		}
		
		RPRI.AddMine(ONSMineProjectile(p));
		ONSMineLayer(Weapon).Mines[ONSMineLayer(Weapon).Mines.Length] = p;
		ONSMineLayer(Weapon).CurrentMines++;

		return p;
	}
	else
	{
		return Super.SpawnProjectile(Start, Dir);
	}
}

defaultproperties
{
	TeamProjectileClassName(0)="Onslaught.ONSMineProjectileRED"
	TeamProjectileClassName(1)="Onslaught.ONSMineProjectileBLUE"
	TeamProjectileClassName(2)="OLTeamGames.OLTeamsONSMineProjectileGREEN"
	TeamProjectileClassName(3)="OLTeamGames.OLTeamsONSMineProjectileGOLD"
}
