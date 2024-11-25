/**
 * Base class for STOMP exchanges
 */
component accessors="true" {
	property name="properties" type="struct";

	/**
	 * Construct our exchange with the given properties
	 *
	 * @properties The properties to set on the exchange
	 */
	function init( struct properties={} ) {
		setProperties( arguments.properties );
		return this;
	}
	
	/**
	 * Abstract method to route a message to the given destination.  The exchange gets to decide the logic it wants to use for routing the message
	 *
	 * @key 
	 * @defaultValue 
	 */
	function routeMessage( required WebSocketSTOMP STOMPBroker, required string destination, required any message ){
		throw( message="Method not implemented", detail="You must implement the routeMessage method in your exchange", type="MethodNotImplemented" );
	}

	/**
	 * Get a property from the exchange
	 *
	 * @key The name of the property to get
	 * @defaultValue The default value to return if the property does not exist
	 */
	function getProperty( required string key, any defaultValue ) {
		if( structKeyExists( getProperties(), key ) ) {
			return getProperties()[ key ];
		} else if( !isNull( arguments.defaultValue ) ) {
			return defaultValue;
		} else {
			return;
		}
	}

	/**
	 * Set a property on the exchange
	 * 
	 * @key The name of the property to set
	 * @value The value to set the property to
	 */
	function setProperty( required string key, required any value ) {
		getProperties()[ key ] = value;
		return this;
	}

	/**
	 * Internal method to actually send a message to a channel.
	 * The original message object will be left unchanged, and a new message object will be created with the appropriate headers set
	 */
	function routeInternal( required WebSocketSTOMP STOMPBroker, required any originalMessage, required any channel, required string destination, required string subscriptionID ) {
		if( channel.isOpen() ) {			
			var message = originalMessage.clone();

			// Setup new message object
			message.setCommand( "MESSAGE" );
			message.setHeader( "subscription", subscriptionID );
			message.setHeader( "message-id", createUUID() );
			message.setHeader( "destination", destination );
			STOMPBroker.sendMessage( STOMPBroker.getMessageParser().serialize( message ), channel );
		}
	
	}

}