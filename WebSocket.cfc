component extends="packages.websocket.WebSocketCore" {
    function onMessage( required any message, required channel ) {
        var data = {};
        
        try{
            data = isStruct(message) ? message : deserializeJson(message);
        } catch (any e) {
            systemOutput(obj="Error parsing JSON: #e.message#", addNewline=true);
        }
        var path = data.path ?: "";
        switch (path) {
            /// Add hear your custom paths to manage the connections.
            case "test":
                this.test(channel);
                break;
            case "stream":
                this.stream(data, channel);
                break;
            default:
                systemOutput(obj="[BOXLANG:SOCKET] Unknown path: '#path#'", addNewline=true);
        }

    }

    function stream(required struct data, required channel ) {
        var blob = data['blob'];
        
        if (blob != null) {
            this.send(
                blob, 
                "streamServer", 
                channel
            );
        }
    }

    function test( required channel ) {
        this.send(
            {
                "message": "I received your message",
            }, 
            "test", 
            channel
        );
    }

    function onConnect( required channel ) {
        this.send(
            {
                "message": "Hi, welcome to the server",
            }, 
            "test", 
            channel
        );
    }

    function onClose( ) {
        this.broadcastMessage({
            "message": "Hi! an user is connected",
            "path": 'close'
        });
    }

    function send(any data, string path, required channel) {
        var res = {
            'data': arguments.data,
            'path': arguments.path
        }
        this.sendMessage(jsonSerialize(res), channel);
    }

    function sendBroadcast(any data, string path) {
        var res = {
            'data': arguments.data,
            'path': arguments.path
        }
        this.broadcastMessage(jsonSerialize(datresa));
    }
}
    
    