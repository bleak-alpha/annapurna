import SockJS from "sockjs-client";
import { Client } from "@stomp/stompjs";

let stompClient = null;

export const connectWebSocket = (onMessageReceived) => {
    const socket = new SockJS("http://localhost:8080/ws");
    stompClient = new Client({
    webSocketFactory: () => socket,
    reconnectDelay: 5000,

    onConnect: () => {
      console.log("✅ WebSocket Connected");
      stompClient.subscribe("/topic/orders", (message) => {
        console.log("Received message:", message.body);
        if (message.body) {
          const data = JSON.parse(message.body);
          onMessageReceived(data);
        }
      });
    },

    onStompError: (frame) => {
      console.error(frame);
    },
  });

  stompClient.activate();
};


export const sendOrderUpdate = (order) => {
    console.log("Publishing:", order);

    if (stompClient && stompClient.connected) {
        stompClient.publish({
            destination: "/app/messagebroadcast",
            body: JSON.stringify(order),
        });
        console.log("Published : ", order);
    } else {
        console.log("STOMP not connected");
    }
};

export const disconnectWebSocket = () => {
  if (stompClient) {
    stompClient.deactivate();
  }
};