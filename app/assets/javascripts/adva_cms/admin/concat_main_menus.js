// concatenate successive sites main menus together. this allows for extension in other engines. pretty lame.
document.addEventListener("DOMContentLoaded", () => {
  let first = null
  Array.from(document.querySelectorAll("#top > .main")).forEach((element, index) => {
    if(index === 0) {
      first = element
    } else {
      first.insertAdjacentHTML("beforeend", element.innerHTML)
      element.remove()
    }
  })
})

