const videoElement = document.getElementById('serverVideo');

let sourceBuffer;

const mediaSource = new MediaSource();
videoElement.src = URL.createObjectURL(mediaSource);

mediaSource.addEventListener('sourceopen', function () {
    sourceBuffer = mediaSource.addSourceBuffer('video/webm; codecs="opus,vp8"');
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
                mimeType: `video/webm; codecs="opus,vp8"`,
                videoBitsPerSecond: 2_500_000, // 2.5 Mbps for video will be OK
                audioBitsPerSecond: 128_000    // 128 kbps for audio will be OK
            });

            mediaRecorder.ondataavailable = (event) => {
                if (event.data.size > 0 && socket.readyState === WebSocket.OPEN) {
                    event.data.arrayBuffer().then((data) => {
                        var toB64 = (buffer) => {
                            const byteArray = new Uint8Array(buffer);
                            var res = [];
                            byteArray.forEach((node) => res.push(node));
                            return res;
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