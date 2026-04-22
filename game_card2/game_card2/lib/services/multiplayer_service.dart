import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';

class MultiplayerService {
  static const int port = 8080;
  bool isHost = false;
  String? hostIp;
  WebSocketChannel? channel;
  Function(Map<String, dynamic>)? onMessageReceived;
  Function()? onConnected;
  Function()? onDisconnected;

  HttpServer? _server;
  List<WebSocket> _clients = [];

  // Get local IP address
  Future<String?> getLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list();
      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            return addr.address;
          }
        }
      }
    } catch (e) {
      debugPrint('Error getting local IP: $e');
    }
    return null;
  }

  // Start hosting (server)
  Future<void> startHosting() async {
    isHost = true;
    hostIp = await getLocalIp();
    if (hostIp == null) return;

    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, port);
      debugPrint('Server started on $hostIp:$port');

      _server!.listen((HttpRequest request) {
        if (WebSocketTransformer.isUpgradeRequest(request)) {
          WebSocketTransformer.upgrade(request).then((WebSocket ws) {
            _clients.add(ws);
            debugPrint('Client connected');

            ws.listen(
              (data) {
                // Broadcast to all clients
                for (var client in _clients) {
                  if (client != ws) {
                    client.add(data);
                  }
                }
                // Handle locally
                final message = jsonDecode(data);
                onMessageReceived?.call(message);
              },
              onDone: () {
                _clients.remove(ws);
                debugPrint('Client disconnected');
              },
            );
          });
        }
      });

      onConnected?.call();
    } catch (e) {
      debugPrint('Error starting server: $e');
    }
  }

  // Join as client
  Future<void> joinGame(String ip) async {
    isHost = false;
    hostIp = ip;

    try {
      channel = IOWebSocketChannel.connect('ws://$ip:$port');
      debugPrint('Connected to $ip:$port');

      channel!.stream.listen(
        (data) {
          final message = jsonDecode(data);
          onMessageReceived?.call(message);
        },
        onDone: () {
          onDisconnected?.call();
        },
      );

      onConnected?.call();
    } catch (e) {
      debugPrint('Error connecting: $e');
    }
  }

  // Send message
  void sendMessage(Map<String, dynamic> message) {
    final data = jsonEncode(message);
    if (isHost) {
      // Broadcast to all clients
      for (var client in _clients) {
        client.add(data);
      }
    } else {
      channel?.sink.add(data);
    }
  }

  // Disconnect
  void disconnect() {
    if (isHost) {
      _server?.close();
      for (var client in _clients) {
        client.close();
      }
      _clients.clear();
    } else {
      channel?.sink.close();
    }
    onDisconnected?.call();
  }
}