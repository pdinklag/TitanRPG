class RPGInteraction extends Interaction;

struct Vec2
{
	var float X, Y;
};

struct Rect
{
	var float X, Y, W, H;
};

var RPGPlayerReplicationInfo RPRI;

var RPGSettings Settings;
var RPGCharSettings CharSettings;

var float TimeSeconds;

var bool bMenuEnabled; //false as long as server settings were not yet received

var bool bUpdateCanvas;

var bool bDefaultBindings, bDefaultArtifactBindings; //use default keybinds because user didn't set any
var float LastLevelMessageTime;
var Color EXPBarColor, DisabledOverlay, RedColor, WhiteColor;
var Color HUDColorTeam[4], HUDTintTeam[4];
var localized string LevelText;

var Material ArtifactBorderMaterial;
var Rect ArtifactBorderMaterialRect;
var float ArtifactBorderMaterialTextureScale, ArtifactHighlightIndention;
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

//Status icon
var Material StatusIconBorderMaterial;
var Rect StatusIconBorderMaterialRect;
var Vec2 StatusIconSize;
var float StatusIconInnerScale;
var Color StatusIconOverlay;
var Material MonsterIcon, TurretIcon;

//Pre-calculated values for PostRender - updated if the canvas size or settings changed
var Vec2 CanvasSize, FontScale, ArtifactIconPos, StatusIconPos;
var Rect ExpBarRect;
var Font TextFont;
var float ArtifactIconSize;

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

function DrawArtifactBox(class<RPGArtifact> AClass, RPGArtifact A, Canvas Canvas, HudCDeathmatch HUD, float X, float Y, float Size, optional bool bSelected)
{
	local int Time;
	local float XL, YL;

	Canvas.Style = 5;
	
	if(A != None && bSelected)
		Canvas.DrawColor = HUD.HudColorHighlight;
	else
		Canvas.DrawColor = GetHUDTeamColor(HUD);
	
	Canvas.SetPos(X, Y);
	Canvas.DrawTile(
		ArtifactBorderMaterial, 
		Size, Size, 
		ArtifactBorderMaterialRect.X,
		ArtifactBorderMaterialRect.Y,
		ArtifactBorderMaterialRect.W,
		ArtifactBorderMaterialRect.H);
	
	if(AClass.default.IconMaterial != None)
	{
		if(A != None && A.bActive)
			Canvas.DrawColor = GetHUDTeamColor(HUD);
		else if(A == None || TimeSeconds < A.NextUseTime)
			Canvas.DrawColor = DisabledOverlay;
		else
			Canvas.DrawColor = WhiteColor;
		
		Canvas.SetPos(X + Size * 0.5 * (1.0 - ArtifactIconInnerScale), Y + Size * 0.5 * (1.0 - ArtifactIconInnerScale));
		Canvas.DrawTile(AClass.default.IconMaterial, Size * ArtifactIconInnerScale, Size * ArtifactIconInnerScale, 0, 0, AClass.default.IconMaterial.MaterialUSize(), AClass.default.IconMaterial.MaterialVSize());
	}
	
	if(A != None && TimeSeconds < A.NextUseTime)
	{
		Time = int(A.NextUseTime - TimeSeconds) + 1;
		
		Canvas.DrawColor = WhiteColor;
		Canvas.TextSize(string(Time), XL, YL);
		Canvas.SetPos(X + (Size - XL) * 0.5, Y + (Size - YL) * 0.5);
		Canvas.DrawText(string(Time));
	}
}

