class StatusIconMonsters extends RPGStatusIcon;

simulated function bool IsVisible()
{
	return (RPRI.NumMonsters > 0);
}

simulated function string GetText()
{
	return RPRI.NumMonsters $ "/" $ RPRI.MaxMonsters;
}

defaultproperties
{
	IconMaterial=Texture'<? echo($packageName); ?>.StatusIcons.Monster'
}
