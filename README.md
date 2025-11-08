# Angler's Spot

A comprehensive Flutter fishing app with marketplace, catch logging, chat, and weather forecasting features.

## Features

### 🎣 Marketplace
- **Buy & Sell Fishing Gear**: List items with multiple photos, pricing, and detailed descriptions
- **Real-time Updates**: Instantly see new listings and sold items
- **Direct Messaging**: Contact sellers directly through integrated chat
- **Categories**: Rods, Reels, Lures, Tackle, Boats, Electronics, Clothing, Accessories, and more
- **Item Management**: Edit listings, mark as sold, or delete items you've posted
- **Condition Ratings**: New, Like New, Good, Fair, Poor

### 💬 Chat System
- **Public Channels**: Join community fishing discussions
- **Direct Messages**: Private conversations between buyers and sellers
- **Real-time Messaging**: Instant message delivery and updates
- **Admin Tools**: Moderators can create and manage channels

### 📊 Catch Log
- **Log Your Catches**: Record species, weight, length, location, and photos
- **Weather Tracking**: Automatic weather conditions at time of catch
- **Statistics**: Track your fishing success over time
- **Photo Gallery**: Showcase your best catches

### ⛅ Weather Forecast
- **Location-based Forecasts**: Get weather for your fishing spots
- **7-day Outlook**: Plan your fishing trips in advance
- **Fishing Conditions**: Wind, temperature, and precipitation data

### 👤 User Profiles
- **Public Profiles**: Share your fishing achievements
- **Avatar & Display Name**: Customize your identity
- **Catch Statistics**: Showcase your best catches
- **Marketplace Listings**: View items you're selling

## Tech Stack

- **Framework**: Flutter 3.9.2+
- **State Management**: Riverpod 3.0.0
- **Backend**: Supabase (PostgreSQL, Auth, Storage, Realtime)
- **Maps**: Google Maps Flutter
- **Image Handling**: Image Picker
- **Icons**: Lucide Icons

## Database Schema

### Core Tables
- `profiles` - User profiles with roles (admin, moderator, user, anonymous)
- `marketplace_items` - Item listings with pricing, images, and sold status
- `chat_channels` - Public channels and direct messages
- `chat_messages` - Real-time chat messages
- `catches` - Catch log entries with location and weather data

### Storage Buckets
- `avatars` - User profile pictures
- `catch-photos` - Catch log images
- `community-media` - Marketplace item photos

## Getting Started

### Prerequisites
- Flutter SDK 3.9.2 or higher
- Dart 3.0.0 or higher
- Supabase account
- Google Maps API key (for maps functionality)

### Installation

1. Clone the repository:
```bash
git clone https://github.com/jemaineosia/anglers_spot.git
cd anglers_spot
```

2. Install dependencies:
```bash
flutter pub get
```

3. Set up Supabase:
   - Create a new Supabase project
   - Run the migrations in `supabase/migrations/` in order
   - Create storage buckets: `avatars`, `catch-photos`, `community-media`
   - Set up Row Level Security policies (included in migrations)

4. Configure environment:
   - Add your Supabase URL and anon key to the app
   - Add Google Maps API key for map features

5. Run the app:
```bash
flutter run
```

## Project Structure

```
lib/
├── core/
│   ├── services/        # Core services (storage, etc.)
│   └── utils/           # Utility functions
├── features/
│   ├── auth/            # Authentication & user profiles
│   ├── marketplace/     # Buy/sell fishing gear
│   ├── chat/            # Messaging system
│   ├── catch_log/       # Catch logging
│   ├── plan/            # Weather forecasting
│   └── main/            # Main navigation
└── shared/
    └── widgets/         # Reusable UI components
```

## Recent Updates (November 2025)

### Marketplace Feature (NEW)
- Completely replaced Community social feed with Marketplace
- Users can buy and sell fishing gear
- Integrated direct messaging between buyers and sellers
- Real-time listing updates with Supabase Realtime
- Multi-image upload support (up to 5 images per item)
- Filter by category, condition, and sold status

### Chat Enhancements
- Added Direct Message support for marketplace transactions
- Automatic DM channel creation when messaging sellers
- Improved real-time message delivery

### Real-time Updates
- All marketplace listings update live across devices
- Chat messages sync instantly
- Optimistic UI updates for better user experience

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is private and proprietary.
