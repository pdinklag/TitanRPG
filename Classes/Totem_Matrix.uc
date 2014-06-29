class Totem_Matrix extends RPGTotem CacheExempt;

var config float Multiplier;
var config array<name> Ignore;

var RPGMatrixField Field;

auto state Active {
    event BeginState() {
        Log("Totem_Matrix BeginState: Controller =" @ Controller $ ", IconLocation =" @ IconLocation);
    
        Field = Spawn(class'RPGMatrixField', None,, Location);
        Field.Radius = SightRadius;
        Field.Multiplier = Multiplier;
        Field.Ignore = Ignore;
    }
    
    event EndState() {
        Field.Destroy();
    }
}

defaultproperties {
    Radius=1024
    Multiplier=0.2

    IconClass=class'TotemIcon_Matrix'
    VehicleNameString="Matrix Totem"
}
