//= require jquery

$(function() {
  $('a.reorder').click(function(event) {
    event.preventDefault();
    $(this).parent().toggleClass('active');
    TableTree.toggle($('table.list'), this.id.replace('reorder_', ''), this.href);
  });
});

// adva_cms/jquery/jquery.tablednd_0_5
/**
 * TableDnD plug-in for JQuery, allows you to drag and drop table rows
 * You can set up various options to control how the system will work
 * Copyright (c) Denis Howlett <denish@isocra.com>
 * Licensed like jQuery, see http://docs.jquery.com/License.
 *
 * Configuration options:
 * 
 * onDragStyle
 *   This is the style that is assigned to the row during drag. There are limitations to the styles that can be
 *   associated with a row (such as you can't assign a border--well you can, but it won't be
 *   displayed). (So instead consider using onDragClass.) The CSS style to apply is specified as
 *   a map (as used in the jQuery css(...) function).
 * onDropStyle
 *   This is the style that is assigned to the row when it is dropped. As for onDragStyle, there are limitations
 *   to what you can do. Also this replaces the original style, so again consider using onDragClass which
 *   is simply added and then removed on drop.
 * onDragClass
 *   This class is added for the duration of the drag and then removed when the row is dropped. It is more
 *   flexible than using onDragStyle since it can be inherited by the row cells and other content. The default
 *   is class is tDnD_whileDrag. So to use the default, simply customise this CSS class in your
 *   stylesheet.
 * onDrop
 *   Pass a function that will be called when the row is dropped. The function takes 2 parameters: the table
 *   and the row that was dropped. You can work out the new order of the rows by using
 *   table.rows.
 * onDragStart
 *   Pass a function that will be called when the user starts dragging. The function takes 2 parameters: the
 *   table and the row which the user has started to drag.
 * onAllowDrop
 *   Pass a function that will be called as a row is over another row. If the function returns true, allow 
 *   dropping on that row, otherwise not. The function takes 2 parameters: the dragged row and the row under
 *   the cursor. It returns a boolean: true allows the drop, false doesn't allow it.
 * scrollAmount
 *   This is the number of pixels to scroll if the user moves the mouse cursor to the top or bottom of the
 *   window. The page should automatically scroll up or down as appropriate (tested in IE6, IE7, Safari, FF2,
 *   FF3 beta
 * dragHandle
 *   This is the name of a class that you assign to one or more cells in each row that is draggable. If you
 *   specify this class, then you are responsible for setting cursor: move in the CSS and only these cells
 *   will have the drag behaviour. If you do not specify a dragHandle, then you get the old behaviour where
 *   the whole row is draggable.
 * 
 * Other ways to control behaviour:
 *
 * Add class="nodrop" to any rows for which you don't want to allow dropping, and class="nodrag" to any rows
 * that you don't want to be draggable.
 *
 * Inside the onDrop method you can also call $.tableDnD.serialize() this returns a string of the form
 * <tableID>[]=<rowID1>&<tableID>[]=<rowID2> so that you can send this back to the server. The table must have
 * an ID as must all the rows.
 *
 * Other methods:
 *
 * $("...").tableDnDUpdate() 
 * Will update all the matching tables, that is it will reapply the mousedown method to the rows (or handle cells).
 * This is useful if you have updated the table rows using Ajax and you want to make the table draggable again.
 * The table maintains the original configuration (so you don't have to specify it again).
 *
 * $("...").tableDnDSerialize()
 * Will serialize and return the serialized string as above, but for each of the matching tables--so it can be
 * called from anywhere and isn't dependent on the currentTable being set up correctly before calling
 *
 * Known problems:
 * - Auto-scoll has some problems with IE7  (it scrolls even when it shouldn't), work-around: set scrollAmount to 0
 * 
 * Version 0.2: 2008-02-20 First public version
 * Version 0.3: 2008-02-07 Added onDragStart option
 *             Made the scroll amount configurable (default is 5 as before)
 * Version 0.4: 2008-03-15 Changed the noDrag/noDrop attributes to nodrag/nodrop classes
 *             Added onAllowDrop to control dropping
 *             Fixed a bug which meant that you couldn't set the scroll amount in both directions
 *             Added serialize method
 * Version 0.5: 2008-05-16 Changed so that if you specify a dragHandle class it doesn't make the whole row
 *             draggable
 *             Improved the serialize method to use a default (and settable) regular expression.
 *             Added tableDnDupate() and tableDnDSerialize() to be called when you are outside the table
 */
