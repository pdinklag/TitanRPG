class RPGTotemWall extends Actor
    config(TitanRPG);

var RPGTotem Totems[2];
var bool bConnected;

var Material TeamSkins[4];

var float XSize;

replication {
    reliable if(Role == ROLE_Authority && bNetDirty)
        Totems;
}

simulated event PostNetReceive() {
    Super.PostNetReceive();
    
    if(Role < ROLE_Authority) {
        if(!bConnected && Totems[0] != None && Totems[1] != None) {
            Connect(Totems[0], Totems[1]);
            
            if(Totems[0].Team >= 0 && Totems[0].Team <= 3) {
                Skins[0] = TeamSkins[Totems[0].Team];
            }
            
            bConnected = true;
        }
    }
}

simulated function Connect(RPGTotem A, RPGTotem B) {
    local vector Scale;
    
    Totems[0] = A;
    Totems[1] = B;
    
    A.Wall = Self;
    B.Wall = Self;

    SetLocation(A.Location);
    SetRotation(rotator(B.Location - A.Location));
    
    Scale.X = VSize(A.Location - B.Location) / XSize; 
    Scale.Y = 1;
    Scale.Z = 1;
    
    SetDrawScale3D(Scale);
}

defaultproperties {
    XSize=256
    TeamSkins(0)=FinalBlend'XEffectMat.Shield.RedShell'
    TeamSkins(1)=FinalBlend'XEffectMat.Shield.BlueShell'
    //TODO TeamSkins(2)=FinalBlend'TitanRPG.Totem.WallGreen'
    //TODO TeamSkins(3)=FinalBlend'TitanRPG.Totem.WallGold'
    
    bAlwaysRelevant=True
    NetUpdateFrequency=1
    bNetNotify=True
    
    bCollideWorld=False
    bCollideActors=True
    bBlockActors=True
    bBlockPlayers=True
    bBlockProjectiles=True
    bProjTarget=True
    bBlockZeroExtentTraces=True
    bBlockNonZeroExtentTraces=True
    bBlockKarma=True
    bUseCylinderCollision=False
    
    DrawType=DT_StaticMesh
    StaticMesh=StaticMesh'TitanRPG.Totem.Wall'
    
    //TODO ambient sound
}
