const videoElement = document.getElementById('serverVideo');
var mimeType = getMimeType();
let sourceBuffer;

const mediaSource = new MediaSource();
videoElement.src = URL.createObjectURL(mediaSource);

mediaSource.addEventListener('sourceopen', function () {
    sourceBuffer = mediaSource.addSourceBuffer(mimeType);
    sourceBuffer.addEventListener('updateend', function () {
        if (videoElement.paused) {
            videoElement.play();
        }
    });
});
const peerConnection = new RTCPeerConnection();
let mediaRecorder;

var socketEvents = {
    connected: function (data) {
        console.log('Web Socket connected');
    },

    close: function (e) {
        console.log('Web Socket closed');
    },

    streamServer: function (data) {
        const rawData = new Uint8Array(data.data);
        sourceBuffer?.appendBuffer(rawData);
    },

    test: function (data) {
        console.log(data);
    }
}

let socket;
initSocket();

let retryCount = 0;
const maxRetries = 5; 
const retryDelay = 1000;

function retryConnection() {
    if (retryCount < maxRetries) {
        retryCount++;
        const delay = retryDelay * Math.pow(2, retryCount); // Exponential backoff
        console.log(`Retrying in ${delay / 1000} seconds... (Attempt ${retryCount})`);
        setTimeout(() => initSocket(), delay);
    } else {
        console.error('Max retries reached. Connection failed.');
    }
}

function initSocket() {
    socket = new WebSocket("/ws");
    socket.onmessage = function (e) {
        var data = JSON.parse(e.data);
        console.error(data);
        if (socketEvents[data.path]) {
            socketEvents[data.path](data);
        }
    };

    socket.onclose = function (e) {
        console.error(e);
        retryConnection();
    }

    socket.onerror = function (e) {
        console.error(e);
    }

    socket.onopen = function (e) {
        socketEvents.connected(e);
        socket.send(JSON.stringify({ path: 'test', data: 'Hello' }));
    }
}

document.getElementById('btn-socket-stream')?.addEventListener('click', function () {
    document.getElementById('socket-stream-panel').classList.remove('d-none');

    navigator.mediaDevices.getUserMedia({ video: true, audio: true })
        .then((stream) => {
            document.getElementById('localVideo').srcObject = stream;

            stream.getTracks().forEach((track) => {
                peerConnection.addTrack(track, stream);
            });

            mediaRecorder = new MediaRecorder(stream, {
                mimeType: mimeType,
                videoBitsPerSecond: 2_500_000, // 2.5 Mbps for video will be OK
                audioBitsPerSecond: 128_000    // 128 kbps for audio will be OK
            });

            mediaRecorder.ondataavailable = (event) => {
                if (event.data.size > 0 && socket.readyState === WebSocket.OPEN) {
                    event.data.arrayBuffer().then((data) => {
                        var toB64 = (buffer) => {
                            const byteArray = new Uint8Array(buffer);
                            return Array.from(byteArray);;
                        }
                        socket.send(JSON.stringify({
                            path: 'stream',
                            blob: toB64(data)
                        }));
                    });
                }
            };
            mediaRecorder.start(350);
        })
        .catch((error) => console.error('Error accessing media devices:', error));
});

function getMimeType() {
    var mimeCodecs = [
        // Best performance and widely supported
        'video/mp4; codecs="avc1.42E01E,mp4a.40.2"', // MP4 (H.264, AAC) - Best for compatibility
        'video/webm; codecs="vp9,opus"',             // WebM (VP9, Opus) - Great support in Chrome, Firefox
        'video/webm; codecs="vp8,opus"',             // WebM (VP8, Opus) - Supported in older browsers
    
        // Additional options with good support in most browsers
        'video/ogg; codecs="theora,vorbis"',         // Ogg Theora (older support, primarily Firefox)
        'video/mp4; codecs="avc1.640028,mp4a.40.2"', // MP4 (H.264 High Profile)
        
        // Emerging support (best for specific use cases)
        'video/avi; codecs="MPEG4,mp3"',             // AVI (MPEG-4, MP3) - Less common, but still used
        'video/quicktime; codecs="H.264,mp3"',       // QuickTime (H.264, MP3) - Used in Apple devices
    ];

    for (var i = 0; i < mimeCodecs.length; i++) {
        if (MediaRecorder.isTypeSupported(mimeCodecs[i])) {
            console.log('Using codec:', mimeCodecs[i]);
            return mimeCodecs[i];
        }
    }
}