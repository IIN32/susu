import * as admin from "firebase-admin";
import { onDocumentCreated, onDocumentUpdated } from "firebase-functions/v2/firestore";

admin.initializeApp();

// --- Trigger Functions for Notifications ---

// 1. Notify Admins of New Withdrawal Request
export const onWithdrawalRequest = onDocumentCreated("withdrawals/{requestId}", async (event) => {
    const snapshot = event.data;
    if (!snapshot) return;

    const data = snapshot.data();

    // Notify Admins via Topic
    const payload = {
        notification: {
            title: "New Withdrawal Request",
            body: `Account ${data.susuAccountId} has requested GH¢${data.amount}.`,
        },
        topic: "new_withdrawal",
    };

    try {
        await admin.messaging().send(payload);
        console.log("Successfully sent admin notification.");
    } catch (error) {
        console.error("Error sending admin notification:", error);
    }
});

// 2. Notify User of Status Update on Their Withdrawal
export const onWithdrawalUpdate = onDocumentUpdated("withdrawals/{requestId}", async (event) => {
    const change = event.data;
    if (!change) return;

    const newData = change.after.data();
    const oldData = change.before.data();

    // Only send notification if status has changed
    if (newData.status === oldData.status) return;

    const accountId = newData.susuAccountId;
    const status = newData.status; // e.g., 'processing', 'approved', 'rejected'

    // Find the user linked to this susu account
    const usersRef = admin.firestore().collection('users');
    const userQuery = await usersRef.where('susuAccountId', '==', accountId).limit(1).get();

    if (userQuery.empty) return;

    const userDoc = userQuery.docs[0];
    const fcmToken = userDoc.data().fcmToken;

    if (!fcmToken) return;

    // Custom messages based on status
    let title = "Withdrawal Update";
    let body = `Your request status has changed to: ${status.toUpperCase()}`;

    if (status === 'processing') {
        title = "Request Processing";
        body = `Your withdrawal request for GH¢${newData.amount} is now being processed by an admin.`;
    } else if (status === 'approved') {
        title = "Request Approved! ✅";
        body = `Great news! Your withdrawal of GH¢${newData.amount} has been approved.`;
    } else if (status === 'rejected') {
        title = "Request Declined ❌";
        body = `Your withdrawal request for GH¢${newData.amount} was declined. Please check the app for details.`;
    }

    const payload = {
        notification: {
            title: title,
            body: body,
        },
        token: fcmToken,
    };

    try {
        await admin.messaging().send(payload);
        console.log(`Successfully sent notification to user ${userDoc.id}`);
    } catch (error) {
        console.error("Error sending notification:", error);
    }
});
