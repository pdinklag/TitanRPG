class RPGInteraction extends Interaction;

var RPGPlayerReplicationInfo RPRI;

var RPGSettings Settings;
var RPGCharSettings CharSettings;

var float TimeSeconds;

var bool bMenuEnabled; //false as long as server settings were not yet received

var bool bDefaultBindings, bDefaultArtifactBindings; //use default keybinds because user didn't set any
var float LastLevelMessageTime;
var Font TextFont;
var Color EXPBarColor, DisabledOverlay, RedColor, WhiteColor;
var Color HUDColorTeam[4], HUDTintTeam[4];
var localized string LevelText;

var Material ArrowMaterial;
var Material ArtifactBorderMaterial;
var float 
	ArtifactBorderMaterialTextureScale,
	ArtifactBorderMaterialU, ArtifactBorderMaterialV, ArtifactBorderMaterialUL, ArtifactBorderMaterialVL,
	ArtifactHighlightIndention;
var float ArtifactIconInnerScale;

var string LastWeaponExtra;

var class<RPGArtifact> LastSelectedArtifact;
var string LastSelItemName, LastSelExtra;
var float ArtifactDrawTimer;
var Color ArtifactDrawColor;

var float ExpGain, ExpGainTimer, ExpGainDurationForever;

var array<string> Hint;
var float HintTimer;
var float HintDuration;
var Color HintColor;

var localized string ArtifactTutorialText;

var float SummonedIconSize;
var Color SummonedIconOverlay;
var Material MonsterIcon, TurretIcon;

event Initialized()
{
	CheckBindings();
	TextFont = Font(DynamicLoadObject("UT2003Fonts.jFontSmall", class'Font'));
	
	//Load client settings
	Settings = new(None, "TitanRPG") class'RPGSettings';
	
	FindRPRI();
	CharSettings = new(None, RPRI.PRI.PlayerName) class'RPGCharSettings';
}

function CheckBindings()
{
	local EInputKey Key;
	local string KeyName, KeyBinding;
	
	bDefaultBindings = true;
	bDefaultArtifactBindings = true;
	
	//detect if user made custom binds for our aliases
	for(Key = IK_None; Key < IK_OEMClear; Key = EInputKey(Key + 1))
	{
		KeyName = ViewportOwner.Actor.ConsoleCommand("KEYNAME" @ Key);
		KeyBinding = ViewportOwner.Actor.ConsoleCommand("KEYBINDING" @ KeyName);
		
		if(KeyBinding ~= "RPGStatsMenu")
			bDefaultBindings = false;
		else if (KeyBinding ~= "ActivateItem" || KeyBinding ~= "NextItem" || KeyBinding ~= "PrevItem")
			bDefaultArtifactBindings = false;

		if(!bDefaultBindings && !bDefaultArtifactBindings)
			break;
	}
}

exec function RPGStatsMenu()
{
	if(bMenuEnabled)
	{
		if(RPRI == None)
			FindRPRI();

		if(RPRI != None)
		{
			ViewportOwner.GUIController.OpenMenu("<? echo($packageName); ?>.RPGMenu");
			RPGMenu(GUIController(ViewportOwner.GUIController).TopPage()).InitFor(RPRI);
		}
	}
}

//Detect pressing of a key bound to one of our aliases
//KeyType() would be more appropriate for what's done here, but Key doesn't seem to work/be set correctly for that function
//which prevents ConsoleCommand() from working on it
function bool KeyEvent(EInputKey Key, EInputAction Action, float Delta)
{
	if(Action != IST_Press)
		return false;
	
	if(bDefaultBindings && Key == IK_L)
	{
		RPGStatsMenu();
		return true;
	}
	else if(bDefaultArtifactBindings && ViewportOwner.Actor.Pawn != None)
	{
		if(Key == IK_U)
		{
			ViewportOwner.Actor.ActivateItem();
			return true;
		}
		else if(Key == IK_LeftBracket)
		{
			ViewportOwner.Actor.PrevItem();
			return true;
		}
		else if(Key == IK_RightBracket)
		{
			if (ViewportOwner.Actor.Pawn != None)
				ViewportOwner.Actor.Pawn.NextItem();

			return true;
		}
	}

	//Don't care about this event, pass it on for further processing
	return false;
}

