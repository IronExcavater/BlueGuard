namespace BlueShield.Core.Bluetooth;

public sealed class BluetoothRestoredEventArgs(bool success, DateTimeOffset timestamp) : EventArgs
{
    public bool Success { get; init; } = success;
    public DateTimeOffset Timestamp { get; init; } = timestamp;
}
