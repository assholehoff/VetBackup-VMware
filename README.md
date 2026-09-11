# VetBackup-VMware

Backup solution for the long-since discontinued veterinary management database software `VetVision` running in a Windows 11 VM under macOS running VMware Fusion.

This is the second, (slightly) more performant version, where the shell scripts (Korn and PowerShell) are replaced by compiled native programs (Swift and C#). It also comes with a menu bar widget for easy configuration and info on backups.

<img width="360" height="300" alt="Skärmavbild 2026-09-11 kl  13 18 11" src="https://github.com/user-attachments/assets/daf02164-ddb9-4992-bfd5-ebae09fd00da" />

## Challenge

Because the database in question contains animal medical records and personal information on their owners, it is imperative that backups are performed daily, at least once. Once backed up, the copy must be copied off computer asap. This has been done by utilising iCloud (encrypted storage) and a BSD box (with disk encryption) on LAN. This way, at most a day's entries is lost on catastrophic failure. Such failure most likely being fluid damage into the computer (animal urine) or theft. Neither can be prevented through software (where my responsibilities end), but the impact of such a catastrophe can be significantly reduced.

## Procedure

1. scheduled time strikes: Mac component checks if VM is running
    1. if not; check VM bundle disk image modified date
    2. if last backup is **from today**; check if VM was used past 20 minutes after last backup time
    3. if last backup is **not** from today; check if VM was used after that day
2. then asks the Windows utility for modified date for `Database.fdb`
3. determine whether to request a new copy
4. log result and scan backup folder, and **if** there are **≥10** archives;
5. flag outdated archives (by setting `BackupFile.isOutdated` to `true`), **keeping**:
    1. all archives made during the last 7 days
    2. the 3 most recent archives older than 7 but no older than 14 days
    3. the 1 most recent archive per month for the preceding 6 months

<img width="256" height="250" alt="Skärmavbild 2026-09-04 kl  19 05 51" src="https://github.com/user-attachments/assets/28e89f18-3631-4b78-af5d-444b41d8ea14" /><img width="256" height="250" alt="Skärmavbild 2026-09-04 kl  19 05 54" src="https://github.com/user-attachments/assets/56640fdd-660d-4efd-a6ae-49018c5825c0" />

<img width="506" height="266" alt="Skärmavbild 2026-09-11 kl  13 40 09" src="https://github.com/user-attachments/assets/74569089-4f65-4012-9189-ce53d230a06c" /><img width="506" height="266" alt="Skärmavbild 2026-09-11 kl  13 40 17" src="https://github.com/user-attachments/assets/ea43253d-a2b5-42be-b62e-94fdf766e52f" /><img width="506" height="266" alt="Skärmavbild 2026-09-11 kl  13 40 22" src="https://github.com/user-attachments/assets/e260c160-da70-4fef-b4be-845dcbdbab34" /><img width="506" height="266" alt="Skärmavbild 2026-09-11 kl  13 50 58" src="https://github.com/user-attachments/assets/f686aa8a-b6cd-4165-997e-57204ee9b98f" />
