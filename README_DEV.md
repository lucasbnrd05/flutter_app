# Developer Setup Guide - GreenWatch

This guide details the steps required to set up the GreenWatch local development environment after cloning the repository. Certain configurations, particularly API keys, are intentionally excluded from version control (via `.gitignore`) for security reasons and must be configured manually.

## Prerequisites

Before you begin, ensure you have installed:

1.  **Flutter SDK:** Follow the official installation instructions at [flutter.dev](https://flutter.dev/docs/get-started/install).
2.  **A New York Times Developer Account:** You will need an API key for the **Article Search API**. Create an account and an application at [https://developer.nytimes.com/](https://developer.nytimes.com/).

## Initial Setup Steps

1.  **Clone the Repository:**
    ```bash
    git clone flutter_app
    cd flutter_app 
    ```

2.  **Install Flutter Dependencies:**
    This command downloads all the necessary packages listed in `pubspec.yaml`.
    ```bash
    flutter pub get
    ```

3.  **Configure the NYT API Key (Crucial Step):**
    The file containing the API key (`lib/config/api_config.dart`) is not included in the Git repository. You must create it manually:

    *   **Create the `config` directory** inside the `lib` directory if it doesn't already exist.
    *   **Create a file named `api_config.dart`** inside `lib/config/`.
    *   **Add the following content** to `lib/config/api_config.dart`, replacing `"YOUR_PERSONAL_NYT_API_KEY_HERE"` with your actual NYT API key obtained in the prerequisites:

        ```dart
        // lib/config/api_config.dart
        // WARNING: This file is in .gitignore and must NOT be committed.
        // It contains sensitive information.

        const String nytApiKey = "YOUR_PERSONAL_NYT_API_KEY_HERE";
        ```

    *   **Never commit this file!** The `.gitignore` file is already configured to ignore it.

## Running the Application

1.  Ensure you have a running device (emulator, simulator, or physical device) connected and recognized by Flutter (`flutter devices`).
2.  Run the application from the project root:
    ```bash
    flutter run
    ```

## Project Structure Overview

*   `lib/config/`: Contains sensitive configuration files (e.g., API keys). Ignored by Git.
*   `lib/models/`: Defines data structures (e.g., `Article`).
*   `lib/services/`: Contains logic for interacting with external APIs (e.g., `NytApiService`).
*   `lib/providers/` or `lib/state/`: (If applicable) Manages application state (e.g., `ThemeProvider`).
*   `lib/ux_unit/` or `lib/widgets/`: Contains reusable UI components (e.g., `CustomDrawer`, `ArticleCard`).
*   `lib/pages/` or `lib/screens/`: Contains the main application screens (e.g., `HomePage`, `SettingsPage`).
*   `lib/themes/`: Defines application themes.
*   `lib/main.dart`: The application's entry point.
*   `assets/`: Contains static resources (images, fonts, etc.).

## Common Troubleshooting

*   **NYT API Errors (e.g., 401 Unauthorized, 403 Forbidden, 429 Too Many Requests):**
    *   Double-check that the API key in `lib/config/api_config.dart` is correct and matches the one from the NYT Developer portal exactly.
    *   Ensure the "Article Search API" is enabled for your application on the NYT portal.
    *   Check if you've hit the NYT API rate limits (free tier).
*   **Network Errors:** Ensure your machine has an active internet connection.
*   **Dependency Issues:** If you encounter errors related to packages, try running:
    ```bash
    flutter clean
    flutter pub get
    ```
*   **App Fails to Launch:** Check the error logs in the console after running `flutter run`. Ensure your Flutter setup is correct (`flutter doctor`).

---
