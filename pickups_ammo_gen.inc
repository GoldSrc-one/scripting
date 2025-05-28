new g_valve_weapon[][32] = {"weapon_9mmhandgun", "weapon_357", "weapon_shotgun", "weapon_9mmAR", "weapon_crossbow", "weapon_rpg", "weapon_gauss", "weapon_egon"};
new g_valve_ammo[][32] = {"ammo_9mmbox", "ammo_357", "ammo_buckshot", "ammo_9mmAR", "ammo_crossbow", "ammo_rpgclip", "ammo_gaussclip", "ammo_egonclip"};

new g_cstrike_weapon[][32] = {"weapon_usp", "weapon_fiveseven", "weapon_deagle", "weapon_p228", "weapon_glock18", "weapon_elite", "weapon_m3", "weapon_xm1014", "weapon_mac10", "weapon_ump45", "weapon_p90", "weapon_mp5navy", "weapon_tmp", "weapon_awp", "weapon_g3sg1", "weapon_scout", "weapon_sg550", "weapon_ak47", "weapon_m249", "weapon_m4a1", "weapon_aug", "weapon_sg552", "weapon_galil", "weapon_famas"};
new g_cstrike_ammo[][32] = {"ammo_45acp", "ammo_57mm", "ammo_50ae", "ammo_357sig", "ammo_9mm", "ammo_9mm", "ammo_buckshot", "ammo_buckshot", "ammo_9mm", "ammo_45acp", "ammo_57mm", "ammo_9mm", "ammo_9mm", "ammo_338magnum", "ammo_762nato", "ammo_762nato", "ammo_556nato", "ammo_762nato", "ammo_556natobox", "ammo_556nato", "ammo_556nato", "ammo_556nato", "ammo_556nato", "ammo_556nato"};

get_num_ammo(game) {
        if (game == g_valve) return 8;
        if (game == g_cstrike) return 24;
        return 0;
}

get_ammo_weapon(game, ammo) {
        if (game == g_valve) return g_valve_weapon[ammo];
        if (game == g_cstrike) return g_cstrike_weapon[ammo];
        new emptyString[32] = "";
        return emptyString;
}

get_ammo_classname(game, ammo) {
        if (game == g_valve) return g_valve_ammo[ammo];
        if (game == g_cstrike) return g_cstrike_ammo[ammo];
        new emptyString[32] = "";
        return emptyString;
}

const MAX_AMMO = 24;
