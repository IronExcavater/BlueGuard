using BlueShield.Core.Startup;
using Windows.ApplicationModel;

namespace BlueShield.Startup;

internal sealed class StartupService : IStartupService
{
    private const string TaskId = "BlueShieldStartup";

    public async Task<bool> IsEnabledAsync()
    {
        try
        {
            var task = await StartupTask.GetAsync(TaskId);
            return task.State is StartupTaskState.Enabled or StartupTaskState.EnabledByPolicy;
        }
        catch
        {
            return false;
        }
    }

    public async Task<bool> SetEnabledAsync(bool enabled)
    {
        try
        {
            var task = await StartupTask.GetAsync(TaskId);

            if (enabled)
            {
                var state = await task.RequestEnableAsync();
                return state is StartupTaskState.Enabled or StartupTaskState.EnabledByPolicy;
            }

            task.Disable();
            return true;
        }
        catch
        {
            return false;
        }
    }
}
