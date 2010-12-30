class RPGMenu_Settings extends RPGMenu_TabPage;

var automated GUISectionBackground sbCustomize;
var automated moCheckBox chkWeaponExtra, chkArtifactText, chkExpGain, chkExpBar, chkHints, chkClassicArtifactSelection;
var automated moSlider slExpGain, slIconsPerRow, slIconScale, slIconsX, slIconsY, slExpBarX, slExpBarY;

function InitComponent(GUIController MyController, GUIComponent MyOwner)
{
	Super.InitComponent(MyController, MyOwner);
}

function InitMenu()
{
	chkWeaponExtra.Checked(!RPGMenu.RPRI.Interaction.Settings.bHideWeaponExtra);
	chkArtifactText.Checked(!RPGMenu.RPRI.Interaction.Settings.bHideArtifactName);
	chkExpBar.Checked(!RPGMenu.RPRI.Interaction.Settings.bHideExpBar);
	chkClassicArtifactSelection.Checked(RPGMenu.RPRI.Interaction.Settings.bClassicArtifactSelection);
	
	slExpGain.SetComponentValue(string(RPGMenu.RPRI.Interaction.Settings.ExpGainDuration), true);
	slExpBarX.SetComponentValue(string(RPGMenu.RPRI.Interaction.Settings.ExpBarX), true);
	slExpBarY.SetComponentValue(string(RPGMenu.RPRI.Interaction.Settings.ExpBarY), true);
	if(chkExpBar.IsChecked())
	{
		slExpGain.MySlider.MenuState = MSAT_Blurry;
		slExpBarX.MySlider.MenuState = MSAT_Blurry;
		slExpBarY.MySlider.MenuState = MSAT_Blurry;
	}
	else
	{
		slExpGain.MySlider.MenuState = MSAT_Disabled;
		slExpBarX.MySlider.MenuState = MSAT_Disabled;
		slExpBarY.MySlider.MenuState = MSAT_Disabled;
	}
	
	slIconsPerRow.SetComponentValue(string(RPGMenu.RPRI.Interaction.Settings.IconsPerRow), true);
	if(chkClassicArtifactSelection.IsChecked())
		slIconsPerRow.MySlider.MenuState = MSAT_Disabled;
	else
		slIconsPerRow.MySlider.MenuState = MSAT_Blurry;

	slIconScale.SetComponentValue(string(RPGMenu.RPRI.Interaction.Settings.IconScale), true);
	slIconsX.SetComponentValue(string(RPGMenu.RPRI.Interaction.Settings.IconsX), true);
	
	if(chkClassicArtifactSelection.IsChecked())
		slIconsY.SetComponentValue(string(RPGMenu.RPRI.Interaction.Settings.IconClassicY), true);
	else
		slIconsY.SetComponentValue(string(RPGMenu.RPRI.Interaction.Settings.IconsY), true);
}

