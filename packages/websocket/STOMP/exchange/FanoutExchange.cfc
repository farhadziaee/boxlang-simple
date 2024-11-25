/**
 * Fanout STOMP exchange.  Will route messages to all the bound destinations to a routing key
 */
component extends="BaseExchange" {
	
	/**
	 * Find the matching binding and send the message to ALL the destinations
	 */
	function routeMessage( required WebSocketSTOMP STOMPBroker, required string destination, required any message ) {
		var bindings = getProperty( "bindings", {} );
		for( var routingKey in bindings ) {
			// both the regex and the destination are lowercased already
			if( routingKey == destination ) {
				// Send message to all bindings
				bindings[ routingKey ].each( function( newDestination ) {
					// Start from the top again, since we can route to another exchange
					StompBroker.routeMessage( newDestination, message );
				} );
			}
		}
	}

}