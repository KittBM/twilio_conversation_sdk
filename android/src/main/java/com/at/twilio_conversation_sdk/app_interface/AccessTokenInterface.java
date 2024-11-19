package com.at.twilio_conversation_sdk.app_interface;

import java.util.Map;

public interface AccessTokenInterface {
    default void onTokenStatusChange(Map status) {}
}