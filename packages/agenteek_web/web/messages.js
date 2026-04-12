window.toggleMessage = function (id) {
  if (!id) return;
  var el = document.getElementById(id);
  if (el) el.classList.toggle('collapsed');
};

window.copyMessageHtml = function (event, btn) {
  event.stopPropagation();
  if (!btn) return;
  var el = btn.closest('.message');
  if (el) {
    var clone = el.cloneNode(true);
    var aside = clone.querySelector('aside');
    if (aside) aside.remove();
    var copyBtn = clone.querySelector('.copy-btn');
    if (copyBtn) copyBtn.remove();

    var html = clone.innerHTML;
    var text = clone.innerText;

    if (navigator.clipboard && navigator.clipboard.write) {
      var htmlBlob = new Blob([html], { type: 'text/html' });
      var textBlob = new Blob([text], { type: 'text/plain' });
      var clipboardItem = new ClipboardItem({
        'text/html': htmlBlob,
        'text/plain': textBlob
      });
      navigator.clipboard.write([clipboardItem]).then(showSuccess).catch(fallbackCopy);
    } else {
      // Fallback if full clipboard API is not supported
      fallbackCopy();
    }

    function fallbackCopy() {
      navigator.clipboard.writeText(html.trim()).then(showSuccess);
    }

    function showSuccess() {
      var originalText = btn.innerHTML;
      btn.innerHTML = '✓';
      setTimeout(function () {
        btn.innerHTML = originalText;
      }, 2000);
    }
  }
};
