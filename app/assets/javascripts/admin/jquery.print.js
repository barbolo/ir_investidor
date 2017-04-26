function printElement(element) {
  var newWindow = window.open('', 'Print-Window');

  var html = $("html").clone();

  html.find("script").remove();

  html.find("body").html($(element).html());

  html.find("head").append(
    "<script>" +
    "setTimeout(function () { window.print(); }, 500);" +
    "window.onfocus = function () { setTimeout(function () { window.close(); }, 500); }" +
    "</script>"
  );


  newWindow.document.open();
  newWindow.document.write("<!DOCTYPE html><html>" + html.html() + "</html>");
}
