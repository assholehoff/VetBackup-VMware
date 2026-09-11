# VetBackup.app -- the macOS component

### v1.0.0

- Updated **BackupFolder** to
    - identify outdated archives
    - keep an index of said archives
    - track the total size of all archives
    - track the total size of outdated archives
    - tag the **BackupFile** representing an outdated archive
    - delete outdated archives
- Updated **Archive** window with
    - Button to toggle highlight outdated backups in red
    - Button to delete outdated backups
    - Polished the UI in the window
- Setup automatically incrementing build numbers (`version.sh`)

