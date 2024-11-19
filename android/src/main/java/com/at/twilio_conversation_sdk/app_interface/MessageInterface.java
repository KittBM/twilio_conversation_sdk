package com.at.twilio_conversation_sdk.app_interface;

import com.twilio.conversations.Conversation;

import java.util.Map;

public interface MessageInterface {
    default void onMessageUpdate(Map message) {}
    default void onSynchronizationChanged(Map status) {}
}