# Marvel Comics Roku App - Application Flow

This document provides a detailed explanation of how the Marvel Comics Roku app works from startup to video playback, including all components, API calls, navigation, and user interactions.

## Table of Contents
1. [App Startup & Initialization](#app-startup--initialization)
2. [Marvel Comics Scene](#marvel-comics-scene)
3. [Character Details Scene](#character-details-scene)
4. [Video Player Scene](#video-player-scene)
5. [Navigation Flow](#navigation-flow)
6. [API Integration](#api-integration)
7. [Key Handling & Back Navigation](#key-handling--back-navigation)
8. [Component Architecture](#component-architecture)

---

## App Startup & Initialization

### 1. Main Entry Point (`source/Main.brs`)
```
App Launch → Main() function executes
```

**What happens:**
- Creates `roSGScreen` object for SceneGraph rendering
- Sets up message port for event handling
- Creates `MarvelComicsScene` as the root scene
- Shows the screen and enters main event loop
- Listens for screen close events (app exit)

**Key Code:**
```brightscript
screen = CreateObject("roSGScreen")
scene = screen.CreateScene("MarvelComicsScene")
screen.show()
while(true)
    msg = wait(0, m.port)
    if msg.isScreenClosed() then return
end while
```

### 2. Scene Creation Process
```
Main.brs → MarvelComicsScene.xml → MarvelComicsScene.brs init()
```

---

## Marvel Comics Scene

### 1. Scene Initialization (`MarvelComicsScene.brs`)
```
Scene Created → init() → fetchMarvelComics() → API Call
```

**What happens in `init()`:**
- Gets references to all UI elements (loading label, comics grid, detail elements)
- Sets up Marvel API credentials (public/private keys)
- Configures event listeners for grid selection and focus
- Starts fetching Marvel comics data immediately

### 2. Marvel API Integration
```
fetchMarvelComics() → MarvelApiTask → API Response → parseMarvelData()
```

**API Call Details:**
- **Endpoint**: `https://gateway.marvel.com/v1/public/comics`
- **Authentication**: MD5 hash of (timestamp + private_key + public_key)
- **Parameters**: 
  - `limit=10` (10 comics)
  - `format=comic` 
  - `orderBy=-onsaleDate` (newest first)
  - `dateDescriptor=lastWeek` (recent comics)
  - `hasDigitalIssue=true` (digital availability)

**MarvelApiTask Process:**
1. Creates background task for API call
2. Makes HTTP request with proper headers
3. Handles response/timeout/errors
4. Returns structured response to scene

### 3. Comics Grid Display
```
API Response → parseMarvelData() → createComicsGrid() → showComicsGrid()
```

**Data Processing:**
- Parses JSON response from Marvel API
- Extracts comic data: title, description, thumbnail, full images, ID
- Creates `ContentNode` structure for `RowList` component
- Sets up horizontal scrolling grid with comic posters

**UI Elements Created:**
- **Loading Label**: "Loading Marvel Comics..." (initially visible)
- **Comics Grid**: Horizontal `RowList` with comic posters
- **Detail Panel**: Shows focused comic's title, description, and large image
- **Comic Posters**: Individual `ComicPosterItem` components

### 4. User Interaction - Comic Focus & Selection
```
User Navigation → onComicFocused() → updateFocusedComicDetails()
User Presses OK → onComicSelected() → navigateToCharacterDetails()
```

**Focus Behavior:**
- As user navigates left/right through comics, detail panel updates
- Shows large image, title, and description of currently focused comic

**Selection Behavior:**
- User presses OK/Enter on a comic
- Extracts comic ID and title
- Creates `CharacterDetailsScene` as child scene
- Passes comic data via interface field

---

## Character Details Scene

### 1. Scene Creation & Data Handling
```
navigateToCharacterDetails() → CharacterDetailsScene created → comicData set → onComicDataSet()
```

**Scene Creation Process:**
- `CharacterDetailsScene` created as child of `MarvelComicsScene`
- Comic data passed: `{comicId: "12345", comicTitle: "Comic Name"}`
- Main comics UI hidden, character scene gets focus
- Header updated with comic title

### 2. Character API Call
```
onComicDataSet() → fetchCharactersForComic() → MarvelApiTask → Character API
```

**Characters API Details:**
- **Endpoint**: `https://gateway.marvel.com/v1/public/comics/{comicId}/characters`
- **Authentication**: Same MD5 hash method as comics API
- **Purpose**: Get all characters associated with specific comic

**Example URL:**
```
https://gateway.marvel.com/v1/public/comics/70685/characters?ts=123456&apikey=public_key&hash=md5_hash
```

### 3. Characters List Display
```
API Response → parseCharactersData() → createCharactersList() → showCharactersList()
```

**Character List Structure:**
- Vertical `RowList` with multiple rows (one character per row)
- Each row contains one `CharacterListItem` component
- Shows character thumbnail, name, and description

**Character Item Components:**
- **Character Image**: 100x100px thumbnail from Marvel API
- **Character Name**: Large bold font
- **Character Description**: Smaller text, wrapped
- **Selection Rectangle**: Highlights focused character

### 4. Character Selection
```
User Presses OK → onCharacterSelected() → navigateToVideoPlayer()
```

**Selection Process:**
- Extracts selected character data (name, description, ID)
- Creates `VideoPlayerScene` as child
- Hides character details UI
- Passes character data to video player

---

## Video Player Scene

### 1. Video Player Creation & Setup
```
navigateToVideoPlayer() → VideoPlayerScene created → characterData set → setupVideoPlayer()
```

**Video Player Initialization:**
- Creates native Roku `Video` component (full screen 1920x1080)
- Sets up video content with sample Big Buck Bunny video
- Configures info overlay with character name and instructions
- Sets up timer to auto-hide overlay after 5 seconds

### 2. Video Content Configuration
```
setupVideoPlayer() → Video Content Creation → Auto-play
```

**Video Setup:**
- **URL**: `"http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"`
- **Format**: MP4 streaming
- **Title**: "Big Buck Bunny"
- **Auto-play**: Starts immediately when character data is set

### 3. Video Player UI Elements
- **Full-Screen Video**: Native Roku video player
- **Info Overlay**: Semi-transparent overlay at top
- **Character Name Label**: Shows selected character name
- **Instruction Label**: "Press BACK to return to characters"
- **Auto-Hide Timer**: Overlay disappears after 5 seconds

### 4. Video Player Controls
```
User Input → onKey() → Video Controls / Navigation
```

**Key Handling:**
- **OK/Play/Pause**: Toggle play/pause, show overlay
- **Directional Keys**: Show overlay (for info visibility)
- **BACK**: Stop video, return to character details

---

## Navigation Flow

### Complete User Journey
```
App Start → Comics Grid → Character Details → Video Player
     ↓           ↓              ↓              ↓
  Main.brs → MarvelComics → CharacterDetails → VideoPlayer
                ↑              ↑              ↑
            BACK (stay)    BACK (comics)   BACK (chars)
```

### Scene Hierarchy
```
MarvelComicsScene (root)
├── ComicsGrid (RowList)
│   └── ComicPosterItem (components)
├── ComicDetailsGroup (info panel)
└── CharacterDetailsScene (child)
    ├── CharactersList (RowList)
    │   └── CharacterListItem (components)
    └── VideoPlayerScene (child)
        └── Video (native component)
```

### Navigation State Management
- **Forward Navigation**: Creates child scenes, hides parent UI
- **Back Navigation**: Removes child scenes, restores parent UI, sets focus
- **Scene References**: Parent stores reference to child for cleanup

---

## API Integration

### Authentication Process
```
timestamp → MD5(timestamp + private_key + public_key) → API URL
```

**Marvel API Requirements:**
1. **Public Key**: ``
2. **Private Key**: ``
3. **Timestamp**: Current Unix timestamp
4. **Hash**: MD5 of concatenated string

### API Endpoints Used

#### 1. Comics API
```
GET https://gateway.marvel.com/v1/public/comics
Parameters:
- ts: timestamp
- apikey: public_key
- hash: md5_hash
- limit: 10
- format: comic
- formatType: comic
- orderBy: -onsaleDate
- dateDescriptor: lastWeek
- hasDigitalIssue: true
```

#### 2. Characters API  
```
GET https://gateway.marvel.com/v1/public/comics/{comicId}/characters
Parameters:
- ts: timestamp
- apikey: public_key
- hash: md5_hash
```

### MarvelApiTask Component
- **Purpose**: Background HTTP requests (non-blocking)
- **Extends**: `Task` (runs on separate thread)
- **Features**: Timeout handling, error reporting, SSL certificates
- **Response Format**: `{code: 200, body: "json_string"}`

---

## Key Handling & Back Navigation

### Key Event Flow
```
Hardware Button → Scene onKey() → Action / Navigation
```

### Back Button Behavior by Scene

#### 1. VideoPlayerScene
```brightscript
BACK pressed → Stop video → Set navigateToCharacters = true → Parent handles
```

#### 2. CharacterDetailsScene  
```brightscript
BACK pressed → Set navigateToComics = true → Parent handles
```

#### 3. MarvelComicsScene (Root)
```brightscript
BACK pressed → Check for child scenes → Consume event (prevent app exit)
```

### Navigation Event Handling
- **Child to Parent Communication**: Uses interface fields as flags
- **Observer Pattern**: Parent observes child's navigation fields
- **Scene Cleanup**: Remove child, restore parent UI, set focus
- **App Exit Prevention**: Root scene consumes BACK to prevent exit

---

## Component Architecture

### Component Files Structure
```
components/
├── MarvelComicsScene.xml/.brs        # Main scene
├── CharacterDetailsScene.xml/.brs    # Character listing
├── VideoPlayerScene.xml/.brs         # Video playback
├── ComicPosterItem.xml/.brs         # Individual comic display
├── CharacterListItem.xml/.brs       # Individual character display
└── MarvelApiTask.xml/.brs           # API networking
```

### Component Responsibilities

#### MarvelComicsScene
- **UI**: Comics grid, detail panel, loading states
- **Logic**: API calls, navigation management, focus handling
- **Children**: Can create CharacterDetailsScene

#### CharacterDetailsScene  
- **UI**: Character list, loading states, comic header
- **Logic**: Character API calls, selection handling
- **Children**: Can create VideoPlayerScene

#### VideoPlayerScene
- **UI**: Full-screen video, info overlay, controls
- **Logic**: Video playback, key handling, back navigation
- **Children**: None (leaf component)

#### Item Components
- **ComicPosterItem**: Displays comic poster + title
- **CharacterListItem**: Displays character image + name + description

#### MarvelApiTask
- **Purpose**: Background HTTP requests
- **Threading**: Runs API calls on separate thread
- **Features**: Error handling, timeout, SSL support

### Data Flow Pattern
```
User Input → Scene Logic → API Call → Data Processing → UI Update
     ↓           ↓           ↓           ↓              ↓
Navigation → Child Scene → New API → Parse Response → New UI
```

---

## Error Handling

### API Error Scenarios
1. **Network Timeout**: 15-second timeout, shows error message
2. **Invalid Response**: JSON parsing fails, shows error
3. **HTTP Errors**: Non-200 status codes, displays error code
4. **No Data**: Empty results, shows "No characters/comics found"

### UI Error States
- **Loading States**: Shows loading messages during API calls
- **Error Messages**: User-friendly error descriptions
- **Fallback Content**: Graceful degradation when data unavailable
- **Debug Logging**: Detailed console output for development

---

## Performance Considerations

### Background Processing
- **API Calls**: Run on separate threads via Task components
- **UI Responsiveness**: Main thread never blocked by network requests
- **Image Loading**: Posters load asynchronously

### Memory Management
- **Scene Cleanup**: Child scenes removed when navigating back
- **Component Reuse**: RowList efficiently manages item components
- **Content Nodes**: Proper cleanup of data structures

### Network Optimization
- **Reasonable Limits**: Only fetch 10 comics to avoid large responses
- **Efficient Queries**: Use Marvel API filters for relevant data
- **Error Recovery**: Graceful handling of network failures

---

This flow documentation covers the complete journey through the Marvel Comics Roku app, from startup initialization through video playback, including all the technical details of how components interact, data flows, and user navigation works.