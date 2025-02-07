#if defined _gimme_included
  #endinput
#endif
#define _gimme_included

/**
 * Gives a client an item by item index.
 *
 * @param client			Client Index. Does an alive/in-game/valid check.
 * @param itemIndex			Item Definition Index of weapon being given. Also works with custom weapons.
 * @param warpaint			Blank, 0, 1 or Warpaint ID number. valid warpaint ids: 200-297, 300-310, 390, 391. 1 = australium 
 * @param effect			Blank, 0 or Unusual Effect ID number. valid numbers 0-220.
 * @param paint				Blank, 0 or Paint ID number. valid numbers 0-29.
 * @return					true if weapon is given, else false.
 * @error					Invalid/dead client, or item index not found.
 */
native bool giveitem(int client, int itemIndex, int warpaint = 0, int effect = 0, int paint = 0);

/**
 * Gives a client a warpainted weapon by item index.
 *
 * @param client			Client Index. Does an alive/in-game/valid check.
 * @param itemIndex			Item Definition Index of weapon being given. Must be warpaintable.
 * @param warpaint			Warpaint ID. Valid numbers are: 200-297, 300-310, 390, 391.
 * @return					true if weapon is given, else false.
 * @error					Invalid/dead client, or item index not found.
 */
native bool givewp(int client, int itemIndex, int warpaint);

public SharedPlugin:__pl_gimme = 
{
	name = "gimme",
	file = "gimme.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_gimme_SetNTVOptional()
{
	MarkNativeAsOptional("giveitem");
}
#endif