jQuery.tableDnD = {
  /** Keep hold of the current table being dragged */
  currentTable : null,
  /** Keep hold of the current drag object if any */
  dragObject: null,
  /** The current mouse offset */
  mouseOffset: null,
  /** Remember the old value of Y so that we don't do too much processing */
  oldY: 0,

  /** Actually build the structure */
  build: function(options) {
    // Set up the defaults if any

    this.each(function() {
      // This is bound to each matching table, set up the defaults and override with user options
      this.tableDnDConfig = $.extend({
        onDragStyle: null,
        onDropStyle: null,
        // Add in the default class for whileDragging
        onDragClass: "tDnD_whileDrag",
        onDrop: null,
                onDrag: null, // ADDED
        onDragStart: null,
        scrollAmount: 5,
        serializeRegexp: /[^\-]*$/, // The regular expression to use to trim row IDs
        serializeParamName: null, // If you want to specify another parameter name instead of the table ID
        dragHandle: null // If you give the name of a class here, then only Cells with this class will be draggable
      }, options || {});
      // Now make the rows draggable
      jQuery.tableDnD.makeDraggable(this);
    });

    // Now we need to capture the mouse up and mouse move event
    // We can use bind so that we don't interfere with other event handlers
    jQuery(document)
      .bind('mousemove', jQuery.tableDnD.mousemove)
      .bind('mouseup', jQuery.tableDnD.mouseup);

    // Don't break the chain
    return this;
  },

  /** This function makes all the rows on the table draggable apart from those marked as "NoDrag" */
  makeDraggable: function(table) {
    var config = table.tableDnDConfig;
    if (table.tableDnDConfig.dragHandle) {
      // We only need to add the event to the specified cells
      var cells = $("td."+table.tableDnDConfig.dragHandle, table);
      cells.each(function() {
        // The cell is bound to "this"
        jQuery(this).mousedown(function(ev) {
          jQuery.tableDnD.dragObject = this.parentNode;
          jQuery.tableDnD.currentTable = table;
          jQuery.tableDnD.mouseOffset = jQuery.tableDnD.getMouseOffset(this, ev);
          if (config.onDragStart) {
            // Call the onDrop method if there is one
            config.onDragStart(table, this);
          }
          return false;
        });
      })
    } else {
      // For backwards compatibility, we add the event to the whole row
      var rows = jQuery("tr", table); // get all the rows as a wrapped set
      rows.each(function() {
        // Iterate through each row, the row is bound to "this"
        var row = $(this);
        if (! row.hasClass("nodrag")) {
          row.mousedown(function(ev) {
            if (ev.target.tagName == "TD") {
              jQuery.tableDnD.dragObject = this;
              jQuery.tableDnD.currentTable = table;
              jQuery.tableDnD.mouseOffset = jQuery.tableDnD.getMouseOffset(this, ev);
              if (config.onDragStart) {
                // Call the onDrop method if there is one
                config.onDragStart(table, this);
              }
              return false;
            }
          }).css("cursor", "move"); // Store the tableDnD object
        }
      });
    }
  },

  updateTables: function() {
    this.each(function() {
      // this is now bound to each matching table
      if (this.tableDnDConfig) {
        jQuery.tableDnD.makeDraggable(this);
      }
    })
  },

  /** Get the mouse coordinates from the event (allowing for browser differences) */
  mouseCoords: function(ev){
    if(ev.pageX || ev.pageY){
      return {x:ev.pageX, y:ev.pageY};
    }
    return {
      x:ev.clientX + document.body.scrollLeft - document.body.clientLeft,
      y:ev.clientY + document.body.scrollTop  - document.body.clientTop
    };
  },

  /** Given a target element and a mouse event, get the mouse offset from that element.
    To do this we need the element's position and the mouse position */
  getMouseOffset: function(target, ev) {
    ev = ev || window.event;

    var docPos  = this.getPosition(target);
    var mousePos  = this.mouseCoords(ev);
    return {x:mousePos.x - docPos.x, y:mousePos.y - docPos.y};
  },

  /** Get the position of an element by going up the DOM tree and adding up all the offsets */
  getPosition: function(e){
    var left = 0;
    var top  = 0;
    /** Safari fix -- thanks to Luis Chato for this! */
    if (e.offsetHeight == 0) {
      /** Safari 2 doesn't correctly grab the offsetTop of a table row
      this is detailed here:
      http://jacob.peargrove.com/blog/2006/technical/table-row-offsettop-bug-in-safari/
      the solution is likewise noted there, grab the offset of a table cell in the row - the firstChild.
      note that firefox will return a text node as a first child, so designing a more thorough
      solution may need to take that into account, for now this seems to work in firefox, safari, ie */
      e = e.firstChild; // a table cell
    }

    while (e.offsetParent){
      left += e.offsetLeft;
      top  += e.offsetTop;
      e   = e.offsetParent;
    }

    left += e.offsetLeft;
    top  += e.offsetTop;

    return {x:left, y:top};
  },

  mousemove: function(ev) {
    if (jQuery.tableDnD.dragObject == null) {
      return;
    }

    var dragObj = jQuery(jQuery.tableDnD.dragObject);
    var config = jQuery.tableDnD.currentTable.tableDnDConfig;
    var mousePos = jQuery.tableDnD.mouseCoords(ev);
    var y = mousePos.y - jQuery.tableDnD.mouseOffset.y;
    //auto scroll the window
    var yOffset = window.pageYOffset;
     if (document.all) {
      // Windows version
      //yOffset=document.body.scrollTop;
      if (typeof document.compatMode != 'undefined' &&
         document.compatMode != 'BackCompat') {
         yOffset = document.documentElement.scrollTop;
      }
      else if (typeof document.body != 'undefined') {
         yOffset=document.body.scrollTop;
      }

    }
      
    if (mousePos.y-yOffset < config.scrollAmount) {
      window.scrollBy(0, -config.scrollAmount);
    } else {
      var windowHeight = window.innerHeight ? window.innerHeight
          : document.documentElement.clientHeight ? document.documentElement.clientHeight : document.body.clientHeight;
      if (windowHeight-(mousePos.y-yOffset) < config.scrollAmount) {
        window.scrollBy(0, config.scrollAmount);
      }
    }


    if (y != jQuery.tableDnD.oldY) {
      // work out if we're going up or down...
      var movingDown = y > jQuery.tableDnD.oldY;
      // update the old value
      jQuery.tableDnD.oldY = y;
      // update the style to show we're dragging
      if (config.onDragClass) {
        dragObj.addClass(config.onDragClass);
      } else {
        dragObj.css(config.onDragStyle);
      }
      // If we're over a row then move the dragged row to there so that the user sees the
      // effect dynamically
      var currentRow = jQuery.tableDnD.findDropTargetRow(dragObj, y, movingDown);
      if (currentRow) {
        // TODO worry about what happens when there are multiple TBODIES
        if (movingDown && jQuery.tableDnD.dragObject != currentRow) {
          jQuery.tableDnD.dragObject.parentNode.insertBefore(jQuery.tableDnD.dragObject, currentRow.nextSibling);
        } else if (! movingDown && jQuery.tableDnD.dragObject != currentRow) {
          jQuery.tableDnD.dragObject.parentNode.insertBefore(jQuery.tableDnD.dragObject, currentRow);
        }
                if (config.onDrag) {
                    config.onDrag(jQuery.tableDnD.currentTable, jQuery.tableDnD.dragObject);
                }
      }
    }

    return false;
  },

  /** We're only worried about the y position really, because we can only move rows up and down */
  findDropTargetRow: function(draggedRow, y, movingDown) {
    var rows = jQuery.tableDnD.currentTable.rows;
    for (var i=0; i<rows.length; i++) {
      var row = rows[i];
      var rowY  = this.getPosition(row).y;
      var rowHeight = parseInt(row.offsetHeight)/2;
      if (row.offsetHeight == 0) {
        rowY = this.getPosition(row.firstChild).y;
        rowHeight = parseInt(row.firstChild.offsetHeight)/2;
      }
      // Because we always have to insert before, we need to offset the height a bit
      if ((y > rowY - rowHeight) && (y < (rowY + rowHeight))) {
        // that's the row we're over
                // If it's the same as the current row, ignore it
                if (row == draggedRow.get(0)) {return null;}
        var config = jQuery.tableDnD.currentTable.tableDnDConfig;
        if (config.onAllowDrop) {
          if (config.onAllowDrop(draggedRow, row, movingDown)) {
            return row;
          } else {
            return null;
          }
        } else {
          // If a row has nodrop class, then don't allow dropping (inspired by John Tarr and Famic)
          var nodrop = $(row).hasClass("nodrop");
          if (! nodrop) {
            return row;
          } else {
            return null;
          }
        }
        return row;
      }
    }
    return null;
  },

  mouseup: function(e) {
    if (jQuery.tableDnD.currentTable && jQuery.tableDnD.dragObject) {
      var droppedRow = jQuery.tableDnD.dragObject;
      var config = jQuery.tableDnD.currentTable.tableDnDConfig;
      // If we have a dragObject, then we need to release it,
      // The row will already have been moved to the right place so we just reset stuff
      if (config.onDragClass) {
        jQuery(droppedRow).removeClass(config.onDragClass);
      } else {
        jQuery(droppedRow).css(config.onDropStyle);
      }
      jQuery.tableDnD.dragObject   = null;
      if (config.onDrop) {
        // Call the onDrop method if there is one
        config.onDrop(jQuery.tableDnD.currentTable, droppedRow);
      }
      jQuery.tableDnD.currentTable = null; // let go of the table too
    }
  },

  serialize: function() {
    if (jQuery.tableDnD.currentTable) {
      return jQuery.tableDnD.serializeTable(jQuery.tableDnD.currentTable);
    } else {
      return "Error: No Table id set, you need to set an id on your table and every row";
    }
  },

  serializeTable: function(table) {
    var result = "";
    var tableId = table.id;
    var rows = table.rows;
    for (var i=0; i<rows.length; i++) {
      if (result.length > 0) result += "&";
      var rowId = rows[i].id;
      if (rowId && rowId && table.tableDnDConfig && table.tableDnDConfig.serializeRegexp) {
        rowId = rowId.match(table.tableDnDConfig.serializeRegexp)[0];
      }

      result += tableId + '[]=' + rows[i].id;
    }
    return result;
  },

  serializeTables: function() {
    var result = "";
    this.each(function() {
      // this is now bound to each matching table
      result += jQuery.tableDnD.serializeTable(this);
    });
    return result;
  }

}

jQuery.fn.extend(
  {
    tableDnD : jQuery.tableDnD.build,
    tableDnDUpdate : jQuery.tableDnD.updateTables,
    tableDnDSerialize: jQuery.tableDnD.serializeTables
  }
);










// adva_cms/jquery/jquery.table_tree
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
      beforeSend: function(xhr) {
        xhr.setRequestHeader("Accept", "text/javascript, text/html, application/xml, text/xml, */*");
      },
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
