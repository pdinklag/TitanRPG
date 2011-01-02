class RPGMenu_PlayerLevels extends RPGMenu_TabPage;

//nevermind the class and control names, copypasta was fast and easy
struct AbilityInfo
{
	var string PlayerName;
	var int Team;
	var int Level, ExpNeeded;
	var float Exp;
};
var array<AbilityInfo> AbilityInfos;

var automated GUISectionBackground sbAbilities, sbDesc;
var automated GUIMultiColumnListBox lstAbilities;
var automated GUIMultiColumnList Abilities;

var Color TeamTextColor[4];

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
	Super.InitComponent(MyController, MyOwner);
	
	Abilities = lstAbilities.List;
	Abilities.bMultiselect = false;
	Abilities.bInitializeList = false;
	Abilities.SortColumn = -1;
	Abilities.OnDrawItem = DrawAbilityInfo;
	Abilities.OnClick = AbilitySelected;
}

function ModifyStyle(GUIStyles DStyle, int Team)
{
	local int i;

	if(Team >= 0 && Team < 4)
	{
		for(i = 0; i < 5; i++)
			DStyle.FontColors[i] = TeamTextColor[Team];
	}
}

function ResetStyle(GUIStyles DStyle)
{
	local int i;
	
	for(i = 0; i < 5; i++)
		DStyle.FontColors[i] = DStyle.default.FontColors[i];
}

function DrawAbilityInfo(Canvas Canvas, int i, float X, float Y, float W, float H, bool bSelected, bool bPending)
{
	local string LevelText;
	local float CellLeft, CellWidth;
	local GUIStyles DStyle;
	
	if(bSelected)
    {
        Abilities.SelectedStyle.Draw(Canvas, Abilities.MenuState, X, Y, W, H + 1);
        DStyle = Abilities.SelectedStyle;
    }
    else
	{
        DStyle = Abilities.Style;
	}
	
	ModifyStyle(DStyle, AbilityInfos[i].Team);
	
	Abilities.GetCellLeftWidth(0, CellLeft, CellWidth);
	
	DStyle.DrawText(Canvas, Abilities.MenuState, CellLeft, Y, CellWidth, H, TXTA_Left, AbilityInfos[i].PlayerName, Abilities.FontScale);

	LevelText =
		string(AbilityInfos[i].Level) @ "(" $
		string(int(AbilityInfos[i].Exp)) @ "/" @ string(AbilityInfos[i].ExpNeeded) @ "=" @
		class'Util'.static.FormatPercent(AbilityInfos[i].Exp / float(AbilityInfos[i].ExpNeeded)) $ ")";

	Abilities.GetCellLeftWidth(1, CellLeft, CellWidth);
	DStyle.DrawText(Canvas, Abilities.MenuState, CellLeft, Y, CellWidth, H, TXTA_Left, LevelText, Abilities.FontScale);
	
	ResetStyle(DStyle);
}

function InitMenu()
{
	Timer();
	SetTimer(1.f, true);
}

function CloseMenu()
{
	KillTimer();
	AbilityInfos.Length = 0;
}

function Timer()
{
	local int i;
	local RPGPlayerLevelInfo PLI;
	local AbilityInfo AInfo;
	local int OldAbilityListIndex, OldAbilityListTop;
	
	OldAbilityListIndex = Abilities.Index;
	OldAbilityListTop = Abilities.Top;
	
	Abilities.Clear();
	AbilityInfos.Remove(0, AbilityInfos.Length);
	
	foreach RPGMenu.RPRI.AllActors(class'RPGPlayerLevelInfo', PLI)
	{
		if(!PLI.PRI.bOnlySpectator)
		{
			AInfo.PlayerName = PLI.PRI.PlayerName;
			
			if(PLI.PRI.Team != None)
				AInfo.Team = PLI.PRI.Team.TeamIndex;
			else
				AInfo.Team = 255;
			
			AInfo.Level = PLI.RPGLevel;
			AInfo.Exp = PLI.Experience;
			AInfo.ExpNeeded = PLI.ExpNeeded;
			
			for(i = 0; i < AbilityInfos.Length; i++)
			{
				if(AbilityInfos[i].Level < AInfo.Level || (AbilityInfos[i].Level == AInfo.Level && AbilityInfos[i].Exp < AInfo.Exp))
					break;
			}
			AbilityInfos.Insert(i, 1);
			AbilityInfos[i] = AInfo;
			
			Abilities.AddedItem();
		}
	}
	
	Abilities.SetIndex(OldAbilityListIndex);
	Abilities.SetTopItem(OldAbilityListTop);
}

function bool AbilitySelected(GUIComponent Sender)
{
	Abilities.InternalOnClick(Sender);
	return true;
}

defaultproperties
{
	TeamTextColor(0)=(R=255,G=128,B=128,A=255)
	TeamTextColor(1)=(R=128,G=128,B=255,A=255)
	TeamTextColor(2)=(R=128,G=255,B=128,A=255)
	TeamTextColor(3)=(R=255,G=255,B=128,A=255)

	Begin Object Class=AltSectionBackground Name=sbAbilities_
		Caption="Player levels"
		LeftPadding=0.000000
		RightPadding=0.000000
		WinWidth=0.997718
		WinHeight=0.929236
		WinLeft=0.000085
		WinTop=0.013226
		OnPreDraw=sbAbilities_.InternalPreDraw
	End Object
	sbAbilities=AltSectionBackground'sbAbilities_'

	Begin Object Class=GUIMultiColumnListBox Name=lstAbilities_
		bAcceptsInput=True
		bVisibleWhenEmpty=True
		bDisplayHeader=True
		ColumnHeadings(0)="Player"
		HeaderColumnPerc(0)=0.40
		ColumnHeadings(1)="Level"
		HeaderColumnPerc(1)=0.60
		SelectedStyleName="BrowserListSelection"
		OnCreateComponent=lstAbilities_.InternalOnCreateComponent
		StyleName="ServerBrowserGrid"
		WinWidth=0.969019
		WinHeight=0.785741
		WinLeft=0.014434
		WinTop=0.082350
	End Object
	lstAbilities=GUIMultiColumnListBox'lstAbilities_'
	
	WinHeight=0.700000
}