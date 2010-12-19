class AbilityLoadedMedic extends RPGAbility;

var config array<int> LevelCap;

var ReplicatedArray LevelCapRepl;

replication
{
	reliable if(Role == ROLE_Authority && bNetInitial)
		LevelCapRepl;
}

simulated event PreBeginPlay()
{
	local int i;
	
	Super.PreBeginPlay();

	if(ShouldReplicateInfo())
	{
		LevelCapRepl = Spawn(class'ReplicatedArray', Owner);
		for(i = 0; i < LevelCap.Length; i++)
			LevelCapRepl.IntArray[i] = LevelCap[i];
		
		LevelCapRepl.Replicate();
	}
}

simulated event PostNetReceive()
{
	local int i;
	
	Super.PostNetReceive();

	if(Role < ROLE_Authority && LevelCapRepl != None)
	{
		LevelCap.Length = LevelCapRepl.IntArray.Length;
		for(i = 0; i < LevelCap.Length; i++)
			LevelCap[i] = LevelCapRepl.IntArray[i];
		
		LevelCapRepl.SetOwner(Owner);
		LevelCapRepl.ServerDestroy();
	}
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
	
	Log("LevelCap.Length =" @ LevelCap.Length);
	for(i = 0; i < LevelCap.Length; i++)
		Text = repl(Text, "$" $ string(i + 1), string(LevelCap[i]));
	
	return Text;
}

defaultproperties
{
	AbilityName="Loaded Medic"
	Description="Gives you bonuses towards healing."
	LevelDescription(0)="Level 1 allows you to heal teammates +$1 beyond their starting health."
	LevelDescription(1)="Level 2 allows you to heal teammates +$2 beyond their starting health."
	LevelDescription(2)="Level 3 allows you to heal teammates +$3 beyond their starting health."
	StartingCost=10
	CostAddPerLevel=10
	MaxLevel=3
	LevelCap(0)=30
	LevelCap(1)=50
	LevelCap(2)=70
	RequiredAbilities(0)=(AbilityClass=class'AbilityDenial',Level=1)
}
