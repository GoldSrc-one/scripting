
/**
 * Is the current map a deathmatch map (including fy maps)?
 *
 * @return               "true" for deathmatch/fy maps and "false" for teamplay and non-fy maps.
 */
stock bool:IsMapDeathmatchOrFy() {
    if(GetEntityOwner(0) == GetGameIndex("cstrike")) {
        new mapname[64];
        get_mapname(mapname, 64);
        if(equal(mapname, "fy_", 3) && !equal(mapname, "fy_nuketown"))
            return true;
    }

    return IsMapDeathmatch();
}