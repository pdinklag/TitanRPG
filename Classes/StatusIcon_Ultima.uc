class StatusIcon_Ultima extends RPGStatusIcon;

var AbilityUltima Ultima;

function Tick(float dt)
{
	Ultima = AbilityUltima(RPRI.GetAbility(class'AbilityUltima'));
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
