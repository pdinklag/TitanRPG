class WeaponSuperHealer extends WeaponHealer
	HideDropDown
	CacheExempt;

var localized string MedicText;

simulated function bool CanThrow()
{
	return false;
}

function DropFrom(vector StartLocation)
{
	Destroy();
}

function bool ConsumeAmmo(int Mode, float Load, bool bAmountNeededIsMax)
{
	Identify();
	return true;
}

simulated function WeaponTick(float dt)
{
	MaxOutAmmo();
	Super.WeaponTick(dt);
}

function int GetMaxHealthBonus()
{
	local AbilityLoadedMedic LM;

	LM = AbilityLoadedMedic(HolderRPRI.GetOwnedAbility(class'AbilityLoadedMedic'));
	if(LM != None)
		return LM.GetHealMax();
	else
		return Super.GetMaxHealthBonus();
}

simulated function string GetWeaponNameExtra()
{
	local string text;
	
	text = Super.GetWeaponNameExtra();
	
	if(text != "")
		text $= ", ";
	
	text $= MedicText;
	text $= ", ";
	text $= class'WeaponInfinity'.default.InfAmmoText;
	return text;
}

static function string ConstructItemName(int Modifier, class<Weapon> WeaponClass)
{
	return repl(default.PatternPos, "$W", WeaponClass.default.ItemName);
}

defaultproperties
{
	MedicText="enhanced"
	MinModifier=5
	MaxModifier=5
	AIRatingBonus=0.100000
	PatternPos="Medic $W of Infinity"
	bCanThrow=False
	ForbiddenWeaponTypes(0)=Class'XWeapons.BallLauncher'
	ForbiddenWeaponTypes(1)=Class'XWeapons.TransLauncher'
	ForbiddenWeaponTypes(2)=Class'XWeapons.Redeemer'
	ForbiddenWeaponTypes(3)=Class'XWeapons.Painter'
	ForbiddenWeaponTypes(4)=Class'OnslaughtFull.ONSPainter'
}
