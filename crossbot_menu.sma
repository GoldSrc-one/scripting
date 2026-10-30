#include <amxmodx>
#include <fakemeta>

#include "crossplay"

new g_bots_max;
new g_bots_nogoal;
new g_bot_difficulty;
new g_bot_melee;
new g_bot_brain;
new g_ratio_cvars[MAX_GAMES];
new g_team_cvars[MAX_GAMES];
new g_cstrike = -1;
new g_dod = -1;
new g_difficulties[][] = {"Easy", "Normal", "Hard", "Expert"}
new Float:g_ratios[MAX_GAMES];
new g_teams[MAX_GAMES];
new bool:g_nogoal = false;
new bool:g_deathmatch = true;
new g_mapOwner = -1;

const g_bots_think_task = 1;
const g_vote_menu_task = 100;
const g_vote_action_task = 200;
// Seconds a bot is left alone before a team kick: lets the join finish and caps churn
// when a game puts bots on the wrong side anyway.
const g_team_kick_grace = 30;

new g_teamNames[3][8] = {"ANY", "BLUE", "RED"};

new g_dodAllies[][] = {"garand", "carbine", "tommy", "grease", "spring", "bar", "30cal", "bazooka"};
new g_dodAxis[][] = {"k98", "k43", "mp40", "mp44", "k98s", "fg42", "mg34", "mg42", "pschreck"};

public plugin_precache() {
    register_plugin("CrossBot Menu", __DATE__, "GoldSrc.one");

    g_bots_max = register_cvar("bots_max", "8");
    g_bots_nogoal = register_cvar("bots_nogoal", "0");
}

public plugin_init() {
    register_clcmd("say bots", "bots_menu");
    register_clcmd("say /bots", "bots_menu");
    register_clcmd("say !bots", "bots_menu");
    register_clcmd("bots_ratio", "bots_ratio");
    register_forward(FM_Touch, "TouchPre", 0);
    register_forward(FM_Touch, "TouchPost", 1);
    register_forward(FM_SetModel, "SetModelPost", 1);

    set_task(1.0, "bots_think", g_bots_think_task, _, _, "b");
    register_clcmd("say", "bots_advertise");

    // CrossBot registers these; the fallbacks only keep the menu working without it.
    g_bot_difficulty = get_cvar_pointer("crossbot_difficulty");
    if(!g_bot_difficulty)
        g_bot_difficulty = register_cvar("crossbot_difficulty", "1");
    g_bot_melee = get_cvar_pointer("crossbot_melee_only");
    if(!g_bot_melee)
        g_bot_melee = register_cvar("crossbot_melee_only", "0");
    g_bot_brain = get_cvar_pointer("crossbot_brain");
    if(!g_bot_brain)
        g_bot_brain = register_cvar("crossbot_brain", "0");
    new prefix = get_cvar_pointer("crossbot_name_prefix");
    if(prefix)
        set_pcvar_string(prefix, "[BOT] ");

    for(new iGame = 0; iGame < GetNumGames(); iGame++) {
        new gameName[16], cvarName[32];
        GetGameName(iGame, gameName, 16);
        format(cvarName, 32, "bots_ratio_%s", gameName);
        g_ratio_cvars[iGame] = register_cvar(cvarName, "-1");
        format(cvarName, 32, "bots_team_%s", gameName);
        g_team_cvars[iGame] = register_cvar(cvarName, "0");
    }

    g_cstrike = GetGameIndex("cstrike");
    g_dod = GetGameIndex("dod");

    g_deathmatch = IsMapDeathmatch();
    g_mapOwner = GetEntityOwner(0);

    if(g_mapOwner == g_cstrike) {
        g_teamNames[1] = "CT";
        g_teamNames[2] = "T";
    }
    if(g_mapOwner == g_dod) {
        g_teamNames[1] = "Allies";
        g_teamNames[2] = "Axis";
    }
}

Float:default_ratio(iGame) {
    new gameName[16];
    GetGameName(iGame, gameName, 16);
    if(equal(gameName, "valve") || equal(gameName, "gearbox"))
        return random_float(10.0, 20.0);
    if(equal(gameName, "cstrike") || equal(gameName, "czero"))
        return random_float(35.0, 45.0);
    if(equal(gameName, "dmc"))
        return random_float(5.0, 15.0);
    if(equal(gameName, "tfc") || equal(gameName, "dod"))
        return random_float(30.0, 40.0);
    return 0.0;
}

