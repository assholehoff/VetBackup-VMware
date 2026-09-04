# VetBackup-VMware

Backup solution for the long-since discontinued veterinary management database software `VetVision` running in a Windows 11 VM under macOS running VMware Fusion.

This is the second, (slightly) more performant version, where the shell scripts (Korn and PowerShell) are replaced by compiled native programs (Swift and C#). It also comes with a menu bar widget for easy configuration and info on backups.

## Premise

Because the database in question contains animal medical records and personal information on their owners, it is imperative that backups are performed daily, at least once. Once backed up, the copy must be copied off computer asap. This has been done by utilising iCloud (encrypted storage) and a BSD box (with disk encryption) on LAN. This way, at most a day's entries is lost on catastrophic failure. Such failure most likely being fluid damage into the computer (animal urine) or theft. Neither can be prevented through software (where my responsibilities end), but the impact of such a catastrophe can be significantly reduced.

## Procedure

1. Check if the database is locked
2. Handle any locking program and acquire new lock
3. Copy database and release lock
4. Compress and send outside VM
5. Send copy of zip file outside computer

Like before, scheduling and triggering is handled in macOS. I find `launchd(8)` to be way, _way_ easier and more reliable than the Windows Task Scheduler. 

## TODO

- [x] Discrete, disappearing notification when backup is occurring/done.
- [x] iCloud upload status of old backups
- [ ] LAN file server upload status of old backups
    - [ ] BSD daemon for LAN file server
- [X] Scheduler
- [ ] Cleaner
- [ ] \(LOW) Some kind of check on the copy. I have yet to find a better method than raising an alarm when a copy is (significantly) smaller than previous copies
- [ ] \(LOW) A clever way to figure out when making a backup during the day is least intrusive. Every cycle requires VetVision to be closed for less than a minute

<img width="512" height="500" alt="Skärmavbild 2026-09-04 kl  19 05 51" src="https://github.com/user-attachments/assets/28e89f18-3631-4b78-af5d-444b41d8ea14" />
<img width="512" height="500" alt="Skärmavbild 2026-09-04 kl  19 05 54" src="https://github.com/user-attachments/assets/56640fdd-660d-4efd-a6ae-49018c5825c0" />