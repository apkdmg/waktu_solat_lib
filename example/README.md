# Waktu Solat Lib Example

A simple Flutter application demonstrating the usage of the `waktu_solat_lib` package.

## Features

This example app shows how to:

*   Instantiate the `WaktuSolatClient`.
*   Fetch the list of Malaysian states and their zones using `getStates()`.
*   Fetch the list of all prayer zone codes using `getZones()`.
*   Fetch prayer times for a specific zone (e.g., "SGR01") using `getPrayerTimesByZone()`.
*   Fetch prayer times using GPS coordinates (using hardcoded coordinates for this example) with `getPrayerTimesByGps()`.
*   Handle potential `WaktuSolatApiException` errors during API calls.
*   Display the fetched data in the UI.

## Getting Started

1.  **Navigate to the example directory:**
    ```bash
    cd example
    ```
2.  **Get Flutter packages:**
    ```bash
    flutter pub get
    ```
3.  **Run the app:**
    ```bash
    flutter run
    ```

This will launch the example application on your connected device or emulator.
