class RPGMenu_Abilities extends RPGMenu_TabPage;

var array<class<RPGAbilityCategory> > Categories;

struct AbilityInfo
{
	var class<RPGAbilityCategory> Category; //if not None, this entry is a category header
	
	var RPGAbility LinkedAbility;
	var string Name;
	var int NextLevel;
	var int Cost;
};
var array<AbilityInfo> AbilityInfos;

var automated GUISectionBackground sbAbilities, sbDesc;
var automated GUIScrollTextBox lblDesc;
var automated GUILabel lblStats;
var automated GUIMultiColumnListBox lstAbilities;
var automated GUIMultiColumnList Abilities;
var automated GUIButton btBuy;

var GUIStyles CategoryStyle;

var localized string 
	Text_Buy, Text_BuyX, Text_Level, Text_Stats, Text_CantBuy, Text_Requirements, Text_AlreadyMax, Text_Max, Text_Forbidden, Text_DoNotHaveThisYet,
	Text_StatsAvailable, Text_Intro, Text_Description;

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
	
	//sbAbilities.ManageComponent(lstAbilities);
	//sbDesc.ManageComponent(lblDesc);
	
	lblDesc.MyScrollText.SetContent(Text_Intro);
}

function DrawAbilityInfo(Canvas Canvas, int i, float X, float Y, float W, float H, bool bSelected, bool bPending)
{
	local int Level, MaxLevel;
	local string CostString, LevelString;
	local float CellLeft, CellWidth;
	local GUIStyles DStyle;
	
	if(AbilityInfos[i].Category != None)
		DStyle = Abilities.SectionStyle;
	else if(bSelected)
        DStyle = Abilities.SelectedStyle;
    else
        DStyle = Abilities.Style;

	DStyle.Draw(Canvas, Abilities.MenuState, X, Y, W, H + 1);

	Abilities.GetCellLeftWidth(0, CellLeft, CellWidth);
	DStyle.DrawText(Canvas, Abilities.MenuState, CellLeft, Y, CellWidth, H, TXTA_Left, AbilityInfos[i].Name, Abilities.FontScale);

	if(AbilityInfos[i].LinkedAbility != None)
	{
		MaxLevel = AbilityInfos[i].LinkedAbility.MaxLevel;
		Level = AbilityInfos[i].LinkedAbility.AbilityLevel;
		if(Level == 0)
		{
			LevelString = Text_DoNotHaveThisYet;
		}
		else
		{
			LevelString = Text_Level @ string(Level);
			
			if(Level >= MaxLevel)
				LevelString @= Text_Max;
		}

		Abilities.GetCellLeftWidth(1, CellLeft, CellWidth);
		DStyle.DrawText(Canvas, Abilities.MenuState, CellLeft, Y, CellWidth, H, TXTA_Left, LevelString, Abilities.FontScale);
		
		if(Level < MaxLevel)
		{
			if(AbilityInfos[i].Cost > 0)
				CostString = string(AbilityInfos[i].Cost);
			else
				CostString = Text_CantBuy;
		}
		else
		{
			CostString = Text_AlreadyMax;
		}
			
		Abilities.GetCellLeftWidth(2, CellLeft, CellWidth);
		DStyle.DrawText(Canvas, Abilities.MenuState, CellLeft, Y, CellWidth, H, TXTA_Left, CostString, Abilities.FontScale);
	}
}

function InitMenu()
{
	local AbilityInfo AInfo;
	local RPGAbility Ability;
	local int OldAbilityListIndex, OldAbilityListTop;
	local int i, k, n, x;

	OldAbilityListIndex = Abilities.Index;
	OldAbilityListTop = Abilities.Top;
	
	Abilities.Clear();
	AbilityInfos.Length = 0;
	
	for(i = 0; i < Categories.Length; i++)
	{
		x = AbilityInfos.Length;
		n = 0;
		
		for(k = 0; k < RPGMenu.RPRI.AllAbilities.Length; k++)
		{
			Ability = RPGMenu.RPRI.AllAbilities[k];
			if(!Ability.bIsStat && Ability.Category == Categories[i])
			{
				n++;
				
				AInfo.LinkedAbility = Ability;
				AInfo.Name = Ability.AbilityName;
				
				if(Ability.AbilityLevel < Ability.MaxLevel)
					AInfo.NextLevel = Ability.AbilityLevel + 1;
				else
					AInfo.NextLevel = 0;

				AInfo.Cost = Ability.Cost();
	
				AbilityInfos[AbilityInfos.Length] = AInfo;
				Abilities.AddedItem();
			}
		}
		
		if(n > 0)
		{
			AInfo.LinkedAbility = None;
			AInfo.Category = Categories[i];
			AInfo.Cost = 0;
			AInfo.NextLevel = 0;
			AInfo.Name = Categories[i].default.CategoryName;
			
			AbilityInfos.Insert(x, 1);
			AbilityInfos[x] = AInfo;
			Abilities.AddedItem();
			
			AInfo.Category = None;
		}
	}
	
	Abilities.SetIndex(OldAbilityListIndex);
	Abilities.SetTopItem(OldAbilityListTop);
	
	lblStats.Caption = Text_StatsAvailable @ string(RPGMenu.RPRI.PointsAvailable);
	
	SelectAbility();
}

function CloseMenu()
{
	AbilityInfos.Length = 0;
}

