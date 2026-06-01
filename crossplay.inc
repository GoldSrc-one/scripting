/**
 * Maximum number of loaded game dlls
 */
const MAX_GAMES = 8;

/**
 * Get total number of loaded game dlls
 *
 * @return			  	 Number of loaded game dlls.
 */
native GetNumGames();

/**
 * Get game name (gamedir) by index.
 *
 * @param gameIndex      Number between 0 and GetNumGames() - 1.
 * @param game			 Output array.
 * @param gameLen		 Output array length.
 * 
 * @return				 Cells written.
 */
native GetGameName(gameIndex, game[], gameLen);

/**
 * Get game index by name (gamedir) or -1 if not found.
 * @param game           Game name (gamedir)
 *
 * @return               Number between 0 and GetNumGames() - 1, or -1 if not found.
 */
stock GetGameIndex(const game[]) {
    new alias[64];
    copy(alias, 64, game);
    if(equal(game, "cstrike"))
        alias = "czero";
    if(equal(game, "czero"))
        alias = "cstrike";

    new numGames = GetNumGames();
    for(new iGame = 0; iGame < numGames; iGame++) {
        new gameName[64];
        GetGameName(iGame, gameName, 64);
        if(equal(game, gameName) || equal(alias, gameName))
            return iGame;
    }

    return -1;
}

/**
 * Get game abbreviation by name (gamedir).
 * @param game           Game name (gamedir)
 * @param abbr           Game name abbreviation (out)
 * @param abbrLen        Output array length
 *
 * @return               True if abbreviation has been found.
 */
stock bool:GetGameAbbr(const game[], abbr[], abbrLen) {
    if(equal(game, "cstrike")) { copy(abbr, abbrLen, "CS");  return true; }
    if(equal(game, "czero"))   { copy(abbr, abbrLen, "CZ");  return true; }
    if(equal(game, "dmc"))     { copy(abbr, abbrLen, "DMC"); return true; }
    if(equal(game, "dod"))     { copy(abbr, abbrLen, "DOD"); return true; }
    if(equal(game, "gearbox")) { copy(abbr, abbrLen, "OP4"); return true; }
    if(equal(game, "tfc"))     { copy(abbr, abbrLen, "TFC"); return true; }
    if(equal(game, "valve"))   { copy(abbr, abbrLen, "HL");  return true; }

    copy(abbr, abbrLen, game);
    return false;
}

/**
 * Get index of the game that owns this entity.
 *
 * @param entityIndex    Entity number.
 * 
 * @return				 Game index or -1 if invalid.
 */
native GetEntityOwner(entityIndex);

/**
 * Execute the given callback inside the context of given game.
 *
 * @param gameIndex      Number between 0 and GetNumGames() - 1.
 * @param callback       Name of the function that will be executed in the context.
 * 
 * @return				 Return value of the callback.
 */
native GameContext(gameIndex, const callback[]);

/**
 * Is the current map a deathmatch map?
 * 
 * @return				 "true" for deathmatch maps and "false" for teamplay maps.
 */
native bool:IsMapDeathmatch();

/**
 * Respawn the player as if new CS round just started.
 *
 * @param playerIndex	 Number between 1 and 32 inclusive.
 */
native RoundRespawn(playerIndex);

/**
 * Notify CS and DOD about the entity classname.
 * Use this after changing an entity's classname.
 * Otherwise the entity will be invisible to CS/DOD.
 *
 * @param entityIndex	 Index of the entity that had the classname changed.
 */
native ClassnameChanged(entityIndex);

/**
 * Get the name of the game for given client.
 * This is based on the PORT to which the client connected.
 * Use this only if you care about cstrike/czero distinction.
 *
 * @param clientIndex	 Number between 1 and 32 inclusive.
 * @param game			 Output array.
 * @param gameLen		 Output array length.
 *
 * @return				 Cells written.
 */
native GetClientGame(clientIndex, game[], gameLen);

/**
 * Get model index. This is necessary due to the model index mapping.
 * (Each game client receives different model indices to save up on precached models.)
 *
 * @param gameIndex      Number between 0 and GetNumGames() - 1.
 * @param model          Name of the model.
 * @param bodyOffset     Returns the body offset in the merged model.
 * @param sequenceOffset Reutrns the sequence offset in the merged model.
 * 
 * @return				 Model index for given name and game.
 */
native GetGameModelIndex(gameIndex, const model[], &bodyOffset = 0, &sequenceOffset = 0);

/**
 * Called right before spawning the player.
 *
 * @param playerIndex	 Number between 1 and 32 inclusive.
 */
forward PrePlayerSpawn(playerIndex);

/**
 * Called right after spawning the player.
 *
 * @param playerIndex	 Number between 1 and 32 inclusive.
 */
forward PostPlayerSpawn(playerIndex);

/**
 * Called by Team Fortress Classic before info_tfgoal gets evaluated.
 */
forward PreDoResults(goalIndex, apIndex, bool:addBonuses);

/**
 * Called by Team Fortress Classic after info_tfgoal gets evaluated.
 */
forward PostDoResults(goalIndex, apIndex, bool:addBonuses);

/**
 * Called by Team Fortress Classic when giving out ammo.
 * Triggered by info_tfgoal or building_dispenser.
 * Return PLUGIN_HANDLED to prevent the original function call.
 * Return PLUGIN_CONTINUE to call the original function.
 *
 * @param playerIndex	 Number between 1 and 32 inclusive.
 * @param shells         "buckshot"
 * @param nails          "9mm"
 * @param rockets	     "rockets"
 * @param cells          "uranium"
 */
forward GiveTFAmmo(playerIndex, shells, nails, rockets, cells);