function InternalOnChange(GUIComponent Sender)
{
	RPGMenu.RPRI.ServerNoteActivity(); //Disable idle kicking when actually doing something

	switch(Sender)
	{
		case chkWeaponExtra:
			RPGMenu.RPRI.Interaction.Settings.bHideWeaponExtra = !chkWeaponExtra.IsChecked();
			break;
			
		case chkArtifactText:
			RPGMenu.RPRI.Interaction.Settings.bHideArtifactName = !chkArtifactText.IsChecked();
			break;
			
		case chkExpBar:
			RPGMenu.RPRI.Interaction.Settings.bHideExpBar = !chkExpBar.IsChecked();
			
			if(chkExpBar.IsChecked())
			{
				slExpGain.MySlider.MenuState = MSAT_Blurry;
				slExpBarX.MySlider.MenuState = MSAT_Blurry;
				slExpBarY.MySlider.MenuState = MSAT_Blurry;
			}
			else
			{
				slExpGain.MySlider.MenuState = MSAT_Disabled;
				slExpBarX.MySlider.MenuState = MSAT_Disabled;
				slExpBarY.MySlider.MenuState = MSAT_Disabled;
			}

			break;
			
		case slExpGain:
			RPGMenu.RPRI.Interaction.Settings.ExpGainDuration = float(slExpGain.GetComponentValue());
			break;
			
		case slIconsPerRow:
			RPGMenu.RPRI.Interaction.Settings.IconsPerRow = int(slIconsPerRow.GetComponentValue());
			break;
			
		case slIconScale:
			RPGMenu.RPRI.Interaction.Settings.IconScale = float(slIconScale.GetComponentValue());
			break;
			
		case slExpBarX:
			RPGMenu.RPRI.Interaction.Settings.ExpBarX = float(slExpBarX.GetComponentValue());
			break;

		case slExpBarY:
			RPGMenu.RPRI.Interaction.Settings.ExpBarY = float(slExpBarY.GetComponentValue());
			break;
			
		case slIconsX:
			RPGMenu.RPRI.Interaction.Settings.IconsX = float(slIconsX.GetComponentValue());
			break;
			
		case slIconsY:
			if(chkClassicArtifactSelection.IsChecked())
				RPGMenu.RPRI.Interaction.Settings.IconClassicY = float(slIconsY.GetComponentValue());
			else
				RPGMenu.RPRI.Interaction.Settings.IconsY = float(slIconsY.GetComponentValue());
				
			break;
		
		case chkExpGain:
			RPGMenu.RPRI.Interaction.Settings.bHideExpGain = !chkExpGain.IsChecked();
			break;

		case chkClassicArtifactSelection:
			RPGMenu.RPRI.Interaction.Settings.bClassicArtifactSelection = chkClassicArtifactSelection.IsChecked();
			
			if(chkClassicArtifactSelection.IsChecked())
				slIconsPerRow.MySlider.MenuState = MSAT_Disabled;
			else
				slIconsPerRow.MySlider.MenuState = MSAT_Blurry;
			
			if(chkClassicArtifactSelection.IsChecked())
				slIconsY.SetComponentValue(string(RPGMenu.RPRI.Interaction.Settings.IconClassicY), true);
			else
				slIconsY.SetComponentValue(string(RPGMenu.RPRI.Interaction.Settings.IconsY), true);
			
			break;
		
		case chkHints:
			RPGMenu.RPRI.Interaction.Settings.bHideHints = !chkHints.IsChecked();
			break;
	}
	
	RPGMenu.RPRI.Interaction.bUpdateCanvas = true;
}

