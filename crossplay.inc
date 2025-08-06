/**
 * Maximum number of loaded game dlls
 */
const MAX_GAMES = 8;

/**
 * Get total number of loaded game dlls
 *
 * @return				Number of loaded game dlls.
 */
native GetNumGames();

/**
 * Get game name (gamedir) by index.
 *
 * @param gameIndex     Number between 0 and GetNumGames() - 1.
 * @param game			Output array.
 * @param gameLen		Output array length.
 * 
 * @return				Cells written.
 */
native GetGameName(gameIndex, game[], gameLen);

/**
 * Get game index by name (gamedir) or -1 if not found.
 * @param game          Game name (gamedir)
 *
 * @return              Number between 0 and GetNumGames() - 1, or -1 if not found.
 */
stock GetGameIndex(const game[]) {
    new numGames = GetNumGames();
    for(new iGame = 0; iGame < numGames; iGame++) {
        new gameName[64];
        GetGameName(iGame, gameName, 64);
        if(equal(game, gameName))
            return iGame;
    }

    if(equal(game, "cstrike")) return GetGameIndex("czero");
    if(equal(game, "czero")) return GetGameIndex("cstrike");
    
    return -1;
}

/**
 * Get index of the game that owns this entity.
 *
 * @param entityIndex   Entity number.
 * 
 * @return				Game index or -1 if invalid.
 */
native GetEntityOwner(entityIndex);

/**
 * Execute the given callback inside the context of given game.
 *
 * @param gameIndex     Number between 0 and GetNumGames() - 1.
 * @param callback      Name of the function that will be executed in the context.
 * 
 * @return				Return value of the callback.
 */
native GameContext(gameIndex, const callback[]);

/**
 * Respawns the player, skipping round-restart check.
 * Must be called from inside a GameContext
 *
 * @param playerIndex	Number between 1 and 32 inclusive.
 *
 * @return				True on success.
 */
native bool:SpawnPlayer(playerIndex);

/**
 * Get the name of the game for given client.
 * This is based on the PORT to which the client connected.
 * Use this only if you care about cstrike/czero distinction.
 *
 * @param clientIndex	Number between 1 and 32 inclusive.
 * @param game			Output array.
 * @param gameLen		Output array length.
 *
 * @return				Cells written.
 */
native GetClientGame(clientIndex, game[], gameLen);

/**
 * Get model index. This is necessary due to the model index mapping.
 * (Each game client receives different model indices to save up on precached models.)
 *
 * @param gameIndex     Number between 0 and GetNumGames() - 1.
 * @param model         Name of the model.
 * 
 * @return				Model index for given name and game.
 */
native GetGameModelIndex(gameIndex, const model[]);

/**
 * Called right before spawning the player.
 *
 * @param playerIndex	Number between 1 and 32 inclusive.
 */
forward PrePlayerSpawn(playerIndex);

/**
 * Called right after spawning the player.
 *
 * @param playerIndex	Number between 1 and 32 inclusive.
 */
forward PostPlayerSpawn(playerIndex);
