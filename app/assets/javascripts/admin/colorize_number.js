$(function() {
  $('.colorize-number').each(function () {
    var txt = $(this).text();
    txt = txt.replace('.', '').replace(',', '.');
    txt = txt.replace(/[^0-9\-\.]/g, ''); // remove non digits
    var num = parseFloat(txt);
    if (num < 0) {
      $(this).addClass("number-negative");
    } else if (num > 0) {
      $(this).addClass("number-positive");
    }
  });
});
