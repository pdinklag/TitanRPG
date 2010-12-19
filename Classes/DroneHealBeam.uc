class DroneHealBeam extends xEmitter;

var Material RedSkin, BlueSkin, GreenSkin, GoldSkin, DefaultSkin;

simulated function SetTeamNum(byte x)
{
	if(x == 0)
		Skins[0] = RedSkin;
	else if(x == 1)
		Skins[0] = BlueSkin;
	//OLTeamGames
	else if(x == 2)
		Skins[0] = GreenSkin;
	else if(x == 3)
		Skins[0] = GoldSkin;
}

defaultproperties
{
	mParticleType=PT_Beam
	mMaxParticles=3
	mRegenDist=12.000000
	mSpinRange(0)=45000.000000
	mSizeRange(0)=8.000000
	mColorRange(0)=(B=240,G=240,R=240)
	mColorRange(1)=(B=240,G=240,R=240)
	mAttenuate=False
	mAttenKa=0.000000
	mBendStrength=3.000000
	bNetTemporary=False
	bReplicateInstigator=True
	RemoteRole=ROLE_SimulatedProxy
	AmbientSound=Sound'WeaponSounds.LinkGun.BLinkGunBeam2'
	Skins(0)=FinalBlend'XEffectMat.Link.LinkBeamYellowFB'
	RedSkin=FinalBlend'XEffectMat.Link.LinkBeamRedFB'
	BlueSkin=FinalBlend'XEffectMat.Link.LinkBeamBlueFB'
	GreenSkin=FinalBlend'XEffectMat.Link.LinkBeamGreenFB'
	GoldSkin=FinalBlend'XEffectMat.Link.LinkBeamYellowFB'
	Style=STY_Additive
	bHardAttach=True
	SoundVolume=192
	SoundRadius=96.000000
}
