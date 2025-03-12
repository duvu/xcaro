# Hướng Dẫn Tích Hợp WebSocket

## Thông Tin Chung

### Endpoint WebSocket
```
ws://your-server/api/ws
```

### Xác Thực
- WebSocket endpoint yêu cầu JWT token để xác thực
- Token có thể được gửi qua:
  - Query parameter: `?token=your_jwt_token`
  - Authorization header: `Bearer your_jwt_token`

### Cấu Trúc Message
```typescript
interface WSMessage {
  type: string;      // Loại event
  room_id?: string;  // ID phòng (nếu có)
  payload: any;      // Dữ liệu của event
}
```

### Các Event Types
```typescript
// Game events
const EVENT_GAME_STATE = "game_state";  // Cập nhật trạng thái game
const EVENT_GAME_START = "game_start";  // Game bắt đầu
const EVENT_GAME_END = "game_end";      // Game kết thúc
const EVENT_GAME_MOVE = "game_move";    // Nước đi mới

// Room events
const EVENT_ROOM_UPDATE = "room_update";   // Cập nhật thông tin phòng
const EVENT_PLAYER_JOIN = "player_join";   // Người chơi tham gia
const EVENT_PLAYER_LEAVE = "player_leave"; // Người chơi rời đi
const EVENT_CHAT_MESSAGE = "chat_message"; // Tin nhắn chat

// Stream events
const EVENT_STREAM_START = "stream_start";   // Stream bắt đầu
const EVENT_STREAM_STOP = "stream_stop";     // Stream kết thúc
const EVENT_STREAM_STATUS = "stream_status"; // Cập nhật trạng thái stream

// System events
const EVENT_ERROR = "error"; // Thông báo lỗi
const EVENT_PING = "ping";   // Kiểm tra kết nối
const EVENT_PONG = "pong";   // Phản hồi kiểm tra kết nối
```

## Tích Hợp Flutter

### Cài Đặt Dependencies
```yaml
dependencies:
  web_socket_channel: ^2.4.0
```

### Kết Nối WebSocket
```dart
import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';

class GameWebSocket {
  WebSocketChannel? _channel;
  String? _token;
  
  void connect(String token) {
    _token = token;
    final wsUrl = Uri.parse('ws://your-server/api/ws?token=$token');
    _channel = WebSocketChannel.connect(wsUrl);
    
    // Lắng nghe messages
    _channel?.stream.listen(
      (message) => _handleMessage(message),
      onError: (error) => print('WebSocket error: $error'),
      onDone: () {
        print('WebSocket disconnected');
        // Thử kết nối lại sau 5 giây
        Future.delayed(Duration(seconds: 5), () => connect(_token!));
      },
    );
  }
  
  void _handleMessage(String message) {
    final data = jsonDecode(message);
    switch(data['type']) {
      case 'game_state':
        // Xử lý cập nhật trạng thái game
        break;
      case 'chat_message':
        // Xử lý tin nhắn chat
        break;
      // Xử lý các event khác...
    }
  }
  
  void sendMessage(String type, String? roomId, dynamic payload) {
    if (_channel == null) return;
    
    final message = {
      'type': type,
      'room_id': roomId,
      'payload': payload,
    };
    
    _channel?.sink.add(jsonEncode(message));
  }
  
  void dispose() {
    _channel?.sink.close();
  }
}
```

### Sử Dụng Trong Flutter
```dart
final gameWs = GameWebSocket();

// Kết nối khi có token
gameWs.connect('your_jwt_token');

// Gửi nước đi
gameWs.sendMessage('game_move', 'room_123', {
  'position': {'x': 2, 'y': 3}
});

// Gửi tin nhắn chat
gameWs.sendMessage('chat_message', 'room_123', {
  'content': 'Hello everyone!'
});

// Đóng kết nối khi không cần thiết
gameWs.dispose();
```

## Tích Hợp NextJS

### Cài Đặt Dependencies
```bash
npm install --save socket.io-client
```

### Tạo WebSocket Service
```typescript
// services/websocket.ts
import { io, Socket } from 'socket.io-client';

interface WSMessage {
  type: string;
  room_id?: string;
  payload: any;
}

class GameWebSocket {
  private socket: Socket | null = null;
  private token: string | null = null;
  
  connect(token: string) {
    this.token = token;
    
    this.socket = io('ws://your-server', {
      auth: {
        token
      },
      reconnection: true,
      reconnectionDelay: 5000,
    });
    
    this.socket.on('connect', () => {
      console.log('WebSocket connected');
    });
    
    this.socket.on('disconnect', () => {
      console.log('WebSocket disconnected');
    });
    
    this.socket.on('message', (message: WSMessage) => {
      this.handleMessage(message);
    });
  }
  
  private handleMessage(message: WSMessage) {
    switch(message.type) {
      case 'game_state':
        // Xử lý cập nhật trạng thái game
        break;
      case 'chat_message':
        // Xử lý tin nhắn chat
        break;
      // Xử lý các event khác...
    }
  }
  
  sendMessage(type: string, roomId?: string, payload?: any) {
    if (!this.socket) return;
    
    const message: WSMessage = {
      type,
      room_id: roomId,
      payload
    };
    
    this.socket.emit('message', message);
  }
  
  disconnect() {
    if (this.socket) {
      this.socket.disconnect();
      this.socket = null;
    }
  }
}

export const gameWs = new GameWebSocket();
```

### Sử Dụng Trong Component
```typescript
// components/Game.tsx
import { useEffect } from 'react';
import { gameWs } from '../services/websocket';

export default function Game() {
  useEffect(() => {
    // Kết nối khi component mount
    gameWs.connect('your_jwt_token');
    
    // Cleanup khi unmount
    return () => {
      gameWs.disconnect();
    };
  }, []);
  
  const handleMove = (x: number, y: number) => {
    gameWs.sendMessage('game_move', 'room_123', {
      position: { x, y }
    });
  };
  
  const sendChat = (content: string) => {
    gameWs.sendMessage('chat_message', 'room_123', {
      content
    });
  };
  
  return (
    // JSX của component
  );
}
```

## Xử Lý Lỗi và Kết Nối Lại

### Các Trường Hợp Lỗi Phổ Biến
1. Mất kết nối mạng
2. Token hết hạn
3. Server restart

### Chiến Lược Xử Lý
1. Tự động thử kết nối lại sau 5 giây
2. Giữ trạng thái local và đồng bộ khi kết nối lại
3. Thông báo cho người dùng về trạng thái kết nối

## Bảo Mật
1. Luôn sử dụng WSS (WebSocket Secure) trong production
2. Không lưu JWT token trong localStorage
3. Xác thực mọi message từ client
4. Rate limiting để tránh spam

## Performance
1. Sử dụng binary protocol khi cần truyền dữ liệu lớn
2. Batch các update nhỏ
3. Compress payload khi cần thiết
4. Đóng kết nối khi không sử dụng 