class StatusIcon_Totems extends RPGStatusIcon;

function bool IsVisible()
{
	return (RPRI.NumTotems > 0);
}

function string GetText()
{
	return RPRI.NumTotems $ "/" $ RPRI.MaxTotems;
}

defaultproperties
{
	IconMaterial=Texture'TitanRPG.StatusIcons.Totem'
}
