//
//  MessageDelegate.swift
//  twilio_conversation_sdk
//
//  Created by Parth Patel on 19/11/24.
//

protocol MessageDelegate: AnyObject {
    func onMessageUpdate(message: [String: Any],  messageSubscriptionId : String)
    func onSynchronizationChanged(status: [String: Any])
}