public plugin_cfg() {
    new Float:ratioSum = 0.0;
    for(new iGame = 0; iGame < GetNumGames(); iGame++) {
        new Float:ratio = get_pcvar_float(g_ratio_cvars[iGame]);
        g_ratios[iGame] = ratio < 0.0 ? default_ratio(iGame) : ratio;
        ratioSum += g_ratios[iGame] / 100.0;

        g_teams[iGame] = clamp(get_pcvar_num(g_team_cvars[iGame]), 0, 2);
    }
    if(ratioSum > 0.0) {
        for(new iGame = 0; iGame < MAX_GAMES; iGame++)
            g_ratios[iGame] /= ratioSum;
    }

    g_nogoal = get_pcvar_num(g_bots_nogoal) != 0;
}

stock bool:FALSE = false;
#define ANNOUNCE(%0,%1,%2) \
do { \
    new player_name[64];\
    get_user_name(%0, player_name, 64);\
    log_message(%1, player_name, %2);\
    client_print(0, print_chat, %1, player_name, %2);\
} while(FALSE)

new g_voting = false;
new g_voters = 0;
new g_voteYes = 0;
new g_voteNo = 0;
new g_voteMenu = 0;
new g_voteAction[32];
new g_votePlayerId = 0;
new g_voteValue = 0;

const maxBans = 32;
new g_voteBanIDs[maxBans];
new Float:g_voteBanTimes[maxBans];

public vote_menu(player_id, menuTitle[], action[32]) {
    if(g_voting) {
        client_print(player_id, print_chat, "Cannot vote right now!");
        return;
    }

    new userid =  get_user_userid(player_id);
    new Float:time = get_gametime();
    for(new i = 0; i < maxBans; i++) {
        if(g_voteBanTimes[i] < time)
            break;

        if(g_voteBanIDs[i] == userid) {
            client_print(player_id, print_chat, "You cannot vote in next %.0f seconds!", g_voteBanTimes[i] - time);
            return;
        }
    }

    new menu = menu_create(menuTitle, "vote_menu_handler");
    menu_additem(menu, "Yes do it!");
    menu_additem(menu, "No don't do it!");

    g_voting = true;
    g_voters = 0;
    g_voteNo = 0;
    g_voteYes = 0;
    g_voteMenu = menu;
    g_voteAction = action;
    g_votePlayerId = player_id;

    for(new i = 1; i <= get_maxplayers(); i++) {
        if(!is_user_connected(i) || is_user_bot(i) || is_user_hltv(i))
            continue;

        if(i != player_id) {
            menu_display(i, menu);
            set_task(10.0, "vote_menu_cancel", g_vote_menu_task + i);
        }

        g_voters++;
    }

    if(g_voters > 1) {
        client_print(player_id, print_chat, "You have started a vote.");
    }

    vote_menu_handler(player_id, menu, 0);
}

public vote_menu_handler(player_id, menu, item) {
    remove_task(g_vote_menu_task + player_id);

    if(item == 0) {
        g_voteYes++;
    }
    if(item == 1) {
        g_voteNo++;
    }
    g_voters--;

    if(g_voters != 0)
        return PLUGIN_HANDLED;

    g_voting = false;
    menu_destroy(menu);

    if(g_voteYes <= g_voteNo) {
        client_print(g_votePlayerId, print_chat, "The vote failed, you will not be able to vote again for the next 5 minutes.");
        for(new i = 1; i < maxBans; i++) {
            g_voteBanIDs[i] = g_voteBanIDs[i - 1];
            g_voteBanTimes[i] = g_voteBanTimes[i - 1];
        }
        g_voteBanIDs[0] = get_user_userid(g_votePlayerId);
        g_voteBanTimes[0] = get_gametime() + 300.0;
        return PLUGIN_HANDLED;
    }

    set_task(0.0, g_voteAction, g_vote_action_task);
    return PLUGIN_HANDLED;
}

public vote_menu_cancel(task_id) {
    show_menu(task_id - g_vote_menu_task, 0, "^n", 1 );
    vote_menu_handler(task_id - g_vote_menu_task, g_voteMenu, MENU_EXIT);
}

bool:getGameAbbr(iGame, gameAbbr[16]) {
    GetGameName(iGame, gameAbbr, 16);
    return GetGameAbbr(gameAbbr, gameAbbr, 16);
}