function DrawStatusIcon(Canvas Canvas, Material Icon, float X, float Y, float SizeX, float SizeY, optional int Num, optional int Max)
{
	local string Text;
	local float XL, YL;
	local float IconSize;

	Canvas.Style = 5;

	Canvas.SetPos(X, Y);
	Canvas.DrawColor = WhiteColor;
	Canvas.DrawTile(
		StatusIconBorderMaterial,
		SizeX, SizeY,
		StatusIconBorderMaterialRect.X, StatusIconBorderMaterialRect.Y,
		StatusIconBorderMaterialRect.W, StatusIconBorderMaterialRect.H
	);
	
	IconSize = FMin(SizeX, SizeY) * StatusIconInnerScale;
	
	Canvas.SetPos(X + (SizeX - IconSize) * 0.5, Y + (SizeY - IconSize) * 0.5);
	Canvas.DrawColor = StatusIconOverlay;
	Canvas.DrawTile(Icon, IconSize, IconSize, 0, 0, Icon.MaterialUSize(), Icon.MaterialVSize());
	
	if(Num != 0)
	{
		if(Max != 0)
			Text = Num $ "/" $ Max;
		else
			Text = string(Num);
		
		Canvas.TextSize(Text, XL, YL);
		Canvas.SetPos(X + (SizeX - XL) * 0.5, Y + (SizeY - YL) * 0.5 + 1);
		Canvas.DrawColor = WhiteColor;
		Canvas.DrawText(Text);
	}
}

function UpdateCanvas(Canvas Canvas)
{
	local float XL, YL;

	CanvasSize.X = Canvas.ClipX;
	CanvasSize.Y = Canvas.ClipY;
	
	FontScale.X = Canvas.ClipX / 1024.0f;
	FontScale.Y = Canvas.ClipY / 768.0f;
	
	Canvas.FontScaleX = FontScale.X;
	Canvas.FontScaleY = FontScale.Y;
	
	Canvas.TextSize(LevelText @ "000", XL, YL);
	
	ExpBarRect.X = Canvas.ClipX * Settings.ExpBarX;
	ExpBarRect.Y = Canvas.ClipY * Settings.ExpBarY;
	ExpBarRect.W = FMax(XL + 9.0f * FontScale.X, 135.0f * FontScale.X);
	ExpBarRect.H = Canvas.ClipY / 48.0f;

	StatusIconSize.X = default.StatusIconSize.X * Canvas.ClipX / 640.0f;
	StatusIconSize.Y = default.StatusIconSize.Y * Canvas.ClipY / 480.0f;
	
	StatusIconPos.X = Canvas.ClipX - StatusIconSize.X;
	StatusIconPos.Y = Canvas.ClipY * 0.07f;
	
	ArtifactIconPos.X = Canvas.ClipX * Settings.IconsX;
	
	if(Settings.bClassicArtifactSelection)
		ArtifactIconPos.Y = Canvas.ClipY * Settings.IconClassicY;
	else
		ArtifactIconPos.Y = Canvas.ClipY * Settings.IconsY;
	
	ArtifactIconSize = 
		ArtifactBorderMaterialRect.Y * (ArtifactBorderMaterialTextureScale * Canvas.ClipY / 480.0f) * Settings.IconScale;
}

