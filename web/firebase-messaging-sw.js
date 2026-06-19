importScripts("https://www.gstatic.com/firebasejs/10.7.1/firebase-app-compat.js");
importScripts("https://www.gstatic.com/firebasejs/10.7.1/firebase-messaging-compat.js");

firebase.initializeApp({
  apiKey: "AIzaSyCNLjShoGXxW6wmC930HNg8aiO1JzPi6vw",
  appId: "1:602563067692:web:a62b881ad36ce6d3b73689",
  messagingSenderId: "602563067692",
  projectId: "diacareai-e8700",
  authDomain: "diacareai-e8700.firebaseapp.com",
  databaseURL: "https://diacareai-e8700-default-rtdb.firebaseio.com",
  storageBucket: "diacareai-e8700.firebasestorage.app"
});

const messaging = firebase.messaging();

messaging.onBackgroundMessage((payload) => {
  console.log('[firebase-messaging-sw.js] Received background message ', payload);
  
  const notificationTitle = payload.notification.title || "DiaCare AI";
  const notificationOptions = {
    body: payload.notification.body,
    icon: "/favicon.png"
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});