getRatiosString(const Float:ratios[]) {
    new ratiosString[64];
    new pos = 0;

    for(new iGame = 0; iGame < MAX_GAMES; iGame++) {
        new gameAbbr[16];
        if(getGameAbbr(iGame, gameAbbr))
            pos += format(ratiosString[pos], 64, "%s:%.0f%% ", gameAbbr, ratios[iGame]);
    }

    return ratiosString;
}

getTeamsString(const teams[]) {
    new teamsString[64];
    new pos = 0;

    for(new iGame = 0; iGame < MAX_GAMES; iGame++) {
        new gameAbbr[16];
        if(getGameAbbr(iGame, gameAbbr))
            pos += format(teamsString[pos], 64, "%s:%s ", gameAbbr, g_teamNames[teams[iGame]]);
    }

    return teamsString;
}

get_difficulty() {
    return clamp(get_pcvar_num(g_bot_difficulty), 0, 3);
}

public bots_menu(player_id) {
    new menu = menu_create("Bots menu", "bots_menu_handler");
    menu_additem(menu, "Kill all bots");
    new changeBotCount[64];
    format(changeBotCount, 64, "Change max bot count (now: %d)", get_pcvar_num(g_bots_max));
    menu_additem(menu, changeBotCount);
    new changeBotDifficulty[64];
    format(changeBotDifficulty, 64, "Change bot difficulty (now: %s)", g_difficulties[get_difficulty()]);
    menu_additem(menu, changeBotDifficulty);
    new changeBotRatios[64];
    format(changeBotRatios, 64, "Change bot ratios (now: %s)", getRatiosString(g_ratios));
    menu_additem(menu, changeBotRatios);
    new changeBotTeams[64];
    format(changeBotTeams, 64, "Change bot teams (now: %s)", getTeamsString(g_teams));
    menu_additem(menu, changeBotTeams);
    new changeBotNoGoal[64];
    format(changeBotNoGoal, 64, "%s bots picking up bombs and flags", g_nogoal ? "Allow" : "Prevent");
    menu_additem(menu, changeBotNoGoal);
    new melee[64];
    format(melee, 64, "Melee only (now: %s)", get_pcvar_num(g_bot_melee) ? "On" : "Off");
    menu_additem(menu, melee);
    new brain[64];
    format(brain, 64, "Communicate (now: %s)", get_pcvar_num(g_bot_brain) ? "On" : "Off");
    menu_additem(menu, brain);
    // No paging; pad to 9 items so the forced exit lands on key 0.
    while(menu_items(menu) < 9)
        menu_addblank2(menu);
    menu_setprop(menu, MPROP_PERPAGE, 0);
    menu_setprop(menu, MPROP_EXIT, MEXIT_FORCE);
    menu_display(player_id, menu);
    return PLUGIN_HANDLED;
}

new Float:g_player_ratios[33][MAX_GAMES];
new g_player_teams[33][MAX_GAMES];
public bots_menu_handler(player_id, menu, item) {
    menu_destroy(menu);
    if(item == 0) {
        new playerName[64];
        get_user_name(player_id, playerName, 64);
        new menuTitle[256];
        format(menuTitle, 256, "Kill all the bots? %s has started the vote.", playerName);
        vote_menu(player_id, menuTitle, "kill_all_bots");
    }
    if(item == 1) {
        new changeBotCount[64];
        format(changeBotCount, 64, "Change max bot count (%d)", get_pcvar_num(g_bots_max));
        menu = menu_create(changeBotCount, "bot_count_handler");
        for(new i = 0; i <= (get_maxplayers()/4)*3; i += 4) {
            new botCount[4];
            format(botCount, 4, "%d", i);
            menu_additem(menu, botCount);
        }
        menu_display(player_id, menu);
    }
    if(item == 2) {
        new changeBotDifficulty[64];
        format(changeBotDifficulty, 64, "Change bot difficulty (%s)", g_difficulties[get_difficulty()]);
        menu = menu_create(changeBotDifficulty, "bot_difficulty_handler");
        for(new i = 0; i < 4; i++) {
            menu_additem(menu, g_difficulties[i]);
        }
        menu_display(player_id, menu);
    }
    if(item == 3) {
        for(new iGame = 0; iGame < MAX_GAMES; iGame++)
            g_player_ratios[player_id][iGame] = g_ratios[iGame];

        ratios_menu(player_id);
    }
    if(item == 4) {
        if(g_deathmatch) {
            bots_menu(player_id);
            return PLUGIN_HANDLED;
        }

        for(new iGame = 0; iGame < MAX_GAMES; iGame++)
            g_player_teams[player_id][iGame] = g_teams[iGame];

        teams_menu(player_id);
    }
    if(item == 5) {
        new playerName[64];
        get_user_name(player_id, playerName, 64);
        new menuTitle[256];
        format(menuTitle, 256, "%s bots picking up bombs and flags? %s has started the vote.", g_nogoal ? "Allow" : "Prevent", playerName);
        vote_menu(player_id, menuTitle, "toggle_nogoal");
    }
    if(item == 6) {
        new playerName[64];
        get_user_name(player_id, playerName, 64);
        new menuTitle[256];
        format(menuTitle, 256, "%s ^"melee only^"? %s has started the vote.", get_pcvar_num(g_bot_melee) ? "Disable" : "Enable", playerName);
        vote_menu(player_id, menuTitle, "toggle_melee");
    }
    if(item == 7) {
        new playerName[64];
        get_user_name(player_id, playerName, 64);
        new menuTitle[256];
        format(menuTitle, 256, "%s bots communicating? %s has started the vote.", get_pcvar_num(g_bot_brain) ? "Disable" : "Enable", playerName);
        vote_menu(player_id, menuTitle, "toggle_brain");
    }
    return PLUGIN_HANDLED;
}

