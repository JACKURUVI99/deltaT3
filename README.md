# DELTA-T3-> Chat Room System

A command-line multiplayer chat room system built with Lua featuring real-time messaging, user authentication, room management, and leaderboards.

## Features

- Real-time multiplayer chat
- User authentication and registration
- Public and private chat rooms
- Message leaderboards
- Persistent chat history
- Docker containerization
- CI/CD pipeline with GitHub Actions

## Quick Start

### Using Docker
1. Clone the repository
2. Run with Docker Compose:
```bash
docker-compose up -d
```

3. Connect with the client:
```bash
lua client.lua
```

### Manual Setup

1. Install dependencies:
```bash
# On Arch Linux
sudo pacman -S lua luarocks mysql

# Install Lua rocks
luarocks install luasocket
luarocks install luasql-mysql
luarocks install md5
```

2. Setup MySQL database:
```bash
mysql -u root -p < init.sql
```

3. Run the server:
```bash
lua server.lua
```

4. Run the client:
```bash
lua client.lua
```

## Usage

### Client Commands

- `/join <room_name>` - Join a chat room
- `/create <room_name> [private]` - Create a new room
- `/rooms` - List available rooms
- `/leaderboard` - Show message leaderboard
- `/help` - Show commands
- `/quit` - Exit

### Authentication

- Register new account or login with existing credentials
- All passwords are securely hashed using MD5

## Database Schema

- `users` - User accounts and authentication
- `rooms` - Chat room information
- `messages` - Chat message history
- `user_stats` - User activity statistics

## Deployment

The system includes automated CI/CD with GitHub Actions:

1. Push to main branch triggers build
2. Docker images are built and pushed to Docker Hub
3. Use `deploy.sh` for production deployment

## Configuration

- Server runs on port 8080
- MySQL on port 3306
- Database: `chatdb`
- MySQL user: `root`, password: `0804`
