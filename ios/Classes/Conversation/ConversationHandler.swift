import UIKit
import TwilioConversationsClient
import Flutter
import Foundation

class ConversationsHandler: NSObject, TwilioConversationsClientDelegate {
    
    
    
    // MARK: Conversations variables
   private var client: TwilioConversationsClient?
    var lastReadIndex: NSNumber?
    weak var messageDelegate: MessageDelegate?
    weak var clientDelegate: ClientDelegate?
//    weak var tokenDelegate:TokenDelegate?
    public var messageSubscriptionId: String = ""
    var tokenEventSink: FlutterEventSink?

    
    
//    MARK: raw
    func conversationsClient(_ client: TwilioConversationsClient, conversation: TCHConversation,
                    messageAdded message: TCHMessage) {
        
        
        guard client.synchronizationStatus == .completed else {
            return
        }
       
        self.getMessageInDictionary(message) { [self] messageDictionary in
            if let messageDict = messageDictionary {
                var updatedMessage: [String: Any] = [:]
                updatedMessage["conversationId"] = conversation.sid ?? ""
                updatedMessage["message"] = messageDict
                //MARK: Update Index
                let computedIndex: NSNumber = {
                    if let lastRead = lastReadIndex {
                        return lastRead
                    } else if let lastMessageIndex = conversation.lastMessageIndex {
                        // Extract the value of lastMessageIndex and add 1
                        return NSNumber(value: lastMessageIndex.intValue + 1)
                    } else {
                        return 0
                    }
                }()

                conversation.setLastReadMessageIndex(computedIndex) { result, index in
                    print("setLastReadMessageIndex \(result.description)")
                }

                self.messageDelegate?.onMessageUpdate(message: updatedMessage, messageSubscriptionId: self.messageSubscriptionId)
                
//                print("lastReadIndex \(conversation.lastMessageIndex)")

            }
        }
    }
    
    func registerFCMToken(token: String,completion: @escaping (_ success : Bool) -> Void){
        
         let data = token.hexToData
//        print(data) // Output: 5 bytes
      
        
        self.client?.register(withNotificationToken: data ?? Data(), completion: { result in
             if result.isSuccessful {
                 completion(true)
             }
             print("Twilio Notification Token Set: \(result) with token \(token)")
             print("Device push token registration was\(result.isSuccessful ? "" : " not") successful")
         })
     }
   
    
    func conversationsClient(_ client: TwilioConversationsClient, conversation: TCHConversation, synchronizationStatusUpdated status: TCHConversationSynchronizationStatus) {
//        self.messageDelegate?.onSynchronizationChanged(status: ["status" : conversation.synchronizationStatus.rawValue])
//        print("StatusConversations \(conversation.synchronizationStatus.rawValue) ")
        
    }
    
    func conversationsClientTokenWillExpire(_ client: TwilioConversationsClient) {
        print("Access token will expire.->\(String(describing: tokenEventSink))")
        var tokenStatusMap: [String: Any] = [:]
        tokenStatusMap["statusCode"] = 200
        tokenStatusMap["message"] = Strings.accessTokenWillExpire
        tokenEventSink?(tokenStatusMap)
    }
    
    
    func conversationsClient(_ client: TwilioConversationsClient, synchronizationStatusUpdated status: TCHClientSynchronizationStatus) {
        
        print("statusclient->\(status.hashValue)--\(client.synchronizationStatus)")
       
        guard status == .completed else {
            return
        }
        self.clientDelegate?.onClientSynchronizationChanged(status: ["status":client.synchronizationStatus.rawValue])
        print("StatusClient \(client.synchronizationStatus.rawValue) ")

//            checkConversationCreation { (_, conversation) in
//               if let conversation = conversation {
//                   self.joinConversation(conversation)
//               } else {
//                   self.createConversation { (success, conversation) in
//                       if success, let conversation = conversation {
//                           self.joinConversation(conversation)
//                       }
//                   }
//               }
//            }
        }
    
    
    
    func conversationsClientTokenExpired(_ client: TwilioConversationsClient) {
        print("Access token expired.\(String(describing: tokenEventSink))")
        var tokenStatusMap: [String: Any] = [:]
        tokenStatusMap["statusCode"] = 401
        tokenStatusMap["message"] = Strings.accessTokenExpired
        tokenEventSink?(tokenStatusMap)
    }
    
    public func updateAccessToken(accessToken:String,completion: @escaping (TCHResult?) -> Void) {
        self.client?.updateToken(accessToken, completion: { tchResult in
            completion(tchResult)
        })
    }

 

