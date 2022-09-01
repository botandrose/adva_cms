$(document).ready(function() {
  $('div.tabs li a').click(function() {
    div = $(this).closest('div');
    $('div.active, li.active', div).removeClass('active')
    // activate selected tab and tab content
    $(this).closest('li').addClass('active');
    selected = '#tab_' + $(this).attr('href').replace('#', '');
    $(selected).addClass('active');
  });
});

// concatenate successive sites main menus together. this allows for extension in other engines. pretty lame.
$(function() {
  var first = null;
  $("#top > .main").each(function(index) {
    if(index == 0) {
      first = this;
    } else {
      $(first).append(this.innerHTML);
      $(this).remove();
    }
  });
});