public kill_all_bots() {
    ANNOUNCE(g_votePlayerId, "%s has killed all the bots", 0);
    for(new player_id = 1; player_id <= get_maxplayers(); player_id++) {
        if(!is_user_connected(player_id) || !is_user_bot(player_id) || !is_user_alive(player_id))
            continue;

        user_kill(player_id, 1);
    }
}

public bot_count_handler(player_id, menu, item) {
    menu_destroy(menu);
    if(item != MENU_EXIT) {
        new newCount = item * 4;

        new playerName[64];
        get_user_name(player_id, playerName, 64);
        new menuTitle[256]
        format(menuTitle, 256, "Set the max bot count to %d (now %d)? %s has started the vote.", newCount, get_pcvar_num(g_bots_max), playerName);
        g_voteValue = newCount;
        vote_menu(player_id, menuTitle, "change_bots_max");

    }
    return PLUGIN_HANDLED;
}

public bot_difficulty_handler(player_id, menu, item) {
    menu_destroy(menu);
    if(item != MENU_EXIT) {
        new playerName[64];
        get_user_name(player_id, playerName, 64);
        new menuTitle[256]
        format(menuTitle, 256, "Set the bot difficulty to %s (now %s)? %s has started the vote.", g_difficulties[item], g_difficulties[get_difficulty()], playerName);
        g_voteValue = item;
        vote_menu(player_id, menuTitle, "change_bot_difficulty");

    }
    return PLUGIN_HANDLED;
}

public change_bots_max() {
    ANNOUNCE(g_votePlayerId, "%s has changed the max bot count to %d", g_voteValue);
    set_pcvar_num(g_bots_max, g_voteValue);
}

public change_bot_difficulty() {
    ANNOUNCE(g_votePlayerId, "%s has changed the bot difficulty to %s", g_difficulties[g_voteValue]);
    set_pcvar_num(g_bot_difficulty, g_voteValue);
}

ratios_menu(player_id) {
    new menu = menu_create("Change bot ratios", "bot_ratio_handler");
    for(new iGame = 0; iGame < MAX_GAMES; iGame++) {
        new gameAbbr[16];
        if(getGameAbbr(iGame, gameAbbr)) {
            new gameRatio[32];
            format(gameRatio, 32, "%s (%.0f %%)", gameAbbr, g_player_ratios[player_id][iGame]);
            menu_additem(menu, gameRatio);
        }
    }
    menu_additem(menu, "Save");
    menu_display(player_id, menu);
}

new g_ratio_game[33];
public bot_ratio_handler(player_id, menu, item) {
    menu_destroy(menu);
    if(item < 0)
        return PLUGIN_HANDLED;
    for(new iGame = 0; iGame < MAX_GAMES; iGame++) {
        new gameAbbr[16];
        if(!getGameAbbr(iGame, gameAbbr))
            continue;

        item--;
        if(item < 0) {
            g_ratio_game[player_id] = iGame;
            client_cmd(player_id, "messagemode bots_ratio");
            return PLUGIN_HANDLED;
        }
    }

    new playerName[64];
    get_user_name(player_id, playerName, 64);
    new menuTitle[256]
    format(menuTitle, 256, "Change the bot ratios to: %s (now: %s)? %s has started the vote.", getRatiosString(g_player_ratios[player_id]), getRatiosString(g_ratios), playerName);
    vote_menu(player_id, menuTitle, "change_bot_ratios");
    return PLUGIN_HANDLED;
}

