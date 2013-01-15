class ArtifactBase_DelayedUse extends RPGArtifact
	abstract
    HideDropDown;

var bool bIgnoreUsedUp;

var config bool bCanBeCanceled;
var float Countdown;

function UsedUp()
{
	if(bIgnoreUsedUp)
		Super.UsedUp();
}

state Activated
{
	function BeginState()
	{
		Super.BeginState();
		
		Countdown = MinActivationTime; //MinActivationTime serves as the delay
	}

	event Tick(float dt)
	{
		Countdown -= dt;
		if(Countdown <= 0)
		{
			DoEffect();
			GotoState('');
			bIgnoreUsedUp = true; //don't tell player that his adrenaline is used up
		}
	
		Super.Tick(dt); //drain adrenaline
		bIgnoreUsedUp = false;
	}

	function bool DoEffect()
	{
		return true;
	}

	function EndState()
	{
		Super.EndState();
	}
}

function bool CanDeactivate()
{
	return bCanBeCanceled;
}

defaultproperties
{
	bCanBeCanceled=True
	MinActivationTime=1.000000
}