function FindRPRI()
{
	local int i;
	
	if(RPRI != None)
		return;

	RPRI = class'RPGPlayerReplicationInfo'.static.GetFor(ViewportOwner.Actor);
	if(RPRI == None)
	{
		Warn("RPGInteraction: Could not find RPRI!");
		return;
	}

	RPRI.Interaction = Self;
	
	if(RPRI.bImposter)
		return;

	for(i = 0; i < Settings.MyBuilds.Length; i++)
	{
		if(Settings.MyBuilds[i] ~= RPRI.RPGName)
			return;
	}
	
	Log("Adding" @ RPRI.RPGName @ "to MyBuilds", 'TitanRPG');
	Settings.MyBuilds[Settings.MyBuilds.Length] = RPRI.RPGName;
	Settings.SaveConfig();
}

function int GetHUDTeamIndex(HudCDeathmatch HUD)
{
	if(HUD.IsA('HudOLTeamDeathmatch')) //OLTeamGames support
		return int(HUD.GetPropertyText("OLTeamIndex"));
	else
		return HUD.TeamIndex;
}

function Color GetHUDTeamColor(HudCDeathmatch HUD)
{
	local int TeamIndex;
	TeamIndex = GetHUDTeamIndex(HUD);

	if(TeamIndex >= 0 && TeamIndex <= 3)
		return HUDColorTeam[TeamIndex];
	else
		return HUDColorTeam[1];
}

function Color GetHUDTeamTint(HudCDeathmatch HUD)
{
	local int TeamIndex;
	TeamIndex = GetHUDTeamIndex(HUD);

	if(TeamIndex >= 0 && TeamIndex <= 3)
		return HUDTintTeam[TeamIndex];
	else
		return HUDTintTeam[1];
}

function DrawArtifactBox(class<RPGArtifact> AClass, RPGArtifact A, Canvas Canvas, HudCDeathmatch HUD, float tX, float tY, float Size, optional bool bSelected)
{
	local int x;
	local float XL, YL;

	Canvas.Style = 5;
	
	if(A != None && bSelected)
		Canvas.DrawColor = HUD.HudColorHighlight;
	else
		Canvas.DrawColor = GetHUDTeamColor(HUD);
	
	Canvas.SetPos(tX, tY);
	Canvas.DrawTile(ArtifactBorderMaterial, Size, Size, ArtifactBorderMaterialU, ArtifactBorderMaterialV, ArtifactBorderMaterialUL, ArtifactBorderMaterialVL);
	
	if(AClass.default.IconMaterial != None)
	{
		if(A != None && A.bActive)
			Canvas.DrawColor = GetHUDTeamColor(HUD);
		else if(A == None || TimeSeconds < A.NextUseTime)
			Canvas.DrawColor = DisabledOverlay;
		else
			Canvas.DrawColor = WhiteColor;
		
		Canvas.SetPos(tX + Size * 0.5 * (1.0 - ArtifactIconInnerScale), tY + Size * 0.5 * (1.0 - ArtifactIconInnerScale));
		Canvas.DrawTile(AClass.default.IconMaterial, Size * ArtifactIconInnerScale, Size * ArtifactIconInnerScale, 0, 0, AClass.default.IconMaterial.MaterialUSize(), AClass.default.IconMaterial.MaterialVSize());
	}
	
	if(A != None && TimeSeconds < A.NextUseTime)
	{
		x = int(A.NextUseTime - TimeSeconds) + 1;
		
		Canvas.DrawColor = WhiteColor;
		Canvas.TextSize(string(x), XL, YL);
		Canvas.SetPos(tX + (Size - XL) * 0.5, tY + (Size - YL) * 0.5);
		Canvas.DrawText(string(x));
	}
}

function float DrawSummoned(Canvas Canvas, Material Icon, float XL, float YL, float Size, int Num, int Max)
{
	local string Text;
	local float YLSmall, XLSmall;

	Canvas.SetPos(XL, YL);
	Canvas.Style = 5;
	Canvas.DrawColor = SummonedIconOverlay;
	Canvas.DrawTile(Icon, Size, Size, 0, 0, Icon.MaterialUSize(), Icon.MaterialVSize());
	
	Text = Num $ "/" $ Max;
	Canvas.TextSize(Text, XLSmall, YLSmall);
	Canvas.SetPos(XL + (Size - XLSmall) * 0.5, YL + (Size - YLSmall) * 0.5);
	Canvas.DrawColor = WhiteColor;
	Canvas.DrawText(Text);
	
	return Size + 1;
}

