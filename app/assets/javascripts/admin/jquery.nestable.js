$(function() {
  $('.sortable-items').nestable({
    maxDepth: 2,
    threshold: 5,
    listNodeName: 'ul',
    expandBtnHTML: '',
    collapseBtnHTML: ''
  });
  var save_changes_btn = $('#save-changes');

  function updateSortableItems() {
    // update each item
    var items = $('.sortable-items .dd-handle');
    $.each(items, function(index, item) {
      var parent = $(item).parents('.dd-list').parents('.dd-item');
      if ($(parent).is('.dd-item')) { // has parent

        // if parent is removed, the item should also be removed
        if ($(parent).find('> .dd-handle').hasClass('dd-nodrag')) {
          $(item).addClass('dd-nodrag');
          $(item).find('.destroy input').prop('checked', true);
        }

        // set parent id
        $(item).find('input.parent-id').val($(parent).find('> .dd-handle input.id').val());
      } else { // doesn't have a parent
        // unset parent id
        $(item).find('input.parent-id').val(null);
      }

      // set position
      $(item).find('input.position').val(index);
    });

    // enable save changes button
    if (typeof save_changes_btn.attr('disabled') != 'undefined') {
      save_changes_btn.removeAttr('disabled');
    }
  }
  $('.sortable-items').on('change', updateSortableItems);

  // Clicking at destroy checkbox
  $('.sortable-items .destroy input').change(function(event) {
    var item = $(event.target).parents('.dd-handle');
    if (item.hasClass('dd-nodrag')) {
      // undestroy
      item.removeClass('dd-nodrag');
      // undestroy children if is a parent
      var children = $(item).parents('.dd-item').find('.dd-list');
      if (children.is('.dd-list')) { // is a parent
        $(children).find('.dd-handle').removeClass('dd-nodrag');
        $(children).find('.destroy input').prop('checked', false);
      }
    } else {
      // destroy
      item.addClass('dd-nodrag');
    }
    updateSortableItems();
  });

  save_changes_btn.click(function() {
    save_changes_btn.parents('.sortable-items-container').find('form').submit();
  });
});
