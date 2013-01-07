class Weapon_Repair extends Weapon_Infinity
	HideDropDown
	CacheExempt;
	
var localized string RepairText;

static function bool AllowedFor(class<Weapon> Weapon, Pawn Other)
{
	if(!Super.AllowedFor(Weapon, Other))
		return false;

	return ClassIsChildOf(Weapon, class'Xweapons.LinkGun');
}

simulated function bool CanThrow()
{
	return false;
}

function DropFrom(vector StartLocation)
{
	Destroy();
}

simulated function string GetWeaponNameExtra()
{
	local string text;
	
	text = Super.GetWeaponNameExtra();
	
	if(text != "")
		text $= ", ";
	
	text $= Repl(RepairText, "$1", GetBonusPercentageString(BonusPerLevel));
	return text;
}

function StartEffect()
{
	Identify();
}

static function string ConstructItemName(int Modifier, class<Weapon> WeaponClass)
{
	return repl(default.PatternPos, "$W", WeaponClass.default.ItemName);
}

defaultproperties
{
	RepairText="$1 vehicle repairing"
	DamageBonus=0.000000
	BonusPerLevel=0.250000
	MinModifier=1
	MaxModifier=1
	ModifierOverlay=Shader'TitanRPG.Overlays.GreenShader'
	PatternPos="Repair $W of Infinity"
	bCanThrow=False
}
