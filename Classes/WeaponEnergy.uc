class WeaponEnergy extends RPGWeapon
	HideDropDown
	CacheExempt;

var localized string AdrenBonusText;

static function bool AllowedFor(class<Weapon> Weapon, Pawn Other)
{
	if(!Super.AllowedFor(Weapon, Other))
		return false;
	
	if (Other.Controller != None && Other.Controller.bAdrenalineEnabled)
		return true;

	return false;
}

function RPGAdjustTargetDamage(out int Damage, int OriginalDamage, Pawn Victim, Vector HitLocation, out Vector Momentum, class<DamageType> DamageType)
{
	local float AdrenalineBonus;

	Super.RPGAdjustTargetDamage(Damage, OriginalDamage, Victim, HitLocation, Momentum, DamageType);
	
	if(Victim == None || Victim == Instigator)
		return;
	
	Identify();

	if(Damage > Victim.Health)
		AdrenalineBonus = Victim.Health;
	else
		AdrenalineBonus = Damage;

	AdrenalineBonus *= BonusPerLevel * float(Modifier);

	//Adrenaline full
	if(
		UnrealPlayer(Instigator.Controller) != None &&
		Instigator.Controller.Adrenaline < Instigator.Controller.AdrenalineMax &&
	    Instigator.Controller.Adrenaline + AdrenalineBonus >= Instigator.Controller.AdrenalineMax &&
		!Instigator.InCurrentCombo()
	)
	{
		UnrealPlayer(Instigator.Controller).ClientDelayedAnnouncementNamed('Adrenalin', 15);
	}

	Instigator.Controller.Adrenaline = FMin(Instigator.Controller.Adrenaline + AdrenalineBonus, Instigator.Controller.AdrenalineMax);
}

simulated function string GetWeaponNameExtra()
{
	local string text;
	
	text = Super.GetWeaponNameExtra();
	
	if(text != "")
		text $= ", ";
	
	text $= Repl(AdrenBonusText, "$1", GetBonusPercentageString(BonusPerLevel));
	
	return text;
}

defaultproperties
{
	DamageBonus=0.040000
	BonusPerLevel=0.020000
	AdrenBonusText="$1 adrenaline gain"
	MinModifier=-3
	MaxModifier=4
	ModifierOverlay=Shader'XGameShaders.PlayerShaders.LightningHit'
	PatternPos="$W of Energy"
	PatternNeg="Draining $W"
	//AI
	AIRatingBonus=0.000000
}
