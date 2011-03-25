//This baby generates a HTML file with all the info you'll ever need
class HelpGenerator extends Object abstract;

static function WriteHeader(FileLog F, string PageName)
{
	F.Logf("<!DOCTYPE html PUBLIC '-//W3C//DTD XHTML 1.0 Strict//EN' 'http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd'>");
	F.Logf("<html><head><link rel='stylesheet' type='text/css' href='titanrpg-style.css' />");
	F.Logf("<title>" $ F.Level.Game.GameReplicationInfo.ShortName @ "-" @ PageName $ "</title></head><body>");
}

static function WriteTail(FileLog F)
{
	F.Logf("</body></html>");
}

static function GenerateHelp(MutTitanRPG Mut)
{
	local FileLog F;
	local int i;
	local class<RPGWeapon> RWClass;
	local RPGWeapon RW;
	
	Log("Generating help HTML files - this might result in a number of 'Accessed None' errors you can safely ignore.", 'TitanRPG');
	
	/*
		Weapon Modifiers
	*/
	F = Mut.Spawn(class'FileLog');
	F.OpenLog("titanrpg-weapons.html",, true);
	
	WriteHeader(F, "Weapon Modifiers");
	
	F.Logf("<table class='listing'>");
	F.Logf("<tr><th>Pic</th><th>Name</th><th>Info</th><th>Levels</th><th>Chance</th></tr>");
	
	for(i = 0; i < Mut.WeaponModifiers.Length; i++)
	{
		F.Logf("<tr>");
	
		RWClass = Mut.WeaponModifiers[i].WeaponClass;
		
		F.Logf("<td><img src='images/" $ RWClass.name $ ".jpg' alt='" $ RWClass.name $ "' /></td>");
		
		F.Logf("<td>" $ Repl(RWClass.default.PatternPos, "$W", "Weapon"));
		
		if(
			RWClass.default.MinModifier < 0 &&
			RWClass.default.PatternNeg != "" &&
			RWClass.default.PatternNeg != "$W" &&
			RWClass.default.PatternNeg != RWClass.default.PatternPos
		)
		{
			F.Logf("<br /><span class='neg'>" $ Repl(RWClass.default.PatternNeg, "$W", "Weapon") $ "</span>");
		}
		
		F.Logf("</td>");
		
		//eeeeek... so dirty, but so effective
		RW = Mut.Spawn(RWClass);
		RW.SetModifier(1);
		F.Logf("<td>" $ RW.GetWeaponNameExtra());
		
		if(RW.MinModifier < 0)
		{
			RW.SetModifier(-1);
			F.Logf("<br />" $ RW.GetWeaponNameExtra());
		}

		RW.Destroy();
		F.Logf("</td>");
		
		if(RWClass.default.MinModifier != RWClass.default.MaxModifier)
			F.Logf("<td>" $ RWClass.default.MinModifier @ "to" @ RWClass.default.MaxModifier $ "</td>");
		else
			F.Logf("<td>" $ RWClass.default.MinModifier $ "</td>");
		
		F.Logf("<td>" $ class'Util'.static.FormatPercent(
			float(Mut.WeaponModifiers[i].Chance) / float(Mut.TotalModifierChance)) $ "</td>");
		
		F.Logf("</tr>");
	}
	F.Logf("</table>");
	WriteTail(F);
	F.CloseLog();
	
	F.Destroy();
	Log("Done generating help files - check your UserLogs.", 'TitanRPG');
}

defaultproperties
{
}
