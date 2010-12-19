class AbilityEnergyLeech extends RPGAbility;

function HandleDamage(int Damage, Pawn Injured, Pawn Instigator, out vector Momentum, class<DamageType> DamageType, bool bOwnedByInstigator)
{
	local float AdrenalineBonus;

	if (Damage < 1 || !bOwnedByInstigator || DamageType == class'DamTypeCounterShove'  || Injured == Instigator || Instigator == None || Injured == None ||  UnrealPlayer(Instigator.Controller) == None || Instigator.Controller.Adrenaline >= Instigator.Controller.AdrenalineMax || Instigator.InCurrentCombo() || HasActiveArtifact(Instigator))
		return;
	
	if (Damage > Injured.Health)
		AdrenalineBonus = Injured.Health;
	else
		AdrenalineBonus = Damage;
	AdrenalineBonus *= BonusPerLevel * AbilityLevel;

	if (Instigator.Controller.Adrenaline + AdrenalineBonus >= Instigator.Controller.AdrenalineMax)
		UnrealPlayer(Instigator.Controller).ClientDelayedAnnouncementNamed('Adrenalin', 15);

	Instigator.Controller.Adrenaline = FMin(Instigator.Controller.Adrenaline + AdrenalineBonus, Instigator.Controller.AdrenalineMax);
}

static function bool HasActiveArtifact(Pawn Instigator)
{
	return class'RPGArtifact'.static.HasActiveArtifact(Instigator);
}

simulated function string DescriptionText()
{
	return repl(Super.DescriptionText(), "$1", class'Util'.static.FormatPercent(BonusPerLevel));
}

defaultproperties
{
	AbilityName="Energy Leech"
	Description="Whenever you deal damage to another player, you gain $1 of the damage per level as adrenaline."
	StartingCost=5
	CostAddPerLevel=5
	MaxLevel=5
	ForbiddenAbilities(0)=(AbilityClass=class'AbilityVampire',Level=1)
	BonusPerLevel=0.010000
}
