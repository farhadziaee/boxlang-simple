/**
 * Direct STOMP exchange.  Will route messages directly 
 */
component extends="BaseExchange" {

	/**
	 * For any incoming message, send it directly any subscriptions that match the destination.
	 * Custom bindings can also be provided to create a direct route from one destination to another
	 */
	function routeMessage( required WebSocketSTOMP STOMPBroker, required string destination, required any message ) {

		// Check subscriptions
		var subs = STOMPBroker.getSubscriptions();
		if( structKeyExists( subs, destination ) ) {
			// Route exact matches to subscriptions
			subs[ destination ].each( function( channelSubID, subscription ) {
				// This is getting send back to a client over the websocket
				if( subscription.type == "channel" ) {
					var subscriptionID = subscription.subscriptionID;
					// actually send to a channel.
					routeInternal( STOMPBroker, message, subscription[ "channel" ], destination, subscriptionID )
				} else {
					// type == "internal"
					// This is a server-side subscriptions. We just call the function directly.
					subscription[ "callback" ]( message );
				}
			} );
		}

		// Check for custom bindings
		var bindings = getProperty( "bindings", {} );
		if( structKeyExists( bindings, destination ) ) {
			bindings[ destination ].each( function( bindingID, binding ) {
				// This will match an exchange and process again from the top
				STOMPBroker.routeMessage( destination, message )
			} );
		}

	}

}