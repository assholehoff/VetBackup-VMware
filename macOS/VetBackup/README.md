# VetBackup.app -- the macOS component

## Future version of VetBackup

The next version of VetBackup will be a complete redesign of the suite. The plan is to use a Windows daemon, thereby eliminating the need for the VM to be unlocked. The macOS app and the Windows daemon will communicate over HTTPS. There will also be an admin/monitoring app I can run on my iPad/iPhone.

### v1.1.0 plan

- Migrate all `ObservableObject` classes to use `@Observable` macro
    - 
