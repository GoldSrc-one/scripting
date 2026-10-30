#include <amxmodx>
#include <amxmisc>
#include "crossplay"

const AUTH_LEN = 35;
const GAME_LEN = 16;
const NAME_LEN = 32;

enum _:Row {
    R_AUTH[AUTH_LEN],
    R_GAME[GAME_LEN],
    R_NAME[NAME_LEN],
    R_KILLS,
    R_DEATHS
};

new Array:g_stats;
new Trie:g_index;
new g_row[33] = {-1, ...};
new g_path[128];

public plugin_init() {
    register_plugin("Crossplay Stats", __DATE__, "GoldSrc.one");

    register_event("DeathMsg", "OnDeath", "a");
    register_clcmd("say rank", "ShowRank");
    register_clcmd("say /rank", "ShowRank");
    register_clcmd("say !rank", "ShowRank");
    register_clcmd("say top15", "ShowTop15");
    register_clcmd("say /top15", "ShowTop15");
    register_clcmd("say !top15", "ShowTop15");

    g_stats = ArrayCreate(Row);
    g_index = TrieCreate();

    get_datadir(g_path, charsmax(g_path));
    add(g_path, charsmax(g_path), "/crossplay_stats.txt");
    LoadStats();

    set_task(60.0, "SaveStats", _, _, _, "b");
}

public plugin_end() {
    SaveStats();
}

LoadStats() {
    new f = fopen(g_path, "rt");
    if(!f)
        return;

    new line[256], kills[12], deaths[12], row[Row];
    while(fgets(f, line, charsmax(line))) {
        trim(line);
        if(!line[0])
            continue;

        parse(line, row[R_AUTH], AUTH_LEN - 1, row[R_GAME], GAME_LEN - 1, row[R_NAME], NAME_LEN - 1, kills, charsmax(kills), deaths, charsmax(deaths));
        row[R_KILLS] = str_to_num(kills);
        row[R_DEATHS] = str_to_num(deaths);
        AddRow(row);
    }
    fclose(f);
}

AddRow(row[Row]) {
    new key[AUTH_LEN + GAME_LEN + 1];
    formatex(key, charsmax(key), "%s|%s", row[R_AUTH], row[R_GAME]);
    new idx = ArrayPushArray(g_stats, row);
    TrieSetCell(g_index, key, idx);
    return idx;
}

public SaveStats() {
    new tmp[140];
    formatex(tmp, charsmax(tmp), "%s.tmp", g_path);
    new f = fopen(tmp, "wt");
    if(!f)
        return;

    new row[Row];
    for(new i = 0; i < ArraySize(g_stats); i++) {
        ArrayGetArray(g_stats, i, row);
        fprintf(f, "^"%s^" ^"%s^" ^"%s^" %d %d^n", row[R_AUTH], row[R_GAME], row[R_NAME], row[R_KILLS], row[R_DEATHS]);
    }
    fclose(f);

    // Atomic replace where the OS allows it (Linux), so the external reader never sees a partial file.
    if(!rename_file(tmp, g_path, 1)) {
        delete_file(g_path);
        rename_file(tmp, g_path, 1);
    }
}

public client_putinserver(id) {
    g_row[id] = -1;
    if(is_user_bot(id) || is_user_hltv(id))
        return;

    new iGame = GetEntityOwner(id);
    if(iGame == -1)
        return;

    new auth[AUTH_LEN];
    get_user_authid(id, auth, charsmax(auth));
    if(!auth[0] || containi(auth, "LAN") != -1 || containi(auth, "PENDING") != -1 || containi(auth, "BOT") != -1)
        return;

    new game[GAME_LEN];
    GetGameName(iGame, game, charsmax(game));

    new name[NAME_LEN];
    get_user_name(id, name, charsmax(name));
    replace_all(name, charsmax(name), "^"", "'");

    new row[Row], key[AUTH_LEN + GAME_LEN + 1], idx;
    formatex(key, charsmax(key), "%s|%s", auth, game);
    if(TrieGetCell(g_index, key, idx)) {
        ArrayGetArray(g_stats, idx, row);
    } else {
        copy(row[R_AUTH], AUTH_LEN - 1, auth);
        copy(row[R_GAME], GAME_LEN - 1, game);
        idx = AddRow(row);
    }

    copy(row[R_NAME], NAME_LEN - 1, name);
    ArraySetArray(g_stats, idx, row);
    g_row[id] = idx;
}

public OnDeath() {
    new killer = read_data(1);
    new victim = read_data(2);
    new maxplayers = get_maxplayers();

    if(1 <= victim <= maxplayers)
        AddStat(g_row[victim], R_DEATHS);

    if(killer != victim && 1 <= killer <= maxplayers && 1 <= victim <= maxplayers && is_user_connected(killer) && !is_user_bot(victim))
        AddStat(g_row[killer], R_KILLS);
}

AddStat(idx, field) {
    if(idx == -1)
        return;

    new row[Row];
    ArrayGetArray(g_stats, idx, row);
    row[field]++;
    ArraySetArray(g_stats, idx, row);
}

public ShowRank(id) {
    if(g_row[id] == -1) {
        client_print(id, print_chat, "Your stats are not tracked.");
        return PLUGIN_HANDLED;
    }

    new row[Row], other[Row];
    ArrayGetArray(g_stats, g_row[id], row);
    new score = row[R_KILLS] - row[R_DEATHS];

    new total = ArraySize(g_stats);
    new rank = 1;
    for(new i = 0; i < total; i++) {
        ArrayGetArray(g_stats, i, other);
        if(other[R_KILLS] - other[R_DEATHS] > score)
            rank++;
    }

    new abbr[16];
    GetGameAbbr(row[R_GAME], abbr, charsmax(abbr));
    client_print(id, print_chat, "Your rank is %d of %d with %d kills, %d deaths (%s)", rank, total, row[R_KILLS], row[R_DEATHS], abbr);
    return PLUGIN_HANDLED;
}

public ShowTop15(id) {
    client_print(id, print_chat, "Type /top15 into the discord chat to see the leaderboard.");
    return PLUGIN_HANDLED;
}
