namespace BlueShield.Core.Startup;

public interface IStartupService
{
    Task<bool> IsEnabledAsync();

    // Returns false if the OS denied the request (e.g. user dismissed the consent dialog).
    Task<bool> SetEnabledAsync(bool enabled);
}
