/**
 * Distribution STOMP exchange.  Will route messages to one of the bound destinations 
 */
component extends="BaseExchange" {

	/**
	 * find the binding for this incoming message, and choose which destination to send it to
	 */
	function routeMessage( required WebSocketSTOMP STOMPBroker, required string destination, required any message ) {
		var bindings = getProperty( "bindings", {} );
		for( var routingKey in bindings ) {
			if( routingKey == destination ) {
				// Send message to one binding
				var possibleDesinations = bindings[ routingKey ];
				StompBroker.routeMessage( chooseNextDestination( possibleDesinations ), message );
			}
		}
	}

	/**
	 * This depends on our configured type.  We default to random if not configured.
	 *
	 * @possibleDestinations An array of possible destinations to choose from
	 */
	function chooseNextDestination( required array possibleDestinations ) {
		var type = getProperty( "type", "random" );
		switch( type ) {
			case "random":
				return chooseRandomDestination( possibleDestinations );
			case "roundrobin":
				return chooseRoundRobinDestination( possibleDestinations );
			default:
				throw( message="Unknown distribution type", detail="The distribution type #type# is not supported", type="UnknownDistributionType" );
		}
	}

	/**
	 * Choose a random destinatino from the list
	 */
	function chooseRandomDestination( required array possibleDestinations ) {
		return possibleDestinations[ randRange( 1, arrayLen( possibleDestinations ) ) ];
	}

	/**
	 * Implement round robin with an application variable to track state.
	 * Using application here because if debug mode is enabled, this exchange will be re-created on every request
	 *
	 * @possibleDestinations 
	 */
	function chooseRoundRobinDestination( required array possibleDestinations ) {
		// Lock to ensure that the current destination is updated atomically
		// Use application scope so we can maintain state even when in debug mode 
		var exchangeName = "STOMProundRobin-#getProperty( "name" )#";
		// We need to increment the counter atomically
		cflock( name="#exchangeName#", type="exclusive", timeout=60 ) {
			application[ exchangeName ] = application[ exchangeName ] ?: 0;
			if( application[ exchangeName ] == 0 ) {
				application[ exchangeName ] = 1;
			} else {
				application[ exchangeName ]++;
				if( application[ exchangeName ] > arrayLen( possibleDestinations ) ) {
					application[ exchangeName ] = 1;
				}
			}
			return possibleDestinations[ application[ exchangeName ] ];
		}
	}

}