local socket = require("socket")

local client = {socket = nil, authenticated = false, room = nil}

local function connect()
    client.socket = socket.connect("localhost", 8080)
    if not client.socket then
        print("Failed to connect")
        return false
    end
    client.socket:settimeout(0.1)
    print("Connected to chat server at localhost:8080")
    return true
end

local function send(msg)
    if client.socket then client.socket:send(msg .. "\n") end
end

local function receive()
    while true do
        local data, err = client.socket:receive()
        if data then
            if data == "WELCOME" then
                print("[Server] Welcome to the chat server!")
            elseif data == "LOGIN_SUCCESS" then
                client.authenticated = true
                print("Login successful.")
            elseif data == "LOGIN_FAILED" then
                print("Login failed.")
            elseif data == "REGISTER_SUCCESS" then
                print("Registration successful. Please login.")
            elseif data == "REGISTER_FAILED" then
                print("Registration failed. Username might be taken.")
            elseif data:match("^JOINED:") then
                client.room = data:sub(8)
                print("Joined room: " .. client.room)
            elseif data:match("^MSG:") then
                local user, msg = data:match("^MSG:([^:]+):(.+)$")
                if user and msg then
                    print("[" .. user .. "] " .. msg)
                end
            elseif data:match("^ERROR:") then
                print("[Error] " .. data:sub(7))
            else
                print("[Server] " .. data)
            end
        elseif err ~= "timeout" then
            print("Connection closed by server.")
            os.exit()
        else
            break
        end
    end
end

local function input_loop()
    while true do
        io.write("> ")
        local line = io.read()
        if not line then break end
        if line:sub(1,1) == "/" then
            local cmd, arg = line:match("^/(%S+)%s*(.*)")
            if cmd == "login" then
                if client.authenticated then
                    print("Already logged in.")
                else
                    io.write("Username: ")
                    local u = io.read()
                    io.write("Password: ")
                    local p = io.read()
                    send("LOGIN:" .. u .. "|" .. p)
                end
            elseif cmd == "register" then
                io.write("Choose username: ")
                local u = io.read()
                io.write("Choose password: ")
                local p = io.read()
                send("REGISTER:" .. u .. "|" .. p)
            elseif cmd == "join" then
                if not client.authenticated then
                    print("Please login first.")
                elseif arg == "" then
                    print("Usage: /join <room>")
                else
                    send("JOIN:" .. arg)
                end
            elseif cmd == "quit" then
                print("Goodbye!")
                client.socket:close()
                os.exit()
            elseif cmd == "help" then
                print([[
Available commands:
/login                - Login to your account
/register             - Register a new account
/join <room>          - Join or create a chat room
/quit                 - Quit the chat client
/help                 - Show this help message
Type messages directly to send to the joined room.
]])
            else
                print("Unknown command. Type /help for commands.")
            end
        else
            if client.authenticated and client.room then
                send("MSG:" .. line)
            else
                print("Please login and join a room first.")
            end
        end
        receive()
    end
end

print("Lua Chat Client")
if connect() then
    print("Type /help for commands.")
    input_loop()
end
