var Filter = {
  add: function() {
    var set = $(this).closest('.set');
    set.clone().insertBefore(set);
    $('.filter_remove', set).removeClass('first');
  },
  remove: function() {
    $(this).closest('.set').remove();
  },
  select: function() {
    var set = $(this).closest('.set');
    var name = this.options[this.selectedIndex].value;

    $('.filter', set).removeClass('selected');
    $($('.filter_' + name, set)[0]).addClass('selected');
  }
}

$(function() {
  $(document).on('click', '.selected_filter', Filter.select);
  $(document).on('click', '.filter_add', Filter.add);
  $(document).on('click', '.filter_remove', Filter.remove);
});
