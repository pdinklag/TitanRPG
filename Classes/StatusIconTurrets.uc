class StatusIconTurrets extends RPGStatusIcon;

simulated function bool IsVisible()
{
	return (RPRI.NumTurrets > 0);
}

simulated function string GetText()
{
	return RPRI.NumTurrets $ "/" $ RPRI.MaxTurrets;
}

defaultproperties
{
	IconMaterial=Texture'<? echo($packageName); ?>.StatusIcons.Turret'
}
