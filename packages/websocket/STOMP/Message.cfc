/**
 * I am a STOMP message.
 */
component accessors=true {
	property name="command" type="string";
	property name="headers" type="struct";
	property name="body" type="string";
	// Will be null if this message didn't originate from a WebSocket
	property name="channel";

	variables.requiredHeaders = {
		"CONNECT": [ "accept-version" ], // , "host"
		"STOMP": [ "accept-version" ], // , "host"
		"CONNECTED": [ "version" ],
		"SEND": [ "destination" ],
		"SUBSCRIBE": [ "destination", "id" ],
		"UNSUBSCRIBE": [ "id" ],
		"ACK": [ "id" ],
		"NACK": [ "id" ],
		"BEGIN": [ "transaction" ],
		"COMMIT": [ "transaction" ],
		"ABORT": [ "transaction" ],
		"DISCONNECT": [],
		"MESSAGE": [ "destination", "message-id", "subscription" ],
		"RECEIPT": [ "receipt-id" ],
		"ERROR": []
	};

	/**
	 * Create a new STOMP message.
	 */
	function init( required string command, struct headers={}, any body="", channel ) {
		setCommand( command );
		setHeaders( headers );
		setBody( body );
		if( !isNull( arguments.channel ) ) {
			setChannel( arguments.channel );
		}
		return this;
	}

	/**
	 * Get a header value by key.
	 */
	function getHeader( required string key, string defaultValue)  {
		if( structKeyExists( getHeaders(), key ) ) {
			return getHeaders()[ key ];
		} else if( !isNull( arguments.defaultValue ) ) {
			return defaultValue;
		} else {
			return;
		}
	}

	/**
	 * Set a header value by key.
	 */
	function setHeader( required string key, required string value ) {
		getHeaders()[ key ] = value;
		return this;
	}

	/**
	 * Remove a header by key.
	 */
	function removeHeader( required string key ) {
		structDelete( getHeaders(), key );
		return this;
	}

	/**
	 * Get the body of the message.
	 */
	function getBody() {
		if( getHeader( "content-type", "" ) == "application/json" ) {
			// validate JSON
			if( !isJSON( body ) ) {
				throw( type="InvalidJSON", message="Message has content-type of JSON, but message body is not valid JSON. Body: #body# #serializeJSON(headers)#, #getCommand()#" );

			}
			return deserializeJSON( body );
		}
		return body;
	}

	/**
	 * Get the body of the message.
	 */
	function getBodyRaw() {
		return body;
	}

	/**
	 * Set the body of the message.
	 */
	function setBody( required any body ) {
		if( !isSimpleValue( arguments.body ) ) {
			arguments.body = serializeJSON( arguments.body );
			setHeader( "content-type", "application/json" );
		}
		variables.body = toString( arguments.body );
		return this;
	}

	/**
	 * Validate message properties.
	 */
	Message function validate() {
		// validate command
		if( !listFindNoCase( "SEND,SUBSCRIBE,UNSUBSCRIBE,BEGIN,COMMIT,ABORT,ACK,NACK,DISCONNECT,CONNECT,STOMP,CONNECTED,MESSAGE,RECEIPT,ERROR", getCommand() ) ) {
			throw( type="InvalidCommand", message="Invalid STOMP command: #getCommand()#" );
		}

		// validate headers required by command
		if( structKeyExists( requiredHeaders, getCommand() ) ) {
			var missingHeaders = [];
			for( var header in requiredHeaders[ getCommand() ] ) {
				if( !structKeyExists( getHeaders(), header ) ) {
					missingHeaders.append( header );
				}
			}
			if( !arrayIsEmpty( missingHeaders ) ) {
				throw( type="MissingHeaders", message="Missing required headers for command #getCommand()#: #arrayToList( missingHeaders )#" );
			}
		}
		return this;
	}

	function clone() {
		return new Message(
			getCommand(),
			// Remove sensitive details
			getHeaders().filter( (k,v)=> k != "login" && k != "passcode" ),
			getBody(),
			getChannel()
		);
	}


}