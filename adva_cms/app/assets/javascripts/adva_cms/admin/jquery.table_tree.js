$(function() {
	$('a.reorder').click(function(event) {
    event.preventDefault();
    $(this).parent().toggleClass('active');
    TableTree.toggle($('table.list'), this.id.replace('reorder_', ''), this.href);
  });
});
