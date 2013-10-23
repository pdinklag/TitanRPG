class Ability_TurretHealth extends RPGAbility;

function ModifyTurret(Vehicle T, Pawn Master) {
	T.Health = int(float(T.Health) * (1.0f + float(AbilityLevel) * BonusPerLevel));
	T.SuperHealthMax = T.SuperHealthMax - T.HealthMax + T.Health;
	T.HealthMax = T.Health;
}

simulated function string DescriptionText() {
	return Repl(Super.DescriptionText(), "$1", class'Util'.static.FormatPercent(BonusPerLevel));
}

defaultproperties {
	AbilityName="Turret Armor"
	Description="Increases your turrets' armor by $1 per level."
	BonusPerLevel=0.10
	StartingCost=5
	MaxLevel=5
	RequiredAbilities(0)=(AbilityClass=class'Ability_TurretSummon',Level=1)
	Category=class'AbilityCategory_Engineer'
}
