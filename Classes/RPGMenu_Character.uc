class RPGMenu_Character extends RPGMenu_TabPage;

//nevermind the class and control names, copypasta was fast and easy
struct AbilityInfo
{
	var string Key;
	var string Value;
	var bool bSection;
};
var array<AbilityInfo> AbilityInfos;

var automated GUISectionBackground sbAbilities;
var automated GUIMultiColumnListBox lstAbilities;
var automated GUIMultiColumnList Abilities;
var automated moComboBox cmbMyBuilds;
var automated GUIButton btSwitch, btReset, btRemove;

var localized string Rebuild_Caption, Rebuild_Hint;
var localized string 
	Text_CharInfo, Text_Name, Text_Level, Text_Experience,
	Text_StatPoints, Text_Stats, Text_Abilities, Text_Disabled;

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
	Super.InitComponent(MyController, MyOwner);
	
	Abilities = lstAbilities.List;
	Abilities.bMultiselect = false;
	Abilities.bInitializeList = false;
	Abilities.SortColumn = -1;
	Abilities.OnDrawItem = DrawAbilityInfo;
	//Abilities.OnClick = AbilitySelected;
}

function DrawAbilityInfo(Canvas Canvas, int i, float X, float Y, float W, float H, bool bSelected, bool bPending)
{
	local float CellLeft, CellWidth;
	local GUIStyles DStyle;
	
	if(AbilityInfos[i].bSection)
		DStyle = Abilities.SectionStyle;
	else if(bSelected)
		DStyle = Abilities.SelectedStyle;
    else
        DStyle = Abilities.Style;
	
	DStyle.Draw(Canvas, Abilities.MenuState, X, Y, W, H + 1);

	Abilities.GetCellLeftWidth(0, CellLeft, CellWidth);
	DStyle.DrawText(Canvas, Abilities.MenuState, CellLeft, Y, CellWidth, H, TXTA_Left, AbilityInfos[i].Key, Abilities.FontScale);

	Abilities.GetCellLeftWidth(1, CellLeft, CellWidth);
	DStyle.DrawText(Canvas, Abilities.MenuState, CellLeft, Y, CellWidth, H, TXTA_Left, AbilityInfos[i].Value, Abilities.FontScale);
}

function Add(string Key, string Value, optional bool bSection)
{
	local AbilityInfo AInfo;
	
	AInfo.Key = Key;
	AInfo.Value = Value;
	AInfo.bSection = bSection;
	
	AbilityInfos[AbilityInfos.Length] = AInfo;
	Abilities.AddedItem();
}

function FillMyBuildsList()
{
	local int i, x;
	
	cmbMyBuilds.RemoveItem(0, cmbMyBuilds.ItemCount());
	if(RPGMenu.RPRI.Interaction != None)
	{
		x = -1;
		
		for(i = 0; i < RPGMenu.RPRI.Interaction.Settings.MyBuilds.Length; i++)
		{
			cmbMyBuilds.AddItem(RPGMenu.RPRI.Interaction.Settings.MyBuilds[i]);
			
			if(RPGMenu.RPRI.Interaction.Settings.MyBuilds[i] ~= RPGMenu.RPRI.RPGName)
				x = i;
		}
	}
	
	if(x >= 0)
		cmbMyBuilds.SilentSetIndex(x);
}

