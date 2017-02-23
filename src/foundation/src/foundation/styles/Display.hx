package foundation.styles;

@:enum
abstract Display (String) from String to String {
	var None = 'none';
	var Inline = 'inline';
	var Block = 'block';
	var InlineBlock = 'inline-block';
	var Contents = 'contents';
	var ListItem = 'list-item';
	var InlineListItem = 'inline-list-item';
	var Table = 'table';
}
