class RPGShieldGun extends ShieldGun
    HideDropDown
	CacheExempt;

simulated event PreBeginPlay()
{
	if(Role == ROLE_Authority && class'MutTitanRPG'.static.Instance(Level).bOLTeamGames)
		AttachmentClass = class<InventoryAttachment>(DynamicLoadObject("OLTeamGames.OLTeamsShieldAttachment", class'Class'));

	Super.PreBeginPlay();
}

function AdjustPlayerDamage( out int Damage, Pawn InstigatedBy, Vector HitLocation,
						         out Vector Momentum, class<DamageType> DamageType)
{
    local int Drain;
	local vector Reflect;
    local vector HitNormal;
    local float DamageMax;
	local int TempDamage;

	DamageMax = 100.0;
	if ( DamageType == class'Fell' )
		DamageMax = 20.0;
    else if( !DamageType.default.bArmorStops || !DamageType.default.bLocationalHit || (DamageType == class'DamTypeShieldImpact' && InstigatedBy == Instigator) )
        return;

    if ( CheckReflect(HitLocation, HitNormal, 0) )
    {
		//We have a problem here, UDamage is not applied to the damage here yet!!
		//We are going to make UDamage work on the shield gun now.
		TempDamage = Damage;
		if(InstigatedBy != None && InstigatedBy.HasUDamage())
			TempDamage = TempDamage * 2 * InstigatedBy.DamageScaling; //apply UDamage
		
		Reflect = MirrorVectorByNormal( Normal(Location - HitLocation), Vector(Instigator.Rotation) );
		Momentum *= 1.25;
		
		if(DamageType == class'DamTypeLightningRod') //special rod handling
		{
			Drain = Min(AmmoAmount(1), TempDamage);
			TempDamage -= Drain;
			
			ConsumeAmmo(1,Drain);
			DoReflectEffect(Drain);
		}
		else
		{
			Drain = Min( AmmoAmount(1)*2, TempDamage );
			Drain = Min(Drain, DamageMax);
			
			TempDamage -= Drain;
			if ( (Instigator != None) && (Instigator.PlayerReplicationInfo != None) && (Instigator.PlayerReplicationInfo.HasFlag != None) )
			{
				Drain = Min(AmmoAmount(1), Drain);
				ConsumeAmmo(1,Drain);
				DoReflectEffect(Drain);
			}
			else
			{
				ConsumeAmmo(1,Drain/2);
				DoReflectEffect(Drain/2);
			}
		}
		
		Damage = TempDamage;
		if(InstigatedBy != None && InstigatedBy.HasUDamage())
			Damage = Damage / 2 / InstigatedBy.DamageScaling; //unapply UDamage as later code will apply it again
    }
}