function InitMenu()
{
	local int OldAbilityListIndex, OldAbilityListTop;
	local int i, NumStatsOwned;
	local array<RPGAbility> Stats;

	OldAbilityListIndex = Abilities.Index;
	OldAbilityListTop = Abilities.Top;
	
	Abilities.Clear();
	AbilityInfos.Remove(0, AbilityInfos.Length);

	Add(Text_CharInfo, "", true);
	Add(Text_Name, RPGMenu.RPRI.RPGName);
	Add(Text_Level, string(RPGMenu.RPRI.RPGLevel));
	Add(Text_Experience, 
		string(int(RPGMenu.RPRI.Experience)) @ "/" @ string(RPGMenu.RPRI.NeededExp) @
		"(" $ class'Util'.static.FormatPercent(RPGMenu.RPRI.Experience / float(RPGMenu.RPRI.NeededExp)) $ ")");

	Add(Text_StatPoints, string(RPGMenu.RPRI.PointsAvailable));
	
	for(i = 0; i < RPGMenu.RPRI.AllAbilities.Length; i++)
	{
		if(RPGMenu.RPRI.AllAbilities[i].bIsStat)
		{
			Stats[Stats.Length] = RPGMenu.RPRI.AllAbilities[i];
			
			if(RPGMenu.RPRI.AllAbilities[i].AbilityLevel > 0)
				NumStatsOwned++;
		}
	}
	
	if(Stats.Length > 0)
	{
		Add("", "");
		Add(Text_Stats, "", true);
		
		for(i = 0; i < Stats.Length; i++)
		{
			if(Stats[i].bAllowed)
				Add(Stats[i].StatName, string(Stats[i].AbilityLevel));
			else
				Add(Stats[i].StatName, Text_Disabled);
		}
	}
	
	if(RPGMenu.RPRI.Abilities.Length - NumStatsOwned > 0)
	{
		Add("", "");
		Add(Text_Abilities, "", true);
		
		for(i = 0; i < RPGMenu.RPRI.Abilities.Length; i++)
		{
			if(!RPGMenu.RPRI.Abilities[i].bIsStat)
			{
				if(RPGMenu.RPRI.Abilities[i].bAllowed)
					Add(RPGMenu.RPRI.Abilities[i].AbilityName, string(RPGMenu.RPRI.Abilities[i].AbilityLevel));
				else
					Add(RPGMenu.RPRI.Abilities[i].AbilityName, Text_Disabled);
			}
		}
	}
	
	Abilities.SetIndex(OldAbilityListIndex);
	Abilities.SetTopItem(OldAbilityListTop);
	
	if(RPGMenu.RPRI.bAllowRebuild)
	{
		btReset.Hint = Rebuild_Hint;
		btReset.Caption = Rebuild_Caption;
	}
	
	FillMyBuildsList();
}

function bool SwitchClicked(GUIComponent Sender)
{
	if(!(cmbMyBuilds.GetText() ~= RPGMenu.RPRI.RPGName))
	{
		Controller.OpenMenu(class'MutTitanRPG'.default.PackageName $ ".RPGSwitchConfirmationWindow");
		RPGSwitchConfirmationWindow(Controller.TopPage()).RPGMenu = RPGMenu;
		RPGSwitchConfirmationWindow(Controller.TopPage()).NewBuild = cmbMyBuilds.GetText();
		RPGSwitchConfirmationWindow(Controller.TopPage()).Init();
	}
	return true;
}

function bool ResetClicked(GUIComponent Sender)
{
	if(RPGMenu.RPRI.bAllowRebuild)
	{
		Controller.OpenMenu(class'MutTitanRPG'.default.PackageName $ ".RPGRebuildConfirmationWindow");
		RPGRebuildConfirmationWindow(Controller.TopPage()).RPGMenu = RPGMenu;
		RPGRebuildConfirmationWindow(Controller.TopPage()).Init();
	}
	else
	{
		Controller.OpenMenu(class'MutTitanRPG'.default.PackageName $ ".RPGResetConfirmationWindow");
		RPGResetConfirmationWindow(Controller.TopPage()).RPGMenu = RPGMenu;
		RPGResetConfirmationWindow(Controller.TopPage()).Init();
	}
	return true;
}

function bool RemoveClicked(GUIComponent Sender)
{
	local RPGCharSettings CharSettings;
	local int i;
	
	if(!(cmbMyBuilds.GetText() ~= RPGMenu.RPRI.RPGName))
	{
		for(i = 0; i < RPGMenu.RPRI.Interaction.Settings.MyBuilds.Length; i++)
		{
			if(RPGMenu.RPRI.Interaction.Settings.MyBuilds[i] ~= cmbMyBuilds.GetText())
			{
				CharSettings = new(None, RPGMenu.RPRI.Interaction.Settings.MyBuilds[i]) class'RPGCharSettings';
				if(CharSettings != None)
					CharSettings.ClearConfig();
			
				RPGMenu.RPRI.Interaction.Settings.MyBuilds.Remove(i, 1);
				FillMyBuildsList();
				break;
			}
		}
	}
	return true;
}

