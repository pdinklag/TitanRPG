class StatusIcon_Monsters extends RPGStatusIcon;

function bool IsVisible()
{
	return (RPRI.NumMonsters > 0);
}

function string GetText()
{
	return RPRI.NumMonsters $ "/" $ RPRI.MaxMonsters;
}

defaultproperties
{
	IconMaterial=Texture'TitanRPG.StatusIcons.Monster'
}
