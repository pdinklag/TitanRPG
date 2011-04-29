class RPGMenu_Stats extends RPGMenu_TabPage;

var array<RPGAbility> Stats;

var automated GUISectionBackground sbAbilities;
var automated GUILabel lblStats;
var automated GUIMultiColumnListBox lstAbilities;
var automated GUIMultiColumnList Abilities;
var automated GUIButton btBuy;

var automated moEditBox ebAmount;
var int LastAmount;

var GUIStyles CategoryStyle;

var bool bLoseFocus; //fix

var localized string Text_Max, Text_StatsAvailable;

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
	Super.InitComponent(MyController, MyOwner);

	Abilities = lstAbilities.List;
	Abilities.bMultiselect = false;
	Abilities.bInitializeList = false;
	Abilities.SortColumn = -1;
	Abilities.OnDrawItem = DrawAbilityInfo;
	Abilities.OnClick = OnAbilityClick;
	Abilities.OnKeyEvent = OnAbilityKeyEvent;
	
	ebAmount.OnKeyEvent = OnAmountKeyEvent;
}

function DrawAbilityInfo(Canvas Canvas, int i, float X, float Y, float W, float H, bool bSelected, bool bPending)
{
	local string LevelString;
	local float CellLeft, CellWidth;
	local GUIStyles DStyle;
	
	if(Stats[i].IsA('RPGAbilityCategory'))
		DStyle = Abilities.SectionStyle;
	else if(bSelected)
        DStyle = Abilities.SelectedStyle;
    else
        DStyle = Abilities.Style;

	DStyle.Draw(Canvas, Abilities.MenuState, X, Y, W, H + 1);

	Abilities.GetCellLeftWidth(0, CellLeft, CellWidth);
	DStyle.DrawText(Canvas, Abilities.MenuState, CellLeft, Y, CellWidth, H, TXTA_Left, Stats[i].StatName @ Stats[i].StatDescriptionText(), Abilities.FontScale);

	if(!Stats[i].IsA('RPGAbilityCategory'))
	{
		LevelString = string(Stats[i].AbilityLevel);

		if(Stats[i].AbilityLevel >= Stats[i].MaxLevel)
			LevelString @= Text_Max;

		Abilities.GetCellLeftWidth(1, CellLeft, CellWidth);
		DStyle.DrawText(Canvas, Abilities.MenuState, CellLeft, Y, CellWidth, H, TXTA_Left, LevelString, Abilities.FontScale);
	}
}

function InitMenu()
{
	local RPGAbility Ability;
	local int OldAbilityListIndex, OldAbilityListTop;
	local int i;
	
	OldAbilityListIndex = Abilities.Index;
	OldAbilityListTop = Abilities.Top;
	
	Abilities.Clear();
	Stats.Length = 0;
	
	for(i = 0; i < RPGMenu.RPRI.AllAbilities.Length; i++)
	{
		Ability = RPGMenu.RPRI.AllAbilities[i];
		if(Ability.bIsStat)
		{
			Stats[Stats.Length] = Ability;
			Abilities.AddedItem();
		}
	}
	
	ebAmount.SetText(string(LastAmount));
	
	if(bLoseFocus)
	{
		ebAmount.LoseFocus(None);
		bLoseFocus = true;
	}

	Abilities.SetIndex(OldAbilityListIndex);
	Abilities.SetTopItem(OldAbilityListTop);
	
	lblStats.Caption = Text_StatsAvailable @ string(RPGMenu.RPRI.PointsAvailable);
	
	SelectAbility();
}

function CloseMenu()
{
	LastAmount = int(ebAmount.GetText());
	bLoseFocus = true;
	Stats.Length = 0;
}

function SelectAbility()
{
	local RPGAbility Stat;
	
	RPGMenu.RPRI.ServerNoteActivity(); //Disable idle kicking when actually doing something
	
	if(Abilities.Index >= 0)
	{
		Stat = Stats[Abilities.Index];
		
		if(Stat.AbilityLevel < Stat.MaxLevel && RPGMenu.RPRI.PointsAvailable >= Stat.StartingCost)
			btBuy.MenuState = MSAT_Blurry;
		else
			btBuy.MenuState = MSAT_Disabled;
	}
	else
	{
		btBuy.MenuState = MSAT_Disabled;
	}
}

