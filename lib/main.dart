import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_mjpeg/flutter_mjpeg.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ESP32 Robot & Camera Control',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final String cameraUrl = "http://192.168.4.1:81/stream";
  final String esp32Url = "http://192.168.4.1";

  String statusMessage = "Connected";
  bool isLiveFeedOn = false;
  bool isLedOn = false; // Track LED state
  Timer? _movementTimer;

  Future<void> sendCommand(String command) async {
    final Uri url = Uri.parse('$esp32Url/$command');
    try {
      final response = await http.get(url).timeout(Duration(seconds: 5));

      if (response.statusCode == 200) {
        setState(() {
          statusMessage = "Command '$command' sent successfully.";
        });
      } else {
        setState(() {
          statusMessage = "Failed to send command: ${response.statusCode}";
        });
      }
    } on TimeoutException catch (_) {
      setState(() {
        statusMessage = "Timeout: Failed to send '$command'.";
      });
    } catch (e) {
      setState(() {
        statusMessage = "Error: Failed to send '$command'.";
      });
    }
  }

  Future<void> toggleLiveFeed() async {
    if (isLiveFeedOn) {
      await sendCommand('stopstream');
    } else {
      await sendCommand('startstream');
    }
    setState(() {
      isLiveFeedOn = !isLiveFeedOn;
    });
  }

  void startMovement(String command) {
    _movementTimer?.cancel(); // Cancel any existing timer
    _movementTimer = Timer.periodic(Duration(milliseconds: 100), (timer) {
      sendCommand(command);
    });
  }

  void stopMovement() {
    _movementTimer?.cancel();
    sendCommand('stop'); // Send stop command when released
  }

  void toggleLed() {
    isLedOn = !isLedOn; // Toggle LED state
    sendCommand(isLedOn ? 'ledon' : 'ledoff'); // Send corresponding command
  }

  Widget buildJoystickControls() {
    return Container(
      padding: EdgeInsets.all(16),
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey, width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onLongPress: () => startMovement('go'),
            onLongPressUp: stopMovement,
            child: ElevatedButton(
              onPressed: () => sendCommand('go'), // Fallback for tap
              style: ElevatedButton.styleFrom(
                shape: CircleBorder(),
                padding: EdgeInsets.all(10),
                backgroundColor: Colors.green,
              ),
              child: Icon(Icons.arrow_upward, size: 35),
            ),
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onLongPress: () => startMovement('left'),
                onLongPressUp: stopMovement,
                child: ElevatedButton(
                  onPressed: () => sendCommand('left'), // Fallback for tap
                  style: ElevatedButton.styleFrom(
                    shape: CircleBorder(),
                    padding: EdgeInsets.all(10),
                    backgroundColor: Colors.green,
                  ),
                  child: Icon(Icons.arrow_back, size: 35),
                ),
              ),
              SizedBox(width: 12),
              ElevatedButton(
                onPressed: () => sendCommand('stop'),
                style: ElevatedButton.styleFrom(
                  shape: CircleBorder(),
                  padding: EdgeInsets.all(10),
                  backgroundColor: Colors.red,
                ),
                child: Icon(Icons.stop, size: 35),
              ),
              SizedBox(width: 12),
              GestureDetector(
                onLongPress: () => startMovement('right'),
                onLongPressUp: stopMovement,
                child: ElevatedButton(
                  onPressed: () => sendCommand('right'), // Fallback for tap
                  style: ElevatedButton.styleFrom(
                    shape: CircleBorder(),
                    padding: EdgeInsets.all(10),
                    backgroundColor: Colors.green,
                  ),
                  child: Icon(Icons.arrow_forward, size: 35),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          GestureDetector(
            onLongPress: () => startMovement('back'),
            onLongPressUp: stopMovement,
            child: ElevatedButton(
              onPressed: () => sendCommand('back'), // Fallback for tap
              style: ElevatedButton.styleFrom(
                shape: CircleBorder(),
                padding: EdgeInsets.all(10),
                backgroundColor: Colors.green,
              ),
              child: Icon(Icons.arrow_downward, size: 35),
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: toggleLed,
            style: ElevatedButton.styleFrom(
              backgroundColor: isLedOn ? Colors.red : Colors.yellow[700],
              fixedSize: Size(150, 50),
            ),
            child: Text(isLedOn ? 'LED OFF' : 'LED ON'),
          ),
        ],
      ),
    );
  }

  Widget buildStatusMessage() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        statusMessage,
        style: TextStyle(
          color: statusMessage.contains("Error") || statusMessage.contains("Timeout")
              ? Colors.red
              : Colors.green,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget buildCameraStream() {
    return isLiveFeedOn
        ? Mjpeg(
            error: (context, error, stack) {
              return Center(
                child: Text(
                  "Failed to load camera stream.",
                  style: TextStyle(color: Colors.red),
                ),
              );
            },
            stream: cameraUrl,
            timeout: Duration(seconds: 10),
            isLive: isLiveFeedOn,
          )
        : Center(
            child: Text(
              "Live feed is off",
              style: TextStyle(color: Colors.grey),
            ),
          );
  }

  Widget buildToggleButton() {
    return ElevatedButton(
      onPressed: toggleLiveFeed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isLiveFeedOn ? Colors.red : Colors.green,
        fixedSize: Size(150, 50),
      ),
      child: Text(isLiveFeedOn ? 'Stop Live Feed' : 'Start Live Feed'),
    );
  }

  @override
  void dispose() {
    _movementTimer?.cancel(); // Cancel timer to avoid memory leaks
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ESP32 Robot Control'),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: buildCameraStream(),
          ),
          buildStatusMessage(),
          buildToggleButton(), // Start/Stop Live Feed button
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  buildJoystickControls(), // Joystick with LED control
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}