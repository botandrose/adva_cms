//= require adva_cms/cookie

(function() {
  class CookieFlash {
    transferFromCookies() {
      var data = JSON.parse(unescape(Cookie.get('flash')).replace(/\+/g, ' '))
      if(!data) data = {}
      this.data = data
      Cookie.erase('flash')
    }

    show(type, message) {
      if(!this.data || this.data == {}) this.transferFromCookies()

      var flash = this.root.querySelector('#flash_' + type)
      if(!flash) return

      // if no message is given, look it up in the hash
      if(!message) message = this.data[type]

      if(!message && type == 'error') message = this.data['alert']

      if(!message) return
      
      if(message.toString().match(/<li/)) message = "<ul>" + message + '</ul>'
      flash.innerHTML = message
      flash.style.display = ""
    }
    
    showAll() {
      this.show('error')
      this.show('notice')
    }
    
    error(message) {
      this.show('error', message)
    }

    notice(message) {
      this.show('notice', message)
    }

    hide(type) {
      var flash = this.root.querySelector('#flash_' + type)
      if(!flash) return

      flash.innerHTML = ''
      flash.style.display = 'none'
    }

    hideAll() {
      this.hide('error')
      this.hide('notice')
    }
  }

  document.addEventListener("DOMContentLoaded", () => {
    Flash.root = document.body
    Flash.showAll()
  })

  window.Flash = new CookieFlash()
})()