function PostRender(Canvas Canvas)
{
	local float XL, YL, XLSmall, YLSmall, EXPBarX, EXPBarY, EXPBarW, EXPBarH;
	local float tX, tY, xX, xY, Scale;
	local int i, x, row;
	local Pawn P;
	local RPGArtifact A;
	local array<class<RPGArtifact> > Artifacts;
	local class<RPGArtifact> AClass;
	local HudCDeathmatch HUD;
	local float Fade;
	local string Extra;
	
	if(ViewportOwner == None || ViewportOwner.Actor == None)
		return;
	
	TimeSeconds = ViewportOwner.Actor.Level.TimeSeconds;

	P = ViewportOwner.Actor.Pawn;
	if(P == None || P.Health <= 0)
	{
		LastSelectedArtifact = None;
		LastSelItemName = "";
		LastSelExtra = "";
		return;
	}
	
	if(RedeemerWarhead(P) != None)
		return;
		
	if(RPRI == None)
		FindRPRI();
	
	if(RPRI == None)
		return;
	
	HUD = HudCDeathmatch(ViewportOwner.Actor.myHUD);
	if(HUD == None || HUD.bHideHUD || HUD.bShowScoreboard || HUD.bShowLocalStats)
		return;
		
	if(HUD.IsA('HUD_Assault') && !HUD_Assault(HUD).ShouldShowObjectiveBoard())
		DrawAdrenaline(Canvas, HUD);

	if(TextFont != None)
		Canvas.Font = TextFont;
	
	Canvas.FontScaleX = Canvas.ClipX / 1024.f;
	Canvas.FontScaleY = Canvas.ClipY / 768.f;

	Canvas.TextSize(LevelText @ RPRI.RPGLevel, XL, YL);
	if(!Settings.bHideExpBar && RPRI.NeededExp > 0)
	{
		//increase size of the display if necessary for really high levels
		XL = FMax(XL + 9.f * Canvas.FontScaleX, 135.f * Canvas.FontScaleX);
		Canvas.Style = 5; //STY_Alpha
		Canvas.DrawColor = EXPBarColor;
		
		EXPBarX = Canvas.ClipX * Settings.ExpBarX;
		EXPBarY = Canvas.ClipY * Settings.ExpBarY;
		ExpBarW = XL;
		ExpBarH = Canvas.ClipY / 48.f;
		Canvas.SetPos(EXPBarX, EXPBarY);
		
		Canvas.DrawTile(Material'InterfaceContent.Hud.SkinA', XL * RPRI.Experience / RPRI.NeededExp, 15.0 * Canvas.FontScaleY, 836, 454, -386 * RPRI.Experience / RPRI.NeededExp, 36);
		Canvas.DrawColor = GetHUDTeamTint(HUD);
		
		Canvas.SetPos(EXPBarX, EXPBarY);
		Canvas.DrawTile(Material'InterfaceContent.Hud.SkinA', ExpBarW, ExpBarH * 0.9375, 836, 454, -386, 36);
		Canvas.DrawColor = WhiteColor;
		Canvas.SetPos(EXPBarX, EXPBarY);
		Canvas.DrawTile(Material'InterfaceContent.Hud.SkinA', ExpBarW, ExpBarH, 836, 415, -386, 38);

		Canvas.Style = 2; //STY_Normal
		Canvas.DrawColor = WhiteColor;
		Canvas.TextSize(LevelText @ RPRI.RPGLevel, xX, xY);
		Canvas.SetPos(EXPBarX + ExpBarW * 0.5 - xX * 0.5, ExpBarY - xY);
		Canvas.DrawText(LevelText @ RPRI.RPGLevel);
		
		tX = Canvas.FontScaleX;
		tY = Canvas.FontScaleY;
		
		Canvas.FontScaleX *= 0.75;
		Canvas.FontScaleY *= 0.75;
		
		Canvas.TextSize(int(RPRI.Experience) $ "/" $ RPRI.NeededExp, XLSmall, YLSmall);
		Canvas.SetPos(ExpBarX + ExpBarW * 0.5 - XLSmall * 0.5, ExpBarY + ExpBarH * 0.5 - YLSmall * 0.5 + 1);
		Canvas.DrawText(int(RPRI.Experience) $ "/" $ RPRI.NeededExp);
		
		Canvas.Style = 5; //STY_Alpha
		if(!Settings.bHideExpGain && Settings.ExpGainDuration > 0 &&
			(Settings.ExpGainDuration >= ExpGainDurationForever || ExpGainTimer > TimeSeconds))
		{
			if(ExpGain >= 0)
			{
				Extra = "+" $ class'Util'.static.FormatFloat(ExpGain);
				Canvas.DrawColor = WhiteColor;
			}
			else
			{
				Extra = class'Util'.static.FormatFloat(ExpGain);
				Canvas.DrawColor = RedColor;
			}
			
			if(Settings.ExpGainDuration < ExpGainDurationForever)
			{
				Fade = ExpGainTimer - TimeSeconds;
				if (Fade <= 1)
					Canvas.DrawColor.A = 255 * Fade;
			}

			Canvas.TextSize(Extra, XLSmall, YLSmall);
			Canvas.SetPos(ExpBarX + ExpBarW * 0.5 - XLSmall * 0.5, ExpBarY + ExpBarH + 1);
			Canvas.DrawText(Extra);
		}
		
		Canvas.FontScaleX = tX;
		Canvas.FontScaleY = tY;
	}
	
	//Summoned Monsters and Turrets
	if(!Settings.bHideSummoned && (RPRI.NumMonsters > 0 || RPRI.NumTurrets > 0))
	{
		Canvas.Style = 5;
		Canvas.DrawColor = WhiteColor;
	
		tX = Canvas.FontScaleX;
		tY = Canvas.FontScaleY;
		Canvas.FontScaleX *= 0.75;
		Canvas.FontScaleY *= 0.75;
	
		YL = Canvas.ClipY * 0.75;
		XL = Canvas.ClipX - SummonedIconSize - 3;
		
		if(RPRI.NumMonsters > 0)
			XL -= DrawSummoned(Canvas, MonsterIcon, XL, YL, SummonedIconSize, RPRI.NumMonsters, RPRI.MaxMonsters);
		
		if(RPRI.NumTurrets > 0)
			XL -= DrawSummoned(Canvas, TurretIcon, XL, YL, SummonedIconSize, RPRI.NumTurrets, RPRI.MaxTurrets);
		
		Canvas.FontScaleX = tX;
		Canvas.FontScaleY = tY;
	}

	//Hint
	Canvas.Style = 5; //STY_Alpha
	if(Hint.Length > 0 && HintTimer > TimeSeconds)
	{
		Canvas.DrawColor = HintColor;
		
		Fade = HintTimer - TimeSeconds;
		if (Fade <= 1)
			Canvas.DrawColor.A = 255 * Fade;
		
		Canvas.TextSize(Hint[0], Fade, tY);
		for(i = 0; i < Hint.Length; i++)
		{
			Canvas.TextSize(Hint[i], tX, Fade); //Fade is used as a dummy here, we only want XL
			Canvas.SetPos(Canvas.ClipX - tX - 1, Canvas.ClipY * 0.1 + tY * i);
			Canvas.DrawText(Hint[i], true);
		}
	}

	if(!RPRI.bGameEnded) //from here on, only if there's still a game going on... should reduce the crashes ~pd
	{
		if(Settings.bClassicArtifactSelection)
		{	
			A = RPGArtifact(P.SelectedItem);
			if(A != None)
			{
				YL *= Settings.IconScale;
		
				tX = Canvas.ClipX * Settings.IconsX;
				tY = Canvas.ClipY * Settings.IconClassicY;
			
				//Name
				Canvas.Style = 5; //STY_Alpha
				Canvas.DrawColor = WhiteColor;
				Canvas.StrLen(A.ItemName, xX, xY);
				
				if(Settings.IconsX > 0.85)
					xX = tX + YL * 2 - xX;
				else if(Settings.IconsX < 0.15)
					xX = tX;
				else
					xX = tX + YL - xX * 0.5;
					
				if(Settings.IconClassicY < 0.25)
					xY = tY + YL * 2 + 1;
				else
					xY = tY - xY - 1;
				
				Canvas.SetPos(xX, xY);
				Canvas.DrawText(A.ItemName);
				
				//Icon
				DrawArtifactBox(A.class, A, Canvas, HUD, tX, tY, YL * 2);
			}
		}
		else
		{
			/*
			bHasArtifacts = false;
			
			if(Settings.bShowAllArtifacts)
			{
				Artifacts = RPRI.AllArtifacts;
				A = RPGArtifact(P.SelectedItem);
				bHasArtifacts = (A != None);
			}
			else
			{
				for(Inv = P.Inventory; Inv != None; Inv = Inv.Inventory)
				{
					A = RPGArtifact(Inv);
					if(A != None)
					{
						bHasArtifacts = true;
						Artifacts[Artifacts.Length] = A.class;
					}
				}
			}
			*/
			
			//the scale is relative to a 640x480 resolution - adapt it to current
			YL = ArtifactBorderMaterialVL * (ArtifactBorderMaterialTextureScale * Canvas.ClipY / 480.0);
			x = Min(Settings.IconsPerRow, Artifacts.Length);
			
			Scale = 1.f;
			
			if(x > 10)
				Scale /= float(x) / 10.f;

			Scale *= Settings.IconScale;
			
			YL *= Scale;
			Canvas.FontScaleX *= Scale * 1.5f;
			Canvas.FontScaleY *= Scale * 1.5f;
			
			xX = Canvas.ClipX * Settings.IconsX;
			xY = Canvas.ClipY * Settings.IconsY;
			
			tY = xY;
			for(i = 0; i < RPRI.ArtifactOrder.Length; i++)
			{
				AClass = RPRI.ArtifactOrder[i].ArtifactClass;
				A = RPGArtifact(P.FindInventoryType(AClass));
				
				if(AClass != None && (A != None || RPRI.ArtifactOrder[i].bShowAlways))
				{
					if(++row > Settings.IconsPerRow)
					{
						row = 1;
						
						xX += (1.f + ArtifactHighlightIndention) * YL;
						tY = xY;
					}
				
					tX = xX;
				
					if(A != None && A == P.SelectedItem)
					{
						if(Settings.IconsPerRow > 1)
						{
							if(Settings.IconsX > 0.85)
								tX -= ArtifactHighlightIndention * YL;
							else if(Settings.IconsX < 0.15)
								tX += ArtifactHighlightIndention * YL;
						}
						else
						{
							if(Settings.IconsY > 0.75)
								tY -= ArtifactHighlightIndention * YL;
							else if(Settings.IconsY < 0.25)
								tY += ArtifactHighlightIndention * YL;
						}
					}
					
					DrawArtifactBox(AClass, A, Canvas, HUD, tX, tY, YL, A != None && A == P.SelectedItem);
					tY += YL;
				}
			}
		}
		
		//display artifact name and info as well as the weapon extra info! -pd
		//if both artifact and weapon info should be drawn, only display the latest information
		if(!Settings.bHideArtifactName && !HUD.bHideWeaponName &&
			HUD.WeaponDrawTimer > TimeSeconds &&
			ArtifactDrawTimer > TimeSeconds)
		{
			if(ArtifactDrawTimer > HUD.WeaponDrawTimer)
				HUD.WeaponDrawTimer = 0;
			else
				ArtifactDrawTimer = 0;
		}

		//Draw artifact name
		if(!Settings.bHideArtifactName && LastSelectedArtifact != None && ArtifactDrawTimer > TimeSeconds)
		{
			Canvas.Font = HUD.GetMediumFontFor(Canvas);
			Canvas.FontScaleX = Canvas.default.FontScaleX;
			Canvas.FontScaleY = Canvas.default.FontScaleY;
			Canvas.DrawColor = ArtifactDrawColor;

			Canvas.Style = 5; //STY_Alpha
			Fade = ArtifactDrawTimer - TimeSeconds;
			if (Fade <= 1)
				Canvas.DrawColor.A = 255 * Fade;
				
			Canvas.Strlen(LastSelItemName, XL, YL);
			Canvas.SetPos((Canvas.ClipX / 2) - (XL / 2), Canvas.ClipY * 0.8 - YL);
			Canvas.DrawText(LastSelItemName);
			
			if(!Settings.bHideWeaponExtra)
			{
				if(LastSelExtra != "")
				{
					Canvas.FontScaleX = Canvas.default.FontScaleX * 0.6;
					Canvas.FontScaleY = Canvas.default.FontScaleY * 0.6;
				
					Canvas.Strlen(LastSelExtra, XL, YL);
					Canvas.SetPos((Canvas.ClipX / 2) - (XL / 2), Canvas.ClipY * 0.8);
					Canvas.DrawText(LastSelExtra);
				}
			}
		}
		else
		{
			if(!Settings.bHideWeaponExtra && !HUD.bHideWeaponName)
			{
				if(LastWeaponExtra != "" && HUD.WeaponDrawTimer > TimeSeconds)
				{
					Canvas.Font = HUD.GetMediumFontFor(Canvas);
					Canvas.FontScaleX = Canvas.default.FontScaleX * 0.6;
					Canvas.FontScaleY = Canvas.default.FontScaleY * 0.6;
					Canvas.DrawColor = HUD.WeaponDrawColor;

					Canvas.Style = 5; //STY_Alpha
					Fade = HUD.WeaponDrawTimer - TimeSeconds;

					if (Fade <= 1)
						Canvas.DrawColor.A = 255 * Fade;

					Canvas.Strlen(LastWeaponExtra, XL, YL);
					Canvas.SetPos((Canvas.ClipX / 2) - (XL / 2), Canvas.ClipY * 0.8);
					Canvas.DrawText(LastWeaponExtra);
				}
				
				if(P.PendingWeapon != None)
				{
					if(P.PendingWeapon.IsA('RPGWeapon') && RPGWeapon(P.PendingWeapon).bIdentified)
						LastWeaponExtra = RPGWeapon(P.PendingWeapon).GetWeaponNameExtra();
					else
						LastWeaponExtra = "";
				}
			}
		}

		//get newest artifact
		if(!Settings.bHideArtifactName &&
			RPGArtifact(P.SelectedItem) != None &&
			P.SelectedItem.class != LastSelectedArtifact)
		{
			ArtifactDrawTimer = TimeSeconds + 1.5;
			LastSelectedArtifact = RPGArtifact(P.SelectedItem).class;
			LastSelItemName = RPGArtifact(P.SelectedItem).ItemName;
			LastSelExtra = class<RPGArtifact>(P.SelectedItem.class).static.GetArtifactNameExtra();
			ArtifactDrawColor = RPGArtifact(P.SelectedItem).HudColor;
			
			HUD.WeaponDrawTimer = 0; //do not display weapon name anymore
		}
		else if(RPGArtifact(P.SelectedItem) == None)
		{
			LastSelectedArtifact = None;
			LastSelItemName = "";
			LastSelExtra = "";
		}
	}

	Canvas.DrawColor = WhiteColor;
	Canvas.Font = Canvas.default.Font;
	Canvas.FontScaleX = Canvas.default.FontScaleX;
	Canvas.FontScaleY = Canvas.default.FontScaleY;
}

