using H.NotifyIcon;
using Microsoft.UI.Xaml;

namespace BlueShield.Windows;

public sealed partial class HostWindow : Window
{
    public HostWindow()
    {
        InitializeComponent();
        this.HideInTaskbar();
        Activated += OnFirstActivated;
    }

    private void OnFirstActivated(object sender, WindowActivatedEventArgs args)
    {
        Activated -= OnFirstActivated;
        this.Hide();
    }
}
