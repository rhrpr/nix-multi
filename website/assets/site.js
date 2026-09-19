document.querySelectorAll('pre').forEach((block) => {
  if (!navigator.clipboard || !window.isSecureContext) return;
  const code = block.querySelector('code');
  if (!code) return;
  const button = document.createElement('button');
  button.className = 'copy-button';
  button.type = 'button';
  button.textContent = 'Copy';
  button.setAttribute('aria-label', 'Copy code to clipboard');
  button.addEventListener('click', async () => {
    try {
      await navigator.clipboard.writeText(code.textContent);
      button.textContent = 'Copied!';
    } catch {
      button.textContent = 'Select code to copy';
    }
    setTimeout(() => { button.textContent = 'Copy'; }, 2500);
  });
  block.append(button);
});
