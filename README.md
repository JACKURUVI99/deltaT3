# DELTA-T3-> Chat Room 

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

# Delta Task 3 - Phase 3B

## Reverse Engineering

Using Z3 SMT solver to find a 12-character string that satisfies a symbolic expression:

**Key:** `315525` **Solution:** `zp|}un|~~~~W`

```python
from z3 import *
KEY = 315525

for LEN in range(1, 31):
    s = Solver()
    x = [BitVec(f'x{i}', 8) for i in range(LEN)]
    terms = []

    for i in range(LEN):
        s.add(x[i] >= 32, x[i] <= 126)
        xi = ZeroExt(24, x[i])
        term = (
            (xi * xi) +
            (xi * (100 - i)) +
            BitVecVal(i, 32) +
            (xi * 7) +
            ((xi | BitVecVal(i, 32)) & BitVecVal(i + 3, 32))
        ) - ((xi * xi) % BitVecVal(i + 1, 32))
        terms.append(term)

    s.add(Sum(terms) == BitVecVal(KEY, 32))

    if s.check() == sat:
        m = s.model()
        print(''.join(chr(m[v].as_long()) for v in x))
        break
```

---

## JWT Vulnerability

Chatcli server uses weak or hardcoded JWT secret.

### Exploitation:

- Find secret in code.
- Craft token with payload: `{ "user": "admin" }`
- Send:

```
GET /flag
Authorization: Bearer <token>
```

---

## Cryptography - Diffie-Hellman & Attacks

**Prime (p):** 65537\
**Generator (g):** primitive root of `p`

### Process:

- Generate keys for Alice & Bob
- Compute shared secret

### Attacks:

- Brute-force key recovery
- Baby-Step Giant-Step (BSGS)

### Output:

```
Shared secrets match: True
Brute-forced match: True
BSGS match: True
```

---

## Forensics - Steganography

### Steps:

1. Split secret into 3 parts
2. Embed each in BMP using `steghide`
3. Serve via Flask
4. Capture via `tshark`
5. Extract with password

### Embed Script:

```bash
secret="flag{you_got_me}"
part_len=$(( ${#secret} / 3 ))

p1=${secret:0:part_len}
p2=${secret:part_len:part_len}
p3=${secret:$((2*part_len))}

tmp=$(mktemp)
convert sample.png -define bmp:format=bmp3 sample_1.bmp
cp sample_1.bmp sample_2.bmp sample_3.bmp

for i in 1 2 3; do
  echo ${!p$i} > $tmp
  steghide embed -f -cf sample_$i.bmp -ef $tmp -p 123
done
rm $tmp
```

### Flask Server:

```python
from flask import Flask, send_file, abort
app = Flask(__name__)
FILES = {f"/file{i}.bmp": f"sample_{i}.bmp" for i in range(1, 4)}

@app.route("/<filename>")
def serve_file(filename):
    path = FILES.get(f"/{filename}")
    return send_file(path, mimetype="image/bmp") if path else abort(404)

app.run(host="0.0.0.0", port=8080)
```

### Capture:

```bash
sudo tshark -i lo -w f.pcap
```

---

## Binary Exploitation

### Code:

```c
void win() {
    system("cat flag.txt");
}

void vuln() {
    char buf[64], input[128];
    fgets(input, sizeof(input), stdin);
    printf(input); // format string
    strcpy(buf, input); // buffer overflow
}
```

### Issues:

- Format string: `printf(input)`
- Overflow: `strcpy(buf, input)`

### Goal:

Exploit to execute `win()` function.

Tools: GDB, pwndbg, scripting frameworks

