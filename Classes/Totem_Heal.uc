class Totem_Heal extends RPGTotem
    config(TitanRPG);

var config int HealAmount;

function FireAt(Actor Other) {
    local Pawn P;
    local Effect_Heal Heal;
    local FX_Beam Beam;
    
    P = Pawn(Other);
    if(P != None && SameTeamAs(P.Controller)) {
        Heal = Effect_Heal(class'Effect_Heal'.static.Create(P, Instigator.Controller));
        if(Heal != None) {
            Heal.HealAmount = HealAmount;
            Heal.SelfHealingCap = HealAmount;
            Heal.Start();
            
            Beam = Instigator.Spawn(class'FX_HealingBeam', Indicator);
            Beam.LinkedPawn = P;
        }
    }
}

defaultproperties {
    HealAmount=10

    AffectedClass=class'Pawn'
    IndicatorClass=class'TotemIndicator_Heal'
}