function PostRender(Canvas Canvas)
{
	local float XL, YL, X, Y, CurrentX, CurrentY, Size, Fade;
	local int i, Row;
	local string Text;
	
	local array<class<RPGArtifact> > Artifacts;
	local class<RPGArtifact> AClass;
	local RPGArtifact A;
	local Pawn P;
	
	local HudCDeathmatch HUD;
	
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
	
	if(bUpdateCanvas || CanvasSize.X != Canvas.ClipX || CanvasSize.Y != Canvas.ClipY)
		UpdateCanvas(Canvas);
	
	Canvas.FontScaleX = FontScale.X;
	Canvas.FontScaleY = FontScale.Y;

	Canvas.TextSize(LevelText @ RPRI.RPGLevel, XL, YL);
	
	Canvas.Style = 5; //STY_Alpha
	
	//Draw exp bar
	if(!Settings.bHideExpBar && RPRI.NeededExp > 0)
	{
		//Progress
		Canvas.DrawColor = EXPBarColor;
		Canvas.SetPos(ExpBarRect.X, ExpBarRect.Y);
		
		XL = RPRI.Experience / RPRI.NeededExp;
		Canvas.DrawTile(
			Material'InterfaceContent.Hud.SkinA',
			ExpBarRect.W * XL,
			15.0f * Canvas.FontScaleY,
			836, 454, -386 * XL, 36);
		
		//Tint
		Canvas.DrawColor = GetHUDTeamTint(HUD);
		Canvas.SetPos(ExpBarRect.X, ExpBarRect.Y);
		Canvas.DrawTile(Material'InterfaceContent.Hud.SkinA', ExpBarRect.W, ExpBarRect.H * 0.9375f, 836, 454, -386, 36);
		
		//Border
		Canvas.DrawColor = WhiteColor;
		Canvas.SetPos(ExpBarRect.X, ExpBarRect.Y);
		Canvas.DrawTile(Material'InterfaceContent.Hud.SkinA', ExpBarRect.W, ExpBarRect.H, 836, 415, -386, 38);

		//Level Text
		Text = LevelText @ RPRI.RPGLevel;
		Canvas.TextSize(Text, XL, YL);
		Canvas.SetPos(ExpBarRect.X + 0.5 * (ExpBarRect.W - XL), ExpBarRect.Y - YL);
		Canvas.DrawText(Text);
		
		//Experience Text
		Canvas.FontScaleX *= 0.75;
		Canvas.FontScaleY *= 0.75;
		
		Text = int(RPRI.Experience) $ "/" $ RPRI.NeededExp;
		Canvas.TextSize(Text, XL, YL);
		Canvas.SetPos(ExpBarRect.X + 0.5 * (ExpBarRect.W - XL), ExpBarRect.Y + 0.5 * (ExpBarRect.H - YL) + 1);
		Canvas.DrawText(Text);
		
		//Experience Gain
		if(!Settings.bHideExpGain && Settings.ExpGainDuration > 0 &&
			(Settings.ExpGainDuration >= ExpGainDurationForever || ExpGainTimer > TimeSeconds))
		{
			if(ExpGain >= 0)
			{
				Text = "+" $ class'Util'.static.FormatFloat(ExpGain);
				Canvas.DrawColor = WhiteColor;
			}
			else
			{
				Text = class'Util'.static.FormatFloat(ExpGain);
				Canvas.DrawColor = RedColor;
			}
			
			if(Settings.ExpGainDuration < ExpGainDurationForever)
			{
				Fade = ExpGainTimer - TimeSeconds;
				if(Fade <= 1.0f)
					Canvas.DrawColor.A = 255 * Fade;
			}

			Canvas.TextSize(Text, XL, YL);
			Canvas.SetPos(ExpBarRect.X + 0.5 * (ExpBarRect.W - XL), ExpBarRect.Y + 0.5 * (ExpBarRect.H - YL) + 1);
			Canvas.DrawText(Text);
		}
		
		//Reset
		Canvas.FontScaleX = FontScale.X;
		Canvas.FontScaleY = FontScale.Y;
	}
	
	//Draw status icons
	if(
		!Settings.bHideStatusIcon && (RPRI.NumMonsters > 0 || RPRI.NumTurrets > 0) &&
		(!HUD.IsA('HUD_Assault') || !HUD_Assault(HUD).ShouldShowObjectiveBoard())
	)
	{
		Canvas.FontScaleX *= 0.75f;
		Canvas.FontScaleY *= 0.75f;

		X = StatusIconPos.X;
		Y = StatusIconPos.Y;
		
		if(RPRI.NumMonsters > 0)
		{
			DrawStatusIcon(Canvas, MonsterIcon, X, Y, StatusIconSize.X, StatusIconSize.Y, RPRI.NumMonsters, RPRI.MaxMonsters);
			X -= StatusIconSize.X;
		}
		
		if(RPRI.NumTurrets > 0)
		{	
			DrawStatusIcon(Canvas, TurretIcon, X, Y, StatusIconSize.X, StatusIconSize.Y, RPRI.NumTurrets, RPRI.MaxTurrets);
			X -= StatusIconSize.X;
		}
		
		//Reset
		Canvas.FontScaleX = FontScale.X;
		Canvas.FontScaleY = FontScale.Y;
	}

	//Draw hints
	if(Hint.Length > 0 && HintTimer > TimeSeconds && (!HUD.IsA('HUD_Assault') || !HUD_Assault(HUD).ShouldShowObjectiveBoard()))
	{
		Canvas.DrawColor = HintColor;
		
		Fade = HintTimer - TimeSeconds;
		if(Fade <= 1.0f)
			Canvas.DrawColor.A = 255 * Fade;
		
		Y = Canvas.ClipY * 0.1f;
		for(i = 0; i < Hint.Length; i++)
		{
			Canvas.TextSize(Hint[i], XL, YL);
			Canvas.SetPos(Canvas.ClipX - XL - 1, Y);
			Canvas.DrawText(Hint[i]);
			
			Y += YL;
		}
	}

	//From here on, only if there's still a game going on... should reduce the crashes
	if(!RPRI.bGameEnded) 
	{
		//Draw artifacts
		if(Settings.bClassicArtifactSelection)
		{
			//Classic Selection
			A = RPGArtifact(P.SelectedItem);
			if(A != None)
			{
				//Name
				Canvas.TextSize(A.ItemName, XL, YL);
				
				if(Settings.IconsX > 0.85f)
					X = ArtifactIconPos.X + ArtifactIconSize - XL;
				else if(Settings.IconsX < 0.15f)
					X = ArtifactIconPos.X;
				else
					X = ArtifactIconPos.X + ArtifactIconSize - XL * 0.5f;
					
				if(Settings.IconClassicY < 0.25f)
					Y = ArtifactIconPos.Y + ArtifactIconSize + 1;
				else
					Y = ArtifactIconPos.Y - YL - 1;
				
				Canvas.DrawColor = WhiteColor;
				Canvas.SetPos(X, Y);
				Canvas.DrawText(A.ItemName);
				
				//Icon
				DrawArtifactBox(
					A.class, A, Canvas, HUD, ArtifactIconPos.X, ArtifactIconPos.Y, ArtifactIconSize);
			}
		}
		else
		{
			Size = ArtifactIconSize;
			
			i = Min(Settings.IconsPerRow, Artifacts.Length);
			if(i > 10)
				Size /= float(i) / 10.f;

			CurrentX = ArtifactIconPos.X;
			CurrentY = ArtifactIconPos.Y;

			for(i = 0; i < RPRI.ArtifactOrder.Length; i++)
			{
				AClass = RPRI.ArtifactOrder[i].ArtifactClass;
				A = RPGArtifact(P.FindInventoryType(AClass));
				
				if(AClass != None && (A != None || RPRI.ArtifactOrder[i].bShowAlways))
				{
					if(++Row > Settings.IconsPerRow)
					{
						Row = 1;
						
						CurrentX += (1.f + ArtifactHighlightIndention) * Size;
						CurrentY = ArtifactIconPos.Y;
					}
				
					X = CurrentX;
					Y = CurrentY;
					
					if(A != None && A == P.SelectedItem)
					{
						if(Settings.IconsPerRow > 1)
						{
							if(Settings.IconsX > 0.85)
								X -= ArtifactHighlightIndention * Size;
							else if(Settings.IconsX < 0.15)
								X += ArtifactHighlightIndention * Size;
						}
						else
						{
							if(Settings.IconsY > 0.75)
								Y -= ArtifactHighlightIndention * Size;
							else if(Settings.IconsY < 0.25)
								Y += ArtifactHighlightIndention * Size;
						}
					}
					
					DrawArtifactBox(AClass, A, Canvas, HUD, X, Y, Size, A != None && A == P.SelectedItem);
					CurrentY += Size;
				}
			}
		}
		
		//Solve Weapon extra / Artiface name conflict
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
			
			Fade = ArtifactDrawTimer - TimeSeconds;
			if(Fade <= 1.0f)
				Canvas.DrawColor.A = 255 * Fade;
	
			Canvas.TextSize(LastSelItemName, XL, YL);
			
			Canvas.DrawColor = ArtifactDrawColor;
			Canvas.SetPos((Canvas.ClipX - XL) * 0.5f, Canvas.ClipY * 0.8f - YL);
			Canvas.DrawText(LastSelItemName);
			
			//Artifact extra
			if(!Settings.bHideWeaponExtra)
			{
				if(LastSelExtra != "")
				{
					Canvas.FontScaleX = Canvas.default.FontScaleX * 0.6f;
					Canvas.FontScaleY = Canvas.default.FontScaleY * 0.6f;
				
					Canvas.TextSize(LastSelExtra, XL, YL);
					Canvas.SetPos((Canvas.ClipX - XL) * 0.5f, Canvas.ClipY * 0.8f);
					Canvas.DrawText(LastSelExtra);
				}
			}
		}
		else
		{
			if(!Settings.bHideWeaponExtra && !HUD.bHideWeaponName)
			{
				//Draw weapon extra
				if(LastWeaponExtra != "" && HUD.WeaponDrawTimer > TimeSeconds)
				{
					Canvas.Font = HUD.GetMediumFontFor(Canvas);
					Canvas.FontScaleX = Canvas.default.FontScaleX * 0.6;
					Canvas.FontScaleY = Canvas.default.FontScaleY * 0.6;
					
					Fade = HUD.WeaponDrawTimer - TimeSeconds;

					if(Fade <= 1.0f)
						Canvas.DrawColor.A = 255 * Fade;

					Canvas.TextSize(LastWeaponExtra, XL, YL);
					
					Canvas.DrawColor = HUD.WeaponDrawColor;
					Canvas.SetPos((Canvas.ClipX - XL) * 0.5f, Canvas.ClipY * 0.8f);
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

		//Get newest artifact
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

	//Reset
	Canvas.DrawColor = Canvas.default.DrawColor;
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

exec function KillMonsters()
{
	if(RPRI != None)
		RPRI.ServerKillMonsters();
}

exec function KillTurrets()
{
	if(RPRI != None)
		RPRI.ServerDestroyTurrets();
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
			if(class'MutTitanRPG'.static.Instance(RPRI.Level) != None)
				class'MutTitanRPG'.static.Instance(RPRI.Level).SaveData();
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
	//StatusIcon stuff
	StatusIconBorderMaterial=Texture'HudContent.Generic.HUD'
	StatusIconBorderMaterialRect=(X=119,Y=257,W=55,H=55)
	StatusIconSize=(X=29,Y=29)
	StatusIconInnerScale=0.75
	StatusIconOverlay=(R=255,G=255,B=255,A=128)
	//Status icons
	MonsterIcon=Texture'<? echo($packageName); ?>.StatusIcons.Monster'
	TurretIcon=Texture'<? echo($packageName); ?>.StatusIcons.Turret'
	//
	DisabledOverlay=(R=0,G=0,B=0,A=150)
	LevelText="Level:"
	bVisible=True
	ArtifactTutorialText="You have collected a magic artifact!|Press $1 to use it or press $2 and $3 to browse|if you have multiple artifacts."
	ArtifactBorderMaterial=Texture'HudContent.Generic.HUD'
	ArtifactBorderMaterialTextureScale=0.53
	ArtifactBorderMaterialRect=(X=0,Y=39,W=95,H=54)
	ArtifactIconInnerScale=0.67
	ArtifactHighlightIndention=0.15
}
