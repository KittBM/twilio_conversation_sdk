import 'package:flutter/material.dart';
import 'package:twilio_conversation_sdk/twilio_conversation_sdk.dart';

class ConversationList extends StatefulWidget {
  const ConversationList(this.identity, {super.key});

  final String identity;

  @override
  State<ConversationList> createState() => _ConversationListState();
}

class _ConversationListState extends State<ConversationList> {
  final _twilioConversationSdkPlugin = TwilioConversationSdk();
  late List conversationList = List.empty(growable: true);
  late List lastMessageList = List.empty(growable: true);
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    setState(() {
      isLoading = true;
    });
    listOfConversation();
  }

  Future<void> listOfConversation() async {
    var list = await _twilioConversationSdkPlugin.getConversations() ?? [];

    conversationList.clear();
    conversationList.addAll(list);
    print("Flutter$conversationList");
    for (dynamic conversation in conversationList) {
      var sid = conversation['sid'];
      if (sid != null) {
        //TODO unread msg count working

        /*var lastUnReadMessageCount = await _twilioConversationSdkPlugin.getUnReadMsgCount(
            conversationId: sid) ?? [];
        print("Flutter LastMessageUnReadCount: $lastUnReadMessageCount");*/

        var lastMessage = await _twilioConversationSdkPlugin.getLastMessages(
                conversationId: sid) ??
            [];
        print("Flutter LastMessage: $lastMessage");

        if (lastMessage.isNotEmpty) {
          // Extract the message body from the fetched last message
          var messageBody = lastMessage[0]['lastMessage'] ??
              'No message'; // Default if no body

          // Find and update the conversation in conversationList by matching sid
          int index = conversationList.indexWhere((c) => c['sid'] == sid);
          if (index != -1) {
            // Update the conversation with the last message
            conversationList[index]['lastMessage'] = messageBody;
          }
        }
      }
    }
    isLoading = false;

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 10,
        titleSpacing: 10,
        title: Text(widget.identity),
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop("data");
          },
          icon: const Icon(Icons.arrow_back_ios_new),
          iconSize: 30,
        ),
        actions: [
          IconButton(
            onPressed: () {
              listOfConversation();
            },
            icon: const Icon(Icons.refresh),
            iconSize: 30,
          ),
        ],
      ),
      body: Center(
        child: isLoading
            ? CircularProgressIndicator()
            : Padding(
                padding: const EdgeInsets.all(18.0),
                child: ListView.builder(
                  itemCount: conversationList.length,
                  itemBuilder: (context, index) {
                    int unreadIndex = 0;
                    var lastReadIndex =
                        conversationList.elementAt(index)['lastReadIndex'];
                    var lastMessageIndex =
                        conversationList.elementAt(index)['lastMessageIndex'];
                    if (lastMessageIndex != null && lastReadIndex != null) {
                      unreadIndex = lastMessageIndex - lastReadIndex;
                    }
                    var conversationName =
                        conversationList.elementAt(index)['conversationName'];
                    var lastMessage =
                        conversationList.elementAt(index)['lastMessage'];

                    return Card(
                        child: SizedBox(
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(conversationName),
                                  lastMessage != null
                                      ? Text(
                                          lastMessage,
                                          style: const TextStyle(
                                              color: Colors.blue,
                                              fontWeight: FontWeight.normal),
                                        )
                                      : const SizedBox(),
                                ],
                              ),
                            ),
                            unreadIndex != 0
                                ? Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: const BoxDecoration(
                                        color: Colors.black,
                                        shape: BoxShape.circle),
                                    child: Text(
                                      unreadIndex.toString(),
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold),
                                    ))
                                : Container()
                          ],
                        ),
                      ),
                    ));
                  },
                ),
              ),
      ),
    );
  }
}
