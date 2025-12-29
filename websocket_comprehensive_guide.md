# Comprehensive WebSocket Guide for Networking

## Table of Contents
1. [Introduction](#introduction)
2. [Protocol Overview](#protocol-overview)
3. [How WebSocket Works](#how-websocket-works)
4. [WebSocket vs HTTP](#websocket-vs-http)
5. [Connection Establishment](#connection-establishment)
6. [Frame Structure](#frame-structure)
7. [Message Types](#message-types)
8. [Testing WebSocket Connections](#testing-websocket-connections)
9. [WebSocket Servers](#websocket-servers)
10. [Client Implementation](#client-implementation)
11. [Proxy Configuration](#proxy-configuration)
12. [Security Considerations](#security-considerations)
13. [Common Use Cases](#common-use-cases)
14. [Troubleshooting](#troubleshooting)
15. [Performance Optimization](#performance-optimization)
16. [Practical Examples](#practical-examples)

---

## Introduction

WebSocket is a **communication protocol** that provides full-duplex (bidirectional) communication channels over a single, long-lived TCP connection. It was standardized by the IETF as RFC 6455 in 2011 and is designed to work alongside HTTP, providing a persistent connection for real-time data exchange.

### Key Features
- **Full-duplex communication**: Data flows in both directions simultaneously
- **Low latency**: Minimal overhead after initial handshake
- **Persistent connection**: No need to re-establish connection for each message
- **Event-driven**: Server can push data to clients without polling
- **HTTP-compatible**: Uses standard HTTP ports (80/443) and starts with HTTP upgrade

### Why WebSocket?
Traditional HTTP follows a request-response model where the client must initiate every interaction. WebSocket enables:
- Real-time bidirectional communication
- Reduced network overhead (no repeated headers)
- Lower latency for message delivery
- Server-initiated communication (push notifications)
- Efficient use of network resources

---

## Protocol Overview

### Protocol Specification
- **Standard**: RFC 6455
- **Protocol Schemes**: 
  - `ws://` - WebSocket over TCP (unencrypted)
  - `wss://` - WebSocket over TLS (encrypted)
- **Default Ports**: 
  - Port 80 for `ws://`
  - Port 443 for `wss://`
- **Protocol Type**: Application layer protocol over TCP
- **Connection**: Persistent, stateful connection

### WebSocket URI Format
```
ws-URI = "ws:" "//" host [ ":" port ] path [ "?" query ]
wss-URI = "wss:" "//" host [ ":" port ] path [ "?" query ]
```

Examples:
```
ws://example.com/chat
wss://secure.example.com:8080/streaming?token=abc123
ws://192.168.1.100:9000/data
```

---

## How WebSocket Works

### Connection Lifecycle

```
Client                                Server
  |                                      |
  |  HTTP GET with Upgrade headers       |
  |------------------------------------->|
  |                                      |
  |  HTTP 101 Switching Protocols        |
  |<-------------------------------------|
  |                                      |
  |  WebSocket frames (bidirectional)    |
  |<------------------------------------>|
  |                                      |
  |  Close handshake                     |
  |<------------------------------------>|
  |                                      |
```

### Step-by-Step Process

1. **Client initiates connection** with HTTP upgrade request
2. **Server responds** with 101 status (Switching Protocols)
3. **Connection established** - TCP connection upgraded to WebSocket
4. **Data exchange** using WebSocket frames
5. **Connection closure** via close handshake (graceful) or TCP termination

---

## WebSocket vs HTTP

### Comparison Table

| Feature | HTTP/1.1 | HTTP/2 | WebSocket |
|---------|----------|--------|-----------|
| **Connection** | Request-response | Multiplexed streams | Persistent bidirectional |
| **Direction** | Half-duplex | Half-duplex | Full-duplex |
| **Overhead** | High (headers per request) | Medium (compressed headers) | Low (minimal frame overhead) |
| **Latency** | Higher (connection setup) | Medium | Very low |
| **Server Push** | No (HTTP/1.1), Limited (HTTP/2) | Yes (limited) | Yes (anytime) |
| **Real-time** | Poor (polling required) | Better | Excellent |
| **Stateful** | No | No | Yes |
| **Best For** | Document retrieval, REST APIs | Web pages, multiplexing | Chat, gaming, live updates |

### When to Use WebSocket

**Use WebSocket When:**
- You need real-time, low-latency communication
- Server needs to push data to clients frequently
- Bidirectional communication is required
- You want to reduce overhead of multiple HTTP requests
- Building chat, gaming, or collaborative applications

**Use HTTP/REST When:**
- Request-response model is sufficient
- Caching is important
- Stateless communication is preferred
- Standard web browsing or API calls
- Not all clients support WebSocket

---

## Connection Establishment

### Opening Handshake

#### Client Request
```http
GET /chat HTTP/1.1
Host: example.com:8080
Upgrade: websocket
Connection: Upgrade
Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==
Sec-WebSocket-Version: 13
Origin: http://example.com
Sec-WebSocket-Protocol: chat, superchat
Sec-WebSocket-Extensions: permessage-deflate
```

#### Header Explanation
- **Upgrade: websocket** - Requests protocol upgrade
- **Connection: Upgrade** - Indicates connection upgrade is desired
- **Sec-WebSocket-Key** - Base64-encoded random value (16 bytes)
- **Sec-WebSocket-Version** - Protocol version (13 is current)
- **Origin** - Origin of the request (for security)
- **Sec-WebSocket-Protocol** - Optional subprotocols
- **Sec-WebSocket-Extensions** - Optional extensions (compression, etc.)

#### Server Response
```http
HTTP/1.1 101 Switching Protocols
Upgrade: websocket
Connection: Upgrade
Sec-WebSocket-Accept: s3pPLMBiTxaQ9kYGzzhZRbK+xOo=
Sec-WebSocket-Protocol: chat
```

#### Response Header Explanation
- **101 Switching Protocols** - Indicates successful upgrade
- **Sec-WebSocket-Accept** - Computed from client's key
  - Computed as: Base64(SHA1(Sec-WebSocket-Key + "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"))
- **Sec-WebSocket-Protocol** - Chosen subprotocol (if any)

### Handshake Validation

The server validates:
1. HTTP method is GET
2. HTTP version is 1.1 or higher
3. Host header is present
4. Upgrade header contains "websocket"
5. Connection header contains "Upgrade"
6. Sec-WebSocket-Key is present and properly formatted
7. Sec-WebSocket-Version is supported
8. Origin header (optional security check)

---

## Frame Structure

### WebSocket Frame Format

```
 0                   1                   2                   3
 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
+-+-+-+-+-------+-+-------------+-------------------------------+
|F|R|R|R| opcode|M| Payload len |    Extended payload length    |
|I|S|S|S|  (4)  |A|     (7)     |             (16/64)           |
|N|V|V|V|       |S|             |   (if payload len==126/127)   |
| |1|2|3|       |K|             |                               |
+-+-+-+-+-------+-+-------------+ - - - - - - - - - - - - - - - +
|     Extended payload length continued, if payload len == 127  |
+ - - - - - - - - - - - - - - - +-------------------------------+
|                               |Masking-key, if MASK set to 1  |
+-------------------------------+-------------------------------+
| Masking-key (continued)       |          Payload Data         |
+-------------------------------- - - - - - - - - - - - - - - - +
:                     Payload Data continued ...                :
+ - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - +
|                     Payload Data continued ...                |
+---------------------------------------------------------------+
```

### Frame Fields

#### FIN (1 bit)
- `1` = Final fragment of message
- `0` = More fragments follow

#### RSV1, RSV2, RSV3 (1 bit each)
- Reserved for extensions
- Must be 0 unless extension negotiated

#### Opcode (4 bits)
- `0x0` - Continuation frame
- `0x1` - Text frame (UTF-8)
- `0x2` - Binary frame
- `0x8` - Connection close
- `0x9` - Ping
- `0xA` - Pong
- `0x3-0x7` - Reserved for future data frames
- `0xB-0xF` - Reserved for future control frames

#### MASK (1 bit)
- `1` = Payload is masked (required for client-to-server)
- `0` = Payload is not masked (server-to-client)

#### Payload Length (7 bits, 7+16 bits, or 7+64 bits)
- `0-125` - Actual length
- `126` - Following 2 bytes contain length (16-bit)
- `127` - Following 8 bytes contain length (64-bit)

#### Masking Key (32 bits)
- Present only if MASK bit is set
- Random 4-byte value used to XOR payload

### Frame Size Limits
- **Minimum**: 2 bytes (empty frame)
- **Maximum**: 2^63 bytes (theoretical, practically limited by implementation)
- **Typical**: Keep messages < 1MB for better performance

---

## Message Types

### Data Frames

#### Text Frame (Opcode 0x1)
```
Contains UTF-8 encoded text data
Example: "Hello, WebSocket!"
```

#### Binary Frame (Opcode 0x2)
```
Contains raw binary data
Example: Image data, protocol buffers, etc.
```

### Control Frames

#### Close Frame (Opcode 0x8)
```
Initiates connection closure
Payload contains:
- Status code (2 bytes) [optional]
- Reason (UTF-8 text) [optional]
```

**Common Close Codes:**
- `1000` - Normal closure
- `1001` - Going away (browser navigating away)
- `1002` - Protocol error
- `1003` - Unsupported data type
- `1006` - Abnormal closure (no close frame received)
- `1007` - Invalid frame payload data
- `1008` - Policy violation
- `1009` - Message too big
- `1010` - Extension negotiation failed
- `1011` - Internal server error

#### Ping Frame (Opcode 0x9)
```
Keepalive check from sender
Recipient must respond with Pong
Can contain application data (< 125 bytes)
```

#### Pong Frame (Opcode 0xA)
```
Response to Ping frame
Must contain same payload as Ping
Can be sent unsolicited as unidirectional heartbeat
```

### Fragmentation

Large messages can be split into multiple frames:

```
Frame 1: FIN=0, Opcode=0x1 (text), Payload="Hello "
Frame 2: FIN=0, Opcode=0x0 (continuation), Payload="Web"
Frame 3: FIN=1, Opcode=0x0 (continuation), Payload="Socket"
Result: "Hello WebSocket"
```

**Rules:**
- First frame has message opcode (text/binary)
- Subsequent frames use continuation opcode (0x0)
- Final frame has FIN=1
- Control frames can be injected between fragments

---

## Testing WebSocket Connections

### Using wscat (Command Line Tool)

#### Installation
```bash
# Install Node.js and npm
sudo apt update
sudo apt install nodejs npm

# Install wscat globally
sudo npm install -g wscat

# Verify installation
wscat --version
```

#### Basic Usage
```bash
# Connect to WebSocket server
wscat -c ws://echo.websocket.org

# Connect with SSL/TLS
wscat -c wss://echo.websocket.org

# Connect with custom headers
wscat -c ws://example.com/chat \
  -H "Authorization: Bearer token123" \
  -H "User-Agent: CustomClient"

# Connect with subprotocol
wscat -c ws://example.com/chat \
  -s chat-protocol

# Connect and send message on connect
wscat -c ws://example.com -x "Hello Server"

# Don't mask client frames (debugging)
wscat -c ws://example.com --no-mask

# Binary mode
wscat -c ws://example.com -b
```

#### Interactive Commands
```bash
# Once connected:
> Hello!              # Send text message
> ^C                  # Disconnect
```

### Using websocat (Advanced Tool)

#### Installation
```bash
# Download binary
wget https://github.com/vi/websocat/releases/download/v1.12.0/websocat.x86_64-unknown-linux-musl
chmod +x websocat.x86_64-unknown-linux-musl
sudo mv websocat.x86_64-unknown-linux-musl /usr/local/bin/websocat

# Or install via cargo (Rust)
cargo install websocat
```

#### Usage Examples
```bash
# Simple connection
websocat ws://echo.websocket.org

# Connect and send data from file
cat data.txt | websocat ws://example.com

# Save received data to file
websocat ws://example.com > output.txt

# Bidirectional relay
websocat -E ws://example.com

# Unix socket to WebSocket bridge
websocat --unlink ws-l:127.0.0.1:8080 unix-l:/tmp/socket

# HTTP to WebSocket proxy
websocat --text ws://example.com tcp-l:127.0.0.1:8081
```

### Using curl (Handshake Testing)

```bash
# Test WebSocket handshake
curl -i -N \
  -H "Connection: Upgrade" \
  -H "Upgrade: websocket" \
  -H "Host: example.com" \
  -H "Origin: http://example.com" \
  -H "Sec-WebSocket-Key: $(openssl rand -base64 16)" \
  -H "Sec-WebSocket-Version: 13" \
  http://example.com/ws

# Expected response: HTTP/1.1 101 Switching Protocols
```

### Using Python for Testing

```python
#!/usr/bin/env python3
import asyncio
import websockets

async def test_websocket():
    uri = "ws://echo.websocket.org"
    async with websockets.connect(uri) as websocket:
        # Send message
        await websocket.send("Hello, WebSocket!")
        print(f"Sent: Hello, WebSocket!")
        
        # Receive response
        response = await websocket.recv()
        print(f"Received: {response}")

# Run test
asyncio.run(test_websocket())
```

### Using Browser Developer Tools

```javascript
// Open browser console (F12) and run:

// Connect to WebSocket
const ws = new WebSocket('ws://echo.websocket.org');

// Event handlers
ws.onopen = () => {
    console.log('Connected');
    ws.send('Hello from browser!');
};

ws.onmessage = (event) => {
    console.log('Received:', event.data);
};

ws.onerror = (error) => {
    console.error('Error:', error);
};

ws.onclose = (event) => {
    console.log('Closed:', event.code, event.reason);
};

// Send message
ws.send('Test message');

// Close connection
ws.close(1000, 'Normal closure');
```

### Using tcpdump/Wireshark

```bash
# Capture WebSocket traffic
sudo tcpdump -i eth0 -w websocket.pcap 'tcp port 80 or tcp port 443'

# View capture in real-time
sudo tcpdump -i eth0 -A 'tcp port 80 or tcp port 443'

# Filter for WebSocket handshake
sudo tcpdump -i eth0 -A 'tcp port 80 and (tcp[((tcp[12:1] & 0xf0) >> 2):4] = 0x47455420)'

# Analyze with Wireshark
wireshark websocket.pcap
# Filter: websocket
```

### Using nmap

```bash
# Scan for WebSocket services
nmap -p 80,443,8080 --script http-websocket-info example.com

# Check if server supports WebSocket upgrade
nmap -p 80 --script http-methods example.com

# Comprehensive scan with version detection
nmap -sV -p 80,443,8080 example.com
```

---

## WebSocket Servers

### Python Server (websockets library)

#### Installation
```bash
pip3 install websockets
```

#### Simple Echo Server
```python
#!/usr/bin/env python3
import asyncio
import websockets
import logging

# Enable logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger('websocket-server')

async def echo_handler(websocket, path):
    """Handle incoming WebSocket connections"""
    client_ip = websocket.remote_address[0]
    logger.info(f"Client connected: {client_ip}")
    
    try:
        async for message in websocket:
            logger.info(f"Received from {client_ip}: {message}")
            response = f"Echo: {message}"
            await websocket.send(response)
            logger.info(f"Sent to {client_ip}: {response}")
    
    except websockets.exceptions.ConnectionClosed as e:
        logger.info(f"Client disconnected: {client_ip} - {e}")
    
    except Exception as e:
        logger.error(f"Error handling client {client_ip}: {e}")

async def main():
    # Start server
    server = await websockets.serve(
        echo_handler,
        "0.0.0.0",  # Listen on all interfaces
        8765,       # Port
        ping_interval=30,  # Send ping every 30 seconds
        ping_timeout=10    # Wait 10 seconds for pong
    )
    
    logger.info("WebSocket server started on ws://0.0.0.0:8765")
    await server.wait_closed()

if __name__ == "__main__":
    asyncio.run(main())
```

#### Advanced Python Server with Authentication
```python
#!/usr/bin/env python3
import asyncio
import websockets
import json
import jwt
from datetime import datetime, timedelta

SECRET_KEY = "your-secret-key"
connected_clients = set()

async def authenticate(websocket):
    """Authenticate client using JWT token"""
    try:
        # Wait for authentication message
        auth_msg = await asyncio.wait_for(websocket.recv(), timeout=5.0)
        data = json.loads(auth_msg)
        
        # Verify JWT token
        token = data.get('token')
        payload = jwt.decode(token, SECRET_KEY, algorithms=['HS256'])
        
        return payload.get('user_id')
    
    except asyncio.TimeoutError:
        await websocket.close(1008, "Authentication timeout")
        return None
    
    except Exception as e:
        await websocket.close(1008, f"Authentication failed: {str(e)}")
        return None

async def broadcast(message, exclude=None):
    """Broadcast message to all connected clients except excluded"""
    tasks = []
    for client in connected_clients:
        if client != exclude:
            tasks.append(client.send(message))
    
    if tasks:
        await asyncio.gather(*tasks, return_exceptions=True)

async def chat_handler(websocket, path):
    """Handle chat room connections"""
    user_id = await authenticate(websocket)
    if not user_id:
        return
    
    # Add to connected clients
    connected_clients.add(websocket)
    print(f"User {user_id} connected. Total clients: {len(connected_clients)}")
    
    # Notify others
    await broadcast(json.dumps({
        'type': 'user_joined',
        'user_id': user_id,
        'timestamp': datetime.utcnow().isoformat()
    }), exclude=websocket)
    
    try:
        async for message in websocket:
            data = json.loads(message)
            
            # Echo to all clients
            await broadcast(json.dumps({
                'type': 'message',
                'user_id': user_id,
                'content': data.get('content'),
                'timestamp': datetime.utcnow().isoformat()
            }))
    
    finally:
        # Remove from connected clients
        connected_clients.remove(websocket)
        print(f"User {user_id} disconnected. Total clients: {len(connected_clients)}")
        
        # Notify others
        await broadcast(json.dumps({
            'type': 'user_left',
            'user_id': user_id,
            'timestamp': datetime.utcnow().isoformat()
        }))

async def main():
    server = await websockets.serve(
        chat_handler,
        "0.0.0.0",
        8765,
        ping_interval=20,
        ping_timeout=10,
        max_size=10**6  # 1MB max message size
    )
    
    print("Chat server started on ws://0.0.0.0:8765")
    await server.wait_closed()

if __name__ == "__main__":
    asyncio.run(main())
```

### Node.js Server (ws library)

#### Installation
```bash
npm install ws
```

#### Simple Echo Server
```javascript
const WebSocket = require('ws');

const wss = new WebSocket.Server({ 
    port: 8765,
    perMessageDeflate: false  // Disable compression
});

wss.on('connection', (ws, req) => {
    const clientIp = req.socket.remoteAddress;
    console.log(`Client connected: ${clientIp}`);
    
    // Send welcome message
    ws.send(JSON.stringify({
        type: 'welcome',
        message: 'Connected to WebSocket server'
    }));
    
    // Handle incoming messages
    ws.on('message', (message) => {
        console.log(`Received: ${message}`);
        
        try {
            const data = JSON.parse(message);
            
            // Echo back
            ws.send(JSON.stringify({
                type: 'echo',
                original: data,
                timestamp: new Date().toISOString()
            }));
        } catch (e) {
            // Send plain text echo
            ws.send(`Echo: ${message}`);
        }
    });
    
    // Handle errors
    ws.on('error', (error) => {
        console.error(`Error from ${clientIp}:`, error);
    });
    
    // Handle close
    ws.on('close', (code, reason) => {
        console.log(`Client disconnected: ${clientIp} - Code: ${code}, Reason: ${reason}`);
    });
    
    // Send periodic ping
    const pingInterval = setInterval(() => {
        if (ws.readyState === WebSocket.OPEN) {
            ws.ping();
        }
    }, 30000);
    
    ws.on('close', () => {
        clearInterval(pingInterval);
    });
});

console.log('WebSocket server started on ws://0.0.0.0:8765');
```

#### Advanced Node.js Server with Room Support
```javascript
const WebSocket = require('ws');
const wss = new WebSocket.Server({ port: 8765 });

// Room management
const rooms = new Map();

function joinRoom(ws, roomId, userId) {
    if (!rooms.has(roomId)) {
        rooms.set(roomId, new Set());
    }
    
    const room = rooms.get(roomId);
    room.add(ws);
    
    ws.roomId = roomId;
    ws.userId = userId;
    
    // Broadcast to room
    broadcastToRoom(roomId, {
        type: 'user_joined',
        userId: userId,
        roomId: roomId,
        members: room.size
    }, ws);
}

function leaveRoom(ws) {
    if (!ws.roomId) return;
    
    const room = rooms.get(ws.roomId);
    if (room) {
        room.delete(ws);
        
        if (room.size === 0) {
            rooms.delete(ws.roomId);
        } else {
            broadcastToRoom(ws.roomId, {
                type: 'user_left',
                userId: ws.userId,
                roomId: ws.roomId,
                members: room.size
            });
        }
    }
}

function broadcastToRoom(roomId, data, exclude = null) {
    const room = rooms.get(roomId);
    if (!room) return;
    
    const message = JSON.stringify(data);
    room.forEach(client => {
        if (client !== exclude && client.readyState === WebSocket.OPEN) {
            client.send(message);
        }
    });
}

wss.on('connection', (ws) => {
    console.log('Client connected');
    
    ws.on('message', (message) => {
        try {
            const data = JSON.parse(message);
            
            switch(data.type) {
                case 'join':
                    joinRoom(ws, data.roomId, data.userId);
                    break;
                
                case 'message':
                    if (ws.roomId) {
                        broadcastToRoom(ws.roomId, {
                            type: 'message',
                            userId: ws.userId,
                            content: data.content,
                            timestamp: new Date().toISOString()
                        });
                    }
                    break;
                
                case 'leave':
                    leaveRoom(ws);
                    break;
                
                default:
                    ws.send(JSON.stringify({
                        type: 'error',
                        message: 'Unknown message type'
                    }));
            }
        } catch (e) {
            console.error('Error processing message:', e);
        }
    });
    
    ws.on('close', () => {
        leaveRoom(ws);
        console.log('Client disconnected');
    });
});

console.log('WebSocket server with rooms started on ws://0.0.0.0:8765');
```

### Go Server

```go
package main

import (
    "fmt"
    "log"
    "net/http"
    "github.com/gorilla/websocket"
)

var upgrader = websocket.Upgrader{
    CheckOrigin: func(r *http.Request) bool {
        return true // Allow all origins (adjust for production)
    },
}

func handleWebSocket(w http.ResponseWriter, r *http.Request) {
    // Upgrade HTTP connection to WebSocket
    conn, err := upgrader.Upgrade(w, r, nil)
    if err != nil {
        log.Println("Upgrade error:", err)
        return
    }
    defer conn.Close()
    
    log.Printf("Client connected: %s", conn.RemoteAddr())
    
    for {
        // Read message
        messageType, message, err := conn.ReadMessage()
        if err != nil {
            log.Println("Read error:", err)
            break
        }
        
        log.Printf("Received: %s", message)
        
        // Echo message back
        err = conn.WriteMessage(messageType, message)
        if err != nil {
            log.Println("Write error:", err)
            break
        }
    }
    
    log.Printf("Client disconnected: %s", conn.RemoteAddr())
}

func main() {
    http.HandleFunc("/ws", handleWebSocket)
    
    log.Println("WebSocket server started on :8765")
    log.Fatal(http.ListenAndServe(":8765", nil))
}
```

---

## Client Implementation

### JavaScript/Browser Client

#### Basic Client
```javascript
// Create WebSocket connection
const ws = new WebSocket('ws://localhost:8765');

// Connection opened
ws.addEventListener('open', (event) => {
    console.log('Connected to WebSocket server');
    ws.send('Hello Server!');
});

// Listen for messages
ws.addEventListener('message', (event) => {
    console.log('Message from server:', event.data);
    
    // Parse JSON if needed
    try {
        const data = JSON.parse(event.data);
        console.log('Parsed data:', data);
    } catch (e) {
        // Plain text message
    }
});

// Connection error
ws.addEventListener('error', (event) => {
    console.error('WebSocket error:', event);
});

// Connection closed
ws.addEventListener('close', (event) => {
    console.log('Disconnected from server');
    console.log('Code:', event.code);
    console.log('Reason:', event.reason);
    console.log('Clean:', event.wasClean);
});

// Send message
function sendMessage(message) {
    if (ws.readyState === WebSocket.OPEN) {
        ws.send(message);
    } else {
        console.error('WebSocket is not open');
    }
}

// Send JSON
function sendJSON(data) {
    sendMessage(JSON.stringify(data));
}

// Close connection
function closeConnection() {
    ws.close(1000, 'Client closing connection');
}
```

#### Advanced Client with Reconnection
```javascript
class WebSocketClient {
    constructor(url, options = {}) {
        this.url = url;
        this.reconnectInterval = options.reconnectInterval || 5000;
        this.maxReconnectAttempts = options.maxReconnectAttempts || 10;
        this.reconnectAttempts = 0;
        this.ws = null;
        this.messageHandlers = [];
        
        this.connect();
    }
    
    connect() {
        console.log('Connecting to WebSocket...');
        this.ws = new WebSocket(this.url);
        
        this.ws.onopen = (event) => {
            console.log('WebSocket connected');
            this.reconnectAttempts = 0;
            this.onOpen(event);
        };
        
        this.ws.onmessage = (event) => {
            this.messageHandlers.forEach(handler => {
                try {
                    handler(event.data);
                } catch (e) {
                    console.error('Error in message handler:', e);
                }
            });
        };
        
        this.ws.onerror = (event) => {
            console.error('WebSocket error:', event);
            this.onError(event);
        };
        
        this.ws.onclose = (event) => {
            console.log('WebSocket closed:', event.code, event.reason);
            this.onClose(event);
            this.reconnect();
        };
    }
    
    reconnect() {
        if (this.reconnectAttempts < this.maxReconnectAttempts) {
            this.reconnectAttempts++;
            console.log(`Reconnecting... Attempt ${this.reconnectAttempts}`);
            
            setTimeout(() => {
                this.connect();
            }, this.reconnectInterval);
        } else {
            console.error('Max reconnection attempts reached');
        }
    }
    
    send(data) {
        if (this.ws && this.ws.readyState === WebSocket.OPEN) {
            if (typeof data === 'object') {
                this.ws.send(JSON.stringify(data));
            } else {
                this.ws.send(data);
            }
        } else {
            console.error('WebSocket is not connected');
        }
    }
    
    onMessage(handler) {
        this.messageHandlers.push(handler);
    }
    
    close() {
        this.maxReconnectAttempts = 0;  // Prevent reconnection
        if (this.ws) {
            this.ws.close(1000, 'Client closing');
        }
    }
    
    // Override these methods as needed
    onOpen(event) {}
    onError(event) {}
    onClose(event) {}
}

// Usage
const client = new WebSocketClient('ws://localhost:8765', {
    reconnectInterval: 3000,
    maxReconnectAttempts: 5
});

client.onMessage((data) => {
    console.log('Received:', data);
});

client.send({ type: 'hello', message: 'Hi from client' });
```

### Python Client

```python
#!/usr/bin/env python3
import asyncio
import websockets
import json

async def websocket_client():
    uri = "ws://localhost:8765"
    
    try:
        async with websockets.connect(uri) as websocket:
            print(f"Connected to {uri}")
            
            # Send message
            await websocket.send("Hello Server!")
            print("Sent: Hello Server!")
            
            # Receive response
            response = await websocket.recv()
            print(f"Received: {response}")
            
            # Send JSON
            await websocket.send(json.dumps({
                'type': 'message',
                'content': 'JSON message'
            }))
            
            response = await websocket.recv()
            print(f"Received: {response}")
    
    except websockets.exceptions.WebSocketException as e:
        print(f"WebSocket error: {e}")
    except Exception as e:
        print(f"Error: {e}")

# Run client
asyncio.run(websocket_client())
```

---

## Proxy Configuration

### NGINX Reverse Proxy for WebSocket

#### HTTP to WebSocket
```nginx
http {
    upstream websocket_backend {
        server 127.0.0.1:8765;
        # Add more servers for load balancing
        # server 127.0.0.1:8766;
    }
    
    server {
        listen 80;
        server_name example.com;
        
        location /ws {
            proxy_pass http://websocket_backend;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "Upgrade";
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            
            # Timeouts
            proxy_connect_timeout 7d;
            proxy_send_timeout 7d;
            proxy_read_timeout 7d;
        }
        
        # Regular HTTP traffic
        location / {
            proxy_pass http://backend_server;
        }
    }
}
```

#### HTTPS to WebSocket (WSS)
```nginx
server {
    listen 443 ssl http2;
    server_name example.com;
    
    # SSL certificates
    ssl_certificate /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;
    
    # SSL configuration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;
    
    location /ws {
        proxy_pass http://127.0.0.1:8765;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto https;
        
        # Longer timeouts for WebSocket
        proxy_connect_timeout 1h;
        proxy_send_timeout 1h;
        proxy_read_timeout 1h;
        
        # Buffer settings
        proxy_buffering off;
    }
}

# HTTP to HTTPS redirect
server {
    listen 80;
    server_name example.com;
    return 301 https://$server_name$request_uri;
}
```

#### Load Balancing with Health Checks
```nginx
upstream websocket_cluster {
    least_conn;  # Use least connections algorithm
    
    server 127.0.0.1:8765 max_fails=3 fail_timeout=30s;
    server 127.0.0.1:8766 max_fails=3 fail_timeout=30s;
    server 127.0.0.1:8767 max_fails=3 fail_timeout=30s;
    
    # Sticky sessions based on IP
    ip_hash;
}

server {
    listen 80;
    server_name example.com;
    
    location /ws {
        proxy_pass http://websocket_cluster;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "Upgrade";
        proxy_set_header Host $host;
        
        # Health check configuration
        proxy_next_upstream error timeout invalid_header http_500;
        proxy_connect_timeout 2s;
    }
}
```

### Apache Reverse Proxy

#### Enable Required Modules
```bash
sudo a2enmod proxy
sudo a2enmod proxy_http
sudo a2enmod proxy_wstunnel
sudo systemctl restart apache2
```

#### Configuration
```apache
<VirtualHost *:80>
    ServerName example.com
    
    # WebSocket proxy
    ProxyPass /ws ws://127.0.0.1:8765/
    ProxyPassReverse /ws ws://127.0.0.1:8765/
    
    # Regular HTTP proxy
    ProxyPass / http://127.0.0.1:8080/
    ProxyPassReverse / http://127.0.0.1:8080/
    
    # Error logs
    ErrorLog ${APACHE_LOG_DIR}/websocket_error.log
    CustomLog ${APACHE_LOG_DIR}/websocket_access.log combined
</VirtualHost>
```

### HAProxy Configuration

```haproxy
frontend http_front
    bind *:80
    
    # ACL for WebSocket upgrade
    acl is_websocket hdr(Upgrade) -i WebSocket
    acl is_websocket_path path_beg /ws
    
    # Use WebSocket backend if upgrade header present
    use_backend websocket_back if is_websocket is_websocket_path
    
    # Default backend for HTTP
    default_backend http_back

backend websocket_back
    balance leastconn
    
    # Enable WebSocket protocol
    option http-server-close
    option forwardfor
    
    # Timeouts
    timeout tunnel 1h
    timeout client 1h
    timeout server 1h
    
    # Servers
    server ws1 127.0.0.1:8765 check
    server ws2 127.0.0.1:8766 check

backend http_back
    balance roundrobin
    server web1 127.0.0.1:8080 check
    server web2 127.0.0.1:8081 check
```

---

## Security Considerations

### Authentication

#### Token-Based Authentication
```javascript
// Client sends token in initial message
const ws = new WebSocket('ws://example.com/ws');

ws.onopen = () => {
    ws.send(JSON.stringify({
        type: 'auth',
        token: 'jwt-token-here'
    }));
};
```

#### URL Parameter Authentication (Less Secure)
```javascript
const token = 'jwt-token-here';
const ws = new WebSocket(`ws://example.com/ws?token=${token}`);
```

#### Custom Header Authentication (Not Supported in Browser)
```python
# Python client can send custom headers
import websockets

async with websockets.connect(
    'ws://example.com/ws',
    extra_headers={'Authorization': 'Bearer token'}
) as ws:
    # Connected
    pass
```

### Origin Validation

#### Server-Side Origin Check
```python
async def handler(websocket, path):
    origin = websocket.request_headers.get('Origin')
    allowed_origins = ['https://example.com', 'https://app.example.com']
    
    if origin not in allowed_origins:
        await websocket.close(1008, "Invalid origin")
        return
    
    # Process connection
```

```javascript
// Node.js
const wss = new WebSocket.Server({
    verifyClient: (info) => {
        const origin = info.origin;
        const allowedOrigins = ['https://example.com'];
        return allowedOrigins.includes(origin);
    }
});
```

### TLS/SSL (WSS)

#### Always Use WSS in Production
```javascript
// Good: Encrypted connection
const ws = new WebSocket('wss://example.com/ws');

// Bad: Unencrypted (only for development)
const ws = new WebSocket('ws://example.com/ws');
```

#### Generate Self-Signed Certificate (Development)
```bash
# Generate private key and certificate
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout websocket-key.pem \
  -out websocket-cert.pem \
  -subj "/C=US/ST=State/L=City/O=Org/CN=localhost"

# Python server with SSL
import ssl
import websockets

ssl_context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
ssl_context.load_cert_chain('websocket-cert.pem', 'websocket-key.pem')

start_server = websockets.serve(
    handler, 
    "0.0.0.0", 
    8765,
    ssl=ssl_context
)
```

### Input Validation

```python
async def handler(websocket, path):
    async for message in websocket:
        try:
            # Validate message length
            if len(message) > 1000000:  # 1MB limit
                await websocket.close(1009, "Message too large")
                return
            
            # Parse and validate JSON
            data = json.loads(message)
            
            # Validate required fields
            if 'type' not in data or 'content' not in data:
                await websocket.send(json.dumps({
                    'error': 'Invalid message format'
                }))
                continue
            
            # Sanitize content
            content = data['content'][:500]  # Limit content length
            
            # Process message
            
        except json.JSONDecodeError:
            await websocket.send(json.dumps({
                'error': 'Invalid JSON'
            }))
        
        except Exception as e:
            logging.error(f"Error processing message: {e}")
```

### Rate Limiting

```python
import time
from collections import defaultdict

class RateLimiter:
    def __init__(self, max_requests=10, window=60):
        self.max_requests = max_requests
        self.window = window
        self.requests = defaultdict(list)
    
    def is_allowed(self, client_id):
        now = time.time()
        client_requests = self.requests[client_id]
        
        # Remove old requests outside window
        client_requests[:] = [
            req_time for req_time in client_requests 
            if now - req_time < self.window
        ]
        
        if len(client_requests) < self.max_requests:
            client_requests.append(now)
            return True
        
        return False

limiter = RateLimiter(max_requests=100, window=60)

async def handler(websocket, path):
    client_id = websocket.remote_address[0]
    
    async for message in websocket:
        if not limiter.is_allowed(client_id):
            await websocket.close(1008, "Rate limit exceeded")
            return
        
        # Process message
```

### Common Vulnerabilities

#### Cross-Site WebSocket Hijacking (CSWSH)
```python
# Prevention: Always validate Origin header
async def handler(websocket, path):
    origin = websocket.request_headers.get('Origin')
    if not is_valid_origin(origin):
        await websocket.close(1008, "Invalid origin")
        return
```

#### Denial of Service
```python
# Prevention: Implement connection limits
MAX_CONNECTIONS = 1000
active_connections = set()

async def handler(websocket, path):
    if len(active_connections) >= MAX_CONNECTIONS:
        await websocket.close(1008, "Server at capacity")
        return
    
    active_connections.add(websocket)
    try:
        # Handle connection
        pass
    finally:
        active_connections.remove(websocket)
```

#### Message Injection
```python
# Prevention: Validate and sanitize all input
import html

async def handler(websocket, path):
    async for message in websocket:
        # Escape HTML to prevent XSS
        safe_message = html.escape(message)
        
        # Broadcast safe message
        await broadcast(safe_message)
```

---

## Common Use Cases

### 1. Real-Time Chat Application
```javascript
// Client
const ws = new WebSocket('wss://chat.example.com/ws');

ws.onopen = () => {
    // Join room
    ws.send(JSON.stringify({
        type: 'join',
        room: 'general',
        username: 'user123'
    }));
};

ws.onmessage = (event) => {
    const data = JSON.parse(event.data);
    
    switch(data.type) {
        case 'message':
            displayMessage(data.username, data.content);
            break;
        case 'user_joined':
            showNotification(`${data.username} joined`);
            break;
        case 'user_left':
            showNotification(`${data.username} left`);
            break;
    }
};

function sendMessage(content) {
    ws.send(JSON.stringify({
        type: 'message',
        content: content
    }));
}
```

### 2. Live Data Dashboard
```javascript
// Stock price ticker
const ws = new WebSocket('wss://data.example.com/stocks');

ws.onmessage = (event) => {
    const data = JSON.parse(event.data);
    
    // Update UI with real-time stock prices
    updateStockPrice(data.symbol, data.price, data.change);
};

// Subscribe to specific stocks
ws.onopen = () => {
    ws.send(JSON.stringify({
        type: 'subscribe',
        symbols: ['AAPL', 'GOOGL', 'MSFT']
    }));
};
```

### 3. Multiplayer Gaming
```javascript
// Game client
const ws = new WebSocket('wss://game.example.com/ws');

ws.onmessage = (event) => {
    const data = JSON.parse(event.data);
    
    switch(data.type) {
        case 'player_moved':
            updatePlayerPosition(data.playerId, data.x, data.y);
            break;
        case 'player_attacked':
            showAttackAnimation(data.playerId, data.targetId);
            break;
        case 'game_state':
            updateGameState(data.state);
            break;
    }
};

function sendPlayerAction(action, params) {
    ws.send(JSON.stringify({
        type: 'action',
        action: action,
        params: params
    }));
}
```

### 4. Collaborative Document Editing
```javascript
// Real-time collaborative editing
const ws = new WebSocket('wss://docs.example.com/ws');

let documentId = 'doc-123';

ws.onopen = () => {
    // Join document
    ws.send(JSON.stringify({
        type: 'join_document',
        documentId: documentId
    }));
};

// Send changes
editor.on('change', (delta) => {
    ws.send(JSON.stringify({
        type: 'edit',
        documentId: documentId,
        delta: delta
    }));
});

// Receive changes from others
ws.onmessage = (event) => {
    const data = JSON.parse(event.data);
    
    if (data.type === 'edit' && data.userId !== currentUserId) {
        editor.applyDelta(data.delta);
    }
};
```

### 5. IoT Device Communication
```python
# IoT sensor sending data
import asyncio
import websockets
import json
import random

async def sensor_client():
    uri = "wss://iot.example.com/device/sensor-001"
    
    async with websockets.connect(uri) as websocket:
        while True:
            # Read sensor data
            data = {
                'type': 'sensor_reading',
                'device_id': 'sensor-001',
                'temperature': round(random.uniform(20, 30), 2),
                'humidity': round(random.uniform(40, 60), 2),
                'timestamp': datetime.utcnow().isoformat()
            }
            
            await websocket.send(json.dumps(data))
            await asyncio.sleep(10)  # Send every 10 seconds

asyncio.run(sensor_client())
```

---

## Troubleshooting

### Common Connection Issues

#### Problem: Connection Refused
```bash
# Check if server is running
netstat -tuln | grep 8765

# Check if port is blocked by firewall
sudo ufw status
sudo ufw allow 8765/tcp

# Check with telnet
telnet localhost 8765
```

#### Problem: 101 Switching Protocols Not Received
```bash
# Verify upgrade headers are sent
curl -i -N \
  -H "Connection: Upgrade" \
  -H "Upgrade: websocket" \
  -H "Sec-WebSocket-Version: 13" \
  -H "Sec-WebSocket-Key: x3JJHMbDL1EzLkh9GBhXDw==" \
  http://localhost:8765/

# Check server logs for errors
```

#### Problem: SSL/TLS Errors (WSS)
```bash
# Verify certificate
openssl s_client -connect example.com:443 -servername example.com

# Check certificate expiration
openssl s_client -connect example.com:443 -servername example.com | openssl x509 -noout -dates

# Test with insecure connection (development only)
wscat -c wss://example.com --no-check
```

### Debugging Tools

#### Enable Debug Logging (Python)
```python
import logging

# Enable websockets debug logging
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)

# Websockets library will now output detailed logs
```

#### Network Packet Capture
```bash
# Capture WebSocket handshake
sudo tcpdump -i any -A 'tcp port 8765' -w websocket-debug.pcap

# Read capture
tcpdump -r websocket-debug.pcap -A

# Filter for HTTP upgrade
tcpdump -r websocket-debug.pcap -A | grep -i "upgrade"
```

#### Browser DevTools
```javascript
// Monitor WebSocket in Chrome DevTools
// 1. Open DevTools (F12)
// 2. Go to Network tab
// 3. Filter by "WS" (WebSocket)
// 4. Click on connection to see frames

// Log all events
const ws = new WebSocket('ws://localhost:8765');

ws.onopen = (e) => console.log('OPEN', e);
ws.onmessage = (e) => console.log('MESSAGE', e.data);
ws.onerror = (e) => console.error('ERROR', e);
ws.onclose = (e) => console.log('CLOSE', e.code, e.reason);
```

### Performance Issues

#### Problem: High Latency
```python
# Enable TCP_NODELAY to disable Nagle's algorithm
import socket

# On server socket
sock.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)

# Reduce ping interval for faster detection
server = await websockets.serve(
    handler,
    "0.0.0.0",
    8765,
    ping_interval=10,  # Reduced from 30
    ping_timeout=5
)
```

#### Problem: Memory Leaks
```python
# Ensure proper cleanup of connections
connected_clients = set()

async def handler(websocket, path):
    connected_clients.add(websocket)
    try:
        async for message in websocket:
            # Process message
            pass
    finally:
        connected_clients.remove(websocket)
        # Clean up any per-client resources
```

#### Problem: Message Queuing
```python
# Implement backpressure handling
async def send_with_backpressure(websocket, message):
    try:
        await asyncio.wait_for(
            websocket.send(message),
            timeout=5.0
        )
    except asyncio.TimeoutError:
        # Client is too slow, disconnect them
        await websocket.close(1008, "Client too slow")
```

---

## Performance Optimization

### Connection Pooling

```python
# Limit maximum connections per client
from collections import defaultdict

connections_per_ip = defaultdict(int)
MAX_CONNECTIONS_PER_IP = 5

async def handler(websocket, path):
    client_ip = websocket.remote_address[0]
    
    if connections_per_ip[client_ip] >= MAX_CONNECTIONS_PER_IP:
        await websocket.close(1008, "Too many connections")
        return
    
    connections_per_ip[client_ip] += 1
    
    try:
        # Handle connection
        pass
    finally:
        connections_per_ip[client_ip] -= 1
```

### Message Compression

```python
# Enable permessage-deflate extension
import websockets

server = await websockets.serve(
    handler,
    "0.0.0.0",
    8765,
    compression="deflate"  # Enable compression
)
```

```javascript
// Node.js with compression
const wss = new WebSocket.Server({
    port: 8765,
    perMessageDeflate: {
        zlibDeflateOptions: {
            chunkSize: 1024,
            memLevel: 7,
            level: 3
        },
        zlibInflateOptions: {
            chunkSize: 10 * 1024
        },
        threshold: 1024  // Compress messages > 1KB
    }
});
```

### Binary Messages

```javascript
// Send binary data (more efficient than text)
const binaryData = new Uint8Array([1, 2, 3, 4, 5]);
ws.send(binaryData.buffer);

// Receive binary
ws.binaryType = 'arraybuffer';
ws.onmessage = (event) => {
    if (event.data instanceof ArrayBuffer) {
        const view = new Uint8Array(event.data);
        console.log('Binary data:', view);
    }
};
```

### Batching Messages

```javascript
// Client-side message batching
class MessageBatcher {
    constructor(ws, batchSize = 10, flushInterval = 100) {
        this.ws = ws;
        this.queue = [];
        this.batchSize = batchSize;
        this.flushInterval = flushInterval;
        this.timer = null;
    }
    
    send(message) {
        this.queue.push(message);
        
        if (this.queue.length >= this.batchSize) {
            this.flush();
        } else if (!this.timer) {
            this.timer = setTimeout(() => this.flush(), this.flushInterval);
        }
    }
    
    flush() {
        if (this.queue.length > 0) {
            this.ws.send(JSON.stringify({
                type: 'batch',
                messages: this.queue
            }));
            this.queue = [];
        }
        
        if (this.timer) {
            clearTimeout(this.timer);
            this.timer = null;
        }
    }
}

const batcher = new MessageBatcher(ws);
batcher.send({ type: 'event', data: 'test' });
```

### Load Balancing

```nginx
# NGINX with sticky sessions
upstream websocket_cluster {
    ip_hash;  # Sticky sessions based on client IP
    
    server 10.0.0.1:8765 weight=3;
    server 10.0.0.2:8765 weight=2;
    server 10.0.0.3:8765 weight=1;
}

server {
    listen 80;
    
    location /ws {
        proxy_pass http://websocket_cluster;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "Upgrade";
    }
}
```

---

## Practical Examples

### Example 1: Simple Echo Server and Client

#### Server (Python)
```python
#!/usr/bin/env python3
import asyncio
import websockets

async def echo(websocket, path):
    async for message in websocket:
        await websocket.send(f"Echo: {message}")

start_server = websockets.serve(echo, "localhost", 8765)
asyncio.get_event_loop().run_until_complete(start_server)
asyncio.get_event_loop().run_forever()
```

#### Client (JavaScript)
```html
<!DOCTYPE html>
<html>
<head>
    <title>WebSocket Echo Client</title>
</head>
<body>
    <h1>WebSocket Echo Client</h1>
    <input type="text" id="messageInput" placeholder="Enter message">
    <button onclick="sendMessage()">Send</button>
    <div id="output"></div>
    
    <script>
        const ws = new WebSocket('ws://localhost:8765');
        const output = document.getElementById('output');
        
        ws.onmessage = (event) => {
            output.innerHTML += `<p>Received: ${event.data}</p>`;
        };
        
        function sendMessage() {
            const input = document.getElementById('messageInput');
            ws.send(input.value);
            output.innerHTML += `<p>Sent: ${input.value}</p>`;
            input.value = '';
        }
    </script>
</body>
</html>
```

### Example 2: Chat Room with Authentication

See the advanced server examples in the [WebSocket Servers](#websocket-servers) section.

### Example 3: Real-Time Sensor Data Streaming

```python
#!/usr/bin/env python3
# Sensor simulator
import asyncio
import websockets
import json
import random
from datetime import datetime

async def sensor_stream():
    uri = "ws://localhost:8765/sensor"
    
    async with websockets.connect(uri) as websocket:
        # Authenticate
        await websocket.send(json.dumps({
            'type': 'auth',
            'device_id': 'SENSOR-001',
            'api_key': 'secret-key'
        }))
        
        # Stream sensor data
        while True:
            data = {
                'type': 'reading',
                'temperature': round(random.uniform(20, 30), 2),
                'humidity': round(random.uniform(40, 60), 2),
                'pressure': round(random.uniform(1000, 1020), 2),
                'timestamp': datetime.utcnow().isoformat()
            }
            
            await websocket.send(json.dumps(data))
            await asyncio.sleep(1)

asyncio.run(sensor_stream())
```

---

## Additional Resources

### Official Documentation
- **RFC 6455**: https://tools.ietf.org/html/rfc6455
- **MDN WebSocket API**: https://developer.mozilla.org/en-US/docs/Web/API/WebSocket
- **WHATWG WebSocket Spec**: https://websockets.spec.whatwg.org/

### Libraries and Tools

#### Python
- **websockets**: https://websockets.readthedocs.io/
- **aiohttp**: https://docs.aiohttp.org/en/stable/web_quickstart.html#websockets
- **Django Channels**: https://channels.readthedocs.io/

#### JavaScript/Node.js
- **ws**: https://github.com/websockets/ws
- **Socket.IO**: https://socket.io/ (WebSocket with fallbacks)
- **SockJS**: https://github.com/sockjs/sockjs-node

#### Testing Tools
- **wscat**: https://github.com/websockets/wscat
- **websocat**: https://github.com/vi/websocat
- **Postman**: Supports WebSocket testing

### Security Resources
- **OWASP WebSocket Security**: https://owasp.org/www-community/vulnerabilities/WebSockets
- **WebSocket Security Best Practices**: Various online guides

---

## Quick Reference

### Connection States
```javascript
WebSocket.CONNECTING  // 0 - Connection not yet established
WebSocket.OPEN        // 1 - Connection established
WebSocket.CLOSING     // 2 - Connection closing
WebSocket.CLOSED      // 3 - Connection closed
```

### Common Opcodes
```
0x0 - Continuation
0x1 - Text
0x2 - Binary
0x8 - Close
0x9 - Ping
0xA - Pong
```

### Close Codes
```
1000 - Normal closure
1001 - Going away
1002 - Protocol error
1003 - Unsupported data
1006 - Abnormal closure
1007 - Invalid payload
1008 - Policy violation
1009 - Message too big
1011 - Internal error
```

### Best Practices Checklist
- [ ] Use WSS (TLS) in production
- [ ] Validate Origin header
- [ ] Implement authentication
- [ ] Rate limit connections
- [ ] Validate input data
- [ ] Handle errors gracefully
- [ ] Implement reconnection logic
- [ ] Use appropriate timeouts
- [ ] Monitor connection health (ping/pong)
- [ ] Log important events
- [ ] Test with realistic load
- [ ] Document your WebSocket API

---

## Legal and Ethical Considerations

WebSocket technology should be used responsibly:

- **Respect Privacy**: Don't intercept or monitor WebSocket traffic without authorization
- **Secure Communications**: Always use encryption (WSS) for sensitive data
- **Rate Limiting**: Implement proper rate limiting to prevent abuse
- **Authorization**: Ensure proper access controls are in place
- **Compliance**: Follow relevant data protection regulations (GDPR, CCPA, etc.)

---

**Document Version**: 1.0  
**Last Updated**: December 2025  
**Author**: Networking Specialist  
**Purpose**: Educational and reference material for WebSocket implementation
