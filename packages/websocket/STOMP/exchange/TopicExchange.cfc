/**
 * Topic STOMP exchange.  Will route messages to all subscribers of a topic, allowing wildcards
 * Destinations are in the format foo.bar.baz
 * A * wildcar will match a single segment.  Ex. foo.*  foo.bar.* or foo.*.baz
 * A # wildcard will match any amount of the string.  Ex. foo.# or foo.bar.#
 */
component extends="BaseExchange" {

	/**
	 * We pre-process the wildcard and turn then into regex when creating the exchange
	 *
	 * @properties 
	 */
	function init( struct properties={} ) {
		arguments.properties.bindings = arguments.properties.bindings ?: {};
		// precalculate the regex
		// # matches any char for the rest of the string
		// * matches any char for the rest of the segment, ending with a literal .
		arguments.properties.bindings = arguments.properties.bindings.reduce( (bindings,k,v)=>{
			var regex = "^" & k.lcase().replace( ".", "\.", "all" ).replace( "*", "[^\.]*", "all" ).replace( "##", ".*", "all" ) & "$";
			bindings[ regex ] = v;
			return bindings;
		}, {} )
		super.init( properties=arguments.properties );
		return this;
	}

	/**
	 * Find the matching binding based on our regex and send the message to ALL the destinations
	 */
	function routeMessage( required WebSocketSTOMP STOMPBroker, required string destination, required any message ) {
		destination = destination.lcase();
		var bindings = getProperty( "bindings", {} );
		for( var regex in bindings ) {
			// both the regex and the destination are lowercased already
			if( reFind( regex, destination ) ) {
				var newDestination = bindings[ regex ];
				// Start from the top again, since we can route to another exchange
				StompBroker.routeMessage( newDestination, message );
			}
		}
	}

}