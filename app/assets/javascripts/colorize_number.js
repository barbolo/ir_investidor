$(document).on('turbolinks:load', function () {
  $('.colorize-number').each(function () {
    let txt = $(this).text();
    txt = txt.replace('.', '').replace(',', '.');
    txt = txt.replace(/[^0-9\-\.]/g, ''); // remove non digits
    const num = parseFloat(txt);
    if (num < 0) {
      $(this).addClass("text-danger");
    } else if (num > 0) {
      $(this).addClass("text-success");
    }
  });
});
