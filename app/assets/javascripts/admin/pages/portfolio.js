$(function() {
  $('#portfolio-more').click(function() {
    $('#portfolio-more').addClass('hidden-xs-up');
    $('#portfolio-less, .portfolio-more-content').removeClass('hidden-xs-up');
  });
  $('#portfolio-less').click(function() {
    $('#portfolio-more').removeClass('hidden-xs-up');
    $('#portfolio-less, .portfolio-more-content').addClass('hidden-xs-up');
  });
});
