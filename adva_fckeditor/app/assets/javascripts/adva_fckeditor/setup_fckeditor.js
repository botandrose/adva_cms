//= require adva_fckeditor/fckeditor/fckeditor.js

applyOrRemoveFCKeditors = function() {
  $('textarea.wysiwyg').each(function() {
    id = $(this).attr('id');
    filter = $('select.columnsFilter')[0];

    // transform all textareas to FCKeditors, but only if filter is set to plain HTML or no filter is defined
    if(typeof filter == 'undefined' || $(filter).val() == '') {
      // some calculations
      width = $(this).width();
      if(width == 0) width = 720; // default height = 720px

      height = $(this).height();
      if(height == 0) height = 200; // default height = 200px

      // define toolbar: add "small" class to your html markup in order to use adva small toolbar
      var toolbar = $(this).hasClass('small') ? 'adva-cms-small' : 'adva-cms'

      // initialize FCKeditor
      FCKeditor.BasePath = '/assets/adva_fckeditor/fckeditor/';
      var oFCKeditor = new FCKeditor(id, width, height, toolbar);
      oFCKeditor.Config['CustomConfigurationsPath'] = '/assets/fck_config.js';
      if(typeof FCKGlobalConfig != 'undefined') {
        for(var key in FCKGlobalConfig) {
          oFCKeditor.Config[key] = FCKGlobalConfig[key];
        }
      }
      var bodyClass = $(this).attr("data-body-class");
      if(bodyClass) {
        oFCKeditor.Config.BodyClass = bodyClass;
      }
      oFCKeditor.ReplaceTextarea();
    } else {
      f = $('#' + id + '___Frame');
      c = $('#' + id + '___Config');
      if(f) $(f).remove();
      if(c) $(c).remove();
      $(this).show();
    }
  });
}

$(document).ready(function() {
  applyOrRemoveFCKeditors();
  $('select.columnsFilter').change(function() {
    applyOrRemoveFCKeditors();
  });
});
