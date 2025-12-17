#include <amxmodx>
#include "crossplay"

const MAX_TIPS = 96;
const MAX_TIP_LEN = 256
new g_tipCounts[MAX_GAMES];
new g_tips[MAX_GAMES][MAX_TIPS][MAX_TIP_LEN];

public plugin_init() {
    register_plugin("Tips", "0.0", "GoldSrc.one");

    new f = fopen("tips.txt", "rt");
    if(!f)
        return;

    new line[512];
    new lineLen;
    do {
        lineLen = fgets(f, line, 512);
        for(new iGame = 0; iGame < GetNumGames(); iGame++) {
            new lineStart = GetLineStart(iGame, line);
            if(lineStart < 0)
                continue;
            
            copy(g_tips[iGame][g_tipCounts[iGame]], MAX_TIP_LEN, line[lineStart]);
            g_tipCounts[iGame]++;
        }
    } while (lineLen > 0);
    
    fclose(f);

    set_task(150.0, "tip", _, _, _, "b");
}

GetLineStart(iGame, const line[]) {
    if(equal(line, "[crossplay]", 11))
        return 11;

    new gameName[16];
    new gameNameLen = GetGameName(iGame, gameName, 16);
    if(line[0] == '[' && equal(line[1], gameName, gameNameLen) && line[gameNameLen + 1] == ']')
        return gameNameLen + 2;

    return -1;
}

public tip() {
    for(new player_id = 1; player_id <= get_maxplayers(); player_id++) {
        if(!is_user_connected(player_id) || is_user_bot(player_id) || is_user_hltv(player_id))
            continue;
        
        new iGame = GetEntityOwner(player_id);
        if(iGame == -1)
            continue;

        new iTip = random(g_tipCounts[iGame]);
        client_print(player_id, print_chat, "TIP --> %s", g_tips[iGame][iTip]);
    }
    return PLUGIN_CONTINUE;
}