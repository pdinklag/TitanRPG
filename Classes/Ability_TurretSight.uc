class Ability_TurretSight extends RPGAbility;

function ModifyTurret(Vehicle T, Pawn Master) {
    local FriendlyTurretController C;

	T.SightRadius = T.SightRadius * (1.0f + float(AbilityLevel) * BonusPerLevel);
    
    C = FriendlyTurretController(T.Controller);
    if(C != None) {
        C.SleepDelay = C.SleepDelay * (1.0f + float(AbilityLevel) * BonusPerLevel);
    }
}

simulated function string DescriptionText() {
	return Repl(Super.DescriptionText(), "$1", class'Util'.static.FormatPercent(BonusPerLevel));
}

defaultproperties {
	AbilityName="Scanner"
	Description="Increases your turrets' sight radius and awake time by $1 per level."
	BonusPerLevel=0.20
	StartingCost=5
    CostAddPerLevel=5
	MaxLevel=5
	RequiredAbilities(0)=(AbilityClass=class'Ability_TurretSummon',Level=1)
	Category=class'AbilityCategory_Engineer'
}
