#include <amxmodx>
#include <engine>

#include "crossplay"

new g_bots_max;
new g_bots_melee;
new g_bot_difficulty;
new g_valve = -1;
new g_cstrike = -1;
new g_difficulties[][] = {"Easy", "Normal", "Hard", "Expert"}

public plugin_init() {
    register_plugin("Bots", "0.0", "GoldSrc.one");
    register_clcmd("say bots", "bots_menu");
    register_clcmd("say /bots", "bots_menu");
    register_clcmd("say !bots", "bots_menu");
    g_bots_max = register_cvar("bots_max", "8");
    g_bots_melee = register_cvar("bots_melee", "0");
    g_bot_difficulty = get_cvar_pointer("bot_difficulty");    
    
    set_task(1.0, "bots_think", _, _, _, "b");
    register_clcmd("say", "bots_advertise");

    for(new i = 0; i < GetNumGames(); i++) {
        new gameName[16];
        GetGameName(i, gameName, 16);

        if(strcmp(gameName, "valve") == 0)
            g_valve = i;

        if(strcmp(gameName, "cstrike") == 0)
            g_cstrike = i;
    }
    
    if(g_valve == -1 || g_cstrike == -1)
        set_fail_state("valve + cstrike expected!")
}

public bots_menu(player_id) {
    new menu = menu_create("Bots menu", "bots_menu_handler");
    menu_additem(menu, "Kill all bots");
    new changeBotCount[32];
    format(changeBotCount, 32, "Change max bot count (now: %d)", get_pcvar_num(g_bots_max));
    menu_additem(menu, changeBotCount);
    new changeBotDifficulty[32];
    format(changeBotDifficulty, 32, "Change bot difficulty (now: %s)", g_difficulties[get_pcvar_num(g_bot_difficulty)]);
    menu_additem(menu, changeBotDifficulty);
    new melee[32];
    format(melee, 32, "Crowbars vs knives (now: %s)", get_pcvar_num(g_bots_melee) ? "On" : "Off");
    menu_additem(menu, melee);
    menu_display(player_id, menu);    
    return PLUGIN_HANDLED;
}

stock bool:FALSE = false;
#define ANNOUNCE(%0,%1,%2) \
do { \
    new player_name[64];\
    get_user_name(%0, player_name, 64);\
    log_message(%1, player_name, %2);\
    client_print(0, print_chat, %1, player_name, %2);\
} while(FALSE)

public bots_menu_handler(player_id, menu, item) {
    menu_destroy(menu);
    if(item == 0) {
        ANNOUNCE(player_id, "%s has killed all the bots", 0);
        for(new player_id = 1; player_id <= get_maxplayers(); player_id++) {
            if(!is_user_connected(player_id) || !is_user_bot(player_id) || !is_user_alive(player_id))
                continue;

            user_kill(player_id, 1);
        }
    }
    if(item == 1) {
        new changeBotCount[32];
        format(changeBotCount, 32, "Change max bot count (%d)", get_pcvar_num(g_bots_max));
        menu = menu_create(changeBotCount, "bot_count_handler");
        for(new i = 0; i <= (get_maxplayers()/4)*3; i += 4) {
            new botCount[4];
            format(botCount, 4, "%d", i);
            menu_additem(menu, botCount);
        }
        menu_display(player_id, menu);
    }
    if(item == 2) {
        new changeBotDifficulty[32];
        format(changeBotDifficulty, 32, "Change bot difficulty (%s)", g_difficulties[get_pcvar_num(g_bot_difficulty)]);
        menu = menu_create(changeBotDifficulty, "bot_difficulty_handler");
        for(new i = 0; i < 4; i++) {
            menu_additem(menu, g_difficulties[i]);
        }
        menu_display(player_id, menu);
    }
    if(item == 3) {
        new newMelee = 1 - get_pcvar_num(g_bots_melee);
        ANNOUNCE(player_id, "%s has %s ^"crowbars vs knives^"", newMelee ? "enabled" : "disabled");
        set_pcvar_num(g_bots_melee, newMelee);
    }
    return PLUGIN_HANDLED;
}

public bot_count_handler(player_id, menu, item) {
    menu_destroy(menu);
    if(item != MENU_EXIT) {
        new newCount = item * 4;
        ANNOUNCE(player_id, "%s has changed the max bot count to %d", newCount);
        set_pcvar_num(g_bots_max, newCount);
    }
    return PLUGIN_HANDLED;
}

public bot_difficulty_handler(player_id, menu, item) {
    menu_destroy(menu);
    if(item != MENU_EXIT) {
        ANNOUNCE(player_id, "%s has changed the bot difficulty to %s, the bots will now reconnect", g_difficulties[item]);
        set_pcvar_num(g_bot_difficulty, item);
    }
    return PLUGIN_HANDLED;
}

