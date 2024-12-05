document.addEventListener("DOMContentLoaded", () => {
  const table = document.querySelector("table.list")
  const link = document.querySelector("a.reorder")
  if(table && link) new TableTree(table, link)
})

/**
 * Configuration options:
 *
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
 *   window. The page should automatically scroll up or down as appropriate.
 */

class TableDnD {
  constructor() {
    this.currentTable = null
    this.dragObject = null
    this.mouseOffset = null
    this.oldY = 0
  }

  add(table, options) {
    table.tableDnDConfig = {
      // Add in the default class for whileDragging
      onDragClass: "tDnD_whileDrag",
      onDrop: null,
      onDrag: null, // ADDED
      onDragStart: null,
      scrollAmount: 5,
      ...(options || {}),
    }
    this.makeDraggable(table)
  }

  makeDraggable(table) {
    table.querySelectorAll("tr").forEach(row => {
      row.addEventListener("mousedown", event => this.mousedown(table, row, event))
      row.style.cursor = "move"
    })
    // Now we need to capture the mouse up and mouse move event
    // We can use bind so that we don't interfere with other event handlers
    document.addEventListener('mousemove', event => this.mousemove(event))
    document.addEventListener('mouseup', event => this.mouseup(event))
  }

  mousedown(table, row, event) {
    if(event.target.tagName == "TD") {
      event.preventDefault()
      this.dragObject = row
      this.currentTable = table
      this.mouseOffset = this.getMouseOffset(row, event)
      let config = table.tableDnDConfig
      if(config.onDragStart) config.onDragStart(table, row)
    }
  }

  /** Given a target element and a mouse event, get the mouse offset from that element.
    To do this we need the element's position and the mouse position */
  getMouseOffset(target, event) {
    var docPos  = this.getPosition(target)
    return {
      x: event.pageX - docPos.x,
      y: event.pageY - docPos.y,
    }
  }

  getPosition(element) {
    const rect = element.getBoundingClientRect()
    return {
        x: rect.left + window.pageXOffset,
        y: rect.top + window.pageYOffset,
    }
  }

  mousemove(event) {
    if (this.dragObject == null) {
      return
    }

    var config = this.currentTable.tableDnDConfig
    var y = event.pageY - this.mouseOffset.y
    var yOffset = window.pageYOffset
    if (event.pageY - yOffset < config.scrollAmount) {
      window.scrollBy(0, -config.scrollAmount)
    } else if(window.innerHeight - (event.pageY-yOffset) < config.scrollAmount) {
      window.scrollBy(0, config.scrollAmount)
    }

    if (y != this.oldY) {
      // work out if we're going up or down...
      var movingDown = y > this.oldY
      this.oldY = y
      this.dragObject.classList.add(config.onDragClass)
      // If we're over a row then move the dragged row to there so that the user sees the
      // effect dynamically
      var currentRow = this.findDropTargetRow(this.dragObject, y, movingDown)
      if(currentRow) {
        if (movingDown && this.dragObject != currentRow) {
          this.dragObject.parentNode.insertBefore(this.dragObject, currentRow.nextSibling)
        } else if(!movingDown && this.dragObject != currentRow) {
          this.dragObject.parentNode.insertBefore(this.dragObject, currentRow)
        }
        if(config.onDrag) {
          config.onDrag(this.currentTable, this.dragObject)
        }
      }
    }
    return false
  }

  /** We're only worried about the y position really, because we can only move rows up and down */
  findDropTargetRow(draggedRow, y, movingDown) {
    const rows = Array.from(this.currentTable.querySelectorAll("tr"))
    for (var i=0; i<rows.length; i++) {
      var row = rows[i]
      var rowY = this.getPosition(row).y
      var rowHeight = parseInt(row.offsetHeight)/2
      if (row.offsetHeight == 0) {
        rowY = this.getPosition(row.firstChild).y
        rowHeight = parseInt(row.firstChild.offsetHeight)/2
      }
      // Because we always have to insert before, we need to offset the height a bit
      if ((y > rowY - rowHeight) && (y < (rowY + rowHeight))) {
        // that's the row we're over
        // If it's the same as the current row, ignore it
        if(row == draggedRow) return
        var config = this.currentTable.tableDnDConfig
        if (config.onAllowDrop) {
          if(!config.onAllowDrop(draggedRow, row, movingDown)) return
        }
        return row
      }
    }
  }

  mouseup(e) {
    if(this.currentTable && this.dragObject) {
      var droppedRow = this.dragObject
      var config = this.currentTable.tableDnDConfig
      // If we have a dragObject, then we need to release it,
      // The row will already have been moved to the right place so we just reset stuff
      droppedRow.classList.remove(config.onDragClass)
      this.dragObject = null
      if(config.onDrop) config.onDrop(this.currentTable, droppedRow)
      this.currentTable = null; // let go of the table too
    }
  }

