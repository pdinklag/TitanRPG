class RPGDelayedUseArtifact extends RPGArtifact
	abstract;

var config bool bCanBeCanceled;
var float AdrenalineUsed;

state Activated
{
	function BeginState()
	{
		Super.BeginState();
		AdrenalineUsed = CostPerSec * MinActivationTime;
	}

	event Tick(float dt)
	{
		local float AdrenCost;

		AdrenCost = FMin(AdrenalineUsed, dt * CostPerSec);
		
		AdrenalineUsed -= AdrenCost;
		Instigator.Controller.Adrenaline = FMax(0, Instigator.Controller.Adrenaline - AdrenCost);
		
		if(AdrenalineUsed <= 0.f)
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
