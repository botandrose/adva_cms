TableTree = {
	tableDnDOptions: {
		onDragClass: 'drag',
	  onDragStart: function(table, row) {
			TableTree.startOffset = jQuery.tableDnD.mouseOffset.x;
			$(row).mousemove(TableTree.mousemove);
			if (node = $(row).ttnode()) node.dragStart();
		},
		onDrag: function(table, row) {
			TableTree.current_table.dirty = true;
			if (node = $(row).ttnode()) node.update_children();
		},
		onDrop: function(table, row) {
			$(row).unbind('mousemove', TableTree.mousemove);
			if (node = $(row).ttnode()) node.drop();
			TableTree.current_table.rebuild();
			TableTree.current_table.update_remote(row);
		},
		onAllowDrop: function(draggedRow, row, movingDown) {
			var node = $(row).ttnode();
			next = movingDown ? $(node.next_row_sibling()).ttnode() : node;
			if (next && (next.parent.level >= $(draggedRow).ttnode().level)) return false;
			return $(row).ttnode() ? true : false;
		}
	},
	toggle: function(table, type, collection_url) {
		TableTree.current_table ? TableTree.teardown(table) : TableTree.setup(table, type, collection_url);
	},
	setup: function(table, type, collection_url) {
		$('tbody', table).tableDnD(TableTree.tableDnDOptions);
		TableTree.current_table = new TableTree.Table($(table).get(0), type, collection_url);
		TableTree.current_table.setSortable();
	},
	teardown: function(table) {
		// TableTree.current_table.update_remote();
		jQuery.tableDnD.teardown(table);
		TableTree.current_table.setUnsortable();
		TableTree.current_table = null;
	},
	level: function(element) {
		var match = element.className.match(/level_([\d]+)/);
		return match ? parseInt(match[1]) : 0;
	},
	mousemove: function(event) {
		if (!TableTree.current_table.is_tree) return;

		var offset = jQuery.tableDnD.getMouseOffset(this, event).x - TableTree.startOffset;
		if(offset > 25) {
			TableTree.current_table.dirty = true;
			$(this).ttnode().increment_level(event);
		} else if(offset < -25) {
			TableTree.current_table.dirty = true;
			$(this).ttnode().decrement_level(event);
		}
	},
	Base: function() {},
	Table: function(table, type, collection_url) {
		this.is_tree = $(table).hasClass('tree')
		this.table = table; //$('tbody', table)
		this.type = type;
		this.level = -1;
		this.collection_url = collection_url;
		this.rebuild();
	},
	Node: function(parent, element, level) {
		var _this = this;
		this.parent = parent;
		this.element = element;
		this.level = level;

		this.children = this.find_children().map(function() {
			var level = TableTree.level(this);
			if(level == _this.level + 1) { return new TableTree.Node(_this, this, level); }
		});
	}
}

TableTree.Base.prototype = {
	find_node: function(element) {
    for (var i = 0; i < this.children.length; i++) {
			var child = this.children[i];
			if (this.children[i].element == element) {
				return this.children[i];
			} else {
				var result = this.children[i].find_node(element);
				if (result) return result;
			}
		}
	}
}
TableTree.Table.prototype = jQuery.extend(new TableTree.Base(), {
	rebuild: function() {
		var _this = this;
		this.children = $('tr', this.table).map(function() {
			if(TableTree.level(this) == 0) { return new TableTree.Node(_this, this, TableTree.level(this)); }
		});
	},
	setSortable: function() {
		$('tr', this.table).each(function() {
		  // thead
		  cells = $('th', this);
		  cells.each(function(ix) {
		    if(ix == 0) {
		      this.setAttribute('colspan', cells.length);
		    } else {
		      $(this).hide();
		    }
		  });

      // tbody
			cells = $('td', this);
			cells.each(function(ix) {
				if (ix == 0) {
					element = this;
					this.setAttribute('colspan', cells.length);
					$('a', this).each(function() {
						$(this).hide();
						element.appendChild(document.createTextNode($(this).text()))
					});
				} else {
					$(this).hide(); 
				}
			});
		});
	},
	setUnsortable: function() {
		$('tr', this.table).each(function(ix) {
		  // thead
		  cells = $('th', this);
		  cells.each(function(ix) {
		    if(ix == 0) {
		      this.setAttribute('colspan', 1);
		    } else {
		      $(this).show();
		    }
		  });

      // tbody
			$('td', this).each(function(ix) {
				if(ix == 0) {
					$('a', this).each(function() { 
					  $(this).show();
					});
					$('img.spinner', this).remove();
					this.removeChild(this.lastChild);
					this.setAttribute('colspan', 1);
				} else {
					$(this).show();
				}
			});
		});
	},
	update_remote: function(row) {
		if(!this.dirty) return;
		this.dirty = false;
		_this = this;

		this.show_spinner(row);
		$.ajax({
		  type: "POST",
			url: this.collection_url,
			data: jQuery.extend(this.serialize(row), { authenticity_token: window._auth_token, '_method': 'put' }),
			success: function(msg) { _this.hide_spinner(row); },
			error:   function(msg) { _this.hide_spinner(row); }
		});
	},
	serialize: function(row) {
		row = $(row).ttnode();
		data = {};
		data[this.type + '[' + row.id() + '][parent_id]'] = row.parent_id();
		data[this.type +'[' + row.id() + '][left_id]'] = row.left_id();
		return data;
	},
	show_spinner: function(row) {
		img = document.createElement('img');
		img.src = 'data:image/gif;base64,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';
		img.className = 'spinner';
		$('td', row)[0].appendChild(img);
	},
	hide_spinner: function(row) {
		cell = $('td', row)[0];
		cell.removeChild(cell.lastChild);
	}
});