  teardown(table) {
    table.querySelectorAll("tr").forEach(row => {
      row.removeEventListener("mousedown", event => this.mousedown(table, row, event))
      row.style.cursor = "auto"
    })
    this.dragObject = null
    this.currentTable = null
    this.mouseOffset = null
  }
}

class Base {
  find_node(element) {
    for (var i = 0; i < this.children.length; i++) {
      var child = this.children[i]
      if (this.children[i].element == element) {
        return this.children[i]
      } else {
        var result = this.children[i].find_node(element)
        if (result) return result
      }
    }
  }

  ttnode(node) {
    var subject = node.push ? node[0] : node
    return (this.current_table || this.table_tree.current_table).find_node(subject)
  }
}

class TableTree extends Base {
  constructor(table, link) {
    super()
    this.table = table
    this.type = link.id.replace('reorder_', '')
    this.collection_url = link.href
    this.tableDnD = new TableDnD()

    link.addEventListener("click", event => {
      event.preventDefault()
      link.parentElement.classList.toggle('active')
      this.toggle()
    })

    this.tableDnDOptions = {
      onDragClass: 'drag',
      onDragStart: (table, row) => {
        this.startOffset = this.tableDnD.mouseOffset.x
        row.addEventListener("mousemove", event => this.mousemove(event))
        this.ttnode(row)?.dragStart()
      },
      onDrag: (table, row) => {
        this.current_table.dirty = true
        this.ttnode(row)?.update_children()
      },
      onDrop: (table, row) => {
        row.removeEventListener("mousemove", event => this.mousemove(event))
        this.ttnode(row)?.drop()
        this.current_table.rebuild()
        this.current_table.update_remote(row)
      },
      onAllowDrop: (draggedRow, row, movingDown) => {
        const node = this.ttnode(row)
        const next = movingDown ? node.next_row_sibling() : node
        if(next && next.parent && this.ttnode(draggedRow)) {
          if(next.parent.level >= this.ttnode(draggedRow).level) return false
        }
        return node ? true : false
      }
    }
  }

  toggle() {
    this.current_table ? this.teardown() : this.setup()
  }

  setup() {
    const tbody = this.table.querySelector('tbody')
    this.tableDnD.add(tbody, this.tableDnDOptions)
    this.current_table = new Table(this, this.table, this.type, this.collection_url)
    this.current_table.setSortable()
  }

  teardown() {
    // this.current_table.update_remote()
    this.tableDnD.teardown(this.table)
    this.current_table.setUnsortable()
    this.current_table = null
  }

  level(element) {
    var match = element.className.match(/level_([\d]+)/)
    return match ? parseInt(match[1]) : 0
  }

  mousemove(event) {
    if (!this.current_table.is_tree) return

    const element = event.target.closest("tr")
    const offset = this.tableDnD.getMouseOffset(element, event).x - this.startOffset
    if(offset > 25) {
      this.current_table.dirty = true
      this.ttnode(element).increment_level(event)
    } else if(offset < -25) {
      this.current_table.dirty = true
      this.ttnode(element).decrement_level(event)
    }
  }
}

class Table extends Base {
  constructor(table_tree, table, type, collection_url) {
    super()
    this.table_tree = table_tree
    this.is_tree = table.classList.contains('tree')
    this.table = table
    this.type = type
    this.level = -1
    this.collection_url = collection_url
    this.rebuild()
  }

  rebuild() {
    this.trs = Array.from(this.table.querySelectorAll('tr'))
    this.children = this.trs.map(tr => {
      if(this.table_tree.level(tr) === 0) {
        return new TableNode(this.table_tree, this, tr, this.table_tree.level(tr))
      }
    }).filter(e => e)
  }

  setSortable() {
    this.trs.forEach(tr => {
      // tr is in thead
      let cells = tr.querySelectorAll('th')
      cells.forEach((th, index) => {
        if(index === 0) {
          th.setAttribute('colspan', cells.length)
        } else {
          th.hidden = true
        }
      })

      // tbody
      cells = tr.querySelectorAll('td')
      cells.forEach((td, index) => {
        if (index === 0) {
          td.setAttribute('colspan', cells.length)
          td.querySelectorAll('a').forEach((a, index) => {
            a.hidden = true
            if (index === 0) {
              td.appendChild(document.createTextNode(a.innerText))
            }
          })
        } else {
          td.hidden = true
        }
      })
    })
  }

