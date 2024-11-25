/**
 * This is the base WebSocket core component that is used to handle WebSocket connections.
 * Use this in conjunction with CommandBox or the BoxLang Miniserver's websocket server.
 * Extend this CFC with a /WebSocket.cfc in your web root.
 */
component {
	detectServerType();
	
	/**
	 * Front controller for all WebSocket incoming messages
	 */
	remote function onProcess() {
		try {
			var WSMethod = arguments.WSMethod ?: "";
			var methodArgs = application.socketBox.serverClass.getCurrentExchange().getAttachment( application.socketBox.WEBSOCKET_REQUEST_DETAILS ) ?: [];
			var realArgs = [];
			// Adobe's argumentCollection doesn't work with a java.util.List :/
			for( var arg in methodArgs ) {
				realArgs.append( arg );
			}
			switch( WSMethod ) {
				case "onConnect":
					onConnect( argumentCollection=realArgs );
					break;
				case "onFullTextMessage":
					_onMessage( argumentCollection=realArgs );
					break;
				case "onClose":
					onClose( argumentCollection=realArgs );
					break;
				default:
					println("Unknown method: #WSMethod#");
			}
		} catch (any e) {			
			println( e );
			rethrow;
		}
	}

	/**********************************
	 * CONNECTION LIFECYCLE METHODS
	 **********************************/


	/**
	 * A new incoming connectino has been established
	 */
	function onConnect( required channel ) {
		//println("new connection on channel #channel.toString()#");
	}

	/**
	 * A connection has been closed
	 */
	function onClose( required channel ) {
		//println("connection closed on channel #channel.getPeerAddress().toString()#");
	}

	/**
	 * Get all connections
	 */
	function getAllConnections() {
		return getWSHandler().getConnections().toArray();
	}


	/**********************************
	 * INCOMING MESSAGE METHODS
	 **********************************/

	/**
	 * A new incoming message has been received.  Don't override this method.
	 */
	private function _onMessage( required message, required channel ) {
		var messageText = message;
		// Backwards compat for first iteration of websocket listener
		if( !isSimpleValue( messageText ) ) {
			messageText = message.getData();
		}
		onMessage( messageText, channel );
	}

	/**
	 * A new incoming message has been received.  Override this method.
	 */
	function onMessage( required message, required channel ) {
		// Override me
	}

	/**********************************
	 * OUTGOING MESSAGE METHODS
	 **********************************/

	/**
	 * Send a message to a specific channel
	 */
	function sendMessage( required message, required channel ) {
		//println("sending message to specific channel: #message#");
		getWSHandler().sendMessage( channel, message );
	}

	/**
	 * Broadcast a message to all connected channels
	 */
	function broadcastMessage( required message ) {
		//println("broadcasting message: #message#");
		getWSHandler().broadcastMessage( message );
	}

	/**********************************
	 * UTILITY METHODS
	 **********************************/

	 /**
	  * Get Undertow WebSocket handler from the underlying server
	  */
	private function getWSHandler() {
		if( application.socketBox.serverType == "boxlang-miniserver" ) {
			return application.socketBox.serverClass.getWebsocketHandler();
		} else {
			var exchange = application.socketBox.serverClass.getCurrentExchange()
			if( !isNull( exchange ) ) {
				return exchange.getAttachment( application.socketBox.SITE_DEPLOYMENT_KEY ).getWebsocketHandler();
			}
			// If we're in a cfthread, we won't have a "current" exchange in ThreadLocal
			var deployment = application.socketBox.deployment ?: "";
			if( isSimpleValue( deployment ) ) {
				throw( type="WebSocketHandlerNotFound", message="WebSocket handler not found (no deployment name stored)" );
			}
			return deployment.getWebsocketHandler();				
		}
		throw( type="WebSocketHandlerNotFound", message="WebSocket handler not found" );
	}

	/**
	 * Shim for BoxLang's println()
	 */
	private function println( required message ) {
		systemOutput( message, true );
	}

	/**
	 * Shim for Lucee's systemOutput()
	 */
	private function systemOutput( required message ) {
		writedump( var=message.toString(), output="console" );
	}

	/**
	 * Detect if we're on CommandBox or the BoxLang Miniserver
	 */
	private function detectServerType() {
		if( isNull( application.socketBox ) ) {
			cflock( name="socketBox-init", type="exclusive", timeout=60 ) {
				if( isNull( application.socketBox ) ) {
					try {
						application.socketBox.serverClass = createObject('java', 'runwar.Server')
						application.socketBox.SITE_DEPLOYMENT_KEY = createObject('java', 'runwar.undertow.SiteDeploymentManager' ).SITE_DEPLOYMENT_KEY;
						application.socketBox.WEBSOCKET_REQUEST_DETAILS = createObject('java', 'runwar.undertow.WebsocketReceiveListener' ).WEBSOCKET_REQUEST_DETAILS;
						application.socketBox.serverType = "runwar";
						application.socketBox.deployment = "";
					} catch( any e ) {
						try {
							application.socketBox.serverClass = createObject('java', 'ortus.boxlang.web.MiniServer')
							application.socketBox.WEBSOCKET_REQUEST_DETAILS = createObject('java', 'ortus.boxlang.web.handlers.WebsocketReceiveListener' ).WEBSOCKET_REQUEST_DETAILS;
							application.socketBox.serverType = "boxlang-miniserver";
						} catch( any e) {
							throw( type="ServerTypeNotFound", message="This websocket library can only run in CommandBox or the BoxLang Miniserver." );
						}
					}
				}
			}
		}
		// This song and dance is because threads don't hvae access to the thread local variables to get the current deploy, so we want to capture it when we have a chance for later.
		if( application.socketBox.serverType == "runwar" && isSimpleValue( application.socketBox.deployment ?: '' ) && !isNull( application.socketBox.serverClass.getCurrentExchange() ) ) {
			application.socketBox.deployment = application.socketBox.serverClass.getCurrentExchange().getAttachment( application.socketBox.SITE_DEPLOYMENT_KEY );
		}
	}
	
}