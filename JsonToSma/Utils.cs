using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace JsonToSma
{
    static class Utils
    {
        public static void PrintBlock(string title, List<string> lines)
        {
            Console.WriteLine($"{title} {{");
            lines.ForEach(l => Console.WriteLine($"\t{l}"));
            Console.WriteLine("}");
            Console.WriteLine();
        }
    }
}
