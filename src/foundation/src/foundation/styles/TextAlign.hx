package foundation.styles;

@:enum
abstract TextAlign (String) from String to String {
	var Start = 'start';
	var End = 'end';
	var Left = 'left';
	var Right = 'right';
	var Center = 'center';
	var Justify = 'justify';
	var JustifyAll = 'justify-all';
	var MatchParent = 'match-parent';
}
