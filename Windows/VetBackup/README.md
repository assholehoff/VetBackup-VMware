# The Windows component

## BackupDatabase.exe

This utility tries to get a lock on `Database.fdb`, if unable to do so, it tries to close the database client locking the file and tries again until it succeeds. It then copies the database to a temp directory and releases the lock. It compresses the backup to a `zip` and saves it to a folder.

## LastModifiedDate.exe

This utility checks the modified date on `Database.fdb` and writes that date as a string to a file. That file is then parsed by the **macOS** component.
