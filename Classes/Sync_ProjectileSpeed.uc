class Sync_ProjectileSpeed extends Sync;

var Projectile Proj;
var float SpeedMultiplier;
var name ProcessedTag;

//Identifiers
var class<Projectile> ProjClass;

replication
{
	reliable if(Role == ROLE_Authority && bNetInitial)
		Proj, SpeedMultiplier, ProjClass, ProcessedTag;
}

simulated function bool ClientFunction()
{
	local Projectile P;

	if(Proj == None)
	{
		foreach DynamicActors(class'Projectile', P)
		{
			if(P.Tag != ProcessedTag && P.class == ProjClass && P.Instigator == Instigator)
			{
				Proj = P;
				break;
			}
		}
	}

	if(Proj != None)
	{
		Proj.Speed *= SpeedMultiplier;
		Proj.MaxSpeed *= SpeedMultiplier;
		Proj.Velocity *= SpeedMultiplier;
		
		Proj.Tag = ProcessedTag;
	}
	
	return true;
}

defaultproperties {
    bTryEachTick=True
    LifeSpan=4.00
}
