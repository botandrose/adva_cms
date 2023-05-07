(function($) {
  $.ajaxSetup({ 
    beforeSend: function(xhr) {
      xhr.setRequestHeader("Accept", "text/javascript, text/html, application/xml, text/xml, */*");
    } 
  });
})(jQuery);
