using System;
using System.IO;

// VetBackup.LastModifiedDate - A simple utility to export the last modified date of the Vetvision database.
// Anton Dahlén, 2026

try {
    string sourceFile = args.Length > 0 ? args[0] : @"C:\VetVision\VETDB\Database.fdb";
    string outputFile = args.Length > 1 ? args[1] : @"V:\.DatabaseLastModifiedDate";

    if (!File.Exists(sourceFile)) {
        Console.WriteLine($"Error: Source file '{sourceFile}' does not exist.");
        return 1;
    }

    DateTime modifiedDate = File.GetLastWriteTime(sourceFile);
    string dateString = modifiedDate.ToString("yyyyMMdd-HHmmss");

    File.WriteAllText(outputFile, dateString);
    Console.WriteLine($"{sourceFile} last modified date: {dateString}");
    return 0;
} catch (Exception ex) {
    Console.WriteLine($"Error: {ex.Message}");
    Thread.Sleep(5000); // Wait for 5 seconds before exiting to allow the user to read the error message
    return 1;
}