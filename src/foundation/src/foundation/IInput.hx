package foundation;

/**
  * Interface to represent an data-input widget
  */
interface IInput<T> {
	/* The 'name' of [this] Input */
	var name(get, set) : String;

	/* Obtain the value of [this] Input */
	function getValue():T;

	/* Assign the value of [this] Input */
	function setValue(v : T):T;
}
