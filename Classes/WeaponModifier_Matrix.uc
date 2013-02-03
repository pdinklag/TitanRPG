class WeaponModifier_Matrix extends RPGWeaponModifier;

var config float MatrixRadius;
var config bool bAffectsTranslocator;

var localized string MatrixText;

const SLOWDOWN_CAP = 0.1;

function RPGTick(float dt) {
    local Projectile P;
	local Sync_Matrix Sync;
	local float Multiplier;

	Super.RPGTick(dt);

	if(Instigator.Controller != None) {
		Multiplier = FMax(SLOWDOWN_CAP, 1.0f - BonusPerLevel * float(Modifier));
	
		foreach Instigator.VisibleCollidingActors(class'Projectile', P, MatrixRadius)
		{
			if(P.Tag == 'Matrix')
				continue;
		
			if(P.IsA('TransBeacon') && !bAffectsTranslocator)
				continue;
			
			if(P.Instigator != None)
			{
                if(!class'DevoidEffect_Matrix'.static.CanBeApplied(P.Instigator, Instigator.Controller))
                    continue;
			}

			Identify();
			
			P.Tag = 'Matrix';
			P.Speed *= Multiplier;
			P.MaxSpeed *= Multiplier;
			P.Velocity *= Multiplier;
			
			//Tell clients
			if(Level.NetMode == NM_DedicatedServer)
			{
				Sync = P.Instigator.Spawn(class'Sync_Matrix');
				if(Sync != None)
				{
					Sync.Proj = P;
					Sync.ProjClass = P.class;
					Sync.ProcessedTag = 'Matrix';
					Sync.SpeedMultiplier = Multiplier;
					Sync.ProjVelocity = P.Velocity;
					Sync.ProjLocation = P.Location;
				}
			}
		}
	}
}

simulated function BuildDescription()
{
    local float Multiplier;

	Super.BuildDescription();
    
    Multiplier = FMin(1 - SLOWDOWN_CAP, BonusPerLevel * float(Modifier));
	AddToDescription(Repl(MatrixText, "$1", class'Util'.static.FormatPercent(Multiplier)));
}

defaultproperties
{
	bAffectsTranslocator=False

	MatrixText="$1 enemy projectile slowdown"
	DamageBonus=0.03
	
	MatrixRadius=768
	BonusPerLevel=0.20

	MinModifier=1
	MaxModifier=4
	ModifierOverlay=ColorModifier'TitanRPG.Matrix.MatrixColorModifier'
	PatternPos="Matrix $W"
	//AI
	AIRatingBonus=0.025000
	CountersDamage(0)=class'DamTypeFlakChunk'
	CountersDamage(1)=class'DamTypeFlakShell'
	CountersDamage(2)=class'DamTypeRocket'
	CountersDamage(3)=class'DamTypeRocketHoming'
}
