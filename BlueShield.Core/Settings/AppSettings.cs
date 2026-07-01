namespace BlueShield.Core.Settings;

public sealed class AppSettings(ISettingsStore store)
{
    public bool ProtectionEnabled
    {
        get => store.Get(nameof(ProtectionEnabled), defaultValue: true);
        set => store.Set(nameof(ProtectionEnabled), value);
    }

    public bool LaunchAtStartup
    {
        get => store.Get(nameof(LaunchAtStartup), defaultValue: false);
        set => store.Set(nameof(LaunchAtStartup), value);
    }
}
