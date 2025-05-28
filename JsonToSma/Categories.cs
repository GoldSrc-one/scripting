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
     *          "category1: ["item1", "item2"],
     *          "category2: ["item3", "item4"]
     *      },
     *      "game2" : {
     *          "category3: ["item5", "item6"],
     *          "category4: ["item7", "item8"]
     *      }
     *  }
     */

    static class Categories
    {
        public static void PrintCategories(Dictionary<string, Dictionary<string, List<string>>> jsonDoc)
        {
            int maxCategories = 0;
            var getGameCategories = new List<string>();
            var getGameCategory = new List<string>();
            var getGameCategoryItems = new List<string>();
            var getGameCategoryItem = new List<string>();

            foreach ((var game, var categories) in jsonDoc)
            {
                getGameCategories.Add($"if (game == g_{game}) return e_{game}_categories;");
                getGameCategory.Add($"if (game == g_{game}) return g_{game}_categories[category];");

                Console.WriteLine($"new g_{game}_categories[][32] = {{{string.Join(", ", categories.Select(kvp => $"\"{kvp.Key}\""))}}}");
                var categoriesEnum = new List<string>();

                foreach ((var category, var items) in categories)
                {
                    categoriesEnum.Add($"e_{game}_{category},");
                    getGameCategoryItems.Add($"if (game == g_{game} && category == e_{game}_{category}) return sizeof g_{game}_{category};");
                    getGameCategoryItem.Add($"if (game == g_{game} && category == e_{game}_{category}) return g_{game}_{category}[item];");

                    Console.WriteLine($"new g_{game}_{category}[][32] = {{{string.Join(", ", items.Select(item => $"\"{item}\""))}}}");
                }

                Utils.PrintBlock($"enum _:e_{game}_categories", categoriesEnum);


                if (categories.Count > maxCategories)
                    maxCategories = categories.Count;
            }

            Console.WriteLine($"const MAX_CATEGORIES = {maxCategories};");
            Console.WriteLine();

            getGameCategories.Add("return 0;");
            Utils.PrintBlock("get_game_categories(game)", getGameCategories);

            getGameCategory.Add("new emptyString[32] = \"\";");
            getGameCategory.Add("return emptyString;");
            Utils.PrintBlock("get_game_category(game, category)", getGameCategory);

            getGameCategoryItems.Add("return 0;");
            Utils.PrintBlock("get_game_category_items(game, category)", getGameCategoryItems);

            getGameCategoryItem.Add("new emptyString[32] = \"\";");
            getGameCategoryItem.Add("return emptyString;");
            Utils.PrintBlock("get_game_category_item(game, category, item)", getGameCategoryItem);
        }
    }
}
