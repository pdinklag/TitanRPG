class Ability_Vampire extends RPGAbility;

var config float HealthBonusMax;
var config int HealthBonusAbsoluteCap;

var config float VehicleBonusPerLevel;

//Real health gain - health will be granted once this hits a value of 1
var float RealHealthGain;

var localized string AbsoluteCapText, VehicleText;

replication {
    reliable if(Role == ROLE_Authority)
        ClientReceiveVampConfig;
}

function ServerRequestConfig() {
    Super.ServerRequestConfig();
    ClientReceiveVampConfig(HealthBonusMax, HealthBonusAbsoluteCap, VehicleBonusPerLevel);
}

simulated function ClientReceiveVampConfig(float rHealthBonusMax, int rHealthBonusAbsoluteCap, float rVehicleBonusPerLevel) {
    HealthBonusMax = rHealthBonusMax;
    HealthBonusAbsoluteCap = rHealthBonusAbsoluteCap;
    VehicleBonusPerLevel = rVehicleBonusPerLevel;
}

function ModifyPawn(Pawn Other) {
    Super.ModifyPawn(Other);
    RealHealthGain = 0; //reset on respawn
}

function AdjustTargetDamage(out int Damage, int OriginalDamage, Pawn Injured, Pawn InstigatedBy, vector HitLocation, out vector Momentum, class<DamageType> DamageType) {
	local Pawn HealMe;
	local int HealthBonus, HealthGain;
    local float Bonus, Vampire;

    if(!class'DevoidEffect_Vampire'.static.CanBeApplied(Injured, InstigatedBy.Controller)) {
        return;
    }
    
    if(InstigatedBy.IsA('Vehicle')) {
        Bonus = VehicleBonusPerLevel;
    } else {
        Bonus = BonusPerLevel;
    }
    
    if(Bonus > 0) {
        Vampire = FMax(FMin(float(Injured.Health), float(Damage) * Bonus * float(AbilityLevel)), 0);
        if(Vampire > 0 && InstigatedBy.Controller != None) {
            RealHealthGain += Vampire;
            
            if(RealHealthGain > 1) {
                HealthGain = int(RealHealthGain);
                RealHealthGain -= float(HealthGain); //keeps the fraction
            
                //now works in vehicle side turrets!
                if(ONSWeaponPawn(InstigatedBy) != None) {
                    HealMe = ONSWeaponPawn(InstigatedBy).VehicleBase;
                } else {
                    HealMe = InstigatedBy;
                }
            
                if(HealMe != None) {
                    HealthBonus = HealMe.HealthMax * HealthBonusMax;
                    
                    if(HealthBonusAbsoluteCap > 0) {
                        HealthBonus = Min(HealthBonus, HealthBonusAbsoluteCap);
                    }

                    HealMe.GiveHealth(HealthGain, HealMe.HealthMax + HealthBonus);
                }
            }
        }
    }
}

simulated function string DescriptionText(){
    local string Text;

    Text = repl(
        repl(Super.DescriptionText(), "$1", class'Util'.static.FormatPercent(BonusPerLevel)),
        "$2", class'Util'.static.FormatPercent(HealthBonusMax));

    if(HealthBonusAbsoluteCap > 0) {
        Text = repl(Text, "$3", repl(AbsoluteCapText, "$4", HealthBonusAbsoluteCap));
    } else {
        Text = repl(Text, "$3", "");
    }

    if(VehicleBonusPerLevel > 0 && VehicleBonusPerLevel != BonusPerLevel) {
        Text = repl(Text, "$5", repl(VehicleText, "$6", class'Util'.static.FormatPercent(VehicleBonusPerLevel)));
    } else {
        Text = repl(Text, "$5", "");
    }

    return Text;
}

defaultproperties
{
	AbilityName="Vampirism"
	Description="Whenever you damage an opponent, you are healed for $1 of the damage per level (up to your maximum health amount + $2$3). $5You cannot gain health from self-damage."
	AbsoluteCapText=" or maximally +$4"
    VehicleText="When driving a vehicle, it will be repaired for $6 of the damage per level. "
	StartingCost=10
	CostAddPerLevel=5
	MaxLevel=10
	BonusPerLevel=0.05
    VehicleBonusPerLevel=0.05
	HealthBonusMax=0.333333
	HealthBonusAbsoluteCap=0
	Category=class'AbilityCategory_Health'
}
