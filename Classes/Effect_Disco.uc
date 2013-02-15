class Effect_Disco extends RPGEffect;

var RPGPlayerReplicationInfo RPRI;

var Bot Bot;
var float OldAccuracy, OldCombatStyle;
var int OldSkill;

state Activated
{
	function BeginState()
	{
		Super.BeginState();
        
        if(Bot(Instigator.Controller) != None) {
            Bot = Bot(Instigator.Controller);
            OldAccuracy = Bot.Accuracy;
            OldCombatStyle = Bot.CombatStyle;
            OldSkill = Bot.Skill;
            
            Bot.Accuracy = -1; //couldn't hit the sun
            Bot.CombatStyle = 1; //try to attack anything anyway
            Bot.InitializeSkill(OldSkill - 2); //become even more stupid
        } else if(PlayerController(Instigator.Controller) != None) { 
            RPRI = class'RPGPlayerReplicationInfo'.static.GetFor(Instigator.Controller);
            if(RPRI != None) {
                RPRI.bDiscoMode = true;
                RPRI.NetUpdateTime = Level.TimeSeconds - 1;
            }
        }
	}

	function EndState()
	{
        if(Bot != None) {
            Bot.Accuracy = OldAccuracy;
            Bot.CombatStyle = OldCombatStyle;
            Bot.InitializeSkill(OldSkill);
        }
    
        if(RPRI != None) {
            RPRI.bDiscoMode = false;
            RPRI.NetUpdateTime = Level.TimeSeconds - 1;
        }
    
		Super.EndState();
	}
}

defaultproperties {
	EffectOverlay=Combiner'TitanRPG.Overlays.DiscoCombiner'
	//TODO: EffectSound=Sound'Slaughtersounds.Machinery.Heavy_End'
    
	EffectMessageClass=class'EffectMessage_Disco'
}
