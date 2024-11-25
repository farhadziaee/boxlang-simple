/**
 * A simple STOMP message parser.
 */
component {
	// Adobe CF and Lucee stupidly return an empty string for chr(0), so we can't use that
	// This workaround seems to work on all 3 engines.
	variables.NULL_BYTE = URLDecode( "%00" );
	/**
	 * Convert the STOMP message to a string.
	 */
	function serialize( required message ) {
		var buffer = createObject("java", "java.lang.StringBuffer").init();
		buffer.append( message.getCommand() ).append( chr(10) );
		var body = toString( message.getBodyRaw() );
		if( body != "" ) {
			message.setHeader( "content-length", len( body.getBytes() ) );	
		}
		for( var key in message.getHeaders() ) {
			buffer.append( encode( key ) ).append( ":" ).append( encode( message.getHeaders()[ key ] ) ).append( chr(10) );
		}
		buffer.append( chr(10) ).append( body ).append( NULL_BYTE );
		return buffer.toString();
	}

	/**
	 * Parse a STOMP message from a string.
	 */
	Message function deserialize( required string message, required channel ) {
		var position = 0;
		var headers = {};
		var readNextLine = () => {
			// if we're at the end of the message, return an empty string
			if( position >= len( message ) ) {
				return "";
			}
			var line = "";
			while( message.charAt( position ) != chr(10) ) {
				// ignore carriage returns
				if( message.charAt( position ) != chr(13) ) {
					line &= message.charAt( position );
				}
				position++;
			}
			position++;
			return line;
		};
		// if length is a positive number, read that many characters, erroring if the end is reached prematurely
		// if length is -1, read until a null character is reached
		var readBody = (numeric length=-1) => {
			var body = "";
			if( length == -1 ) {
				while( message.charAt( position ) != NULL_BYTE ) {
					body &= message.charAt( position );
					position++;
					// If we've reached the end of the message, throw an error for missing null byte
					if( position >= len( message ) ) {
						throw( "Unexpected end of message while reading body (missing null byte)" );
					}
				}
			} else {
				for( var i = 0; i < length; i++ ) {
					if( position >= len( message ) ) {
						throw( "Unexpected end of message while reading body (found #len(body)# bytes, but content-length header specified #length# bytes)" );
					}
					body &= message.charAt( position );
					position++;
				}
			}
			// validate we haven't reached the end of the message and the next char is a null byte
			if( position >= len( message ) || message.charAt( position ) != NULL_BYTE ) {
				throw( "Unexpected end of message after reading #length# bytes of body (missing null byte)" );
			}
			// Additional EOL chars are allowed after the null byte, so skip them
			// I'm not bothering to validate that any remaining chars are EOLs.  I'm just skipping all remaining chars.
			return body;
		};
		var command = readNextLine();
		var line = readNextLine();
		while( line != "" ) {
			var header = listToArray( line, ":" );
			headers[ decode( header[ 1 ] ) ] = decode( header[ 2 ] );
			line = readNextLine();
		};
		// if we reached here, we've hit the double line break after the headers, or the end of the message
		var body = "";
		// Ignore body for any other message type.  The spec says other message types MUST NOT have a body
		// but the spec also doesn't specify how to tell if a body is present since the double EOL and NULL byte are required parts of every frame!
		if( listContainsNoCase("SEND,MESSAGE,ERROR",command)) {
			body = readBody( headers[ "content-length" ] ?: -1 );
		}

		return new Message( command, headers, body, channel ).validate();
	}

	/**
	 * encode header part
	 * \r (octet 92 and 114) translates to carriage return (octet 13)
	 * \n (octet 92 and 110) translates to line feed (octet 10)
	 * \c (octet 92 and 99) translates to : (octet 58)
	 * \\ (octet 92 and 92) translates to \ (octet 92)
	 */
	string function encode( required string value ) {
		return replace( value, "\", "\\", "all" )
			.replace( chr(13), "\r", "all" )
			.replace( chr(10), "\n", "all" )
			.replace( ":", "\c", "all" );
	}

	/**
	 * decode header part
	 * \r (octet 92 and 114) translates to carriage return (octet 13)
	 * \n (octet 92 and 110) translates to line feed (octet 10)
	 * \c (octet 92 and 99) translates to : (octet 58)
	 * \\ (octet 92 and 92) translates to \ (octet 92)
	 */
	string function decode( required string value ) {
		return replace( value, "\\", "__tmp__backslash__", "all" )
			.replace( "\r", chr(13), "all" )
			.replace( "\n", chr(10), "all" )
			.replace( "\c", ":", "all" )
			.replace( "__tmp__backslash__", "\", "all" );
	}


}