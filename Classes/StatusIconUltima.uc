class StatusIconUltima extends RPGStatusIcon;

var AbilityUltima Ultima;

simulated function ClientInitialize()
{
	Ultima = AbilityUltima(RPRI.GetAbility(class'AbilityUltima'));
}

simulated function bool IsVisible()
{
	return (
		Ultima != None &&
		Ultima.AbilityLevel >= 0 &&
		Ultima.KillCount > 0
	);
}

simulated function string GetText()
{
	return "";
}

defaultproperties
{
	IconMaterial=Texture'<? echo($packageName); ?>.StatusIcons.Ultima'
}
