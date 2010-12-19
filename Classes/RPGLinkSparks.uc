class RPGLinkSparks extends LinkSparks;

simulated function SetLinkStatus(int Links, bool bLinking, float ls)
{
    mSizeRange[0] = default.mSizeRange[0] * (ls*1.0 + 1);
    mSizeRange[1] = default.mSizeRange[1] * (ls*1.0 + 1);
    mSpeedRange[0] = default.mSpeedRange[0] * (ls*0.7 + 1);
    mSpeedRange[1] = default.mSpeedRange[1] * (ls*0.7 + 1);
    mLifeRange[0] = default.mLifeRange[0] * (ls + 1);
    mLifeRange[1] = mLifeRange[0];
    DesiredRegen = default.mRegenRange[0] * (ls + 1);
}

simulated function SetSparkColor(int TeamIndex)
{
    switch(TeamIndex)
    {
        case 0:
            Skins[0] = Texture(DynamicLoadObject("OLTeamGamesTex.LinkGun.link_spark_red", class'Texture'));
            break;
        case 1:
            Skins[0] = Texture(DynamicLoadObject("OLTeamGamesTex.LinkGun.link_spark_blue", class'Texture'));
            break;
        case 2:
            Skins[0] = Texture'XEffectMat.Link.link_spark_green';
            break;
        case 3:
            Skins[0] = Texture'XEffectMat.Link.link_spark_yellow';
            break;
    }
}

defaultproperties
{
}
