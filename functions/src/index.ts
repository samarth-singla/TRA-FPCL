/**
 * Firebase Cloud Functions for TRA FPCL FCM Notifications
 * Handles sending push notifications using FCM HTTP v1 API
 */

import {onCall} from "firebase-functions/v2/https";
import * as admin from "firebase-admin";
import * as logger from "firebase-functions/logger";

admin.initializeApp();

// ============================================================
// Send Chat Message Notification
// ============================================================
export const sendChatNotification = onCall(async (request) => {
  const {fcmToken, senderName, message, conversationId} = request.data;

  // Validate input
  if (!fcmToken || !senderName || !message || !conversationId) {
    throw new Error("Missing required parameters");
  }

  logger.info("Sending chat notification", {senderName, conversationId});

  try {
    const payload = {
      token: fcmToken,
      notification: {
        title: senderName,
        body: message,
      },
      data: {
        type: "chat_message",
        conversation_id: conversationId,
        sender_name: senderName,
      },
      android: {
        priority: "high" as const,
        notification: {
          channelId: "high_importance_channel",
          sound: "default",
        },
      },
    };

    const response = await admin.messaging().send(payload);
    logger.info("Chat notification sent successfully", {messageId: response});
    return {success: true, messageId: response};
  } catch (error) {
    logger.error("Error sending chat notification:", error);
    throw new Error("Failed to send notification");
  }
});

// ============================================================
// Send Advisory Request Notification to Multiple SMEs
// ============================================================
export const sendAdvisoryNotification = onCall(async (request) => {
  const {smeTokens, raeName, topic, conversationId, district} = request.data;

  if (!smeTokens || !Array.isArray(smeTokens) || smeTokens.length === 0) {
    throw new Error("Missing or invalid SME tokens");
  }

  logger.info("Sending advisory notifications", {
    raeName,
    smeCount: smeTokens.length,
    district,
  });

  try {
    const messages = smeTokens.map((token: string) => ({
      token,
      notification: {
        title: "New Advisory Request 🔔",
        body: `${raeName} needs help: ${topic}`,
      },
      data: {
        type: "advisory_request",
        conversation_id: conversationId,
        rae_name: raeName,
        district: district || "",
      },
      android: {
        priority: "high" as const,
        notification: {
          channelId: "high_importance_channel",
          sound: "default",
        },
      },
    }));

    const response = await admin.messaging().sendEach(messages);

    logger.info("Advisory notifications sent", {
      successCount: response.successCount,
      failureCount: response.failureCount,
    });

    return {
      success: true,
      successCount: response.successCount,
      failureCount: response.failureCount,
    };
  } catch (error) {
    logger.error("Error sending advisory notifications:", error);
    throw new Error("Failed to send notifications");
  }
});

// ============================================================
// Send Advisory Accepted Notification
// ============================================================
export const sendAdvisoryAcceptedNotification = onCall(async (request) => {
  const {fcmToken, smeName, conversationId} = request.data;

  if (!fcmToken || !smeName || !conversationId) {
    throw new Error("Missing required parameters");
  }

  logger.info("Sending advisory accepted notification", {smeName});

  try {
    const payload = {
      token: fcmToken,
      notification: {
        title: "Advisory Request Accepted! ✅",
        body: `${smeName} has accepted your request and is ready to help.`,
      },
      data: {
        type: "advisory_accepted",
        conversation_id: conversationId,
        sme_name: smeName,
      },
      android: {
        priority: "high" as const,
        notification: {
          channelId: "high_importance_channel",
          sound: "default",
        },
      },
    };

    const response = await admin.messaging().send(payload);
    logger.info("Advisory accepted notification sent", {messageId: response});
    return {success: true, messageId: response};
  } catch (error) {
    logger.error("Error sending advisory accepted notification:", error);
    throw new Error("Failed to send notification");
  }
});

// ============================================================
// Send Order Dispatch Notification
// ============================================================
export const sendOrderNotification = onCall(async (request) => {
  const {fcmToken, orderId, productName} = request.data;

  if (!fcmToken || !orderId || !productName) {
    throw new Error("Missing required parameters");
  }

  logger.info("Sending order dispatch notification", {orderId, productName});

  try {
    const payload = {
      token: fcmToken,
      notification: {
        title: "Order Dispatched! 📦",
        body: `Your order for ${productName} has been dispatched.`,
      },
      data: {
        type: "order_dispatched",
        order_id: orderId,
      },
      android: {
        priority: "high" as const,
        notification: {
          channelId: "high_importance_channel",
          sound: "default",
        },
      },
    };

    const response = await admin.messaging().send(payload);
    logger.info("Order notification sent successfully", {messageId: response});
    return {success: true, messageId: response};
  } catch (error) {
    logger.error("Error sending order notification:", error);
    throw new Error("Failed to send notification");
  }
});
