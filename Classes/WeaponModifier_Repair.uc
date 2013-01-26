class WeaponModifier_Repair extends WeaponModifier_Infinity;

var localized string RepairText;

static function bool AllowedFor(class<Weapon> Weapon, Pawn Other)
{
	if(!Super.AllowedFor(Weapon, Other))
		return false;

    return ClassIsChildOf(Weapon, class'RPGLinkGun');
}

simulated function BuildDescription()
{
	Super.BuildDescription();
	AddToDescription(RepairText, BonusPerLevel);
}

defaultproperties
{
	RepairText="$1 vehicle repairing"
	DamageBonus=0.00
	BonusPerLevel=0.25
	MinModifier=1
	MaxModifier=1
    bOmitModifierInName=True
	ModifierOverlay=Shader'TitanRPG.Overlays.GreenShader'
	PatternPos="Repair $W of Infinity"
	bCanThrow=False
}
