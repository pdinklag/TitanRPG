class Effect_Heal extends RPGInstantEffect;

var int HealAmount;

var config int SelfHealingCap;
var config float SelfHealingMultiplier;

static function bool CanBeApplied(Pawn Other, optional Controller Causer, optional float Duration, optional float Modifier) {
	if(!Other.IsA('Vehicle') && (Other.Health >= Other.HealthMax + Modifier || Other.Health <= 0)) {
        return false;
    }

    return Super.CanBeApplied(Other, Causer, Duration, Modifier);
}

function bool ShouldDisplayEffect() {
    return !Instigator.IsA('Vehicle');
}

function HealPassengers(Vehicle V) {
    local int x;
    local array<Pawn> Passengers;
    local Effect_Heal Heal;

    Passengers = class'Util'.static.GetAllPassengers(V);
    for(x = 0; x < Passengers.Length; x++) {
        Heal = Effect_Heal(Create(Passengers[x], EffectCauser, Duration, Modifier));
        if(Heal != None) {
            Heal.HealAmount = HealAmount;
            Heal.SelfHealingCap = SelfHealingCap;
            Heal.SelfHealingMultiplier = SelfHealingMultiplier;
            Heal.Start(); //RECURSION ALERT!
        }
    }
}

function DoEffect()
{
	local Pawn Healer;

	if(Instigator.IsA('Vehicle'))
	{
		HealPassengers(Vehicle(Instigator));
		return; //don't heal the vehicle itself
	}
	
	if(EffectCauser != None) {
		Healer = EffectCauser.Pawn;
        
        if(Healer.IsA('Vehicle')) {
            Healer = Vehicle(Healer).Driver;
        }
    }
	
	if(Healer == Instigator && HealAmount > SelfHealingCap)
		HealAmount = Max(1, int(float(HealAmount) * SelfHealingMultiplier));
	
	Instigator.GiveHealth(HealAmount, Instigator.HealthMax + Modifier);
	
	//Possibly grant experience
	if(
		Healer != None &&
		Healer != Instigator &&
		FriendlyMonsterController(Instigator.Controller) == None
	)
	{
        class'Util'.static.DoHealableDamage(Healer, Instigator, HealAmount);
	}
}

defaultproperties
{
	HealAmount=10
	Modifier=0 //max bonus
	
	SelfHealingCap=0
	SelfHealingMultiplier=0.25
	
	bHarmful=False
    bAllowOnEnemies=False

	EffectOverlay=Shader'TitanRPG.Overlays.BlueShader'
	EffectSound=Sound'TitanRPG.SoundEffects.Heal'
	xEmitterClass=class'FX_Heal'
	
	EffectMessageClass=class'EffectMessage_Heal'
}
