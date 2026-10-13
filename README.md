# iCloud Photo Sync Monitor & Accelerator ☁️ ⚡

> **Native iOS diagnostic monitor, system health governor, and overnight keep-awake accelerator for Apple iCloud Photos backup.**  
> Built to inspect pending cloud upload queues, detect background throttling, and maximize sync throughput.

[![Swift 6](https://img.shields.io/badge/Swift-6.0-orange.svg?style=flat-square)](https://swift.org)
[![iOS 16+](https://img.shields.io/badge/iOS-16.0+-blue.svg?style=flat-square)](https://apple.com/ios)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg?style=flat-square)](LICENSE)

---

## 🎯 What It Does

When importing thousands of photos and 4K videos onto an iPhone, Apple delegates cloud uploads to background system daemons (`cloudphotod` and `cloudd`). Apple provides no built-in detailed telemetry or control panel for this process.

**iCloud Photo Sync Monitor** provides:

1. **🔍 CPL Daemon Queue Inspection**:
   - Dynamically inspects Apple's private `CloudPhotoLibrary.framework` (`CPLStatus`).
   - Displays exact counts for items pending upload (photos, videos, other items).
   - Shows live daemon state (`isSyncing`, `hasChangesToProcess`).
   - Includes a **"Nudge Sync"** button that requests an immediate daemon sync evaluation.

2. **🌡️ Thermal & Power Governor**:
   - **Thermal Pressure Meter**: Detects whether iOS is thermal throttling (`Nominal`, `Fair`, `Serious`, `Critical`). When an iPhone gets warm, Apple halts photo uploads to protect the battery.
   - **Battery & Charger Monitor**: Tracks charging state and warns if battery is low.
   - **Low Power Mode Watcher**: Immediately alerts you if Low Power Mode is on (which freezes iCloud Photos).
   - **Actionable Diagnosis**: Plain-English real-time recommendation explaining whether the phone is currently in an optimal or throttled sync state.

3. **🌙 Overnight Turbo Mode (Cold OLED Keep-Awake)**:
   - Disables iOS idle sleep (`UIApplication.isIdleTimerDisabled = true`).
   - Renders a **true 0% power pitch-black OLED screen** with an ultra-dim clock and subtle status indicators.
   - **Why this works**: Keeping the screen awake normally causes the display to heat up the battery, triggering thermal pauses. The Cold OLED screen consumes virtually 0W of display power, keeping the phone completely cool while forcing the CPU and Wi-Fi to stay active 100% of the time.

4. **📸 Local Photo Library Breakdown**:
   - Total photos and videos indexed.
   - Number of items added in the last 24 hours.
   - Sample analysis of recent assets checking whether full-resolution originals are local or cloud-offloaded.

---

## 🛠️ Project Structure

```
iCloudSyncMonitor/
├── iCloudSyncMonitor.xcodeproj # Xcode project for iOS 16+
└── iCloudSyncMonitor/
    ├── iCloudSyncMonitorApp.swift
    ├── ContentView.swift       # Main diagnostic dashboard
    ├── Models/
    │   └── SyncDiagnosticModels.swift
    ├── Services/
    │   ├── CPLRuntimeInspector.swift   # Private CPLStatus runtime loader
    │   ├── SystemHealthGovernor.swift  # Thermals, battery, Low Power Mode
    │   └── PhotoLibraryAnalyzer.swift  # PhotoKit asset analysis
    ├── Views/
    │   ├── ColdOLEDNightView.swift     # 0% OLED keep-awake mode
    │   ├── CPLDiagnosticCard.swift     # Queue counters & nudge trigger
    │   ├── SystemGovernorCard.swift    # Thermal & battery health gauge
    │   └── PhotoLibraryStatsCard.swift # Local library statistics
    └── Info.plist
```

---

## 🚀 How to Run on Your iPhone

1. Open `iCloudSyncMonitor/iCloudSyncMonitor.xcodeproj` in **Xcode**.
2. Select your connected iPhone from the destination device menu.
3. Press **⌘R** (Run) to install and launch.
4. When prompted, grant **Photo Library Access**.
5. View your live upload queue and tap **"Launch Overnight Turbo Mode"** when charging your phone!
