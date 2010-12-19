class RPGSwitchConfirmationWindow extends FloatingWindow;

var RPGMenu RPGMenu;
var string NewBuild;

var automated GUISectionBackground sbConfirm;
var automated GUIButton btYes, btNo;
var automated GUILabel lblWarning;

var localized string WindowTitle, Text_Switch;

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
	Super.InitComponent(MyController, MyOwner);
	
	OnClose=MyOnClose;
	
	t_WindowTitle.SetCaption(WindowTitle);
}

function Init()
{
	local string x;

	x = repl(Text_Switch, "$1",
		class'Util'.static.HighlightText(NewBuild, class'Util'.default.HighlightColor, lblWarning.Style.FontColors[0]));

	lblWarning.Caption = repl(x, "$2",
		class'Util'.static.HighlightText(RPGMenu.RPRI.RPGName, class'Util'.default.HighlightColor, lblWarning.Style.FontColors[0]));
}

function bool InternalOnClick(GUIComponent Sender)
{
	local GUIController OldController;

	if (Sender == btYes)
	{
		OldController = Controller;
		RPGMenu.RPRI.ServerSwitchBuild(NewBuild);
		Controller.CloseMenu(false);
		OldController.CloseMenu(false);
	}
	else
		Controller.CloseMenu(false);

	return true;
}

function MyOnClose(optional bool bCanceled)
{
	RPGMenu = None;
	Super.OnClose(bCanceled);
}

defaultproperties
{
	WindowTitle="Switch Character"
	Text_Switch="Are you sure you want to switch to $1?|$2 will be saved automatically."
	
	bResizeWidthAllowed=False
	bResizeHeightAllowed=False
	bMoveAllowed=False
	bPersistent=True
    bAllowedAsLast=True
	
	WinWidth=0.600000
	WinHeight=0.374723
	WinLeft=0.200000
	WinTop=0.138333

	Begin Object Class=AltSectionBackground Name=sbConfirm_
		Caption="Confirm Character Switch"
		LeftPadding=0.000000
		RightPadding=0.000000
		WinWidth=0.968723
		WinHeight=0.633004
		WinLeft=0.015875
		WinTop=0.097353
		OnPreDraw=sbConfirm_.InternalPreDraw
	End Object
	sbConfirm=AltSectionBackground'sbConfirm_'

	Begin Object Class=GUIButton Name=YesButton
		Caption="Yes"
		TabOrder=1
		WinWidth=0.482870
		WinHeight=0.149259
		WinLeft=0.015741
		WinTop=0.728191
		OnClick=RPGSwitchConfirmationWindow.InternalOnClick
		OnKeyEvent=YesButton.InternalOnKeyEvent
	End Object
	btYes=GUIButton'YesButton'

	Begin Object Class=GUIButton Name=NoButton
		Caption="No"
		TabOrder=0
		WinWidth=0.482870
		WinHeight=0.149259
		WinLeft=0.504687
		WinTop=0.729162
		OnClick=RPGSwitchConfirmationWindow.InternalOnClick
		OnKeyEvent=NoButton.InternalOnKeyEvent
	End Object
	btNo=GUIButton'NoButton'

	Begin Object Class=GUILabel Name=ResetDesc
		WinWidth=0.915046
		WinHeight=0.390509
		WinLeft=0.042592
		WinTop=0.214305
		StyleName="NoBackground"
		bMultiLine=True
	End Object
	lblWarning=GUILabel'ResetDesc'
}
