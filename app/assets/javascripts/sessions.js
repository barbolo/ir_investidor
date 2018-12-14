// Place all the behaviors and hooks related to the matching controller here.
// All this logic will automatically be available in application.js.

$(document).on('turbolinks:load', function () {
  if ($('#session_sheet').length > 0) {
    $('#session_sheet').change(updateFileInput);
  }

  if ($('#sheetProcessingChecklist').length > 0) {
    setTimeout(refreshPage, 2000); // refresh page every 2 seconds for updates
  }

  function updateFileInput(event) {
    try {
      let filename = $('#session_sheet').get(0).files[0].name;
      if (filename.length > 40) filename = filename.slice(0, 40) + '...';
      $('label[for="session_sheet"]').html(filename);
    } catch {}
    if (event != null) event.preventDefault();
  }

  function refreshPage() {
    Turbolinks.visit(location.toString());
  }
});