function SelectAbility()
{
	local AbilityInfo AInfo;
	
	RPGMenu.RPRI.ServerNoteActivity(); //Disable idle kicking when actually doing something
	
	if(Abilities.Index >= 0)
	{
		AInfo = AbilityInfos[Abilities.Index];
		
		if(AInfo.Cost > 0 && AInfo.NextLevel > 0 && RPGMenu.RPRI.PointsAvailable >= AInfo.Cost)
		{
			btBuy.Caption = Repl(Text_BuyX, "$1", AInfo.Name @ string(AInfo.NextLevel));
			btBuy.MenuState = MSAT_Blurry;
		}
		else
		{
			btBuy.Caption = Text_Buy;
			btBuy.MenuState = MSAT_Disabled;
		}	
		
		sbDesc.Caption = AInfo.Name;
		
		if(AInfo.Category != None)
			lblDesc.MyScrollText.SetContent(AInfo.Category.default.Description);
		else if(AInfo.LinkedAbility != None)
			lblDesc.MyScrollText.SetContent(AInfo.LinkedAbility.DescriptionText());
	}
	else
	{
		btBuy.Caption = Text_Buy;
		btBuy.MenuState = MSAT_Disabled;
		
		sbDesc.Caption = Text_Description;
		lblDesc.MyScrollText.SetContent(Text_Intro);
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

function bool OnAbilityClick(GUIComponent Sender)
{
	Abilities.InternalOnClick(Sender);
	SelectAbility();
	return true;
}

function bool BuyAbility(GUIComponent Sender)
{
	local AbilityInfo AInfo;

	RPGMenu.RPRI.ServerNoteActivity(); //Disable idle kicking when actually doing something
	if(Abilities.Index >= 0)
	{
		AInfo = AbilityInfos[Abilities.Index];
		
		if(AInfo.LinkedAbility != None)
		{
			if(AInfo.LinkedAbility.Buy() && RPGMenu.RPRI.Role < ROLE_Authority) //simulate for a pingless update if client
				RPGMenu.RPRI.ServerBuyAbility(AInfo.LinkedAbility);
		}
	}

	return true;
}

defaultproperties
{
	Categories(0)=class'AbilityCategory_Damage'
	Categories(1)=class'AbilityCategory_Health'
    Categories(2)=class'AbilityCategory_Adrenaline'
	Categories(3)=class'AbilityCategory_Weapons'
    Categories(4)=class'AbilityCategory_Artifacts'
	Categories(5)=class'AbilityCategory_Movement'
    Categories(6)=class'AbilityCategory_Vehicles'
	Categories(7)=class'AbilityCategory_Medic'
	Categories(8)=class'AbilityCategory_Monsters'
	Categories(9)=class'AbilityCategory_Engineer'
	Categories(10)=class'AbilityCategory_Misc'

	Text_StatsAvailable="Available Stat Points:"
	Text_Buy="Buy"
	Text_BuyX="Buy $1"
	Text_Level="Level"
	Text_Stats="Stats"
	Text_CantBuy="Can't buy"
	Text_AlreadyMax="Already at max"
	Text_Max="(MAX)"
	Text_Forbidden="Not allowed"
	Text_Requirements="Not available"
	Text_DoNotHaveThisYet="---"
	Text_Intro="Select an ability and see here for detailed information on it."
	Text_Description="Description"

	Begin Object Class=AltSectionBackground Name=sbAbilities_
		Caption="Available Abilities"
		LeftPadding=0.000000
		RightPadding=0.000000
		WinWidth=0.997718
		WinHeight=0.457739
		WinLeft=0.000085
		WinTop=0.013567
		OnPreDraw=sbAbilities_.InternalPreDraw
	End Object
	sbAbilities=AltSectionBackground'sbAbilities_'

	Begin Object Class=GUIMultiColumnListBox Name=lstAbilities_
		bAcceptsInput=True
		bVisibleWhenEmpty=True
		bDisplayHeader=True
		ColumnHeadings(0)="Ability"
		HeaderColumnPerc(0)=0.50
		ColumnHeadings(1)="You have"
		HeaderColumnPerc(1)=0.20
		ColumnHeadings(2)="Cost"
		HeaderColumnPerc(2)=0.30
		OnCreateComponent=lstAbilities_.InternalOnCreateComponent
		StyleName="ServerBrowserGrid"
		SelectedStyleName="BrowserListSelection"
		SectionStyleName="RPGListSection"
		WinWidth=0.969373
		WinHeight=0.329539
		WinLeft=0.014257
		WinTop=0.082763
	End Object
	lstAbilities=GUIMultiColumnListBox'lstAbilities_'
	
	Begin Object Class=AltSectionBackground Name=sbDesc_
		LeftPadding=0.000000
		RightPadding=0.000000
		WinWidth=0.997719
		WinHeight=0.387763
		WinLeft=0.000085
		WinTop=0.475889
		OnPreDraw=sbDesc_.InternalPreDraw
	End Object
	sbDesc=AltSectionBackground'sbDesc_'
	
	Begin Object Class=GUIScrollTextBox Name=lblDesc_
		bNoTeletype=False
		CharDelay=0.001250
		EOLDelay=0.001250
		OnCreateComponent=lblDesc_.InternalOnCreateComponent
		FontScale=FNS_Small
		WinWidth=0.949444
		WinHeight=0.204867
		WinLeft=0.024222
		WinTop=0.568014
		bNeverFocus=True
	End Object
	lblDesc=GUIScrollTextBox'lblDesc_'

	Begin Object Class=GUIButton Name=btBuy_
		WinWidth=0.516921
		WinHeight=0.060028
		WinLeft=0.479645
		WinTop=0.868341
		OnClick=BuyAbility
		OnKeyEvent=btBuy_.InternalOnKeyEvent
	End Object
	btBuy=GUIButton'btBuy_'
	
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