class RPGMenu_ControlBinder extends KeyBindMenu;

var RPGPlayerReplicationInfo RPRI;

var localized string SelectText, ActivateText;
var localized string BindingLabel[150];

var localized string ArtifactSelectionHeader, ArtifactActivationHeader;

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
	RPRI = class'RPGPlayerReplicationInfo'.static.GetFor(MyController.ViewportOwner.Actor);
    Super.InitComponent(MyController, MyOwner);	
}

function LoadCommands()
{
	local int i, n, x;
	local KeyBinding Binding;

	Super.LoadCommands();
	
	x = Bindings.Length;
	
	n = RPRI.AllArtifacts.Length;
	Bindings.Length = x + n * 2 + 2;
	
	Binding.bIsSectionLabel = true;
	Binding.KeyLabel = ArtifactActivationHeader;
	Bindings[x] = Binding;
	BindingLabel[x] = ArtifactActivationHeader;
	
	Binding.KeyLabel = ArtifactSelectionHeader;
	Bindings[x + n + 1] = Binding;
	BindingLabel[x + n + 1] = ArtifactSelectionHeader;
	
	Binding.bIsSectionLabel = false;
	x++;
	
	for(i = 0; i < RPRI.AllArtifacts.Length; i++)
	{
		Binding.KeyLabel = Repl(ActivateText, "$1", RPRI.AllArtifacts[i].default.ItemName);
		Binding.Alias = "RPGActivateArtifact" @ RPRI.AllArtifacts[i].default.ArtifactID;
		Bindings[x] = Binding;
		BindingLabel[x] = Binding.KeyLabel;
		
		Binding.KeyLabel = Repl(SelectText, "$1", RPRI.AllArtifacts[i].default.ItemName);
		Binding.Alias = "RPGGetArtifact" @ RPRI.AllArtifacts[i].default.ArtifactID;
		Bindings[x + n + 1] = Binding;
		BindingLabel[x + n + 1] = Binding.KeyLabel;
		
		x++;
	}

	// Update the MultiColumnList's sortdata array to reflect the indexes of our Bindings array
    for(i = 0; i < Bindings.Length; i++)
    	li_Binds.AddedItem();
}

function ClearBindings()
{
	local int i, max;

	Super.ClearBindings();
	Bindings = default.Bindings;
	Max = Min(Bindings.Length, ArrayCount(BindingLabel));
	for(i = 0; i < Max; i++)
	{
		if(BindingLabel[i] != "")
			Bindings[i].KeyLabel = BindingLabel[i];
	}
}

defaultproperties
{
	ActivateText="Activate $1"
	SelectText="Select $1"

	PageCaption="Configure RPG Keys"
	Headings(0)="Action"
	
	Bindings(0)=(bIsSectionLabel=true,KeyLabel="General")
	BindingLabel(0)="General"
	Bindings(1)=(KeyLabel="Open RPG Menu",Alias="RPGStatsMenu")
	BindingLabel(1)="Open RPG Menu"
	Bindings(2)=(bIsSectionLabel=true,KeyLabel="Artifacts")
	BindingLabel(2)="Artifacts"
	Bindings(3)=(KeyLabel="Activate Selected Artifact",Alias="ActivateItem")
	BindingLabel(3)="Activate Selected Artifact"
	Bindings(4)=(KeyLabel="Next Artifact",Alias="NextItem")
	BindingLabel(4)="Next Artifact"
	Bindings(5)=(KeyLabel="Previous Artifact",Alias="PrevItem")
	BindingLabel(5)="Previous Artifact"
	Bindings(6)=(KeyLabel="Throw Artifact",Alias="TossArtifact")
	BindingLabel(6)="Throw Artifact"
	Bindings(7)=(bIsSectionLabel=true,KeyLabel="Summoned")
	BindingLabel(7)="Summoned"
	Bindings(8)=(KeyLabel="Kill Monsters",Alias="KillMonsters")
	BindingLabel(8)="Kill Monsters"
	Bindings(9)=(KeyLabel="Destroy Turrets",Alias="KillTurrets")
	BindingLabel(9)="Destroy Turrets"
	Bindings(10)=(KeyLabel="Destroy Totems",Alias="KillTotems")
	BindingLabel(10)="Destroy Totems"
	
	ArtifactSelectionHeader="Artifact Selection"
	ArtifactActivationHeader="Artifact Activation"
}
