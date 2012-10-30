/*
 * goofy gauranteed-to-be-unique spam filter
 * test for variable sent along with the form. this variable is populated in the form via javascript after one second.
 */
(function($) {
  $(function() {
    window.setTimeout(function() {
      $(".antispam").append('<input type="hidden" name="are_you_a_human_or_not" value="if you prick me, do i not bleed?">');
    }, 1000);
  });
})(jQuery);
