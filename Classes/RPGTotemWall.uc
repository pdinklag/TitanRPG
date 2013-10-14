class RPGTotemWall extends Actor
    config(TitanRPG);

var RPGTotem Totems[2];
var bool bConnected;

var Material TeamSkins[4];

var float XSize, XOffset;

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
    local vector Scale, Dir;
    
    Totems[0] = A;
    Totems[1] = B;
    
    A.Walls[A.Walls.Length] = Self;
    B.Walls[B.Walls.Length] = Self;
    
    Dir = Normal(B.Location - A.Location);

    SetLocation(A.Location + Dir * XOffset);
    SetRotation(rotator(Dir));
    
    Scale.X = (VSize(A.Location - B.Location) - 2 * XOffset) / XSize;
    Scale.Y = 1;
    Scale.Z = 1;
    
    SetDrawScale3D(Scale);
}

defaultproperties {
    XSize=256
    XOffset=16
    
    TeamSkins(0)=FinalBlend'TitanRPG.Totem.WallRed'
    TeamSkins(1)=FinalBlend'TitanRPG.Totem.WallBlue'
    TeamSkins(2)=FinalBlend'TitanRPG.Totem.WallGreen'
    TeamSkins(3)=FinalBlend'TitanRPG.Totem.WallGold'
    
    bAlwaysRelevant=True
    NetUpdateFrequency=1
    bNetNotify=True
    
    bWorldGeometry=True
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