    func sendMessage(conversationId: String,
                     messageText: String,
                      attributes: [String: Any],
                      completion: @escaping (TCHResult, TCHMessage?) -> Void) {
        // Fetch the conversation using the provided ID
        self.getConversationFromId(conversationId: conversationId) { conversation in
//            if let error = error {
//                print("Error fetching conversation: \(error.localizedDescription)")
//                result(.failure(error))
//                return
//            }
        
            
            // Convert attributes dictionary into Attributes type

                let attributesObject : TCHJsonAttributes = TCHJsonAttributes(dictionary: attributes)
                
                // Prepare and send the message
                conversation?.prepareMessage()
                    .setAttributes(attributesObject, error: nil)
                    .setBody(messageText).buildAndSend(completion: { tchResult, tchMessages in
                    completion(tchResult,tchMessages)
                })
                    
          
        }
    }

    
    func loginWithAccessToken(_ token: String, completion: @escaping (TCHResult?) -> Void) {
        // Set up Twilio Conversations client
        TwilioConversationsClient.conversationsClient(withToken: token,
         properties: nil,
         delegate: self) { (result, client) in
           self.client = client
            self.clientDelegate?.onClientSynchronizationChanged(status: ["status" : client?.synchronizationStatus.rawValue ?? -1])
            print("\(client?.synchronizationStatus.rawValue ?? -1)")
//            self.client?.delegate?.conversationsClient?(<#T##client: TwilioConversationsClient##TwilioConversationsClient#>, synchronizationStatusUpdated: TCHClientSynchronizationStatus)
            completion(result)
        }
    }

    func shutdown() {
        if let client = client {
            client.delegate = nil
            client.shutdown()
            self.client = nil
        }
    }

    func createConversation(uniqueConversationName:String,_ completion: @escaping (Bool, TCHConversation?,String) -> Void) {
        guard let client = client else {
            return
        }
        // Create the conversation if it hasn't been created yet
        let options: [String: Any] = [
            TCHConversationOptionUniqueName: uniqueConversationName,
            TCHConversationOptionFriendlyName: uniqueConversationName,
            ]
        client.createConversation(options: options) { (result, conversation) in
            if result.isSuccessful {
                completion(result.isSuccessful, conversation,result.resultText ?? "Conversation created.")
            } else {
                completion(false, conversation,result.error?.localizedDescription ?? "Conversation NOT created.")
            }
        }
    }

    func getConversations(_ completion: @escaping([TCHConversation]) -> Void) {
        guard let client = client else {
            return
        }
        guard client.synchronizationStatus == .completed else {
            return
        }

        completion(client.myConversations() ?? [])
    }
    
    func getParticipants(conversationId:String,_ completion: @escaping([TCHParticipant]) -> Void) {
        self.getConversationFromId(conversationId: conversationId) { conversation in
            completion(conversation?.participants() ?? [])
        }
    }
    
    func addParticipants(conversationId:String,participantName:String,_ completion: @escaping(TCHResult?) -> Void) {
        self.getConversationFromId(conversationId: conversationId) { conversation in
            conversation?.addParticipant(byIdentity: participantName, attributes: nil,completion: { status in
                completion(status)
            })
        }
    }
    
    func removeParticipants(conversationId:String,participantName:String,_ completion: @escaping(TCHResult?) -> Void) {
        self.getConversationFromId(conversationId: conversationId) { conversation in
            conversation?.removeParticipant(byIdentity: participantName,completion: { status in
                print("status->\(status)")
                completion(status)
            })
        }
    }


    func joinConversation(_ conversation: TCHConversation,_ completion: @escaping(String?) -> Void) {
        if conversation.status == .joined {
//            self.loadPreviousMessages(conversation,1000) { listOfMessages in
//
//            }
        } else {
            conversation.join(completion: { result in
                if result.isSuccessful {
//                    self.loadPreviousMessages(conversation,1000) { listOfMessages in
//
//                    }
                }
            })
        }
        completion(conversation.sid)
    }
    
    func getConversationFromId(conversationId:String,_ completion: @escaping(TCHConversation?) -> Void){
        guard let client = client else {
            return
        }
        guard client.synchronizationStatus == .completed else {
            return
        }
        client.conversation(withSidOrUniqueName: conversationId) { (result, conversation) in
            if let conversationFromSid = conversation {
                print("message readed")
                completion(conversationFromSid)
            }
        }
    }
    
