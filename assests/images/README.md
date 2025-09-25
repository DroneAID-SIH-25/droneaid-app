# Assets Folder

This folder contains image assets for the Apka Coolie app.

## Current Structure

```
assets/
└── images/
    └── README.md (this file)
```

## Planned Images

The following images should be added to support the Indian cultural theme:

### Welcome Screen Images
- `namaste_hands.png` - Namaste gesture illustration
- `indian_cultural_collage.png` - Diverse Indian people from different states
- `railway_station_bg.png` - Railway station background pattern
- `indian_patterns.png` - Traditional Indian decorative patterns

### Cultural Elements
- `saffron_flag.png` - Indian flag colors
- `railway_icons/` - Various railway-related icons
  - `train_icon.png`
  - `platform_icon.png` 
  - `luggage_icon.png`
  - `coolie_icon.png`

### User Type Icons
- `passenger_avatar.png` - Passenger/Yatri illustration
- `coolie_avatar.png` - Coolie worker illustration  
- `admin_avatar.png` - Admin/Management illustration

### Backgrounds
- `gradient_backgrounds/` - Various Indian-themed gradient backgrounds
- `texture_patterns/` - Indian textile and cultural patterns

## Usage

Images are referenced in the app using:
```dart
Image.asset('assets/images/image_name.png')
```

## Image Requirements

- Format: PNG with transparency support
- Resolution: Multiple resolutions (1x, 2x, 3x) for different screen densities
- Style: Consistent with Indian cultural theme
- Colors: Following app color scheme (Golden Yellow, Black, White)

## Attribution

All images should be properly licensed for commercial use or created originally for this project.