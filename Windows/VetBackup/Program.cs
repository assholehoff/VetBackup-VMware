using System.CommandLine;
using System.Diagnostics;
using VetBackup;

namespace VetBackup {
    public class VetBackup {
        public static async Task<int> Main(string[] args) {
            var targetDirectoryOption = new Option<string>("--target-directory", ["-t"]) { Arity = ArgumentArity.ExactlyOne };
            var targetDateFormat = new Option<string>("--date-format", ["-d"]) { Arity = ArgumentArity.ExactlyOne };
            var targetNamePrefix = new Option<string>("--name-prefix", ["-n"]) { Arity = ArgumentArity.ExactlyOne };
            var sourceFilesArgument = new Argument<string[]>("source") { Arity = ArgumentArity.OneOrMore };

            targetDirectoryOption.Description = "The directory to place the backup zip file into. Defaults to the current working directory.";
            targetDirectoryOption.DefaultValueFactory = def => Directory.GetCurrentDirectory();
            targetDirectoryOption.Validators.Add(result => {
                var value = result.GetValueOrDefault<string>();
                if (value != null && !Directory.Exists(value)) {
                    result.AddError($"The target directory '{value}' does not exist.");
                }
            });

            var rootCommand = new RootCommand {
                targetDirectoryOption,
                targetDateFormat,
                targetNamePrefix,
                sourceFilesArgument
            };

            rootCommand.Description = "VetBackup - A simple backup utility for veterinary practice management software.";

            string temp = Path.GetTempPath();

            var action = new Action<ParseResult>(parseResult => {
                string targetDirectory = parseResult.GetValue(targetDirectoryOption) ?? Directory.GetCurrentDirectory();
                string dateFormat = parseResult.GetValue(targetDateFormat) ?? "yyyyMMdd-HHmmss";
                string namePrefix = parseResult.GetValue(targetNamePrefix) ?? "VetBackup-";
                string[] sourceFiles = parseResult.GetValue(sourceFilesArgument)!;
                string timestamp = DateTime.Now.ToString(dateFormat);
                string workDirectory = Path.Combine(temp, $"{namePrefix}{timestamp}");
                Directory.CreateDirectory(workDirectory);
                foreach (string sourceFile in sourceFiles) {
                    string fileName = Path.GetFileName(sourceFile);
                    string destFile = Path.Combine(workDirectory, fileName);
                    while (VetBackup.FileIsLocked(sourceFile)) {
                        /* Why not iterate through processes?
                         * Because closing one process *may* actually close more than one */
                        List<Process> procs = FileUtil.WhoIsLocking(args[0]);
                        procs[0].CloseMainWindow();
                        procs[0].WaitForExit(1000);
                    }
                    var fi = File.Open(sourceFile, FileMode.Open, FileAccess.Read, FileShare.Read);
                    var fo = File.Create(destFile);
                    fi.CopyTo(fo);
                    fi.Dispose();
                    fo.Dispose();
                    Console.WriteLine($"Copied {sourceFile} to {destFile}");
                }
                string finalZipPath = Path.Combine(targetDirectory, $"{namePrefix}{timestamp}.zip");
                System.IO.Compression.ZipFile.CreateFromDirectory(workDirectory, finalZipPath);
                Directory.Delete(workDirectory, true);
                Console.WriteLine($"Created {finalZipPath}");
            });

            rootCommand.SetAction(action);
            rootCommand.Parse(args).Invoke();

            return 0;
        }
        static bool FileIsLocked(string path) {
            List<Process> procs = FileUtil.WhoIsLocking(path);
            if (procs.Count > 0) {
                //Console.WriteLine($"File {path} is locked by {procs.Count} process(es).");
                return true;
            }
            return false;
        }
    }
}