//draw adrenaline (for assault hud)
function DrawAdrenaline(Canvas C, HudCDeathMatch HUD)
{
	if(!HUD.PlayerOwner.bAdrenalineEnabled)
		return;

	HUD.DrawSpriteWidget(C, HUD.AdrenalineBackground);
	HUD.DrawSpriteWidget(C, HUD.AdrenalineBackgroundDisc);

	if(HUD.CurEnergy == HUD.MaxEnergy)
	{
		HUD.DrawSpriteWidget(C, HUD.AdrenalineAlert);
		HUD.AdrenalineAlert.Tints[HUD.TeamIndex] = HUD.HudColorHighLight;
	}

	HUD.DrawSpriteWidget(C, HUD.AdrenalineIcon);
	HUD.DrawNumericWidget( C, HUD.AdrenalineCount, HUD.DigitsBig);

	if(HUD.CurEnergy > HUD.LastEnergy)
		HUD.LastAdrenalineTime = HUD.Level.TimeSeconds;

	HUD.LastEnergy = HUD.CurEnergy;
	HUD.DrawHUDAnimWidget(HUD.AdrenalineIcon, HUD.default.AdrenalineIcon.TextureScale, HUD.LastAdrenalineTime, 0.6, 0.6);
	HUD.AdrenalineBackground.Tints[HUD.TeamIndex] = HUD.HudColorBlack;
	HUD.AdrenalineBackground.Tints[HUD.TeamIndex].A = 150;
}