public bots_ratio(player_id) {
    if(read_argc() > 1 && g_ratio_game[player_id] != -1) {
        new ratioText[16];
        read_argv(1, ratioText, 16);
        new Float:newRatio = floatclamp(str_to_float(ratioText), 0.0, 100.0);

        new Float:sumOthers = 0.0;
        for(new iGame = 0; iGame < MAX_GAMES; iGame++) {
            if(iGame != g_ratio_game[player_id])
                sumOthers += g_player_ratios[player_id][iGame] / 100.0;
        }

        if(sumOthers == 0.0) {
            newRatio = 100.0;
        } else {
            new Float:factor = (1.0 - (newRatio / 100.0)) / sumOthers;
            for(new iGame = 0; iGame < MAX_GAMES; iGame++)
                g_player_ratios[player_id][iGame] *= factor;
        }
        g_player_ratios[player_id][g_ratio_game[player_id]] = newRatio;
        ratios_menu(player_id);
    }
    g_ratio_game[player_id] = -1;
}

public change_bot_ratios() {
    for(new iGame = 0; iGame < MAX_GAMES; iGame++)
        g_ratios[iGame] = g_player_ratios[g_votePlayerId][iGame];

    ANNOUNCE(g_votePlayerId, "%s has changed the bot ratios to: %s", getRatiosString(g_ratios));
}

teams_menu(player_id) {
    new menu = menu_create("Change bot teams", "bot_teams_handler");
    for(new iGame = 0; iGame < MAX_GAMES; iGame++) {
        new gameAbbr[16];
        if(getGameAbbr(iGame, gameAbbr)) {
            new gameRatio[32];
            format(gameRatio, 32, "%s (%s)", gameAbbr, g_teamNames[g_player_teams[player_id][iGame]]);
            menu_additem(menu, gameRatio);
        }
    }
    menu_additem(menu, "Save");
    menu_display(player_id, menu);
}

public bot_teams_handler(player_id, menu, item) {
    menu_destroy(menu);
    if(item < 0)
        return PLUGIN_HANDLED;
    for(new iGame = 0; iGame < MAX_GAMES; iGame++) {
        new gameAbbr[16];
        if(!getGameAbbr(iGame, gameAbbr))
            continue;

        item--;
        if(item < 0) {
            g_player_teams[player_id][iGame] = (g_player_teams[player_id][iGame] + 1) % sizeof(g_teamNames);
            teams_menu(player_id);
            return PLUGIN_HANDLED;
        }
    }

    new playerName[64];
    get_user_name(player_id, playerName, 64);
    new menuTitle[256]
    format(menuTitle, 256, "Change the bot teams to: %s (now: %s)? %s has started the vote.", getTeamsString(g_player_teams[player_id]), getTeamsString(g_teams), playerName);
    vote_menu(player_id, menuTitle, "change_bot_teams");
    return PLUGIN_HANDLED;
}

public change_bot_teams() {
    for(new iGame = 0; iGame < MAX_GAMES; iGame++)
        g_teams[iGame] = g_player_teams[g_votePlayerId][iGame];

    ANNOUNCE(g_votePlayerId, "%s has changed the bot teams to: %s", getTeamsString(g_teams));
}

public toggle_nogoal() {
    ANNOUNCE(g_votePlayerId, "%s has %s bots picking up bombs and flags.", g_nogoal ? "allowed" : "prevented");
    g_nogoal = !g_nogoal;
}

public toggle_melee() {
    new newMelee = !get_pcvar_num(g_bot_melee);
    ANNOUNCE(g_votePlayerId, "%s has %s ^"melee only^"", newMelee ? "enabled" : "disabled");
    set_pcvar_num(g_bot_melee, newMelee);
}

public toggle_brain() {
    new newBrain = !get_pcvar_num(g_bot_brain);
    ANNOUNCE(g_votePlayerId, "%s has %s bots communicating", newBrain ? "enabled" : "disabled");
    set_pcvar_num(g_bot_brain, newBrain);
}

