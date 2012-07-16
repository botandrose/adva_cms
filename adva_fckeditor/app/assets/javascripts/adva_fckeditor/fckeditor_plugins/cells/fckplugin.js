/*
  adva-cms - Cells for FCKeditor plugin
  published under the same license as adva-cms
*/

FCKCommands.RegisterCommand('ConfigureCell', new FCKDialogCommand(FCKLang['DlgConfigureCellTitle'], FCKLang['DlgConfigureCellTitle'], FCKConfig.PluginsPath + 'cells/cell.html', 400, 300));

// create the "ConfigureCell" toolbar button
var oInsertCellItem      = new FCKToolbarButton('ConfigureCell', FCKLang['DlgConfigureCellTitle']) ;
// oInsertCellItem.IconPath = FCKConfig.PluginsPath + 'cells/cell.gif';

FCKToolbarItems.RegisterItem('ConfigureCell', oInsertCellItem);

// cells should be empty block elements
FCKListsLib.BlockElements['cell'] = 1;
FCKListsLib.EmptyElements['cell'] = 1;

// register a new processor for cells
CellsProcessor = FCKDocumentProcessor.AppendNew();
CellsProcessor.ProcessDocument = function(document) {
  var cells = document.getElementsByTagName('CELL');
  for(var cell; cell = cells[0];) {
    var replace = CellReplacers.ReplacementFor(cell);
		cell.parentNode.insertBefore(replace, cell);
		cell.parentNode.removeChild(cell);
  }
}

String.prototype.camelize = function() {
    return this.replace(/[^a-z0-9]+(.)?/gi, function(match, char) { return (char || '').toUpperCase() }).replace(/^(.)?/, function(match, char) { return (char || '').toUpperCase() });
}

CellReplacers = {
  ReplacementFor: function(cell) {
    fn = cell.attributes['name'].value.camelize();
    replace = this.DefaultReplacer(cell);
    if(this[fn]) { replace = this[fn](cell, replace); }
    return replace;
  },
  DefaultReplacer: function(cell) {
    replace = FCKDocumentProcessor_CreateFakeImage('FCK__Cell', cell.cloneNode(true));
    replace.style.border = '#a9a9a9 1px solid';
    replace.style.background = 'url(/assets/adva_fckeditor/fckeditor/editor/css/images/fck_plugin.gif) center center no-repeat';
    replace.style.width = cell.attributes['width'] ? cell.attributes['width'].value + "px" : "80px";
    replace.style.height = cell.attributes['height'] ? cell.attributes['height'].value + "px" : "80px";
    return replace;
  },

  EmbedFeaturedListings: function(cell, replace) {
    replace.style.width = "260px";
    replace.style.height = "274px";
    return replace;
  },

  EmbedFeaturedListingsAndArticle: function(cell, replace) {
    replace.style.width = "700px";
    replace.style.height = "300px";
    return replace;
  },

  FormsSearchForm: function(cell, replace) {
    replace.style.width = "700px";
    replace.style.height = "80px";
    return replace;
  }
};

// display dialog when cell is double clicked
var CellOnDoubleClick = function(cell) {
  if(cell.nodeName == 'IMG' && cell.className == 'FCK__Cell') {
    FCKCommands.GetCommand('ConfigureCell').Execute();
  }
}

FCK.RegisterDoubleClickHandler(CellOnDoubleClick, 'IMG');

/*
// display dialog when cell is double clicked
var CellOnDoubleClick = function(cell) {
  if(cell.nodeName == 'DIV' && cell.className == 'FCK__Cell') {
    FCKCommands.GetCommand('ConfigureCell').Execute();
  }
}

FCK.RegisterDoubleClickHandler(CellOnDoubleClick, 'DIV');

var DisplayCell = function(cell)
{
  // first create a container
	var cellDisplay = FCKTools.GetElementDocument(cell).createElement('DIV');
	cellDisplay.className = 'FCK__Cell';
	cellDisplay.setAttribute('_fckfakelement', 'true', 0);
	cellDisplay.setAttribute('_fckrealelement', FCKTempBin.AddElement(cell), 0);
	cellDisplay.setAttribute('style', 'border:5px solid red;');
	
	// then embed an iframe with the cell
	iframe = FCKTools.GetElementDocument(cellDisplay).createElement('IFRAME');
	iframe.src = '/admin/cell.html';
	iframe.width = '98%';
	iframe.setAttribute('style', 'border:0;');
	cellDisplay.appendChild(iframe);
	
	return cellDisplay;
}
*/

attributesToString = function(attributes) {
  parts = [];
  for(var i = 0; i < attributes.length; i++) {
    a = attributes.item(i);
    parts.push(a.nodeName + '=' + a.nodeValue);
  }
  return parts.join(';');
}