  setUnsortable() {
    this.trs.forEach(tr => {
      // tr is in thead
      let cells = tr.querySelectorAll('th')
      cells.forEach((th, index) => {
        if(index === 0) {
          this.setAttribute('colspan', 1)
        } else {
          th.hidden = false
        }
      })

      // tbody
      cells = tr.querySelectorAll('td')
      cells.forEach((td, index) => {
        if (index === 0) {
          td.querySelectorAll('a').forEach((a, index) => {
            a.hidden = false
            if (index === 0) {
              td.removeChild(td.lastChild)
            }
          })
          td.querySelector('img.spinner')?.remove()
          td.setAttribute('colspan', 1)
        } else {
          td.hidden = false
        }
      })
    })
  }

  update_remote(row) {
    if(!this.dirty) return
    this.dirty = false
    this.show_spinner(row)

    fetch(this.collection_url, {
      method: "PUT",
      body: new URLSearchParams({
        ...this.serialize(row),
        authenticity_token: window._auth_token,
      }),
    })
    .then(() => this.hide_spinner(row))
    .catch(() => this.hide_spinner(row))
  }

  serialize(row) {
    row = this.ttnode(row)
    let data = {}
    data[`${this.type}[${row.id()}][parent_id]`] = row.parent_id()
    data[`${this.type}[${row.id()}][left_id]`] = row.left_id()
    return data
  }

  show_spinner(row) {
    let img = document.createElement('img')
    img.src = 'data:image/gif;base64,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'
    img.className = 'spinner'
    row.querySelector("td").appendChild(img)
  }

  hide_spinner(row) {
    let cell = row.querySelector('td')
    cell.removeChild(cell.lastChild)
  }
}

class TableNode extends Base {
  constructor(table_tree, parent, element, level) {
    super()
    this.table_tree = table_tree
    this.parent = parent
    this.element = element
    this.level = level

    this.children = this.find_children().map(child => {
      var level = this.table_tree.level(child)
      if(level == this.level + 1) {
        return new TableNode(this.table_tree, this, child, level)
      }
    }).filter(e => e)
  }

  find_children() {
    var stop = false
    return this.row_siblings().slice(this.row_index() + 1).filter(child => {
      var level = this.table_tree.level(child)
      if(this.level == level) stop = true // how to break from an iterator?
      return !stop && this.level + 1 == level
    })
  }

  depth() {
    if (this.children.length > 0) {
      return Math.max.apply(Math, this.children.map(child => child.depth()))
    } else {
      return this.level
    }
  }

  siblings() {
    return this.parent.children
  }

  id() {
    return this.element ? this.to_int(this.element.id) : 'null'
  }

  parent_id() {
    return this.parent.element ? this.to_int(this.parent.element.id) : 'null'
  }

  left_id() {
    let left = this.left()
    return left ? this.to_int(left.element.id) : 'null'
  }

  left() {
    let siblings = this.siblings()
    let ix = siblings.indexOf(this) - 1
    if(ix >= 0) return siblings[ix]
  }

  to_int(str) {
    if(str) return str.replace(/[\D]+/, '')
  }

  next_row_sibling() {
    return this.row_siblings()[this.row_index() + 1]
  }

  row_siblings() {
    this._row_siblings ||= Array.from(this.element.parentElement.children)
    return this._row_siblings
  }

  row_index() {
    return this.row_siblings().indexOf(this.element)
  }

  dragStart() {
    this.element.classList.add('drag')
    this.children.forEach(child => child.dragStart())
  }

  drop() {
    this.element.classList.remove('drag')
    this.children.forEach(child => child.drop())
    this.adjust_level()
  }

  increment_level(event) {
    let prev = this.element.previousElementSibling
    if(prev) prev = this.ttnode(prev)
    if(!prev || prev.level < this.level || this.depth() >= 5) return
    this.update_level(event, this.level + 1)
  }

  decrement_level(event) {
    if(this.level == 0) return
    this.update_level(event, this.level - 1)
  }

  update_level(event, level) {
    if (event) this.table_tree.startOffset = this.table_tree.tableDnD.getMouseOffset(this.element, event).x

    this.element.classList.remove('level_' + this.level)
    this.element.classList.add('level_' + level)

    this.level = level
    this.children.forEach(child => child.update_level(event, level + 1))
  }

  adjust_level() {
    var prev = this.element.previousElementSibling
    if(!prev) {
      this.update_level(null, 0)
    } else if(this.ttnode(prev).level + 1 < this.level) {
      this.update_level(null, this.ttnode(prev).level + 1)
    }
  }

  update_children() {
    this.children.forEach(child => child.element.parentNode.removeChild(child.element))
    var next = this.element.nextSibling
    this.children.forEach(child => this.element.parentNode.insertBefore(child.element, next))
    this.children.forEach(child => child.update_children())
  }
}

