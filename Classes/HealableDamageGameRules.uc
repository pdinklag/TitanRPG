Class HealableDamageGameRules extends GameRules
	config(TitanRPG);

var config int MaxHealthBonus;

function int NetDamage(int OriginalDamage, int Damage, pawn injured, pawn instigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType)
{
	local int DamageRV;

	DamageRV = Super.NetDamage(OriginalDamage, Damage, injured, instigatedBy, HitLocation, Momentum, DamageType);

	if(
        DamageRV > 0 &&
		injured != None &&
		!injured.IsA('Monster') &&
		instigatedBy != None &&
		instigatedBy.Controller != None &&
        instigatedBy != injured &&
		(!injured.IsA('Vehicle') || !Vehicle(Injured).IsVehicleEmpty()) &&
		(injured.Controller == None || !injured.Controller.SameTeamAs(instigatedBy.Controller))
	)
	{
		DoHealableDamage(DamageRV, Injured);
	}
	
	return DamageRV;
}

function DoHealableDamage(int Damage, Pawn Injured)
{
	local HealableDamageInv Inv;
	
	Inv = HealableDamageInv(injured.FindInventoryType(class'HealableDamageInv'));
	if(Inv == None)
	{
		Inv = injured.spawn(class'HealableDamageInv');
		Inv.giveTo(injured);
	}

	Inv.Damage += Damage;
	
	if(Inv.Damage > Injured.HealthMax + MaxHealthBonus)
		Inv.Damage = Injured.HealthMax + MaxHealthBonus;
}

defaultproperties
{
	MaxHealthBonus=150
}
