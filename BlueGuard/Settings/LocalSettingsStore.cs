// Copyright (C) 2026 Niclas Rogulski. All rights reserved.
// SPDX-License-Identifier: MPL-2.0

using BlueGuard.Core.Settings;
using Windows.Storage;

namespace BlueGuard.Settings;

internal sealed class LocalSettingsStore : ISettingsStore
{
    private readonly ApplicationDataContainer _container = ApplicationData.Current.LocalSettings;

    public T Get<T>(string key, T defaultValue) =>
        _container.Values.TryGetValue(key, out var value) ? (T)value! : defaultValue;

    public void Set<T>(string key, T value) =>
        _container.Values[key] = value;
}
