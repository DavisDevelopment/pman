package foundation.styles;

@:enum
abstract EFloat (String) from String to String {
	var Left = 'left';
	var Right = 'right';
	var None = 'none';
	var InlineStart = 'inline-start';
	var InlineEnd = 'inline-end';
}
