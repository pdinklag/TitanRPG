class StatusIcon_Ultima extends RPGStatusIcon;

var Ability_Ultima Ultima;

function Tick(float dt)
{
	Ultima = Ability_Ultima(RPRI.GetAbility(class'Ability_Ultima'));
	bShouldTick = (Ultima == None);
}

function bool IsVisible()
{
	return (
		Ultima != None &&
		Ultima.AbilityLevel >= 0 &&
		Ultima.KillCount > 0
	);
}

function string GetText()
{
	return "";
}

defaultproperties
{
	IconMaterial=Texture'TitanRPG.StatusIcons.Ultima'
	bShouldTick=True
}