pick_a_game(game_counts[], sign) {
    new game = -1;
    if(sign * game_counts[g_valve] < sign * game_counts[g_cstrike])
        game = g_valve;
    else if(sign * game_counts[g_cstrike] < sign * game_counts[g_valve])
        game = g_cstrike;
    else if(random(2))
        game = g_valve;
    else
        game = g_cstrike;
    
    return game;
}

new g_last_difficulty = -1;
new g_evict = false;
new g_last_melee = -1;

public bots_think() {
    new difficulty = get_pcvar_num(g_bot_difficulty);
    if(difficulty != g_last_difficulty) {
        server_cmd("jk_botti botskill %d", 4 - difficulty);
        g_last_difficulty = difficulty;
        g_evict = true;
    }
    new melee = get_pcvar_num(g_bots_melee);
    if(melee != g_last_melee) {
        if(melee) {
            server_cmd("bot_knives_only");
            new weapons[][] = {"weapon_handgrenade", "weapon_snark", "weapon_egon", "weapon_gauss", "weapon_shotgun", "weapon_357", "weapon_hornetgun", "weapon_9mmAR", "weapon_crossbow", "weapon_rpg", "weapon_9mmhandgun",
                "weapon_eagle", "weapon_m249", "weapon_displacer", "weapon_shockrifle", "weapon_sporelauncher", "weapon_sniperrifle"};
            
            for(new i = 0; i < sizeof weapons; i++) {
                server_cmd("jk_botti botweapon %s avoid_this_gun 1", weapons[i]);
            }
            for(new i = 1; i <= 5; i++) {
                server_cmd("jk_botti bot_skill_setup %d keep_optimal_dist 100", i);
                server_cmd("jk_botti bot_skill_setup %d battle_strafe 0", i);
            }
        } else {
            server_cmd("bot_all_weapons");
            server_cmd("jk_botti botweapon reset");
            server_cmd("jk_botti bot_skill_setup reset");
        }
        g_last_melee = melee;
    }

    new total_players;
    new total_bots;
    new game_counts[8];
    for(new player_id = 1; player_id <= get_maxplayers(); player_id++) {
        if(!is_user_connected(player_id))
            continue;

        if(is_user_bot(player_id)) {
            total_bots++;
        } else {
            total_players++;
        }
        
        game_counts[GetEntityOwner(player_id)]++;
    }

    new max_bots = get_pcvar_num(g_bots_max);

    new want_bots = max_bots - total_players;
    if(want_bots < 0) {
        want_bots = 0;
    }

    if(total_bots == 0)
        g_evict = false;

    //add
    if(want_bots > total_bots && !g_evict) {
        new game = pick_a_game(game_counts, 1);
        new gameName[16];
        GetGameName(game, gameName, 16);
        server_print("Adding a %s bot... (%d < %d)", gameName, total_bots, want_bots);

        if(game == g_valve)
            server_cmd("jk_botti addbot UNASSIGNED");
        if(game == g_cstrike)
            server_cmd("bot_add");
    }

    //kick
    if(want_bots < total_bots || g_evict) {
        new game = pick_a_game(game_counts, -1);
        new gameName[16];
        GetGameName(game, gameName, 16);
        if(g_evict)
            server_print("Kicking a %s bot... (evict)", gameName);
        else
            server_print("Kicking a %s bot... (%d > %d)", gameName, total_bots, want_bots);

        new bot_id;
        new bot_game;

        for(new player_id = 1; player_id <= get_maxplayers(); player_id++) {
            if(!is_user_connected(player_id) || !is_user_bot(player_id))
                continue;

            bot_id = player_id;
            bot_game = GetEntityOwner(player_id);
            if(bot_game == game)
                break;
        }

        if(bot_game == g_cstrike) {
            new name[16];
            get_user_name(bot_id, name, 16);
            server_cmd("bot_kick ^"%s^"", name);
        } else {
            new userid = get_user_userid(bot_id);
            server_cmd("kick #%d", userid);
        }
    }
}

const Float:advert_interval = 300.0;
new Float:g_last_advert = -advert_interval;

public bots_advertise(player_id) {
    if(g_last_advert + advert_interval > get_gametime())
        return PLUGIN_CONTINUE;

    new saytext[256];
    read_args(saytext, 255);
    if(strfind(saytext, "bot", 1) == -1)
        return PLUGIN_CONTINUE;

    g_last_advert = get_gametime();
    client_print(0, print_chat, "If you wish to change the bot count or difficulty, say /bots to open the bots menu.");
    return PLUGIN_CONTINUE;
}