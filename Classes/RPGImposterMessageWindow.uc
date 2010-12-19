class RPGImposterMessageWindow extends FloatingWindow;

var automated AltSectionBackground sbImposter;
var automated GUIButton btOK;
var automated GUILabel lblImposterMessage;

var localized string WindowTitle, ImposterText;

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
	Super.InitComponent(MyController, MyOwner);
	
	OnClose=MyOnClose;
	
	t_WindowTitle.SetCaption(WindowTitle);
	lblImposterMessage.Caption = ImposterText;
}

function bool InternalOnClick(GUIComponent Sender)
{
	Controller.CloseMenu(false);
	return true;
}

function MyOnClose(optional bool bCanceled)
{
	Super.OnClose(bCanceled);
}

defaultproperties
{
	WindowTitle="Name already taken"	
	ImposterText="Sorry, your name is already used on this server.|This is a roleplaying game server and every character must have a unique name.||Please choose a different name and reconnect, or stay with your randomly assigned name to try things out. Your progress will then not be saved."
	
	bResizeWidthAllowed=False
	bResizeHeightAllowed=False
	bMoveAllowed=False
	bPersistent=True
    bAllowedAsLast=True
	
	WinWidth=0.600000
	WinHeight=0.624722
	WinLeft=0.214063
	WinTop=0.138333

	Begin Object Class=AltSectionBackground Name=ImposterBackground
		Caption="Name already taken"
		LeftPadding=0.000000
		RightPadding=0.000000
		WinWidth=0.968723
		WinHeight=0.745506
		WinLeft=0.015875
		WinTop=0.097353
		OnPreDraw=ImposterBackground.InternalPreDraw
	End Object
	sbImposter=AltSectionBackground'ImposterBackground'

	Begin Object Class=GUIButton Name=OkButton
		Caption="OK"
		TabOrder=0
		WinWidth=0.482870
		WinHeight=0.081551
		WinLeft=0.497916
		WinTop=0.842546
		OnClick=RPGImposterMessageWindow.InternalOnClick
		OnKeyEvent=OkButton.InternalOnKeyEvent
	End Object
	btOK=GUIButton'OkButton'

	Begin Object Class=GUILabel Name=ImposterMsg
		WinWidth=0.915046
		WinHeight=0.390509
		WinLeft=0.042592
		WinTop=0.214305
		StyleName="NoBackground"
		bMultiLine=True
	End Object
	lblImposterMessage=GUILabel'ImposterMsg'
}
