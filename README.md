# Marvel Comics Roku App

A Roku application that fetches and displays Marvel Comics data using the Marvel API, built with BrightScript and SceneGraph.

## Features
- Connects to Marvel Comics API to fetch recent comics
- Displays comic titles, page counts, release dates, and prices
- Comprehensive logging and error handling
- Detailed debug output to console
- Responsive text display with proper component organization

## Project Structure
```
RokuAmdocs/
├── .vscode/
│   └── launch.json              # VS Code debug configuration
├── components/
│   ├── MarvelApiTask.xml        # Marvel API Task component definition
│   ├── MarvelApiTask.brs        # Marvel API network request logic
│   ├── MarvelComicsScene.xml    # Main scene component UI
│   └── MarvelComicsScene.brs    # Main scene logic and data handling
├── source/
│   └── main.brs                 # App entry point
├── images/                      # App icons and splash screens
├── manifest                     # App configuration
└── README.md                    # This file
```

## Marvel API Integration
This app uses the Marvel Comics API to fetch and display recent comic book data:
- **Public Key**: b63e4263edd3da6685fa48d540bee87a
- **API Endpoint**: https://gateway.marvel.com/v1/public/comics
- **Authentication**: MD5 hash authentication as required by Marvel API
- **Data Retrieved**: Comic titles, descriptions, page counts, release dates, prices, and creator information

## Setup Instructions

### Prerequisites
1. Install the BrightScript Language extension in VS Code
2. Have a Roku device on the same network
3. Enable Developer Mode on your Roku device

### Configuration
1. Update the IP address in `.vscode/launch.json` to match your Roku device's IP
2. Set the correct password for your Roku device in the launch configuration
3. Add your own app icons and splash screen images to the `images/` folder:
   - `icon_focus_hd.png` (336x210px)
   - `icon_focus_sd.png` (248x140px) 
   - `splash_hd.jpg` (1280x720px)
   - `splash_sd.jpg` (720x480px)

### Running the App
1. Open this project in VS Code
2. Press F5 or go to Run > Start Debugging
3. The app will be packaged and deployed to your Roku device
4. The app will automatically fetch Marvel Comics data and display it on screen
5. Check the debug console in VS Code for detailed API response information

### What You'll See
- **On Screen**: List of recent Marvel comics with titles, page counts, and release dates
- **In Debug Console**: Detailed information including comic descriptions, creators, prices, and full API responses


## api call: https://gateway.marvel.com/v1/public/comics?ts=1760645413&apikey=b63e4263edd3da6685fa48d540bee87a&hash=759cab1787e2901d76ee91825e6d5a92&limit=10&format=comic&formatType=comic&orderBy=-onsaleDate&dateDescriptor=lastWeek&hasDigitalIssue=true

### Development Notes
- The main entry point is `source/main.brs`
- The main scene UI is defined in `components/MarvelComicsScene.xml`
- Main scene logic is in `components/MarvelComicsScene.brs`
- API networking is handled by `components/MarvelApiTask.xml` and `components/MarvelApiTask.brs`
- The `manifest` file contains app metadata and configuration

## Troubleshooting
- Ensure your Roku device and computer are on the same network
- Check that Developer Mode is enabled on your Roku device
- Verify the IP address and password in the launch configuration
- Make sure the BrightScript Language extension is installed and active

## Architecture Overview
- **MarvelComicsScene**: Main scene component that handles UI and orchestrates data flow
- **MarvelApiTask**: Dedicated Task component for Marvel API network requests (runs on background thread)
- **Clean separation**: UI logic separated from API/networking logic for better maintainability
- **Proper threading**: Network requests run in background Task to avoid blocking the UI thread

## Next Steps
- Add pagination for browsing more comics
- Implement character and series endpoints
- Add comic cover image display
- Create navigation between different Marvel API endpoints
- Add filtering and search capabilities
- Implement local caching of API responses