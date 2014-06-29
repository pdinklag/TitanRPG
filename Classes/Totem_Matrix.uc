class Totem_Matrix extends RPGTotem CacheExempt;

var config float Multiplier;
var config array<name> Ignore;

var RPGMatrixField Field;

auto state Active {
    event BeginState() {
        Field = Spawn(class'RPGMatrixField',,, IconLocation);
        Field.Radius = SightRadius;
        Field.Multiplier = Multiplier;
        Field.Ignore = Ignore;
    }
    
    event EndState() {
        Field.Destroy();
    }
}

function SetMaster(Controller Master) {
    if(Field != None) {
        Field.Creator = Master;
    }
}

defaultproperties {
    Radius=1024
    Multiplier=0.2

    IconClass=class'TotemIcon_Matrix'
    VehicleNameString="Matrix Totem"
}
