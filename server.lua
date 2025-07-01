local socket = require("socket")
local md5 = require("md5")  -- install md5 via luarocks if kanom na:_]
local luasql = require("luasql.mysql")
local env = luasql.mysql()
local conn = env:connect("chatdb", "root", "0804", "mysql", 3306)
assert(conn, "MySQL connection failed")

local server = assert(socket.bind("*", 8080))
server:settimeout(0)

local clients = {}
local client_data = {}
local rooms = {}

-- Init db tables if tevainall:]
conn:execute([[
CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(32) NOT NULL
)]])
conn:execute([[
CREATE TABLE IF NOT EXISTS messages (
    id INT AUTO_INCREMENT PRIMARY KEY,
    room VARCHAR(50),
    username VARCHAR(50),
    message TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)]])
-- Utils
local function escape(s) return s and s:gsub("'", "''") or "" end
local function hash_password(pw) return md5.sumhexa(pw) end

local function send(sock, msg)
    if sock then
        local ok, err = sock:send(msg .. "\n")
        if not ok then print("Send error: ", err) end
    end
end

-- Command handlers
local function handle_login(sock, username, password)
    local cursor = assert(conn:execute("SELECT password_hash FROM users WHERE username='" .. escape(username) .. "'"))
    local row = cursor:fetch({}, "a")
    cursor:close()
    if row and row.password_hash == hash_password(password) then
        client_data[sock] = client_data[sock] or {}
        client_data[sock].username = username
        client_data[sock].authenticated = true
        send(sock, "LOGIN_SUCCESS")
        print(username .. " logged in")
    else
        send(sock, "LOGIN_FAILED")
    end
end

local function handle_register(sock, username, password)
    local pw_hash = hash_password(password)
    local res, err = conn:execute("INSERT INTO users (username, password_hash) VALUES ('" .. escape(username) .. "','" .. pw_hash .. "')")
    if res then
        send(sock, "REGISTER_SUCCESS")
        print("Registered user: " .. username)
    else
        send(sock, "REGISTER_FAILED")
    end
end

local function handle_join(sock, room)
    local data = client_data[sock]
    if not (data and data.authenticated) then
        send(sock, "ERROR:Login required")
        return
    end
    rooms[room] = rooms[room] or {users = {}}
    -- Remove frm other rooms
    for _, r in pairs(rooms) do
        r.users[data.username] = nil
    end
    rooms[room].users[data.username] = sock
    data.room = room
    send(sock, "JOINED:" .. room)
    print(data.username .. " joined room " .. room)
end

local function handle_message(sock, msg)
    local data = client_data[sock]
    if not (data and data.authenticated and data.room) then
        send(sock, "ERROR:Join a room first")
        return
    end
    local room = data.room
    conn:execute(string.format("INSERT INTO messages (room, username, message) VALUES ('%s','%s','%s')",
        escape(room), escape(data.username), escape(msg)
    ))
    -- Broadcast
    for uname, rsock in pairs(rooms[room].users) do
        send(rsock, "MSG:" .. data.username .. ":" .. msg)
    end
end

print("Server started on port 8080")

while true do
    local recvt = {server}
    for _, c in ipairs(clients) do table.insert(recvt, c) end
    local ready = socket.select(recvt, nil, 0.1)
    for _, sock in ipairs(ready) do
        if sock == server then
            local client = server:accept()
            if client then
                client:settimeout(0)
                table.insert(clients, client)
                send(client, "WELCOME")
            end
        else
            local line, err = sock:receive()
            if not line then
                if err == "closed" then
                    -- Remove client
                    for i, c in ipairs(clients) do if c == sock then table.remove(clients, i) break end end
                    local d = client_data[sock]
                    if d and d.room and rooms[d.room] then
                        rooms[d.room].users[d.username] = nil
                    end
                    client_data[sock] = nil
                    sock:close()
                end
            else
                local cmd, args = line:match("^([^:]+):(.+)$")
                if cmd == "LOGIN" then
                    local u, p = args:match("^([^|]+)|(.+)$")
                    if u and p then handle_login(sock, u, p) else send(sock, "ERROR:Invalid LOGIN") end
                elseif cmd == "REGISTER" then
                    local u, p = args:match("^([^|]+)|(.+)$")
                    if u and p then handle_register(sock, u, p) else send(sock, "ERROR:Invalid REGISTER") end
                elseif cmd == "JOIN" then
                    handle_join(sock, args)
                elseif cmd == "MSG" then
                    handle_message(sock, args)
                else
                    send(sock, "ERROR:Unknown command")
                end
            end
        end
    end
end
