package electron;


/**
  * class full of utility methods for electron
  */
class Tools {
	/**
	  * queue [action] for invokation immediately after the current call-stack
	  */
	public static inline function defer(action : Void -> Void):Void {
		(untyped __js__( 'process.nextTick' )( action ));
	}
}
