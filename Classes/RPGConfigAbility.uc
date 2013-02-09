/*
    Introducing: Config abilities.

    These are new special types of abilities that can be defined entirely in the TitanRPG.ini file.

    They can be referred to by using a "@" sign followed by the name
    with which they were defined in the INI file.

    Every ability module that is defined uses up one of the GenAbility_XX classes, of which
    there is a limited amount. The amount of those classes is the limit of modules that can be
    defined.
*/
class RPGConfigAbility extends Object
    config(TitanRPG)
    PerObjectConfig
    DependsOn(RPGAbility);

//Static counter
var array<RPGConfigAbility> ConfigAbilities;

//Re-define structs because UnrealScript is extremely limited...
struct AbilityStruct
{
	var class<RPGAbility> AbilityClass;
	var int Level;
};

struct GrantItemStruct
{
	var int Level;
	var class<Inventory> InventoryClass;
};

//Properties
var string ModuleName;

var class<RPGGeneratedAbility> AbilityClass;

var config string AbilityName, StatName, Description;
var config class<RPGAbilityCategory> Category;
var config array<string> LevelDescription;

var config int StartingCost, CostAddPerLevel, MaxLevel;
var config bool bUseLevelCost;
var config array<int> LevelCost;
var config array<int> RequiredLevels;

var config array<AbilityStruct> RequiredAbilities;
var config array<AbilityStruct> ForbiddenAbilities;

var config array<GrantItemStruct> GrantItem;

//Resolves an ability name which starts with an "@" sign to the respective GenAbility class used.
static function class<RPGAbility> Resolve(string ModuleName) {
    local int i;
    for(i = 0; i < default.ConfigAbilities.Length; i++) {
        if(default.ConfigAbilities[i].ModuleName ~= ModuleName) {
            return default.ConfigAbilities[i].AbilityClass;
        }
    }
    return None;
}

//Resets everything
static function ResetAll() {
    default.ConfigAbilities.Length = 0;
}

//Selects the next available GenAbility_Xc class and adjusts it to this configuration
function class<RPGAbility> InitAbility() {
    local string ClassName;
    local int i;

    ClassName = class'MutTitanRPG'.default.PackageName $ ".GeneratedAbility_";
    if(default.ConfigAbilities.Length < 10) {
        ClassName $= "0";
    }
    ClassName $= default.ConfigAbilities.Length $ "_t";
    
    AbilityClass = class<RPGGeneratedAbility>(DynamicLoadObject(ClassName, class'Class'));
    if(AbilityClass != None) {
        //Log("Config ability" @ ModuleName @ "is now using" @ AbilityClass);
    
        //Use up
        default.ConfigAbilities[default.ConfigAbilities.Length] = Self;
        AbilityClass.default.Module = Self;
        
        //Initialize
        AbilityClass.default.AbilityName = AbilityName;
        AbilityClass.default.StatName = StatName;
        AbilityClass.default.Description = Description;
        AbilityClass.default.Category = Category;
        
        AbilityClass.default.LevelDescription.Length = LevelDescription.Length;
        for(i = 0; i < LevelDescription.Length; i++) {
            AbilityClass.default.LevelDescription[i] = LevelDescription[i];
        }
        
        AbilityClass.default.StartingCost = StartingCost;
        AbilityClass.default.CostAddPerLevel = CostAddPerLevel;
        AbilityClass.default.MaxLevel = MaxLevel;
        AbilityClass.default.bUseLevelCost = bUseLevelCost;
        
        AbilityClass.default.LevelCost.Length = LevelCost.Length;
        for(i = 0; i < LevelCost.Length; i++) {
            AbilityClass.default.LevelCost[i] = LevelCost[i];
        }
        
        AbilityClass.default.RequiredLevels.Length = RequiredLevels.Length;
        for(i = 0; i < RequiredLevels.Length; i++) {
            AbilityClass.default.RequiredLevels[i] = RequiredLevels[i];
        }
        
        AbilityClass.default.RequiredAbilities.Length = RequiredAbilities.Length;
        for(i = 0; i < RequiredAbilities.Length; i++) {
            AbilityClass.default.RequiredAbilities[i].AbilityClass = RequiredAbilities[i].AbilityClass;
            AbilityClass.default.RequiredAbilities[i].Level = RequiredAbilities[i].Level;
        }
        
        AbilityClass.default.ForbiddenAbilities.Length = ForbiddenAbilities.Length;
        for(i = 0; i < ForbiddenAbilities.Length; i++) {
            AbilityClass.default.ForbiddenAbilities[i].AbilityClass = ForbiddenAbilities[i].AbilityClass;
            AbilityClass.default.ForbiddenAbilities[i].Level = ForbiddenAbilities[i].Level;
        }
        
        AbilityClass.default.GrantItem.Length = GrantItem.Length;
        for(i = 0; i < GrantItem.Length; i++) {
            AbilityClass.default.GrantItem[i].Level = GrantItem[i].Level;
            AbilityClass.default.GrantItem[i].InventoryClass = GrantItem[i].InventoryClass;
        }
    }
    
    return AbilityClass;
}

defaultproperties {
}
