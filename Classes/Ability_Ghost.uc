class Ability_Ghost extends RPGAbility;

var config bool bAllowSuicide; //should Ultima trigger when you killed yourself?

function bool PreventDeath(Pawn Killed, Controller Killer, class<DamageType> DamageType, vector HitLocation, bool bAlreadyPrevented)
{
	local Vehicle V;

	//not on suicide / team switch
	if(DamageType == class'DamageType' || DamageType == class'Suicided')
		return false;
	
	if(Killer == Killed && !bAllowSuicide)
		return false;

	//spacefighters destroy all their inventory on possess, so if we do anything here it will never die
	//because our marker will get destroyed afterward
	if(Killed.IsA('ASVehicle_SpaceFighter') || (Killed.DrivenVehicle != None && Killed.DrivenVehicle.IsA('ASVehicle_SpaceFighter')))
		return false;
		
	if(Killed.IsA('Monster') || (ASVehicle(Killed) != None && ASVehicle(Killed).bNonHumanControl))
		return false;

	if(Killed.bStationary || Killed.IsA('SVehicle'))
	{
		V = Vehicle(Killed);
		
		//Possibly check for ejector seat before doing this... ~pd
		if(V != None && !V.bRemoteControlled && !V.bEjectDriver && V.Driver != None)
			V.Driver.Died(Killer, DamageType, HitLocation);

		return false;
	}
	
	if(Killed.FindInventoryType(class'GhostInv') != None)
		return false;
		
	//ability won't work if pawn is still attached to the vehicle
	if(Killed.DrivenVehicle != None)
	{
		Killed.Health = 1; //so vehicle will properly kick pawn out
		Killed.DrivenVehicle.KDriverLeave(true);
	}
	
	class'RPGEffect'.static.RemoveAll(Killed);
	class'Util'.static.GiveInventory(Killed, class'GhostInv');
	return true;
}

function bool PreventSever(Pawn Killed, name boneName, int Damage, class<DamageType> DamageType)
{
	if(Killed.FindInventoryType(class'GhostInv') != None)
		return false;

	return true;
}

defaultproperties
{
	AbilityName="Ghost"
	Description="Once per spawn, when you get killed, instead of dying, you turn into a non-corporeal and get moved to a different location where you can continue your life."
	ForbiddenAbilities(0)=(AbilityClass=class'Ability_Ultima',Level=1)
	StartingCost=25
	MaxLevel=1
	bAllowSuicide=True
	Category=class'AbilityCategory_Misc'
}
