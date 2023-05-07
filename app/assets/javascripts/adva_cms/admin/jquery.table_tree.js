//= require adva_cms/jquery/jquery.tablednd_0_5
//= require adva_cms/jquery/jquery.table_tree

$(function() {
  $('a.reorder').click(function(event) {
    event.preventDefault();
    $(this).parent().toggleClass('active');
    TableTree.toggle($('table.list'), this.id.replace('reorder_', ''), this.href);
  });
});
