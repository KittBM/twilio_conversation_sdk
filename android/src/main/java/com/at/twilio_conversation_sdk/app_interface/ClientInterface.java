package com.at.twilio_conversation_sdk.app_interface;

import java.util.Map;

public interface ClientInterface {
    default void onClientSynchronizationChanged(Map status) {}
}