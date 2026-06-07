import Echo from 'laravel-echo';

import Pusher from 'pusher-js';
window.Pusher = Pusher;
Pusher.logToConsole = true;

const isSecure = window.location.protocol === 'https:';
const currentHost = window.location.hostname;
const wsPort = isSecure ? 443 : (import.meta.env.VITE_REVERB_PORT ?? 8080);
const wssPort = isSecure ? 443 : (import.meta.env.VITE_REVERB_PORT ?? 8080);

window.Echo = new Echo({
    broadcaster: 'reverb',
    key: import.meta.env.VITE_REVERB_APP_KEY,
    wsHost: currentHost,
    wsPort: wsPort,
    wssPort: wssPort,
    forceTLS: isSecure,
    enabledTransports: ['ws', 'wss'],
});
