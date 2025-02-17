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