function NotifyExpGain(float Amount)
{
	if(Settings.ExpGainDuration >= ExpGainDurationForever || ExpGainTimer > ViewportOwner.Actor.Level.TimeSeconds)
		ExpGain += Amount;
	else
		ExpGain = Amount;

	ExpGainTimer = ViewportOwner.Actor.Level.TimeSeconds + Settings.ExpGainDuration;
}

function ShowHint(string Text)
{
	Split(Text, "|", Hint);
	HintTimer = ViewportOwner.Actor.Level.TimeSeconds + HintDuration;
}

//New function to select a specific artifact!
exec function GetArtifact(string ArtifactID)
{
	if(RPRI != None)
		RPRI.ServerGetArtifact(ArtifactID);
}

//Compability for ONS RPG
exec function RPGGetArtifact(string ArtifactID)
{
	if(RPRI != None)
		RPRI.ServerGetArtifact(ArtifactID);
}

//Directly activate an artifact without having to select it
exec function RPGActivateArtifact(string ArtifactID)
{
	if(RPRI != None)
		RPRI.ServerActivateArtifact(ArtifactID);
}

event NotifyLevelChange()
{
	//close stats menu if it's open
	FindRPRI();
	
	if(RPRI != None)
	{
		if(RPRI.Menu != None)
			GUIController(ViewportOwner.GUIController).RemoveMenu(RPRI.Menu);

		//Save player data (standalone/listen servers only)
		if(RPRI.Level.Game != None)
		{
			if(class'MutTitanRPG'.default.Instance != None)
				class'MutTitanRPG'.default.Instance.SaveData();
		}
	}

	Remove();
}

