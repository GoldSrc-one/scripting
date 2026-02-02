new g_valve_items[][32] = {"item_battery", "item_healthkit", "item_longjump"};
new g_cstrike_items[][32] = {"item_kevlar", "item_assaultsuit", "weapon_shield"};
new g_gearbox_items[][32] = {"item_battery", "item_healthkit", "item_longjump"};
new g_dmc_items[][32] = {"item_health", "item_armor1", "item_armor2", "item_armor3", "item_artifact_invisibility", "item_artifact_super_damage", "item_artifact_invulnerability"};
new g_tfc_items[][32] = {"weaponbox"};
new g_dod_items[][32] = {"ammo_generic_american", "ammo_generic_german"};

get_num_items(game) {
    if (game == g_valve) return sizeof(g_valve_items);
    if (game == g_cstrike) return sizeof(g_cstrike_items);
    if (game == g_gearbox) return sizeof(g_gearbox_items);
    if (game == g_dmc) return sizeof(g_dmc_items);
    if (game == g_tfc) return sizeof(g_tfc_items);
    if (game == g_dod) return sizeof(g_dod_items);
    return 0;
}

get_item(game, item) {
    if (game == g_valve) return g_valve_items[item];
    if (game == g_cstrike) return g_cstrike_items[item];
    if (game == g_gearbox) return g_gearbox_items[item];
    if (game == g_dmc) return g_dmc_items[item];
    if (game == g_tfc) return g_tfc_items[item];
    if (game == g_dod) return g_dod_items[item];
    new emptyString[32] = "";
    return emptyString;
}

const MAX_ITEMS = 7;