using System;
using System.Collections.Generic;
using System.DirectoryServices;
using System.DirectoryServices.AccountManagement;
using System.DirectoryServices.ActiveDirectory;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;

class Program
{
    static void Main(string[] args)
    {
        if (args.Length == 0)
        {
            Console.WriteLine("Please provide at least one keyword as a command-line argument.");
            return;
        }

        string domain = Environment.GetEnvironmentVariable("USERDNSDOMAIN");
        DomainController domainController = Domain.GetCurrentDomain().DomainControllers.Cast<DomainController>().FirstOrDefault();
        string domainControllerName = domainController?.Name;
        string sysvolPath = $"\\\\{domainControllerName}\\SYSVOL\\{domain}";
        string policiesPath = Path.Combine(sysvolPath, "Policies");
        string scriptsPath = Path.Combine(sysvolPath, "Scripts");
        string[] dynamicKeywords = args;
        string[] additionalKeywords = { "user", "username", "name", "User", "Username", "Name", "Username:", "username:", "Username=", "username=", "user ", "username ", "name ", "User ", "Username ", "Name ", "Username: ", "username: ", "Username= ", "username= ", "Username : ", "username : ", "Username = ", "username = " };
        bool matchesFound = false;

        using (PrincipalContext domainContext = new PrincipalContext(ContextType.Domain))
        {
            IEnumerable<FileInfo> files = Directory.EnumerateFiles(policiesPath, "*", SearchOption.AllDirectories)
                .Concat(Directory.EnumerateFiles(scriptsPath, "*", SearchOption.AllDirectories))
                .Select(file => new FileInfo(file))
                .Where(file => file.Name != "GptTmpl.inf" && file.Name != "GPT.INI" && file.Name != "Registry.pol");

            foreach (FileInfo file in files)
            {
                string[] content = File.ReadAllLines(file.FullName);

                foreach (string line in content)
                {
                    IEnumerable<string> matches = dynamicKeywords.Where(keyword => Regex.IsMatch(line, keyword, RegexOptions.IgnoreCase));

                    if (matches.Any())
                    {
                        matchesFound = true;
                        Console.WriteLine($"Match found in file {file.FullName}!");

                        int contextStart = Math.Max(0, Array.IndexOf(content, line) - 3);
                        int contextEnd = Math.Min(Array.IndexOf(content, line) + 3, content.Length - 1);
                        string[] context = content.Skip(contextStart).Take(contextEnd - contextStart + 1).ToArray();

                        IEnumerable<string> additionalKeywordsFound = additionalKeywords.Where(keyword => context.Any(lineContext => lineContext.Contains(keyword)));

                        string username = Regex.Match(line, @"(?i)username\s*[:=]\s*(.+)")?.Groups[1].Value;
                        if (string.IsNullOrEmpty(username))
                        {
                            username = string.Join(" ", context);
                        }

                        string password = Regex.Match(line, @"(?i)(?:password|passw|cred)\s*[=:]\s*(\S+)")?.Groups[1].Value;
                        if (string.IsNullOrEmpty(password))
                        {
                            password = content.SelectMany(lineContext => Regex.Matches(lineContext, @"(?i)(?:password|passw|cred)\s*[=:]\s*(\S+)").Cast<Match>()).FirstOrDefault()?.Groups[1].Value;
                        }

                        if (string.IsNullOrEmpty(password))
                        {
                            password = line;
                        }

                        Console.WriteLine("FileName: " + file.Name);
                        Console.WriteLine("FullName: " + file.FullName);
                        Console.WriteLine("PrecedingContext: " + string.Join(Environment.NewLine, context.TakeWhile(lineContext => lineContext != line)));
                        Console.WriteLine("MatchingLine: " + line);
                        Console.WriteLine("TrailingContext: " + string.Join(Environment.NewLine, context.SkipWhile(lineContext => lineContext != line).Skip(1)));
                        Console.WriteLine("AdditionalKeywordsFound: " + string.Join(", ", additionalKeywordsFound));
                        Console.WriteLine("Username: " + username);
                        Console.WriteLine("Password: " + password);

                        Console.WriteLine(); // Add a line gap
                    }
                }
            }

            if (!matchesFound)
            {
                Console.WriteLine("No matches found.");
            }
        }
    }
}
