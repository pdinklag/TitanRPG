class Ability_Medic extends RPGAbility;

var config array<int> LevelCap;

replication
{
	reliable if(Role == ROLE_Authority)
		ClientReceiveLevelCap;
}

simulated function ClientReceived()
{
	Super.ClientReceived();
	LevelCap.Length = 0;
}

function ServerRequestConfig()
{
	local int i;

	Super.ServerRequestConfig();

	for(i = 0; i < LevelCap.Length; i++)
		ClientReceiveLevelCap(i, LevelCap[i]);
}

simulated function ClientReceiveLevelCap(int i, int Cap)
{
	LevelCap[i] = Cap;
}

function int GetHealMax()
{
	return LevelCap[AbilityLevel - 1];
}

simulated function string DescriptionText()
{
	local int i;
	local string Text;
	
	Text = Super.DescriptionText();
	
	for(i = 0; i < LevelCap.Length; i++)
		Text = repl(Text, "$" $ string(i + 1), string(LevelCap[i]));
	
	return Text;
}

defaultproperties
{
	AbilityName="Medic"
	Description="Gives you bonuses towards healing."
	LevelDescription(0)="Level 1 allows you to heal teammates +$1 beyond their maximum health."
	LevelDescription(1)="Level 2 allows you to heal teammates +$2 beyond their maximum health."
	LevelDescription(2)="Level 3 allows you to heal teammates +$3 beyond their maximum health."
    GrantItem(0)=(Level=1,InventoryClass=Class'Artifact_MakeMedicWeapon')
    GrantItem(1)=(Level=3,InventoryClass=Class'Artifact_HealingBlast')
	StartingCost=10
	CostAddPerLevel=10
	MaxLevel=3
	LevelCap(0)=30
	LevelCap(1)=50
	LevelCap(2)=70
	Category=class'AbilityCategory_Medic'
}
