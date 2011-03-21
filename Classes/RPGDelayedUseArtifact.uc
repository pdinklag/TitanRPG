class RPGDelayedUseArtifact extends RPGArtifact
	abstract;

var config bool bCanBeCanceled;
var float Countdown;

state Activated
{
	function BeginState()
	{
		Super.BeginState();
		
		Countdown = MinActivationTime; //MinActivationTime serves as the delay
	}

	event Tick(float dt)
	{
		Super.Tick(dt); //drain adrenaline
		
		Countdown -= dt;
		if(Countdown <= 0)
		{
			DoEffect();
			GotoState('');
		}
	}

	function DoEffect();

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
