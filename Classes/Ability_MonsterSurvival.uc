class Ability_MonsterSurvival extends RPGAbility;

function ModifyRPRI() {
    Super.ModifyRPRI();
    
    RPRI.bMonstersDie = false;
}

defaultproperties {
    AbilityName="Transcendence"
    Description="Your conjured monsters will live on even if you die."
    StartingCost=10
    MaxLevel=1
    RequiredAbilities(0)=(AbilityClass=class'Ability_MonsterSummon',Level=1)
    Category=class'AbilityCategory_Monsters'
}
