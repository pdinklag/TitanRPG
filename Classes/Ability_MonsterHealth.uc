class Ability_MonsterHealth extends RPGAbility;

var config float GrowthPerLevel;

replication
{
	reliable if(Role == ROLE_Authority)
		GrowthPerLevel;
}

function ModifyMonster(Monster M, Pawn Master)
{
	local float Growth, HeightDifference;

	M.Health = int(float(M.Health) * (1.0f + float(AbilityLevel) * BonusPerLevel));
	M.SuperHealthMax = M.SuperHealthMax - M.HealthMax + M.Health;
	M.HealthMax = M.Health;
	
	if(GrowthPerLevel != 0)
	{
		Growth = (1.0f + GrowthPerLevel * float(AbilityLevel));
		
		HeightDifference = M.CollisionHeight * (Growth - 1.0f);
		M.SetLocation(M.Location + vect(0, 0, 1) * HeightDifference);
		
		M.SetDrawScale(M.DrawScale * Growth);
		M.SetCollisionSize(M.CollisionRadius * Growth, M.CollisionHeight * Growth);
		
		M.GroundSpeed *= Growth;
		M.WaterSpeed *= Growth;
		M.AirSpeed *= Growth;
	}
}

simulated function string DescriptionText()
{
	return Repl(
		Repl(Super.DescriptionText(), "$1", class'Util'.static.FormatPercent(BonusPerLevel)),
		"$2", class'Util'.static.FormatPercent(GrowthPerLevel));
		
}

defaultproperties
{
	AbilityName="Monster Fodder"
	Description="Increases your summoned monsters' health by $1 and grows them by $2 per level, increasing their speed."
	BonusPerLevel=0.10
	GrowthPerLevel=0.0125
	StartingCost=5
	MaxLevel=10
	RequiredAbilities(0)=(AbilityClass=class'Ability_MonsterSummon',Level=1)
	Category=class'AbilityCategory_Monsters'
}
