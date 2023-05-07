document.addEventListener("DOMContentLoaded", () => {
  document.querySelector('a#add_excerpt')?.addEventListener("click", event => {
    event.preventDefault()
    document.querySelector('#article_excerpt_wrapper').hidden = false
    document.querySelector('#add_excerpt_hint').hidden = true
    document.querySelector('#hide_excerpt_hint').hidden = false
    document.querySelector('#article_excerpt').disabled = false
  })
  document.querySelector('a#hide_excerpt')?.addEventListener("click", event => {
    event.preventDefault()
    document.querySelector('#article_excerpt_wrapper').hidden = true
    document.querySelector('#add_excerpt_hint').hidden = false
    document.querySelector('#hide_excerpt_hint').hidden = true
    document.querySelector('#article_excerpt').disabled = true
  })
})
