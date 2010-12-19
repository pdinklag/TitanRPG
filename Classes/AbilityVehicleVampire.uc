class AbilityVehicleVampire extends AbilityVampire;

function HandleDamage(int Damage, Pawn Injured, Pawn Instigator, out vector Momentum, class<DamageType> DamageType, bool bOwnedByInstigator)
{
	if(!bOwnedByInstigator || Injured == Instigator || Vehicle(Instigator) == None)
		return;
		
	Super.HandleDamage(Damage, Injured, Instigator, Momentum, DamageType, bOwnedByInstigator);
}

defaultproperties
{
	AbilityName="Vehicle Vampirism"
	Description="Whenever you damage an opponent from a vehicle or turret, it gets repaired for $1 of the damage per level (up to its starting health amount + $2$3). You can't gain health from self-damage."
	ForbiddenAbilities(0)=(AbilityClass=class'AbilityVehicleSpeed',Level=1)
	RequiredAbilities(0)=(AbilityClass=class'AbilityDamageBonus',Level=5)
	BonusPerLevel=0.050000
	HealthBonusMax=0.500000
	HealthBonusAbsoluteCap=1000
	MaxLevel=10
	bUseLevelCost=true
	LevelCost(0)=5
	LevelCost(1)=10
	LevelCost(2)=15
	LevelCost(3)=20
	LevelCost(4)=25
	LevelCost(5)=25
	LevelCost(6)=25
	LevelCost(7)=25
	LevelCost(8)=25
	LevelCost(9)=25
}