defaultproperties
{
	//Y spacing: 0.052451

	Begin Object Class=AltSectionBackground Name=sbCustomize_
		Caption="TitanRPG Settings"
		LeftPadding=0.000000
		RightPadding=0.000000
		WinWidth=0.997718
		WinHeight=0.929236
		WinLeft=0.000085
		WinTop=0.013226
		OnPreDraw=sbCustomize_.InternalPreDraw
	End Object
	sbCustomize=AltSectionBackground'sbCustomize_'
	
	Begin Object Class=moCheckBox Name=chkArtifactInfo_
		TabOrder=0
		Caption="Show Artifact name"
		Hint="If checked, the name of an artifact is displayed on the screen when selecting one (similar to weapons)."
		WinWidth=0.469274
		WinHeight=0.041475
		WinLeft=0.022492
		WinTop=0.101052
		OnChange=RPGMenu_Settings.InternalOnChange
		OnCreateComponent=chkArtifactInfo_.InternalOnCreateComponent
	End Object
	chkArtifactText=moCheckBox'chkArtifactInfo_'
	
	Begin Object Class=moCheckBox Name=chkWeaponExtra_
		TabOrder=1
		Caption="Show extra information"
		Hint="If checked, a short description about a weapon's magic is displayed below its name when selected. Also controls the extra description for artifacts."
		WinWidth=0.469274
		WinHeight=0.041475
		WinLeft=0.022492
		WinTop=0.153503
		OnChange=RPGMenu_Settings.InternalOnChange
		OnCreateComponent=chkWeaponExtra_.InternalOnCreateComponent
	End Object
	chkWeaponExtra=moCheckBox'chkWeaponExtra_'

	Begin Object Class=moCheckBox Name=chkClassicArtifactSelection_
		TabOrder=2
		Caption="Single artifact display"
		Hint="If checked, only the currently selected artifact will be displayed on the screen like in the old UT2004 RPG versions."
		WinWidth=0.469274
		WinHeight=0.041475
		WinLeft=0.022492
		WinTop=0.205954
		OnChange=RPGMenu_Settings.InternalOnChange
		OnCreateComponent=chkClassicArtifactSelection_.InternalOnCreateComponent
	End Object
	chkClassicArtifactSelection=moCheckBox'chkClassicArtifactSelection_'

	Begin Object Class=moSlider Name=slIconsPerRow_
		TabOrder=3
		Caption="Artifact icons per row"
		Hint="Determine how many artifact icons can be displayed in one vertical row."
		MinValue=1
		MaxValue=25
		bIntSlider=true
		WinWidth=0.877837
		WinHeight=0.041475
		WinLeft=0.022492
		WinTop=0.258405
		OnChange=RPGMenu_Settings.InternalOnChange
		OnCreateComponent=slIconsPerRow_.InternalOnCreateComponent
	End Object
	slIconsPerRow=moSlider'slIconsPerRow_'
	
	Begin Object Class=moSlider Name=slIconScale_
		TabOrder=4
		Caption="Artifact icon scale"
		Hint="Determine the scale of the artifact icons."
		MinValue=0.5
		MaxValue=1.5
		bIntSlider=false
		WinWidth=0.877837
		WinHeight=0.041475
		WinLeft=0.022492
		WinTop=0.310856
		OnChange=RPGMenu_Settings.InternalOnChange
		OnCreateComponent=slIconScale_.InternalOnCreateComponent
	End Object
	slIconScale=moSlider'slIconScale_'
	
	Begin Object Class=moSlider Name=slIconsX_
		TabOrder=5
		Caption="Artifact icon X"
		Hint="Determine the X position of the artifact icon(s)."
		MinValue=0.0
		MaxValue=1.0
		bIntSlider=false
		WinWidth=0.877837
		WinHeight=0.041475
		WinLeft=0.022492
		WinTop=0.363307
		OnChange=RPGMenu_Settings.InternalOnChange
		OnCreateComponent=slIconsX_.InternalOnCreateComponent
	End Object
	slIconsX=moSlider'slIconsX_'
	
	Begin Object Class=moSlider Name=slIconsY_
		TabOrder=6
		Caption="Artifact icon Y"
		Hint="Determine the Y position of the artifact icon(s)."
		MinValue=0.0
		MaxValue=1.0
		bIntSlider=false
		WinWidth=0.877837
		WinHeight=0.041475
		WinLeft=0.022492
		WinTop=0.415758
		OnChange=RPGMenu_Settings.InternalOnChange
		OnCreateComponent=slIconsY_.InternalOnCreateComponent
	End Object
	slIconsY=moSlider'slIconsY_'
	
	Begin Object Class=moCheckBox Name=chkExpBar_
		TabOrder=7
		Caption="Show experience bar"
		Hint="If checked, your level, experience and experience gain is displayed on the right side of your screen."
		WinWidth=0.469274
		WinHeight=0.041475
		WinLeft=0.022492
		WinTop=0.468209
		OnChange=RPGMenu_Settings.InternalOnChange
		OnCreateComponent=chkExpBar_.InternalOnCreateComponent
	End Object
	chkExpBar=moCheckBox'chkExpBar_'
	
	Begin Object Class=moSlider Name=slExpBarX_
		TabOrder=8
		Caption="Experience bar X"
		Hint="Determine the X position of the experience bar."
		MinValue=0.0
		MaxValue=1.0
		bIntSlider=false
		WinWidth=0.877837
		WinHeight=0.041475
		WinLeft=0.022492
		WinTop=0.520660
		OnChange=RPGMenu_Settings.InternalOnChange
		OnCreateComponent=slExpBarX_.InternalOnCreateComponent
	End Object
	slExpBarX=moSlider'slExpBarX_'
	
	Begin Object Class=moSlider Name=slExpBarY_
		TabOrder=9
		Caption="Experience bar Y"
		Hint="Determine the Y position of the experience bar."
		MinValue=0.0
		MaxValue=1.0
		bIntSlider=false
		WinWidth=0.877837
		WinHeight=0.041475
		WinLeft=0.022492
		WinTop=0.573111
		OnChange=RPGMenu_Settings.InternalOnChange
		OnCreateComponent=slExpBarY_.InternalOnCreateComponent
	End Object
	slExpBarY=moSlider'slExpBarY_'
	
	Begin Object Class=moSlider Name=slExpGain_
		TabOrder=10
		Caption="Experience gain duration"
		Hint="Select for how many seconds your exp gain should be displayed below the exp bar. 0 means never display, 21 means display for the whole match."
		MinValue=0
		MaxValue=21 //FIXME - somehow synchronize this with class'RPGInteraction'.default.ExpGainDurationForever
		bIntSlider=true
		WinWidth=0.877837
		WinHeight=0.041475
		WinLeft=0.022492
		WinTop=0.625562
		OnChange=RPGMenu_Settings.InternalOnChange
		OnCreateComponent=slExpGain_.InternalOnCreateComponent
	End Object
	slExpGain=moSlider'slExpGain_'

	WinHeight=0.700000
}