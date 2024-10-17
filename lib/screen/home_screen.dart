import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/html.dart' as html; // For web
import 'package:web_socket_channel/io.dart'; // For mobile
import 'package:flutter/foundation.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late WebSocketChannel channel;
  final TextEditingController messageController = TextEditingController();
  final FocusNode messageFocusNode = FocusNode(); // Create a FocusNode
  final List<String> messages = [];
  String ip = "192.168.29.17";

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      channel = html.HtmlWebSocketChannel.connect(Uri.parse("ws://$ip:8000/ws"));
      print("Connected to WebSocket server: ws://$ip:8000/ws");
    } else {
      channel = IOWebSocketChannel.connect("ws://$ip:8000/ws");
      print("Connected to WebSocket server: ws://$ip:8000/ws");
    }

    channel.stream.listen(
      (message) {
        print("Received message: $message"); // Debugging line
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
      print("Sending message: $message"); // Debugging line
      channel.sink.add(message);
      messageController.clear();
      // Request focus back to the TextField
      messageFocusNode.requestFocus(); 
    }
  }

  @override
  void dispose() {
    // Close the WebSocket connection when the widget is disposed
    channel.sink.close();
    messageController.dispose();
    messageFocusNode.dispose(); // Dispose the FocusNode
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Flutter WebSocket Example"),
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
              autocorrect: true,
              autofocus: true,
              controller: messageController,
              focusNode: messageFocusNode, // Assign the FocusNode
              decoration: const InputDecoration(labelText: "Enter a message"),
              onSubmitted: (value) {
                sendMessage(value); // Send message on Enter key
              },
            ),
            ElevatedButton(
              onPressed: () {
                sendMessage(messageController.text);
              },
              child: const Text("Send"),
            ),
          ],
        ),
      ),
    );
  }
}
