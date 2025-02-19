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
