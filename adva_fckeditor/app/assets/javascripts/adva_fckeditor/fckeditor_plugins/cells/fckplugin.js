/*
  adva-cms - Cells for FCKeditor plugin
  published under the same license as adva-cms
*/

FCKCommands.RegisterCommand('ConfigureCell', new FCKDialogCommand(FCKLang['DlgConfigureCellTitle'], FCKLang['DlgConfigureCellTitle'], FCKConfig.PluginsPath + 'cells/cell.html', 400, 300));

// create the "ConfigureCell" toolbar button
var oInsertCellItem = new FCKToolbarButton('ConfigureCell', FCKLang['DlgConfigureCellTitle']) ;

FCKToolbarItems.RegisterItem('ConfigureCell', oInsertCellItem);

// cells should be empty block elements
FCKListsLib.BlockElements['cell'] = 1;
FCKListsLib.EmptyElements['cell'] = 1;

// display dialog when cell is double clicked
FCK.RegisterDoubleClickHandler(function(cell) {
  FCKCommands.GetCommand('ConfigureCell').Execute();
}, 'cell');

