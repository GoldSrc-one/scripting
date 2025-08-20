#include <amxmodx>
#include "crossplay"

public plugin_init() {
	register_plugin("DiscordLite", "0.0", "GoldSrc.one");
	register_concmd("say", "_dl_sayhandler");
	set_task(0.5, "readin", _, _, _, "b");
	set_task(10.0, "writestatus", _, _, _, "b");
}

public readin() {
	new f = fopen("discord2hlds.txt", "rt");
	if(!f)
		return;

	new line[512];
	new lineLen = 0;
	do {
		lineLen = fgets(f, line, 511);
		for(new i = 0; i < lineLen; i++){
			if(line[i] == '^t') {
				line[i] = 0;
				client_print(0, print_chat, "[Discord] %s: %s", line[0], line[i+1]);
				break;
			}
		}
	} while(lineLen);
	fclose(f);

	f = fopen("discord2hlds.txt", "w");
	if(!f)
		return;
		
	fclose(f);
}

writeout(const game[], const name[], const action[], const text[] = "") {
	new f = fopen("hlds2discord.txt", "at");
	if(!f)
		return;

	fputs(f, game);
	fputs(f, "^t");
	fputs(f, name);
	fputs(f, "^t");
	fputs(f, action);
	fputs(f, "^t");
	fputs(f, text);
	fputs(f, "^n");

	fclose(f);
}

public client_connect(player_id) {
	if(is_user_bot(player_id))
		return PLUGIN_CONTINUE;
	
	new game[64];
	GetClientGame(player_id, game, 63);

	new name[64];
	get_user_name(player_id, name, 63);

	writeout(game, name, "connected");
	return PLUGIN_CONTINUE;
}

public client_disconnect(player_id) {
	if(is_user_bot(player_id))
		return PLUGIN_CONTINUE;
		
	new game[64];
	GetClientGame(player_id, game, 63);

	new name[64];
	get_user_name(player_id, name, 63);

	writeout(game, name, "disconnected");
	return PLUGIN_CONTINUE;
}

public _dl_sayhandler(player_id) {
	if(is_user_bot(player_id))
		return PLUGIN_CONTINUE;
		
	new saytext[256];
	read_args(saytext, 255);
	if(strlen(saytext) == 0 || (strlen(saytext) == 2 && saytext[0] == '"' && saytext[1] == '"'))
		return PLUGIN_CONTINUE;

		
	new game[64];
	GetClientGame(player_id, game, 63);

	new name[64];
	get_user_name(player_id, name, 63);

	if(saytext[0] == '"' && saytext[strlen(saytext) - 1] == '"') {
		saytext[strlen(saytext) - 1] = 0;
		writeout(game, name, "says", saytext[1]);
	} else {
		writeout(game, name, "says", saytext);
	}

	return PLUGIN_CONTINUE;
}

public writestatus() {
	new f = fopen("status.txt", "wt");
	if(!f)
		return PLUGIN_CONTINUE;

	new game[64];
	GetGameName(GetEntityOwner(0), game, 64);

	new map[64];
	get_mapname(map, 64);

	new Float:gametime = get_gametime();
	new timeleft = get_timeleft();

	fprintf(f, "%s^t%s^t%.0f^t%d^n", game, map, gametime, timeleft);

	for(new player_id = 1; player_id <= get_maxplayers(); player_id++) {
		if(!is_user_connected(player_id))
			continue;

		if(is_user_bot(player_id)) {
            GetGameName(GetEntityOwner(player_id), game, 64);
		} else {
			GetClientGame(player_id, game, 64);
		}

		new ip[24];
		get_user_ip(player_id, ip, 24, 1);

		new id[24];
		get_user_authid(player_id, id, 24);

		new name[64];
		get_user_name(player_id, name, 63);

		fprintf(f, "%s^t%s^t%s^t%s^n", game, ip, id, name);
	}

	fclose(f);
	return PLUGIN_CONTINUE;
}