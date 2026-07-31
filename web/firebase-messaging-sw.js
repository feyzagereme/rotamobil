importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.7.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyDNntalqnmuOiJrgrpahfI3RRg8r9cM91w",
  authDomain: "rota360-35ce3.firebaseapp.com",
  projectId: "rota360-35ce3",
  storageBucket: "rota360-35ce3.firebasestorage.app",
  messagingSenderId: "434121736536",
  appId: "1:434121736536:web:e8a409cb916d03dec7e52d",
});

const messaging = firebase.messaging();

// Uygulama arka plandayken (ya da kapalıyken, web sekmesi hâlâ açıksa)
// gelen bildirimleri işler.
messaging.onBackgroundMessage((payload) => {
  const notificationTitle = payload.notification?.title || 'Rota360';
  const notificationOptions = {
    body: payload.notification?.body || '',
    icon: '/icons/Icon-192.png',
  };

  self.registration.showNotification(notificationTitle, notificationOptions);
});