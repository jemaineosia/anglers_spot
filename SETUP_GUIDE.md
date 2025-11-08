# Anglers Spot - Community Fishing App

A Flutter-based community app for anglers to connect, share catches, chat, and check weather forecasts.

## Features

### ✅ Phase 1 - Completed
- **Authentication System**
  - Email/password registration and login
  - Anonymous guest access (limited features)
  - Role-based access control (Admin, Moderator, User, Anonymous)
  - User profiles with stats and bio

- **Main Navigation**
  - Chat (placeholder - coming soon)
  - Community (placeholder - coming soon)
  - Catch Log
  - Forecast (weather and fishing conditions)

- **Profile Management**
  - View profile with stats (catches, posts, followers, following)
  - Role badges
  - Sign out functionality

### 🚧 Coming Soon
- Community feed with posts, likes, and comments
- Real-time chat with multiple channels
- Public/private catch logs
- Admin moderation tools
- Follow/unfollow users
- Post notifications
- And more!

## Setup Instructions

### Prerequisites
- Flutter SDK (^3.9.2)
- Dart SDK
- Supabase account
- iOS/Android development environment

### 1. Clone the Repository
\`\`\`bash
git clone <repository-url>
cd anglers_spot
\`\`\`

### 2. Install Dependencies
\`\`\`bash
flutter pub get
\`\`\`

### 3. Supabase Setup

#### Create a Supabase Project
1. Go to [supabase.com](https://supabase.com)
2. Create a new project
3. Wait for the project to be ready

#### Run Database Migration
1. Install Supabase CLI: `npm install -g supabase`
2. Link your project: `supabase link --project-ref <your-project-ref>`
3. Run the migration:
\`\`\`bash
supabase db push
\`\`\`

Or manually copy and run the SQL from `supabase/migrations/20251108_create_community_schema.sql` in the Supabase SQL Editor.

#### Configure Storage Buckets
1. Go to Supabase Dashboard → Storage
2. Create these buckets:
   - `catch-photos` (public)
   - `avatars` (public)
   - `chat-media` (public)

3. Set storage policies for each bucket to allow authenticated users to upload.

#### Update Supabase Credentials
Replace the credentials in `lib/main.dart` with your own:
\`\`\`dart
await Supabase.initialize(
  url: 'YOUR_SUPABASE_URL',
  anonKey: 'YOUR_SUPABASE_ANON_KEY',
);
\`\`\`

### 4. Configure API Keys

#### Google Maps API (for map features)
1. Get an API key from [Google Cloud Console](https://console.cloud.google.com)
2. Update in `android/app/src/main/AndroidManifest.xml`:
\`\`\`xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_API_KEY"/>
\`\`\`
3. Update in `ios/Runner/AppDelegate.swift` (if using iOS)

#### OpenCage Geocoding API (optional - already configured)
Used for location name lookups. Current key is demo key with limits.
Get your own from [opencagedata.com](https://opencagedata.com)

Update in `lib/features/plan/services/geocoding_service.dart`:
\`\`\`dart
static const _apiKey = 'YOUR_OPENCAGE_API_KEY';
\`\`\`

### 5. Run the App
\`\`\`bash
flutter run
\`\`\`

## Database Schema

### Tables Created:
- `profiles` - User profiles with stats and settings
- `chat_channels` - Chat channels/threads
- `chat_messages` - Messages in channels
- `channel_subscriptions` - User channel notification preferences
- `user_bans` - Moderation bans (channel-specific or app-wide)
- `community_posts` - Social media style posts
- `post_likes` - Likes on posts
- `post_comments` - Comments on posts
- `follows` - User follow relationships
- `catch_logs` - Fishing catch records (updated with `is_public` field)

### Key Features:
- Row Level Security (RLS) enabled on all tables
- Automatic profile creation on user signup
- Auto-increment counters for likes, comments, followers
- Proper indexes for performance
- Cascade deletes for data integrity

## User Roles

- **Admin**: Full access, can moderate all content
- **Moderator**: Can ban users, delete messages, pin messages
- **User**: Registered user with full feature access
- **Anonymous**: Guest access with limited features

## Architecture

- **State Management**: Riverpod
- **Backend**: Supabase (PostgreSQL + Auth + Storage + Realtime)
- **UI**: Material Design 3
- **Icons**: Lucide Icons

## Development Roadmap

### Phase 1: Foundation ✅
- [x] Authentication system
- [x] User profiles
- [x] Main navigation structure
- [x] Database schema

### Phase 2: Community Features (In Progress)
- [ ] Public/private catch logs
- [ ] Community feed
- [ ] Post creation with media
- [ ] Likes and comments
- [ ] Follow system

### Phase 3: Chat System
- [ ] Chat channels
- [ ] Real-time messaging
- [ ] Media sharing in chat
- [ ] Message replies
- [ ] Pin messages
- [ ] Channel subscriptions

### Phase 4: Moderation Tools
- [ ] Admin dashboard
- [ ] Ban/mute users
- [ ] Delete content
- [ ] User reports
- [ ] Content moderation

### Phase 5: Enhancements
- [ ] Push notifications
- [ ] Search functionality
- [ ] Advanced analytics
- [ ] Fishing challenges
- [ ] Leaderboards
- [ ] Species identification
- [ ] Offline support

## Contributing

This is a private project. Contribution guidelines will be added later.

## License

Proprietary - All rights reserved
