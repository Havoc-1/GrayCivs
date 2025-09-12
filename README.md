# Gray Civilians (GrayCivs)

An Arma 3 script system that creates intelligent civilian NPCs who can act as undercover enemies, providing dynamic threat assessment and enhanced gameplay immersion.

## Overview

Gray Civilians transforms ordinary civilian units into potential threats that can either spot and report enemy positions or draw concealed weapons when detected. The system creates tension and unpredictability by making players question the intentions of every civilian they encounter.

## Features

### Shooter System
- Civilians can draw concealed weapons when enemy players get too close
- Choice between drawing pre-configured concealed weapons or searching for nearby dropped weapons
- Configurable activation range, visibility checks, and weapon draw timers
- Realistic line-of-sight mechanics before becoming hostile
- Support for ACE handcuff integration

### Spotter System  
- Civilians equipped with binoculars can spot and report enemy positions
- Radio communication with visual props and realistic timing
- Intelligent positioning system to find optimal spotting locations
- Alert nearby friendly forces when high-value targets are spotted
- Configurable spotting ranges, cooldowns, and detection parameters

### Intelligent Behavior
- Units remain passive until specific conditions are met
- Line-of-sight and distance-based activation
- Realistic weapon handling and inventory management
- Comprehensive logging system for debugging and monitoring
- Failsafe systems to prevent conflicts and ensure stability

## Installation

1. Copy the `scripts` folder to your mission directory
2. Add the following to your `description.ext`:
   ```cpp
   //CFG FUNCTIONS
   class CfgFunctions
   {
       #include "scripts\XK_fnc.hpp"
   };
   ```
3. Add this line to your `init.sqf`:
   ```sqf
   [] call XK_GC_fnc_init;
   ```

## Configuration

All configuration is handled in `scripts/GrayCivs/fn_init.sqf`. Key parameters include:

### General Settings
- `GC_Fac`: Faction that gray civilians work for (default: east)
- `GC_Tick`: Update frequency in seconds (default: 3)

### Shooter Parameters
- `GC_drawTime`: Time range for weapon drawing [min, max] seconds
- `GC_Act`: Activation range in meters (default: 100)
- `GC_Range`: Visibility check range in meters (default: 20)
- `GC_grabChance`: Probability of grabbing nearby weapons vs. drawing concealed (0.7)
- `GC_Weapons`: Array of concealed weapons and magazine counts

### Spotter Parameters
- `GC_SpotRange`: Spotting distance range [min, max] meters
- `GC_SpotTime`: Duration of spotting sessions [min, max] seconds
- `GC_RadioChance`: Probability of using radio communication (0.7)
- `GC_AlertRange`: Range to alert nearby friendly units (200m)

## Usage Examples

### Initialize a Shooter
```sqf
// Basic shooter initialization
[this] call XK_GC_fnc_shooter;

// Advanced shooter with custom parameters
[this, east, 75, 2] call XK_GC_fnc_shooter;
```

### Initialize a Spotter
```sqf
// Enemy spotter with normal AI movement
[this] call XK_GC_fnc_spotter;

// Civilian observer with disabled movement
[this, false, true] call XK_GC_fnc_spotter;
```

### Manual Weapon Operations
```sqf
// Force immediate weapon draw
[unit1] call XK_GC_fnc_drawWeap;

// Draw weapon after 10 seconds with custom weapon list
[unit1, 10, [["hgun_Rook40_F", 2]]] call XK_GC_fnc_drawWeap;

// Search for nearby dropped weapons
[unit1] call XK_GC_fnc_searchWeap;
```

## System Requirements

- **CBA_A3**: Required for timing functions and event handling
- **ACE3**: Optional, provides handcuff integration
- **Arma 3**: Compatible with all versions

## How It Works

### Shooter Mechanics
1. Civilian units start as passive observers
2. When enemy players enter activation range, the system begins monitoring
3. Line-of-sight checks determine when the civilian should become hostile
4. Based on configuration, the unit either draws a concealed weapon or searches for nearby firearms
5. Once armed, the unit switches to combat behavior and engages targets

### Spotter Mechanics
1. Units periodically scan for enemies within detection range
2. When conditions are suitable, they equip binoculars and assume spotting positions
3. Multiple scanning positions are calculated to provide realistic observation behavior
4. Radio communication may occur with visual props and realistic timing
5. Spotted information is relayed to nearby friendly forces

### Safety Features
- Automatic cleanup of dead or incapacitated units
- Faction verification to prevent misuse
- Timeout systems to prevent infinite loops
- Comprehensive error checking and logging
- Performance optimization through efficient PFH usage

## Advanced Configuration

### Custom Weapon Lists
```sqf
GC_Weapons = [
    ["hgun_Rook40_F", 3],        // Zubr .45 with 3 magazines
    ["hgun_Pistol_heavy_02_F", 2], // ACPC2 with 2 magazines
    ["hgun_P07_F", 4]            // P07 with 4 magazines
];
```

### Radio Equipment
```sqf
GC_RadioItem = "Item_ItemRadio";     // Required radio item
GC_RadioModel = [                    // Visual radio model
    "Land_PortableLongRangeRadio_F", 
    [[0,-0.4,1],[0,1,0.4]]
];
```

## Troubleshooting

### Common Issues
- **Units not activating**: Check faction settings and activation ranges
- **No weapons spawning**: Verify weapon class names in GC_Weapons array  
- **Performance issues**: Adjust tick rates and reduce active unit counts

### Debug Features
Enable detailed logging by checking RPT files for `[GrayCivs]` entries. 

## Authors
- **[SGC] Xephros** - Development and ideation
- **[DMCL] _keystone** - Additional development and testing

## Contributing
This system is designed to be modular and extensible. Additional features and improvements are welcome through PRs

## License
This project is licensed under the Arma Public License Share Alike (APL-SA) - see the [Bohemia Interactive Community License page](https://www.bohemia.net/community/licenses/arma-public-license-share-alike) for details.
