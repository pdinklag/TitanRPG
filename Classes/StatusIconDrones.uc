class StatusIconDrones extends RPGStatusIcon;

simulated function bool IsVisible()
{
	return (RPRI.NumDrones > 0);
}

simulated function string GetText()
{
	return RPRI.NumDrones $ "/" $ RPRI.MaxDrones;
}

defaultproperties
{
	IconMaterial=Texture'<? echo($packageName); ?>.StatusIcons.Drone'
}
