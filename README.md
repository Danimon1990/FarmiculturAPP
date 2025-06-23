# FarmiculturAPP 🌱

A comprehensive farm management iOS application built with SwiftUI for tracking crops, managing greenhouse layouts, and monitoring harvests.

## Features

### 🌿 Crop Management
- **Multiple Crop Types**: Support for greenhouse, seeds, tree crops, outdoor beds, and high tunnels
- **Detailed Crop Information**: Track crop varieties, planting dates, expected harvest dates, and growing conditions
- **Visual Layout**: Interactive greenhouse layout with sections and beds

### 🏡 Greenhouse Layout
- **Section Management**: Organize crops into logical sections
- **Bed Tracking**: Individual bed management with plant counts and varieties
- **Status Monitoring**: Track bed states (dirty, clean, ready, growing, harvesting)

### 🌾 Harvest Management
- **Harvest Tracking**: Monitor when crops are ready for harvest
- **Plant Variety Management**: Track different plant varieties within beds
- **Harvest Summary**: Overview of all harvestable plants

### 📊 Data Management
- **Local Storage**: JSON-based data persistence
- **Real-time Updates**: Live updates as you manage your farm
- **Data Export**: Easy backup and restore functionality

## Screenshots

*Screenshots will be added here*

## Requirements

- iOS 15.0+
- Xcode 13.0+
- Swift 5.5+

## Installation

1. Clone the repository:
```bash
git clone https://github.com/yourusername/FarmiculturAPP.git
```

2. Open the project in Xcode:
```bash
cd FarmiculturAPP
open FarmiculturAPP.xcodeproj
```

3. Build and run the project on your device or simulator.

## Project Structure

```
FarmiculturAPP/
├── FarmiculturAPP/
│   ├── Models/
│   │   └── Crop.swift              # Core data models
│   ├── Views/
│   │   ├── ContentView.swift       # Main tab view
│   │   ├── HomeView.swift          # Home dashboard
│   │   ├── CropsView.swift         # Crop listing
│   │   ├── GreenhouseView.swift    # Greenhouse layout
│   │   ├── BedEditView.swift       # Bed editing
│   │   ├── HarvestView.swift       # Harvest management
│   │   ├── HarvestSummaryView.swift # Harvest overview
│   │   ├── SeedsView.swift         # Seed management
│   │   └── NewCropView.swift       # Add new crops
│   ├── Data/
│   │   ├── CropsDataManager.swift  # Data persistence
│   │   └── crops.json              # Sample data
│   └── Utilities/
│       └── AddUpdateView.swift     # Observation management
```

## Data Models

### Crop
The main data model representing a crop area with:
- Basic information (name, type, status)
- Layout details (sections, beds, dimensions)
- Growing information (varieties, dates, conditions)
- Activities and observations

### Bed
Represents individual growing beds with:
- Plant counts and varieties
- Status tracking (dirty, clean, ready, growing, harvesting)
- Harvest functionality

### PlantVariety
Tracks different plant varieties within beds:
- Variety names and counts
- Harvest management

## Usage

### Adding a New Crop
1. Navigate to the "Crops" tab
2. Tap the "+" button
3. Select crop type and fill in details
4. Configure layout (sections/beds for greenhouse types)
5. Save the crop

### Managing Beds
1. Select a greenhouse crop from the list
2. View the layout with sections and beds
3. Tap on any bed to edit its details
4. Add plant varieties and update status

### Harvesting
1. Go to the "Harvest" tab
2. View summary of harvestable plants
3. Select a plant to harvest
4. Enter harvest amount and confirm

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Built with SwiftUI for modern iOS development
- Designed for small to medium-scale farming operations
- Inspired by the need for better farm management tools

## Contact

Daniel Moreno - [@yourtwitter](https://twitter.com/yourtwitter)

Project Link: [https://github.com/yourusername/FarmiculturAPP](https://github.com/yourusername/FarmiculturAPP) 