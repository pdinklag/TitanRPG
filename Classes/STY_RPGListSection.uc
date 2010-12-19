class STY_RPGListSection extends STY2ListSectionHeader;

event Initialize()
{
	local int i;

	Super.Initialize();

	for(i = 0; i < 5; i++)
		Images[i] = Controller.DefaultPens[0];
}

defaultproperties
{
	KeyName="RPGListSection"

    FontColors(0)=(R=255,G=230,B=0,A=255)
    FontColors(1)=(R=255,G=230,B=0,A=255)
    FontColors(2)=(R=255,G=230,B=0,A=255)
    FontColors(3)=(R=255,G=230,B=0,A=255)
    FontColors(4)=(R=255,G=230,B=0,A=255)
	
	ImgColors(0)=(R=16,G=16,B=64,A=255)
	ImgColors(1)=(R=16,G=16,B=64,A=255)
	ImgColors(2)=(R=16,G=16,B=64,A=255)
	ImgColors(3)=(R=16,G=16,B=64,A=255)
	ImgColors(4)=(R=16,G=16,B=64,A=255)
}
