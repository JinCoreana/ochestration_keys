# Toggle the default communications microphone through the Windows Core Audio API.
# No PowerShell module or third-party executable is required.

Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public enum AudioDataFlow { Render = 0, Capture = 1, All = 2 }
public enum AudioRole { Console = 0, Multimedia = 1, Communications = 2 }

[ComImport, Guid("BCDE0395-E52F-467C-8E3D-C4579291692E")]
public class MMDeviceEnumerator { }

[ComImport, Guid("A95664D2-9614-4F35-A746-DE8DB63617E6"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
public interface IMMDeviceEnumerator {
    int EnumAudioEndpoints(AudioDataFlow dataFlow, uint stateMask, out object devices);
    int GetDefaultAudioEndpoint(AudioDataFlow dataFlow, AudioRole role, out IMMDevice device);
}

[ComImport, Guid("D666063F-1587-4E43-81F1-B948E807363F"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
public interface IMMDevice {
    int Activate(ref Guid iid, uint clsContext, IntPtr activationParams, [MarshalAs(UnmanagedType.Interface)] out IAudioEndpointVolume endpoint);
}

[ComImport, Guid("5CDF2C82-841E-4546-9722-0CF74078229A"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
public interface IAudioEndpointVolume {
    int RegisterControlChangeNotify(IntPtr notify);
    int UnregisterControlChangeNotify(IntPtr notify);
    int GetChannelCount(out uint count);
    int SetMasterVolumeLevel(float level, Guid context);
    int SetMasterVolumeLevelScalar(float level, Guid context);
    int GetMasterVolumeLevel(out float level);
    int GetMasterVolumeLevelScalar(out float level);
    int SetChannelVolumeLevel(uint channel, float level, Guid context);
    int SetChannelVolumeLevelScalar(uint channel, float level, Guid context);
    int GetChannelVolumeLevel(uint channel, out float level);
    int GetChannelVolumeLevelScalar(uint channel, out float level);
    int SetMute([MarshalAs(UnmanagedType.Bool)] bool mute, Guid context);
    int GetMute([MarshalAs(UnmanagedType.Bool)] out bool mute);
}

public static class AudioMute {
    public static bool Toggle() {
        var enumerator = (IMMDeviceEnumerator)new MMDeviceEnumerator();
        IMMDevice device;
        int result = enumerator.GetDefaultAudioEndpoint(AudioDataFlow.Capture, AudioRole.Communications, out device);
        if (result != 0) Marshal.ThrowExceptionForHR(result);

        IAudioEndpointVolume endpoint;
        Guid endpointId = typeof(IAudioEndpointVolume).GUID;
        result = device.Activate(ref endpointId, 23, IntPtr.Zero, out endpoint);
        if (result != 0) Marshal.ThrowExceptionForHR(result);

        bool muted;
        result = endpoint.GetMute(out muted);
        if (result != 0) Marshal.ThrowExceptionForHR(result);
        result = endpoint.SetMute(!muted, Guid.Empty);
        if (result != 0) Marshal.ThrowExceptionForHR(result);
        return !muted;
    }
}
"@

$isMuted = [AudioMute]::Toggle()
$indicator = Join-Path $PSScriptRoot "mute_indicator.ps1"
$indicatorMode = if ($isMuted) { "Show" } else { "Hide" }
$indicatorArgs = "-NoProfile -ExecutionPolicy Bypass -File `"$indicator`" -Mode $indicatorMode"
Start-Process powershell.exe -ArgumentList $indicatorArgs -WindowStyle Hidden
if ($isMuted) { Write-Output "Microphone muted" } else { Write-Output "Microphone unmuted" }
