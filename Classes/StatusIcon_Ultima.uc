class StatusIcon_Ultima extends RPGStatusIcon;

var AbilityUltima Ultima;

function Initialize()
{
	Ultima = AbilityUltima(RPRI.GetAbility(class'AbilityUltima'));
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
	IconMaterial=Texture'<? echo($packageName); ?>.StatusIcons.Ultima'
}
