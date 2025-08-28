# twilio_conversation_sdk

# Introduction

A Flutter plugin for [Twilio Conversations SDK](https://www.twilio.com/docs/conversations) which allows you to build engaging conversational messaging experiences for Android and iOS.

## Supported platforms
- Android
- iOS

## Features
- Generate Twilio Access Token(Only Android)
- Create new conversation
- Get list of conversations
- Fetch list of messages in the conversation
- Join an existing conversation
- Send Messages
- Listen to message update whenever new message is received
- Add participants in the conversation
- Remove participants from the conversation
- Get list of participants from the specific conversation
- Listen to access token expiration
- Update Read Messages
- Get Unread Message Count

## Example
Check out the [example](https://github.com/ALAlliancetek/twilio_conversation_sdk/tree/main/example)

## Usage
### Obtain an instance
```dart
final _twilioConversationSdkPlugin = TwilioConversationSdk();
```

### Generate token (Only Android)
```dart
// Use the Twilio helper libraries in your back end web services to create access tokens for both Android and iOS platform. However you can use this method to generate access token for Android.
final String? result = await _twilioConversationSdkPlugin.generateToken(accountSid:credentials['accountSid'],apiKey:credentials['apiKey'],apiSecret:credentials['apiSecret'],identity:credentials['identity'],serviceSid: credentials['serviceSid']);
```

### Initialize conversation client with the access token
```dart
/// Once you receive the access token from your back end web services, pass it to this method to authenticate the twilio user
final String result = await _twilioConversationSdkPlugin.initializeConversationClient(accessToken: accessToken);
```

### Create new conversation
```dart
final String? result = await _twilioConversationSdkPlugin.createConversation(conversationName:conversationName, identity: identity);
```

### Get list of conversations for logged in user
```dart
final List result = await _twilioConversationSdkPlugin.getConversations() ?? [];
```

### Get messages from the specific conversation
```dart
final  List result = await _twilioConversationSdkPlugin.getMessages(conversationId: conversationId) ?? [];
```

### Join an existing conversation
```dart
final String? result = await _twilioConversationSdkPlugin.joinConversation(conversationId:conversationId);
```

### Send message
```dart
final String? result = await _twilioConversationSdkPlugin.sendMessage(message:enteredMessage,conversationId:conversationId);
```

### Add participant in a conversation
```dart
final String? result = await _twilioConversationSdkPlugin.addParticipant(participantName:participantName,conversationId:conversationId);
```
### Remove participant from a conversation
```dart
final String? result = await _twilioConversationSdkPlugin.removeParticipant(participantName:participantName,conversationId:conversationId);
```

### Get participants from the specific conversation
```dart
final  List result = await _twilioConversationSdkPlugin.getParticipants(conversationId: conversationId) ?? [];
```

### Subscribe to message update
```dart
/// Use this method to listen to newly added messages in a conversation
_twilioConversationSdkPlugin.subscribeToMessageUpdate(conversationSid:widget.conversationSid);
_twilioConversationSdkPlugin.onMessageReceived.listen((event) {
});
```

### Unsubscribe to message update
```dart
/// Use this method to receive newly added messages in a conversation
_twilioConversationSdkPlugin.unSubscribeToMessageUpdate(conversationSid: widget.conversationSid);
```

### Listen to access token expiration
```dart
_twilioConversationSdkPlugin.onTokenStatusChange.listen((tokenData) {
if (tokenData["statusCode"] == 401){
     generateAndUpdateAccessToken()
   }
});
```
### Update access token
```dart
/// Call this method if your access token is expired or is about to expire.
/// Regenerate the access token in your backend and use this method to update the token.
final Map? result = await _twilioConversationSdkPlugin.updateAccessToken(accessToken:accessToken);
```

### Get Unread Message Count
```dart
/// Call this method whenever you want to receive unread count of conversation
final Map? result = await _twilioConversationSdkPlugin.getUnReadMsgCount(conversationId: widget.conversationSid);
```

## License
[MIT License](https://github.com/ALAlliancetek/twilio_conversation_sdk/blob/main/LICENSE)


