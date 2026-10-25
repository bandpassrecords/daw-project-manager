// The guide's screenshots open full size on a click; a click, Esc or × closes.
(() => {
  const box = document.createElement('div');
  box.className = 'guide-lightbox';
  box.setAttribute('role', 'dialog');
  box.setAttribute('aria-modal', 'true');
  box.setAttribute('aria-label', 'Screenshot, enlarged');
  box.innerHTML = '<button type="button" aria-label="Close">×</button><img alt="">';
  document.body.append(box);
  const img = box.querySelector('img');
  const close = () => box.classList.remove('open');
  document.addEventListener('click', (e) => {
    const shot = e.target.closest('.shot img');
    if (shot) {
      img.src = shot.currentSrc || shot.src;
      img.alt = shot.alt;
      box.classList.add('open');
    } else if (box.contains(e.target)) {
      close();
    }
  });
  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') close();
  });
})();
