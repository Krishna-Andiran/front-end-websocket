import 'package:flutter/material.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late WebSocketChannel channel;
  TextEditingController messageController = TextEditingController();
  List<String> messages = [];

  @override
  void initState() {
    super.initState();
    // Connect to WebSocket server
    channel = IOWebSocketChannel.connect("ws://10.0.2.2:8000/ws");

    // Listen for incoming messages from the server
    channel.stream.listen(
      (message) {
        setState(() {
          messages.add("Server: $message");
        });
      },
      onError: (error) {
        print('WebSocket error: $error');
      },
      onDone: () {
        print('WebSocket connection closed.');
      },
    );
  }

  void sendMessage(String message) {
    if (message.isNotEmpty) {
      channel.sink.add(message); // Send message to the server
      messageController.clear();
    }
  }

  @override
  void dispose() {
    // Close the WebSocket connection when the widget is disposed
    channel.sink.close();
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Flutter WebSocket Example"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(messages[index]),
                  );
                },
              ),
            ),
            TextField(
              controller: messageController,
              decoration: InputDecoration(labelText: "Enter a message"),
            ),
            ElevatedButton(
              onPressed: () {
                sendMessage(messageController.text);
              },
              child: Text("Send"),
            ),
          ],
        ),
      ),
    );
  }
}
