//= require jquery
//= require jquery_ujs

//= require adva_cms/cookie
//= require adva_cms/jquery.flash
//= require adva_cms/jquery.roles

//= require adva_cms/admin/jquery.admin
//= require adva_cms/admin/jquery.table_tree
//= require adva_cms/admin/toggle_excerpt
//= require adva_cms/admin/ckeditor
//= require has_filter/jquery.filter

(function($) {
  $.ajaxSetup({ 
    beforeSend: function(xhr) {
      xhr.setRequestHeader("Accept", "text/javascript, text/html, application/xml, text/xml, */*");
    } 
  });
})(jQuery);