function bool OnAbilityKeyEvent(out byte Key, out byte State, float delta)
{
	Abilities.InternalOnKeyEvent(Key, State, delta);

	if((Key == 38 || Key == 40) && State == 3) //up / down key released
	{
		SelectAbility();
		return true;
	}
	else
	{
		return false;
	}
}

function bool OnAmountKeyEvent(out byte Key, out byte State, float delta)
{
	if(Key == 13 && State == 3) //up / down key released
	{
		BuyStat(None);
		return true;
	}
	else
	{
		return false;
	}
}

function bool OnAbilityClick(GUIComponent Sender)
{
	Abilities.InternalOnClick(Sender);
	SelectAbility();
	return true;
}

function bool BuyStat(GUIComponent Sender)
{
	local int Amount;
	local RPGAbility Stat;

	RPGMenu.RPRI.ServerNoteActivity(); //Disable idle kicking when actually doing something
	
	LastAmount = int(ebAmount.GetText());
	Amount = Min(RPGMenu.RPRI.PointsAvailable, Max(1, int(ebAmount.GetText())));
	if(Abilities.Index >= 0 && Amount > 0)
	{
		Stat = Stats[Abilities.Index];
		
		if(Stat.Buy(Amount) && RPGMenu.RPRI.Role < ROLE_Authority) //simulate for a pingless update if client
			RPGMenu.RPRI.ServerBuyAbility(Stat, Amount);
	}

	return true;
}

defaultproperties
{
	Text_StatsAvailable="Available Stat Points:"
	Text_Max="(MAX)"
	
	LastAmount=5

	Begin Object Class=AltSectionBackground Name=sbAbilities_
		Caption="Available Stats"
		LeftPadding=0.000000
		RightPadding=0.000000
		WinWidth=0.997718
		WinHeight=0.850358
		WinLeft=0.000085
		WinTop=0.013567
		OnPreDraw=sbAbilities_.InternalPreDraw
	End Object
	sbAbilities=AltSectionBackground'sbAbilities_'

	Begin Object Class=GUIMultiColumnListBox Name=lstAbilities_
		bAcceptsInput=True
		bVisibleWhenEmpty=True
		bDisplayHeader=True
		ColumnHeadings(0)="Stat"
		HeaderColumnPerc(0)=0.67
		ColumnHeadings(1)="You have"
		HeaderColumnPerc(1)=0.33
		OnCreateComponent=lstAbilities_.InternalOnCreateComponent
		StyleName="ServerBrowserGrid"
		SelectedStyleName="BrowserListSelection"
		SectionStyleName="RPGListSection"
		WinWidth=0.969373
		WinHeight=0.694255
		WinLeft=0.014257
		WinTop=0.082763
	End Object
	lstAbilities=GUIMultiColumnListBox'lstAbilities_'

	Begin Object Class=GUIButton Name=btBuy_
		WinWidth=0.056542
		WinHeight=0.077867
		WinLeft=0.932053
		WinTop=0.859569
		Caption="+"
		OnClick=BuyStat
		OnKeyEvent=btBuy_.InternalOnKeyEvent
	End Object
	btBuy=GUIButton'btBuy_'
	
	Begin Object Class=moEditBox Name=ebAmount_
		WinWidth=0.277163
		WinHeight=0.042105
		WinLeft=0.654705
		WinTop=0.875930
		Hint="Amount of levels to buy"
		Caption="Quantity"
	End Object
	ebAmount=moEditBox'ebAmount_'
	
	Begin Object Class=GUILabel Name=lblStats_
		WinWidth=0.476529
		WinHeight=0.070657
		WinLeft=0.016231
		WinTop=0.864362
		StyleName="NoBackground"
	End Object
	lblStats=GUILabel'lblStats_'

	WinHeight=0.700000
}