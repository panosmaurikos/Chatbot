import 'package:flutter/material.dart';
import 'custom_bottom_nav.dart';
import 'classes/customer.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(MaterialApp(home: SimpleChatScreen()));
}

class SimpleChatScreen extends StatefulWidget {
  @override
  _SimpleChatScreenState createState() => _SimpleChatScreenState();
}

final customerInfo = CustomerInfo(
  name: 'replase this with your name',
  licensePlate: 'replase this with your license plate',
  taxId: 'replase this with your tax id',
  contractStartDate: 'replase this with your contract start date',
  contractEndDate: 'replase this with your contract end date',
  phone: 'replase this with your phone number',
  email: 'replase this with your email',
  homeAddress: 'replase this with your home address',
  currentAddress: 'replase this with your current address',
);

class _SimpleChatScreenState extends State<SimpleChatScreen> {
  bool isLoading = false;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> messages = [];
  String? sessionId;
  int _selectedIndex = 0;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }



  final prompt = '''replase this with your prompt''';
  // Initial prompt for the chatbot
  // You can customize this prompt to set the context for the chatbot
@override
void initState() {
  super.initState();
  setState(() => isLoading = true);

  fetchBedrockResponse(prompt, isInitial: true).then((response) {
    if (mounted) {
      setState(() {
        messages.add({'from': 'bot', 'text': response['response'] ?? 'empty response'});
        sessionId = response['session_id'];
        isLoading = false;
      });
      scrollToBottom();
    }
  }).catchError((e) {
    if (mounted) {
      setState(() {
        messages.add({'from': 'bot', 'text': 'Error connecting to server. Please try again.'});
        isLoading = false;
      });
      scrollToBottom();
    }
  });
}

  void sendMessage(String text) async {
  setState(() {
    messages.add({'from': 'user', 'text': text});
    isLoading = true;
  });

  _controller.clear(); 

  try {
    final response = await fetchBedrockResponse(text);
    if (mounted) {
      setState(() {
        messages.add({'from': 'bot', 'text': response['response'] ?? 'Empty response'});
        sessionId = response['session_id'];
        isLoading = false;
      });
    }
  } catch (e) {
    if (mounted) {
      setState(() {
        messages.add({'from': 'bot', 'text': 'Error connecting to server. Please try again.'});
        isLoading = false;
      });
    }
  }
}


  void _onNavTap(int index) {
  setState(() {
    _selectedIndex = index;
  });

  if (index == 0) {
    // Επαναφορά συνομιλίας
    setState(() {
      messages.clear();
      sessionId = null;
    });

    fetchBedrockResponse(prompt, isInitial: true).then((response) {
      if (mounted) {
        setState(() {
          messages.add({'from': 'bot', 'text': response['response'] ?? 'Empty response'});
          sessionId = response['session_id'];
        });
      }
    }).catchError((e) {
      if (mounted) {
        setState(() {
          messages.add({'from': 'bot', 'text': 'Error connecting to server. Please try again.'});
        });
      }
    });
  }
}


  Future<Map<String, String>> fetchBedrockResponse(String message, {bool isInitial = false}) async {
    try {
      final body = {
        'message': message,
        if (sessionId != null && !isInitial) 'session_id': sessionId,
      };
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/send-message'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        return {
          'response': responseBody['response']?.toString() ?? 'No response from server.',
          'session_id': responseBody['session_id']?.toString() ?? sessionId ?? '',
        };
      } else {
        return {
          'response': 'Error: Server responded with status ${response.statusCode}',
          'session_id': sessionId ?? ''
        };
      }
    } catch (e) {
      print('Error in fetchBedrockResponse: $e');
      return {
        'response': 'Σφάλμα σύνδεσης. Δοκιμάστε ξανά.',
        'session_id': sessionId ?? ''
      };
    }
  }

  Widget buildMessage(Map<String, String> message) {
    final isUser = message['from'] == 'user';
    final avatarAsset = isUser ? 'assets/user.png' : 'assets/chat-bots.png';

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: AssetImage(avatarAsset),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          SizedBox(width: 6),
          Flexible(
            child: Container(
              margin: EdgeInsets.symmetric(vertical: 4),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser ? Colors.black : Colors.grey[300],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                message['text']!,
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.black,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          SizedBox(width: 6),
          if (isUser)
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                image: DecorationImage(
                  image: AssetImage(avatarAsset),
                  fit: BoxFit.cover,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Row(
          children: [
            Icon(Icons.shield, color: Colors.black),
            SizedBox(width: 8),
            Text('Δήλωση', style: TextStyle(color: Colors.black)),
            Spacer(),
            Text(customerInfo.licensePlate, style: TextStyle(color: Colors.black)),
          ],
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.grey[100],
            child: Row(
              children: [
                Icon(Icons.location_on, size: 18, color: Colors.black),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    customerInfo.currentAddress,
                    style: TextStyle(fontSize: 14, color: Colors.black87),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(8),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return buildMessage(messages[index]);
              },
            ),
          ),
        if (isLoading)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                SizedBox(width: 12),
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text("Chatbot writing ...", style: TextStyle(color: Colors.grey[700])),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(30),
              ),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.mic_none_sharp),
                    onPressed: () {
                     
                    },
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Write a message...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      if (_controller.text.trim().isNotEmpty) {
                        sendMessage(_controller.text.trim());
                      }
                    },
                    child: Image.asset(
                      'assets/paper-plane.png',
                      width: 32,
                      height: 32,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNav(
        selectedIndex: _selectedIndex,
        onTabSelected: _onNavTap,
      ),
    );
  }
}