class StatusIcon_Turrets extends RPGStatusIcon;

function bool IsVisible()
{
	return (RPRI.NumTurrets > 0);
}

function string GetText()
{
	return RPRI.NumTurrets $ "/" $ RPRI.MaxTurrets;
}

defaultproperties
{
	IconMaterial=Texture'TitanRPG.StatusIcons.Turret'
}
