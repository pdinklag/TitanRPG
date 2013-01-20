class Ability_Looter extends RPGAbility;

var config float PinataChance, UDamageChance;
var config int PinataMin, PinataMax;

var config float LootChance;
var config int MaxExpPickups;

var int ExpPickups;

function ModifyPawn(Pawn Other) {
	Super.ModifyPawn(Other);
    
    ExpPickups = 0; //reset
}

function ScoreKill(Controller Killed, class<DamageType> DamageType) {
    local array<class<Pickup> > Potentials;
    local int i, k, Num;
	local Pickup Pickup;
	local Pawn Victim;
    local xPawn X;
    local Inventory Inv;
    local Weapon W;
    
    if(FRand() < (1 - LootChance)) {
        return;
    }
	
	Victim = Killed.Pawn;
	if(Victim != None && Victim.IsA('xPawn')) {
        if(ExpPickups < MaxExpPickups) {
            Potentials[Potentials.Length] = class'ExperiencePickup';
        }
    
        if(AbilityLevel == MaxLevel && FRand() < PinataChance) {
            //PINATA!
            Num = int(RandRange(PinataMin, PinataMax));
            
            Potentials[Potentials.Length] = class'MiniHealthPack';
            Potentials[Potentials.Length] = class'AdrenalinePickup';
        } else {
            X = xPawn(Instigator);
        
            //Health vial
            if(Instigator.Health < Instigator.SuperHealthMax) {
                Potentials[Potentials.Length] = class'MiniHealthPack';
            }
            
            //Adrenaline
            if(Instigator.Controller != None && Instigator.Controller.Adrenaline < Instigator.Controller.AdrenalineMax) {
                Potentials[Potentials.Length] = class'AdrenalinePickup';
            }
            
            if(AbilityLevel >= 2) {
                //Health pack
                if(Instigator.Health < Instigator.HealthMax) {
                    Potentials[Potentials.Length] = class'HealthPack';
                }
                
                //Ammo
                for(Inv = Instigator.Inventory; Inv != None; Inv = Inv.Inventory) {
                    if(Inv.IsA('Weapon')) {
                        W = Weapon(Inv);
                        if(W.GetAmmoClass(0) != None && W.AmmoAmount(0) < W.GetAmmoClass(0).default.InitialAmount) {
                            if(W.GetAmmoClass(0).default.PickupClass != None) {
                                Potentials[Potentials.Length] = W.GetAmmoClass(0).default.PickupClass;
                            }
                        }
                        
                        if(W.GetAmmoClass(1) != None && W.GetAmmoClass(1) != W.GetAmmoClass(0) && W.AmmoAmount(1) < W.GetAmmoClass(1).default.InitialAmount) {
                            if(W.GetAmmoClass(1).default.PickupClass != None) {
                                Potentials[Potentials.Length] = W.GetAmmoClass(1).default.PickupClass;
                            }
                        }
                    }
                }
            }
            
            if(AbilityLevel >= 3) {
                //Shield
                if(Instigator.IsA('xPawn') &&
                    xPawn(Instigator).CanUseShield(class'ShieldPack'.default.ShieldAmount) > 0) {
                    
                    Potentials[Potentials.Length] = class'ShieldPack';
                }
                
                //UDamage
                if(!Instigator.HasUDamage() && FRand() < UDamageChance) {
                    Potentials[Potentials.Length] = class'UDamagePack';
                }
            }
            
            Num = Rand(AbilityLevel * BonusPerLevel) + 1;
        }
        
        //Spawn pickups
        if(Potentials.Length > 0) {
            for(i = 0; i < Num; i++) {
                k = Rand(Potentials.Length);
                
                Pickup = Spawn(Potentials[k], None, '', Victim.Location + Victim.CollisionHeight * vect(0, 0, 1));
                Pickup.InitDroppedPickupFor(Pickup.Inventory);
                Pickup.Velocity = VRand() * RandRange(100.0f, 200.0f);
                Pickup.Velocity.Z = FMin(200, Abs(Pickup.Velocity.Z));
                
                if(Pickup.IsA('ExperiencePickup')) {
                    ExpPickups++;
                }
            }
        }
	}
}

defaultproperties {
	AbilityName="Looter"
	Description="If you kill somebody, your victim will drop more powerful pickups each level."
    LevelDescription(0)="At level 1, your victims will drop single health vials, adrenaline pills or experience pickups."
    LevelDescription(1)="At level 2, there is a chance that your victims will drop health packs and ammo as needed."
    LevelDescription(2)="At level 3, there is a chance that your victims will drop shield packs as needed, as well as a chance to drop a UDamage or cause a pinata effect."
	MaxLevel=3
	BonusPerLevel=1
    PinataChance=0.05
    PinataMin=6
    PinataMax=12
    UDamageChance=0.15
    LootChance=0.67
    MaxExpPickups=5 //per life
	bUseLevelCost=true
	LevelCost(0)=15
	LevelCost(1)=15
    LevelCost(2)=10
	Category=class'AbilityCategory_Misc'
}