pick_a_game(game_counts[], sign) {
    new minGame = -1;
    new Float:minCount;
    for(new i = 0; i < MAX_GAMES; i++) {
        if(!g_ratios[i])
            continue;

        new Float:gameCount = (sign * game_counts[i]) / (g_ratios[i] / 100.0);

        if(gameCount < minCount || minGame == -1) {
            minGame = i;
            minCount = gameCount;
        }
    }

    return minGame;
}

// The third crossbot_add argument: CS takes the team, DoD a class (which picks the team).
// With no team preference these join the smaller side ourselves, so the balance kick agrees with it.
add_arg(iGame, arg[16], const team_counts[3]) {
    new team = g_teams[iGame];
    if(!team && !g_deathmatch && (iGame == g_cstrike || iGame == g_dod))
        team = team_counts[1] <= team_counts[2] ? 1 : 2;
    copy(arg, 15, "*");
    if(iGame == g_cstrike) {
        new csTeams[][] = {"*", "ct", "t"};
        copy(arg, 15, csTeams[team]);
    }
    if(iGame == g_dod) {
        if(team == 0)
            copy(arg, 15, "random");
        if(team == 1)
            copy(arg, 15, g_dodAllies[random(sizeof(g_dodAllies))]);
        if(team == 2)
            copy(arg, 15, g_dodAxis[random(sizeof(g_dodAxis))]);
    }
}

public bots_think() {
    new total_players;
    new total_bots;
    new game_counts[MAX_GAMES];
    new team_counts[3];
    for(new player_id = 1; player_id <= get_maxplayers(); player_id++) {
        if(!is_user_connected(player_id) || is_user_hltv(player_id))
            continue;

        new team = pev(player_id, pev_team);
        if(team < 0 || team > 2)
            team = 0;
        team_counts[team]++;

        if(is_user_bot(player_id)) {
            total_bots++;
        } else {
            if(!g_deathmatch && !team)
                continue;

            total_players++;
        }

        game_counts[GetEntityOwner(player_id)]++;
    }

    new max_bots = get_pcvar_num(g_bots_max);

    new want_bots = max_bots - total_players;
    if(want_bots < 0) {
        want_bots = 0;
    }

    //add
    if(want_bots > total_bots) {
        new addGame = pick_a_game(game_counts, 1);
        if(addGame != -1) {
            new gameName[16], arg[16];
            GetGameName(addGame, gameName, 16);
            add_arg(addGame, arg, team_counts);
            server_print("Adding a %s %s bot... (%d < %d)", gameName, g_teamNames[g_teams[addGame]], total_bots, want_bots);
            server_cmd("crossbot_add %s ^"^" %s", gameName, arg);
        }
    }

    //kick
    new kick_id = 0;
    new kick_reason[64] = "";
    //kick bad team
    for(new player_id = 1; !g_deathmatch && !kick_id && player_id <= get_maxplayers(); player_id++) {
        if(!is_user_connected(player_id) || !is_user_bot(player_id) || get_user_time(player_id) < g_team_kick_grace)
            continue;

        new bot_game = GetEntityOwner(player_id);
        new bot_team = pev(player_id, pev_team);
        if(!g_teams[bot_game] || !bot_team || bot_team == g_teams[bot_game])
            continue;

        format(kick_reason, 64, "bot team #%d != game team #%d", bot_team, g_teams[bot_game]);
        kick_id = player_id;
    }
    //kick team balance
    for(new player_id = 1; !g_deathmatch && !kick_id && player_id <= get_maxplayers(); player_id++) {
        if(!is_user_connected(player_id) || !is_user_bot(player_id) || get_user_time(player_id) < g_team_kick_grace)
            continue;

        new bot_team = pev(player_id, pev_team);
        if(!bot_team)
            continue;

        new other_team = 3 - bot_team;
        if(team_counts[bot_team] - 1 <= team_counts[other_team])
            continue;

        format(kick_reason, 64, "team #%d count > team #%d count (%d > %d)", bot_team, other_team, team_counts[bot_team], team_counts[other_team]);
        kick_id = player_id;
    }
    //kick game balance
    new bool:kickAnyone = want_bots < total_bots;
    new kickGame = pick_a_game(game_counts, -1);
    for(new player_id = 1; kickAnyone && kickGame != -1 && !kick_id && player_id <= get_maxplayers(); player_id++) {
        if(!is_user_connected(player_id) || !is_user_bot(player_id))
            continue;

        if(GetEntityOwner(player_id) != kickGame)
            continue;

        new gameName[16];
        GetGameName(kickGame, gameName, 16);
        format(kick_reason, 64, "quota (%s)", gameName);
        kick_id = player_id;
    }
    //kick anyone
    for(new player_id = 1; kickAnyone && !kick_id && player_id <= get_maxplayers(); player_id++) {
        if(!is_user_connected(player_id) || !is_user_bot(player_id))
            continue;

        kick_reason = "quota (any)";
        kick_id = player_id;
    }

    if(kick_id) {
        server_print("Kicking a bot... (%s)", kick_reason);
        server_cmd("kick #%d", get_user_userid(kick_id));
    }
}

