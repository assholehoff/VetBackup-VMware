# The Windows component

## BackupDatabase.exe

This utility tries to get a lock on `Database.fdb`, if unable to do so, it tries to close the database client locking the file and tries again until it succeeds. It then copies the database to a temp directory and releases the lock. It compresses the backup to a `zip` and saves it to a folder.

## LastModifiedDate.exe

This utility checks the modified date on `Database.fdb` and writes that date as a string to a file. That file is then parsed by the **macOS** component.

## Recent

### v0.9.5

- Introduced `LastModifiedDate.exe` to extract the exact time `Database.fdb` was modified.
- Added 5 seconds sleep to `catch` to be able to read error messages if the program throws exceptions (both `exe` files)
- Changed default name string (`BackupDatabase.exe`)
- Setup automatically incrementing build numbers

## Planned

### v1.0.0

