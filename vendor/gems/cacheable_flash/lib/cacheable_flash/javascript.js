document.addEventListener("DOMContentLoaded", () => {
  const cookie = document.cookie.match(/(^|;)\\s*flash=([^;\\s]+)/)
  if(!cookie) return
  const data = JSON.parse(unescape(cookie[2]).replaceAll("+"," "))
  document.cookie = 'flash=; path=/; expires=Sat, 01 Jan 2000 00:00:00 GMT;'

  function show(type) {
    const flash = document.querySelector('#flash_' + type)
    const message = data[type]
    if(flash && message) {
      flash.innerHTML = message
      flash.hidden = false
    }
  }
  
  show('error')
  show('alert')
  show('notice')
})