const Float:advert_interval = 300.0;
new Float:g_last_advert = -advert_interval;

public bots_advertise(player_id) {
    if(g_last_advert + advert_interval > get_gametime())
        return PLUGIN_CONTINUE;

    new saytext[256];
    read_args(saytext, 255);
    if(strfind(saytext, "bot", true) == -1)
        return PLUGIN_CONTINUE;

    g_last_advert = get_gametime();
    client_print(0, print_chat, "If you wish to change the bot count or difficulty, say /bots to open the bots menu.");
    return PLUGIN_CONTINUE;
}

new Float:g_dodBreakableTakedamage = DAMAGE_NO;
IgnoreDodBreakable(player, breakable) {
    if(g_mapOwner != g_dod)
        return;

    new Float:takedamage;
    pev(breakable, pev_takedamage, takedamage);
    if(takedamage == DAMAGE_NO || (pev(breakable, pev_spawnflags) & 0x379) == 0)
        return;

    if(!is_user_bot(player) || GetEntityOwner(player) == g_dod || GetEntityOwner(breakable) != g_dod)
        return;

    new classname[32];
    pev(breakable, pev_classname, classname, 32);
    if(!equal(classname, "func_breakable"))
        return;

    g_dodBreakableTakedamage = takedamage;
    set_pev(breakable, pev_takedamage, DAMAGE_NO);
}

public TouchPre(touched, other) {
    if(!pev_valid(touched) || !pev_valid(other))
        return FMRES_IGNORED;

    IgnoreDodBreakable(touched, other);

    if(!g_nogoal)
        return FMRES_IGNORED;

    if(!is_user_bot(other))
        return FMRES_IGNORED;

    new classname[32];
    pev(touched, pev_classname, classname, 32);
    if(equal(classname, "weapon_c4") || equal(classname, "item_tfgoal")) {
        //server_print("Prevented bot touching %s.", classname);
        return FMRES_SUPERCEDE;
    }

    new model[32];
    pev(touched, pev_model, model, 32);
    if(equal(model, "models/w_backpack.mdl") || equal(model, "models/flag.mdl") || equal(model, "models/keycard.mdl") || equal(model, "models/ball.mdl")) {
        //server_print("Prevented bot touching %s.", model);
        return FMRES_SUPERCEDE;
    }

    return FMRES_IGNORED;
}

public TouchPost(touched, other) {
    if(g_dodBreakableTakedamage == DAMAGE_NO)
        return FMRES_IGNORED;

    set_pev(other, pev_takedamage, g_dodBreakableTakedamage);
    g_dodBreakableTakedamage = DAMAGE_NO;
    return FMRES_IGNORED;
}

public SetModelPost(entity, const model[]) {
    if(!g_nogoal)
        return FMRES_IGNORED;

    new classname[32];
    pev(entity, pev_classname, classname, 32);
    if(!equal(classname, "weapon_c4")) {
        return FMRES_SUPERCEDE;
    }

    new Float:bombOrigin[3];
    pev(entity, pev_origin, bombOrigin);

    for(new iPlayer = 1; iPlayer <= get_maxplayers(); iPlayer++) {
        if(!is_user_bot(iPlayer))
            continue;

        new Float:botOrigin[3];
        pev(iPlayer, pev_origin, botOrigin);
        if(bombOrigin[0] != botOrigin[0] || bombOrigin[1] != botOrigin[1] || bombOrigin[2] != botOrigin[2])
            continue;

        set_pev(entity, pev_flags, pev(entity, pev_flags) | FL_KILLME);
        //server_print("Prevented %s touching bot.", model);
        return FMRES_HANDLED;
    }
    return FMRES_IGNORED;
}