TableTree.Node.prototype = jQuery.extend(new TableTree.Base(), {
	find_children: function() {
		var lvl = this.level;
		var stop = false;
		return this.row_siblings().slice(this.row_index() + 1).filter(function() {
			var level = TableTree.level(this);
			if(lvl == level) stop = true; // how to break from a jquery iterator?
			return !stop && lvl + 1 == level;
		});
	},
	depth: function() {
		if (this.children.length > 0) {
			return Math.max.apply(Math, this.children.map(function() { return this.depth() }).get());
		} else {
			return this.level;
		}
	},
	siblings: function() {
		return this.parent.children;
	},
	id: function() {
		return this.element ? this.to_int(this.element.id) : 'null';
	},
	parent_id: function() {
		return this.parent.element ? this.to_int(this.parent.element.id) : 'null';
	},
	left_id: function() {
		left = this.left()
		return left ? this.to_int(left.element.id) : 'null';
	},
	left: function() {
		siblings = this.siblings().get();
		ix = siblings.indexOf(this) - 1;
		if(ix >= 0) return siblings[ix];
	},
	to_int: function(str) { 
		if(str) return str.replace(/[\D]+/, '') 
	},
	next_row_sibling: function () {
		return this.row_siblings()[this.row_index() + 1];
	},
	row_siblings: function() {
		if(!this._row_siblings) { this._row_siblings = $(this.element).parent().children(); }
		return this._row_siblings;
	},
	row_index: function() {
		return this.row_siblings().get().indexOf(this.element);
	},
	dragStart: function() {
		$(this.element).addClass('drag');
		this.children.each(function() { this.dragStart(); })
	},
	drop: function() {
		$(this.element).removeClass('drag');
		this.children.each(function() { this.drop(); })
		this.adjust_level();
	},
	increment_level: function(event) {
		var prev = $(this.element).prev().ttnode();
		if(!prev || prev.level < this.level || this.depth() >= 5) return;
		this.update_level(event, this.level + 1);
	},
	decrement_level: function(event) {
		if(this.level == 0) return;
		this.update_level(event, this.level - 1);
	},
	update_level: function(event, level) {
		if (event) TableTree.startOffset = jQuery.tableDnD.getMouseOffset(this.element, event).x;
		
		$(this.element).removeClass('level_' + this.level);
		$(this.element).addClass('level_' + level);
		
		this.level = level;	
		this.children.each(function() { this.update_level(event, level + 1); });
	},
	adjust_level: function() {
		var prev = $(this.element).prev().ttnode();
		if(!prev) {
			this.update_level(null, 0);
		} else if(prev.level + 1 < this.level) {
			this.update_level(null, prev.level + 1);
		}
	},
	update_children: function() {
		this.children.each(function() { this.element.parentNode.removeChild(this.element); });
		var _this = this;
		var _next = _this.element.nextSibling;
		this.children.each(function() { _this.element.parentNode.insertBefore(this.element, _next); });
		this.children.each(function() { this.update_children() });
	}
});
		
jQuery.fn.extend({
	ttnode: function() {
		var subject = this.push ? this[0] : this;
		return TableTree.current_table.find_node(subject);
	}
});

jQuery.extend(jQuery.tableDnD, {
	teardown: function(table) {
		jQuery('tr', table).each(function() { $(this).unbind('mousedown'); }).css('cursor', 'auto');
		jQuery.tableDnD.dragObject = null;
		jQuery.tableDnD.currentTable = null;
		jQuery.tableDnD.mouseOffset = null;
	}
});
// 
// tableDnD {
// 	toggle: function() {
// 		if (table.hasClass('tree')) {
// 			setupTree()
// 		}
// 	}
// 	// aslödkjföksdfk
// 	Tree {
// 		
// 	}
// }
// 
// 
// 