function BuildSelected(GUIComponent Sender)
{
	if(cmbMyBuilds.GetText() ~= RPGMenu.RPRI.RPGName)
	{
		btRemove.MenuState = MSAT_Disabled;
		btSwitch.MenuState = MSAT_Disabled;
	}
	else
	{
		btRemove.MenuState = MSAT_Blurry;
		btSwitch.MenuState = MSAT_Blurry;
	}
}

function CloseMenu()
{
	AbilityInfos.Length = 0;
}

defaultproperties
{
	Text_CharInfo="Information:"
	Text_Name="Name:"
	Text_Level="Level:"
	Text_Experience="Experience:"
	Text_StatPoints="Stat Points:"
	Text_Stats="Stats:"
	Text_Abilities="Abilities:"
	Text_Disabled="DISABLED"
	
	Rebuild_Caption="Rebuild"
	Rebuild_Hint="Allows you to rebuild your character at a certain cost of experience.";

	Begin Object Class=AltSectionBackground Name=sbAbilities_
		Caption="Character information"
		LeftPadding=0.000000
		WinWidth=0.997718
		WinHeight=0.849959
		WinLeft=0.000085
		WinTop=0.013567
		OnPreDraw=sbAbilities_.InternalPreDraw
	End Object
	sbAbilities=AltSectionBackground'sbAbilities_'

	Begin Object Class=GUIMultiColumnListBox Name=lstAbilities_
		bAcceptsInput=True
		bVisibleWhenEmpty=True
		bDisplayHeader=True
		ColumnHeadings(0)="Key"
		HeaderColumnPerc(0)=0.4
		ColumnHeadings(1)="Value"
		HeaderColumnPerc(1)=0.6
		SelectedStyleName="BrowserListSelection"
		OnCreateComponent=lstAbilities_.InternalOnCreateComponent
		StyleName="ServerBrowserGrid"
		SectionStyleName="RPGListSection"
		WinWidth=0.929513
		WinHeight=0.663918
		WinLeft=0.015054
		WinTop=0.082763
	End Object
	lstAbilities=GUIMultiColumnListBox'lstAbilities_'
	
	Begin Object class=moComboBox Name=cmbMyBuilds_
		WinWidth=0.538844
		WinHeight=0.041458
		WinLeft=0.015169
		WinTop=0.877558
		CaptionWidth=0.350000
		Caption="My Characters:"
		Hint="Lists the characters that you have used in TitanRPG."
		OnChange=RPGMenu_Character.BuildSelected
	End Object
	cmbMyBuilds=cmbMyBuilds_
	
	Begin Object Class=GUIButton Name=btRemove_
		Caption="-"
		Hint="Removes the selected character from the 'My Characters' list."
		WinWidth=0.043973
		WinHeight=0.068000
		WinLeft=0.555008
		WinTop=0.865749
		OnClick=RPGMenu_Character.RemoveClicked
		OnKeyEvent=btRemove_.InternalOnKeyEvent
	End Object
	btRemove=GUIButton'btRemove_'
	
	Begin Object Class=GUIButton Name=btSwitch_
		Caption="Switch"
		Hint="Switches to the selected character without the need to reconnect."
		WinWidth=0.269181
		WinHeight=0.068000
		WinLeft=0.600847
		WinTop=0.866042
		OnClick=RPGMenu_Character.SwitchClicked
		OnKeyEvent=btSwitch_.InternalOnKeyEvent
	End Object		
	btSwitch=GUIButton'btSwitch_'

	Begin Object Class=GUIButton Name=btReset_
		Caption="Reset"
		Hint="Permanently resets your character. This can NOT be undone!"
		WinWidth=0.116331
		WinHeight=0.068000
		WinLeft=0.871865
		WinTop=0.866042
		OnClick=RPGMenu_Character.ResetClicked
		OnKeyEvent=btReset_.InternalOnKeyEvent
	End Object
	btReset=GUIButton'btReset_'

	WinHeight=0.700000
}