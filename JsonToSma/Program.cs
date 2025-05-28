using JsonToSma;
using System.Text.Json;

var file = args[0];
var jsonText = File.ReadAllText(file);

Dictionary<string, Dictionary<string, List<string>>>? categoriesDoc = default!;
try
{
    categoriesDoc = JsonSerializer.Deserialize<Dictionary<string, Dictionary<string, List<string>>>>(jsonText);
}
catch { }
if (categoriesDoc != null)
{
    Categories.PrintCategories(categoriesDoc);
    return;
}

Dictionary<string, Dictionary<string, string>>? ammoDoc = default!;
try
{
    ammoDoc = JsonSerializer.Deserialize<Dictionary<string, Dictionary<string, string>>>(jsonText);
}
catch { }
if (ammoDoc != null)
{
    Ammo.PrintAmmo(ammoDoc);
    return;
}

throw new NotImplementedException();
