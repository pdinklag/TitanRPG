//This draws the health bars for the Awareness ability
class AwarenessInteraction extends Interaction;

var AwarenessEnemyList EnemyList;
var Material HealthBarMaterial;
var float BarUSize, BarVSize;

var int AbilityLevel;

event Initialized()
{
	BarUSize = HealthBarMaterial.MaterialUSize();
	BarVSize = HealthBarMaterial.MaterialVSize();
	EnemyList = ViewportOwner.Actor.Spawn(class'AwarenessEnemyList');
}

function PreRender(Canvas Canvas)
{
	local int i;
	local float Dist, XScale, YScale, HealthScale, ScreenX;
	local vector BarLoc, CameraLocation, X, Y, Z;
	local rotator CameraRotation;
	local Pawn Enemy;

	if (ViewportOwner.Actor.Pawn == None || ViewportOwner.Actor.Pawn.Health <= 0)
		return;

	for (i = 0; i < EnemyList.Enemies.length; i++)
	{
		Enemy = EnemyList.Enemies[i];
		if (Enemy == None || Enemy.Health <= 0 || (xPawn(Enemy) != None && xPawn(Enemy).bInvis))
			continue;
		Canvas.GetCameraLocation(CameraLocation, CameraRotation);
		if (Normal(Enemy.Location - CameraLocation) dot vector(CameraRotation) < 0)
			continue;
		ScreenX = Canvas.WorldToScreen(Enemy.Location).X;
		if (ScreenX < 0 || ScreenX > Canvas.ClipX)
			continue;
 		Dist = VSize(Enemy.Location - CameraLocation);
 		if (Dist > ViewportOwner.Actor.TeamBeaconMaxDist * FClamp(0.04 * Enemy.CollisionRadius, 1.0, 3.0))
 			continue;
		if (!Enemy.FastTrace(Enemy.Location + Enemy.CollisionHeight * vect(0,0,1), ViewportOwner.Actor.Pawn.Location + ViewportOwner.Actor.Pawn.EyeHeight * vect(0,0,1)))
			continue;

		GetAxes(rotator(Enemy.Location - CameraLocation), X, Y, Z);
		if (Enemy.IsA('Monster'))
		{
			BarLoc = Canvas.WorldToScreen(Enemy.Location + (Enemy.CollisionHeight * 1.25 + BarVSize / 2) * vect(0,0,1) - Enemy.CollisionRadius * Y);
		}
		else
		{
			BarLoc = Canvas.WorldToScreen(Enemy.Location + (Enemy.CollisionHeight + BarVSize / 2) * vect(0,0,1) - Enemy.CollisionRadius * Y);
		}
		XScale = (Canvas.WorldToScreen(Enemy.Location + (Enemy.CollisionHeight + BarVSize / 2) * vect(0,0,1) + Enemy.CollisionRadius * Y).X - BarLoc.X) / BarUSize;
		YScale = FMin(0.15 * XScale, 0.50);

 		Canvas.SetPos(BarLoc.X, BarLoc.Y);
 		Canvas.Style = 1;
 		HealthScale = Enemy.Health / Enemy.HealthMax;
 		if (AbilityLevel > 1)
		{
	 		if (HealthScale > 0.5)
 			{
	 			Canvas.DrawColor.R = Clamp(255 * (1.f - (Enemy.HealthMax - (Enemy.HealthMax - Enemy.Health) * 2)/Enemy.HealthMax), 0, 255);
	 			Canvas.DrawColor.G = 255;
		 		Canvas.DrawColor.B = 0;
		 		Canvas.DrawColor.A = 255;
	 		}
		 	else
		 	{
	 			Canvas.DrawColor.R = 255;
	 			Canvas.DrawColor.G = Clamp(255 * (2.f * HealthScale), 0, 255);
		 		Canvas.DrawColor.B = 0;
		 		Canvas.DrawColor.A = 255;
	 		}
			Canvas.DrawTile(HealthBarMaterial, BarUSize*XScale*HealthScale, BarVSize*YScale, 0, 0, BarUSize, BarVSize);
			if (Enemy.ShieldStrength > 0 && xPawn(Enemy) != None)
			{
				Canvas.DrawColor = class'HUD'.default.GoldColor;
				YScale /= 2;
				Canvas.SetPos(BarLoc.X, BarLoc.Y - BarVSize * (YScale + 0.05));
				Canvas.DrawTile(HealthBarMaterial, BarUSize*XScale*Enemy.ShieldStrength/xPawn(Enemy).ShieldStrengthMax, BarVSize*YScale, 0, 0, BarUSize, BarVSize);
			}
		}
		else
		{
			if (HealthScale < 0.25)
				Canvas.DrawColor = class'HUD'.default.RedColor;
			else if (HealthScale < 0.50)
				Canvas.DrawColor = class'HUD'.default.GoldColor;
			else
				Canvas.DrawColor = class'HUD'.default.GreenColor;
			Canvas.DrawTile(HealthBarMaterial, BarUSize*XScale, BarVSize*YScale, 0, 0, BarUSize, BarVSize);
		}
	}
}

event NotifyLevelChange()
{
	Remove();
}

function Remove()
{
	EnemyList.Destroy();
	EnemyList = None;
	
	Master.RemoveInteraction(Self);
}

defaultproperties
{
	HealthBarMaterial=Texture'Engine.WhiteSquareTexture'
	bActive=False
	bVisible=True
}
