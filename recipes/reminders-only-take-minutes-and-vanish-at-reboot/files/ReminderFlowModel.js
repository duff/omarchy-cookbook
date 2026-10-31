// How long until a reminder, the same as the remind command writes it:
// "45s", "20m", "1h 5m", "2d 3h".
function left(seconds) {
  var s = Math.ceil(Number(seconds) || 0)
  if (s <= 0) return "now"
  if (s < 60) return s + "s"
  var minutes = Math.ceil(s / 60)
  var days = Math.floor(minutes / 1440)
  var hours = Math.floor((minutes % 1440) / 60)
  minutes = minutes % 60
  if (days) return hours ? days + "d " + hours + "h" : days + "d"
  if (hours) return minutes ? hours + "h " + minutes + "m" : hours + "h"
  return minutes + "m"
}

// The row picked with the arrow keys: -1 is none, and Up from the first
// row goes back to none.
function moved(selected, count, step) {
  if (count <= 0) return -1
  if (step > 0) return Math.min(count - 1, selected + 1)
  return selected <= 0 ? -1 : selected - 1
}

if (typeof module !== "undefined") {
  module.exports = {
    left: left,
    moved: moved
  }
}