function Remove()
{
	RPRI = None;
	Settings = None;
	CharSettings = None;

	Master.RemoveInteraction(Self);
}

defaultproperties
{	
	ExpGainDurationForever=21.0 //this or higher means forever
	HintDuration=5.000000
	HintColor=(R=255,G=128,B=0,A=255)
	bDefaultBindings=True
	bDefaultArtifactBindings=True
	EXPBarColor=(B=128,G=255,R=128,A=255)
	RedColor=(R=255,A=255)
	WhiteColor=(B=255,G=255,R=255,A=255)
	//Team colors (taken from HudOLTeamDeathmatch
	HUDColorTeam(0)=(R=200,G=0,B=0,A=255)
	HUDColorTeam(1)=(R=50,G=64,B=200,A=255)
	HUDColorTeam(2)=(R=0,G=200,B=0,A=255)
	HUDColorTeam(3)=(R=200,G=200,B=0,A=255)
	//EXP Bar Tints
	HUDTintTeam(0)=(R=100,G=0,B=0,A=100)
	HUDTintTeam(1)=(R=0,G=25,B=100,A=100)
	HUDTintTeam(2)=(R=0,G=100,B=0,A=100)
	HUDTintTeam(3)=(R=100,G=75,B=0,A=100)
	//Summoned stuff
	SummonedIconSize=32
	SummonedIconOverlay=(R=192,G=192,B=192,A=192)
	MonsterIcon=Texture'<? echo($packageName); ?>.ArtifactIcons.MonsterSummon'
	TurretIcon=Texture'<? echo($packageName); ?>.ArtifactIcons.TurretSummon'
	//
	DisabledOverlay=(R=0,G=0,B=0,A=150)
	LevelText="Level:"
	ArrowMaterial=Texture'2K4Menus.Controls.arrowLeft_d'
	bVisible=True
	ArtifactTutorialText="You have collected a magic artifact!|Press $1 to use it or press $2 and $3 to browse|if you have multiple artifacts."
	ArtifactBorderMaterial=Texture'HudContent.Generic.HUD'
	ArtifactBorderMaterialTextureScale=0.53
	ArtifactBorderMaterialU=0.000000
	ArtifactBorderMaterialV=39.000000
	ArtifactBorderMaterialUL=95.000000
	ArtifactBorderMaterialVL=54.000000
	ArtifactIconInnerScale=0.750000
	ArtifactHighlightIndention=0.150000
}
