namespace BlueShield.Core.Bluetooth;

public interface IProtectionService
{
    bool IsEnabled { get; }

    event EventHandler<BluetoothRestoredEventArgs>? BluetoothRestored;

    Task StartAsync(CancellationToken cancellationToken = default);
    Task StopAsync();

    // Stops protection and turns the radio off. Used when the user opts out after an auto-restore.
    Task DisableAsync();
}
