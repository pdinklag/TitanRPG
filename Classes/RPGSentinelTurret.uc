class RPGSentinelTurret extends ASVehicle_Sentinel_Floor
    HideDropDown
    CacheExempt;

auto state Sleeping {
	function TakeDamage( int Damage, Pawn instigatedBy, Vector hitlocation,
					Vector momentum, class<DamageType> damageType) {

        Global.TakeDamage(Damage, instigatedBy, hitlocation, momentum, damageType);
                    
		if ( Role == Role_Authority )
			AwakeSentinel();
	}
}

state Opening {
	function TakeDamage( int Damage, Pawn instigatedBy, Vector hitlocation,
					Vector momentum, class<DamageType> damageType) {

        Global.TakeDamage(Damage, instigatedBy, hitlocation, momentum, damageType);
	}
}

state Closing {
	function TakeDamage( int Damage, Pawn instigatedBy, Vector hitlocation,
					Vector momentum, class<DamageType> damageType) {

        Global.TakeDamage(Damage, instigatedBy, hitlocation, momentum, damageType);
	}
}

defaultproperties {
}
