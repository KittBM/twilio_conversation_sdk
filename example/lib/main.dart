import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jiffy/jiffy.dart';
import 'package:twilio_conversation_sdk/twilio_conversation_sdk.dart';
import 'package:twilio_conversation_sdk_example/conversation_list.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Twilio Conversation SDK',
      home: Conversation(),
    );
  }
}

class Conversation extends StatefulWidget {
  const Conversation({super.key});

  @override
  State<Conversation> createState() => _ConversationState();
}

class _ConversationState extends State<Conversation> {
  static var accountSid = '';
  static var apiKey = '';
  static var apiSecret = '';
  static var serviceSid =
      ''; // Conversation Service SID
  static var identity = '';
  static var participantIdentity = '';
  static var pushSid = '';
  String? accessToken = "";

  final _twilioConversationSdkPlugin = TwilioConversationSdk();

  //var conversationId = "";
  //var conversationId = "";
  var conversationId = "";
  var conversationName = "";
  List messages = List.empty(growable: true);
  TextEditingController message = TextEditingController();
  final ScrollController _controller = ScrollController();
  final double _height = 100.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      _animateToIndex(messages.length);
    });
  }

  void getAccessToken(String accountSid, String apiKey, String apiSecret,
      String identity, String serviceSid, String pushSid) async {
    accessToken = await _twilioConversationSdkPlugin.generateToken(
        accountSid: accountSid,
        apiKey: apiKey,
        apiSecret: apiSecret,
        identity: identity,
        serviceSid: serviceSid,
        pushSid: pushSid);
    final String? resultInitialization = await _twilioConversationSdkPlugin
        .initializeConversationClient(accessToken: accessToken!);
    if (resultInitialization!.isNotEmpty) {
      //final String? resultFCM = await _twilioConversationSdkPlugin.registerFCMToken(fcmToken: "d0ixyx8QTY6MzTeVeDcKFB:APA91bHJysESFNrS_QDUdXvFjxmUmHxAA2u5zWWqVgDv6kjaZdNTandmiXl2E2g88Dha-1hpNX_Qf5YwTYwp7nHzSMoHsTItcl2kLq1Z4BVfx-mc2QkpXfE");
      //print(resultFCM);

      _twilioConversationSdkPlugin.onClientSyncStatusChanged.listen((event) {
        print("Client Status Received ${event.toString()}");
        if (event['status'] != null) {
          if (event['status'] == 2) {
            checkOrCreateConversation();
          }
        }
      });
    }
    setState(() {});
  }

  checkOrCreateConversation() async {
    List conversationList =
        await _twilioConversationSdkPlugin.getConversations() ?? [];
    print("Conversation List $conversationList");
    if (conversationList.isNotEmpty) {
      bool isParticipantFound = false;
      for (Map conversation in conversationList) {
        print("Conversation $conversation");
        List participantList = await _twilioConversationSdkPlugin
                .getParticipants(conversationId: conversation["sid"]) ??
            [];
        for (Map participant in participantList) {
          print("Participant $participant");
          if (participant["identity"] == participantIdentity) {
            isParticipantFound = true;
            conversationId = conversation["sid"];
            conversationName = conversation["conversationName"];
            subscribe();
            break;
          }
        }
        if (isParticipantFound) {
          break;
        }
      }
      if (!isParticipantFound) {
        createConversation();
      }
    } else {
      createConversation();
    }
  }

  unsubscribe() {
    _twilioConversationSdkPlugin.unSubscribeToMessageUpdate(
        conversationSid: conversationId);
  }

  subscribe() {
    _twilioConversationSdkPlugin.subscribeToMessageUpdate(
        conversationSid: conversationId);
    _twilioConversationSdkPlugin.onMessageReceived.listen((event) async {
      if (event['status'] != null) {
        print("Conversation Status Received ${event.toString()}");
        if (event['status'] == 3) {
          await getAllMessages();
        }
      } else if (event['author'] != null) {
        print("Conversation Message Received ${event.toString()}");
        messages.add(event);
        _animateToIndex(messages.length);
      }
      setState(() {});
    });
    setState(() {});
  }

  createConversation() async {
    //String timeStamp = DateTime.now().toString();
    //String conversationName = "Flutter - $timeStamp";
    String conversationFriendlyName = "$identity-$participantIdentity";
    conversationId = (await _twilioConversationSdkPlugin.createConversation(
        conversationName: conversationFriendlyName, identity: identity))!;
    print("Result $conversationId");
    conversationName = conversationFriendlyName;
    joinConversation();
    addParticipant();

    subscribe();
  }

  joinConversation() async {
    String? joinResult = (await _twilioConversationSdkPlugin.joinConversation(
        conversationId: conversationId))!;
    print("Result $joinResult");
  }

  sendMessage({bool isSendAttribute = false}) async {
    String timeStamp = DateTime.now().toString();
    Map<String, String> attribute;
    if (isSendAttribute) {
      attribute = {
        "body": message.text.toString().trim(),
        "url": "http://www.google.com",
        "cardId": timeStamp
      };
    } else {
      attribute = {"body": message.text.toString().trim(), "cardId": timeStamp};
    }

    final String? sendMessage = await _twilioConversationSdkPlugin.sendMessage(
        conversationId: conversationId,
        message: message.text.toString().trim(),
        attribute: attribute);
    print("Result $sendMessage");
    message.text = "";
    setState(() {});
  }

  getAllMessages() async {
    print("Get Message for $conversationId");
    messages.clear();
    var messageList = await _twilioConversationSdkPlugin.getMessages(
            conversationId: conversationId) ??
        [];
    messages.addAll(messageList);
    print("Messages $messages");
    setState(() {});
    Future.delayed(const Duration(milliseconds: 500));
    _animateToIndex(messages.length);
  }

  addParticipant() async {
    final String? addSecondParticipantConversation =
        await _twilioConversationSdkPlugin.addParticipant(
            conversationId: conversationId,
            participantName: participantIdentity);
    print("Result Second $addSecondParticipantConversation");
    unsubscribe();
    subscribe();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: accessToken!.isNotEmpty
          ? Padding(
              padding: const EdgeInsets.only(bottom: 50),
              child: FloatingActionButton(
                // isExtended: true,
                backgroundColor: Colors.black,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) {
                        return ConversationList(identity);
                      },
                    ),
                  ).then((data) {
                    subscribe();
                  });
                  unsubscribe();
                },
                // isExtended: true,
                child: const Icon(
                  Icons.chat,
                  color: Colors.white,
                ),
              ),
            )
          : Container(),
      appBar: AppBar(
        elevation: 10,
        titleSpacing: 10,
        leading: participantIdentity.isNotEmpty
            ? Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                    color: Colors.black, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(
                  participantIdentity.substring(0, 1),
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 25),
                ))
            : Container(),
        title: Text(identity.isEmpty
            ? "Twilio Conversation SDK"
            : "$participantIdentity - $conversationName"),
        actions: [
          accessToken!.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    getAllMessages();
                  },
                  icon: const Icon(Icons.refresh),
                  iconSize: 30,
                )
              : Container(),
        ],
      ),
      body: Center(
        child: Container(
          color: Colors.black12,
          child: Column(
            children: [
              accessToken!.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        onChanged: (value) {
                          identity = value;
                        },
                        decoration: const InputDecoration(
                            labelText: 'Enter your identity'),
                      ),
                    )
                  : Container(),
              accessToken!.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        onChanged: (value) {
                          participantIdentity = value;
                        },
                        decoration: const InputDecoration(
                            labelText: 'Enter participant identity'),
                      ),
                    )
                  : Container(),
              accessToken!.isEmpty
                  ? ElevatedButton(
                      onPressed: () {
                        if (identity.isNotEmpty) {
                          getAccessToken(accountSid, apiKey, apiSecret,
                              identity, serviceSid, pushSid);
                        }
                      },
                      child: Text("Get Access Token"),
                    )
                  : Container(),
              Expanded(
                  child: messages.isNotEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ListView.builder(
                            controller: _controller,
                            shrinkWrap: true,
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              return getMessageView(
                                  messages[index]["attributes"],
                                  messages[index]["body"],
                                  messages[index]["author"],
                                  messages[index]["dateCreated"]);
                            },
                          ),
                        )
                      : const Center(
                          child: Text(
                            "No message yet",
                            style: TextStyle(fontSize: 16, color: Colors.blue),
                          ),
                        )),
              accessToken!.isNotEmpty
                  ? Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.blueGrey,
                              borderRadius: BorderRadius.circular(32),
                            ),
                            child: Row(
                              children: [
                                Flexible(
                                  child: TextField(
                                    controller: message,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      hintText: 'Message',
                                      hintStyle: TextStyle(color: Colors.white),
                                      contentPadding: EdgeInsets.only(
                                          left: 15,
                                          bottom: 11,
                                          top: 11,
                                          right: 15),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () async {
                                    if (message.text.isNotEmpty) {
                                      sendMessage();
                                    } else {
                                      showAlert("Please type your message");
                                    }
                                  },
                                  icon: const Icon(
                                    Icons.send,
                                    color: Colors.white,
                                  ),
                                  iconSize: 30,
                                ),
                              ],
                            ),
                          ),
                        ),
                        Container(
                          decoration: const BoxDecoration(
                              color: Colors.black, shape: BoxShape.circle),
                          alignment: Alignment.center,
                          child: IconButton(
                            onPressed: () async {
                              if (message.text.isNotEmpty) {
                                sendMessage(isSendAttribute: true);
                              } else {
                                showAlert("Please type your message");
                              }
                            },
                            icon: const Icon(
                              Icons.attach_file,
                              color: Colors.white,
                            ),
                            iconSize: 30,
                          ),
                        ),
                      ],
                    )
                  : Container(),
            ],
          ),
        ),
      ),
    );
  }

  getMessageView(String attribute, String message, String author, String date) {
    DateTime tempDate = DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'").parse(date);
    String timeAgo = Jiffy.parseFromDateTime(tempDate).fromNow();

    if (attribute.contains("url")) {
      Map<String, String> attributeModel = Map.castFrom(json.decode(attribute));
      //print(valueMap.runtimeType);
      if (attributeModel['url'] != null) {
        return Align(
          alignment:
              author == identity ? Alignment.centerRight : Alignment.centerLeft,
          child: Card(
            margin: const EdgeInsets.all(10),
            color: author == identity ? Colors.blue : Colors.black,
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: SizedBox(
                width: 100,
                height: 100,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        textAlign: TextAlign.center,
                        attributeModel['url']!,
                        style: TextStyle(
                            color: author == identity
                                ? Colors.white
                                : Colors.white,
                            fontSize: 14),
                      ),
                    ),
                    Text(
                      textAlign: TextAlign.end,
                      timeAgo,
                      style: TextStyle(
                          color:
                              author == identity ? Colors.white : Colors.white,
                          fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      } else {
        return Align(
          alignment:
              author == identity ? Alignment.centerRight : Alignment.centerLeft,
          child: Card(
            margin: const EdgeInsets.all(10),
            child: Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    message,
                    style: TextStyle(
                        color: author == identity ? Colors.blue : Colors.black,
                        fontSize: 14),
                  ),
                  Text(
                    textAlign: TextAlign.end,
                    timeAgo,
                    style: TextStyle(
                        color: author == identity ? Colors.blue : Colors.black,
                        fontSize: 10),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    } else {
      return Align(
        alignment:
            author == identity ? Alignment.centerRight : Alignment.centerLeft,
        child: Card(
          margin: const EdgeInsets.all(10),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  message,
                  style: TextStyle(
                      color: author == identity ? Colors.blue : Colors.black,
                      fontSize: 14),
                ),
                Text(
                  timeAgo,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                      color: author == identity ? Colors.blue : Colors.black,
                      fontSize: 10),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  void _animateToIndex(int index) {
    if (_controller.hasClients) {
      _controller.animateTo(
        index * _height,
        duration: const Duration(seconds: 2),
        curve: Curves.fastOutSlowIn,
      );
    }
  }

  void showAlert(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
    ));
  }
}