    func loadPreviousMessages(_ conversation: TCHConversation,_ messageCount: UInt?,_ completion: @escaping([[String: Any]]?) -> Void) {
        print("synchronizationStatus->\(client?.synchronizationStatus == .completed)")
        guard client?.synchronizationStatus == .completed else {
            return
        }
        var listOfMessagess: [[String: Any]] = []
        conversation.getLastMessages(withCount: messageCount ?? 1000) { (result, messages) in
            if let messagesList = messages {
                messagesList.forEach { message in
                    self.getMessageInDictionary(message) { messageDictionary in
                        if let messageDict = messageDictionary {
                            listOfMessagess.append(messageDict)
                        }
                    }
                }
                completion(listOfMessagess)
            }
        }
    }
    
    func getLastMessage(_ conversation: TCHConversation,_ messageCount: UInt?,_ completion: @escaping([[String: Any]]?) -> Void) {
        print("synchronizationStatus->\(client?.synchronizationStatus == .completed)")
        guard client?.synchronizationStatus == .completed else {
            return
        }
        var listOfMessagess: [[String: Any]] = []
        conversation.getLastMessages(withCount: messageCount ?? 1) { (result, messages) in
            if let messagesList = messages {
                messagesList.forEach { message in
                    self.getMessageInDictionary(message) { messageDictionary in
                        if let messageDict = messageDictionary {
                            listOfMessagess.append(messageDict)
                        }
                    }
                }
                completion(listOfMessagess)
            }
        }
    }
    
    
    func getUnReadMsgCount(conversationId: String, _ completion: @escaping ([[String: Any]]?) -> Void) {
        var list: [[String: Any]] = []
        
        self.getConversationFromId(conversationId: conversationId) { conversation in
            var dictionary: [String: Any] = [:]
            conversation?.getUnreadMessagesCount(completion: { result, count in
                if result.isSuccessful {
                    list.removeAll()
                    print("Total Unread Count \(count)")
                    dictionary["sid"] = conversationId
                    dictionary["unReadCount"] = count
                    list.append(dictionary)
                completion(list)
                }
                else{
                    print("No Unread Count")
                    dictionary["sid"] = conversationId
                    dictionary["unReadCount"] = 0
                    completion(list)
                }
            })
        }
    }


    
    func getMessageInDictionary(_ message:TCHMessage,_ completion: @escaping([String: Any]?) -> Void) {
        var dictionary: [String: Any] = [:]
        var attachedMedia: [[String: Any]] = []
        dictionary["sid"] = message.participantSid
        dictionary["author"] = message.author
        dictionary["body"] = message.body
            do {
                let jsonData = try JSONSerialization.data(withJSONObject: message.attributes()!.dictionary ?? Dictionary(), options: .prettyPrinted)
                if let jsonString = String(data: jsonData, encoding: .utf8) {
                    print(jsonString)
                    dictionary["attributes"] = jsonString

                }
            } catch {
                print("Error converting dictionary to string: \(error.localizedDescription)")
                dictionary["attributes"] = ""

            }
        dictionary["lastMessageDate"] = formatLastMessageDateISO8601(lastMessageDateString: message.dateUpdated?.description)
        dictionary["dateCreated"] = message.dateCreated
        dictionary["lastMessage"] = message.body
        completion(dictionary)
    }
}




func formatLastMessageDateISO8601(lastMessageDateString: String?) -> String? {
    // Create an ISO8601 date formatter for the input
    let inputFormatter = ISO8601DateFormatter()
    inputFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    
    // Create a standard date formatter for the desired output
    let outputFormatter = DateFormatter()
    outputFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
    outputFormatter.timeZone = TimeZone(abbreviation: "UTC") // Convert to UTC
    
    // Parse the input date and format it to the desired output
    if let date = inputFormatter.date(from: lastMessageDateString ?? "") {
        let outputDateString = outputFormatter.string(from: date)
        print("lastMessageDateTime->\(outputDateString)")
        return outputDateString
    } else {
        print("Failed to parse date string")
        return nil
    }
}

// Example usage:
//if let formattedDate = formatLastMessageDateISO8601(lastMessageDateString: "2024-11-22T12:16:21.780Z") {
//    print("Formatted Date: \(formattedDate)")
//} else {
//    print("Date parsing failed.")
//}
extension String {
    var hexToData: Data? {
        // Ensure the string contains a valid hex format and even number of characters
        guard self.count % 2 == 0,
              self.range(of: "^[0-9a-fA-F]+$", options: .regularExpression) != nil else {
            return nil
        }

        // Convert the hex string to `Data`
        var data = Data()
        var index = startIndex
        while index < endIndex {
            let nextIndex = self.index(index, offsetBy: 2)
            if let byte = UInt8(self[index..<nextIndex], radix: 16) {
                data.append(byte)
            } else {
                return nil // Return nil if conversion fails
            }
            index = nextIndex
        }
        return data
    }
}
