class Blast_Flak extends Blast_Projectile;

defaultproperties {
    ProjectileClass=class'FlakBombShell'
    NumProjectiles=100
    SpeedMin=1000
    SpeedMax=1350
    
    ChargeEmitterClass=class'FX_BlastCharger_Flak'
}
