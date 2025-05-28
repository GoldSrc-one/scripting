using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace JsonToSma
{
    /**
     * Expecting a structure like this:
     *  {
     *      "game1" : {
     *          "weapon1": "ammo1",
     *          "weapon2: "ammo3"
     *      },
     *      "game2" : {
     *          "weapon3: "ammo5"
     *      }
     *  }
     */
    static class Ammo
    {
        public static void PrintAmmo(Dictionary<string, Dictionary<string, string>> jsonDoc)
        {
            var getNumAmmo = new List<string>();
            var getAmmoWeapon = new List<string>();
            var getAmmoClassname = new List<string>();
            int maxAmmo = 0;
            foreach ((var game, var ammoPairs) in jsonDoc)
            {
                Console.WriteLine($"new g_{game}_weapon[][32] = {{{string.Join(", ", ammoPairs.Select(p => $"\"{p.Key}\""))}}};");
                Console.WriteLine($"new g_{game}_ammo[][32] = {{{string.Join(", ", ammoPairs.Select(p => $"\"{p.Value}\""))}}};");
                Console.WriteLine();

                getNumAmmo.Add($"if (game == g_{game}) return {ammoPairs.Count};");
                getAmmoWeapon.Add($"if (game == g_{game}) return g_{game}_weapon[ammo];");
                getAmmoClassname.Add($"if (game == g_{game}) return g_{game}_ammo[ammo];");

                if (ammoPairs.Count > maxAmmo)
                    maxAmmo = ammoPairs.Count;
            }

            getNumAmmo.Add("return 0;");
            Utils.PrintBlock("get_num_ammo(game)", getNumAmmo);

            getAmmoWeapon.Add("new emptyString[32] = \"\";");
            getAmmoWeapon.Add("return emptyString;");
            Utils.PrintBlock("get_ammo_weapon(game, ammo)", getAmmoWeapon);

            getAmmoClassname.Add("new emptyString[32] = \"\";");
            getAmmoClassname.Add("return emptyString;");
            Utils.PrintBlock("get_ammo_classname(game, ammo)", getAmmoClassname);

            Console.WriteLine($"const MAX_AMMO = {maxAmmo};");
        }
    }
}

