// Cooldown Content Script
// Automatically detects message inputs and limits on Claude, ChatGPT, and Gemini.

(function() {
  let detectedService = null;
  const hostname = window.location.hostname;

  if (hostname.includes('claude.ai')) {
    detectedService = 'claude';
  } else if (hostname.includes('chatgpt.com')) {
    detectedService = 'chatgpt';
  } else if (hostname.includes('gemini.google.com')) {
    detectedService = 'gemini';
  }

  if (!detectedService) return;

  console.log(`[Cooldown] Auto-detector active for ${detectedService}`);

  // Listen for keydown (Enter key) on textareas
  document.addEventListener('keydown', (e) => {
    if (e.key === 'Enter' && !e.shiftKey) {
      const target = e.target;
      if (target && (target.tagName === 'TEXTAREA' || target.getAttribute('contenteditable') === 'true')) {
        // Double check it's a message editor
        if (isMessageInput(target)) {
          notifyMessageSent();
        }
      }
    }
  }, true);

  // Listen for clicks on send buttons
  document.addEventListener('click', (e) => {
    const target = e.target;
    if (!target) return;
    
    // Look up parent elements if the click was on an icon inside the button
    const button = target.closest('button');
    if (button && isSendButton(button)) {
      notifyMessageSent();
    }
  }, true);

  // Observe page mutations to detect warning/limit banners
  const observer = new MutationObserver((mutations) => {
    for (const mutation of mutations) {
      if (mutation.addedNodes.length > 0) {
        mutation.addedNodes.forEach(node => {
          if (node.nodeType === Node.ELEMENT_NODE) {
            checkElementForLimits(node);
          }
        });
      }
    }
  });

  observer.observe(document.body, {
    childList: true,
    subtree: true
  });

  // Initial check on page load
  checkElementForLimits(document.body);

  // Helper: check if element contains limit warnings
  function checkElementForLimits(element) {
    const text = element.innerText || '';
    if (!text) return;

    if (detectedService === 'claude') {
      // Claude limits: "You are out of messages", "try again at", "message limit reached"
      if (text.includes('out of messages') || text.includes('message limit reached') || text.includes('try again at')) {
        notifyLimitReached();
      }
    } else if (detectedService === 'chatgpt') {
      // ChatGPT limits: "You've hit the limit", "try again after", "You have reached your limit"
      if (text.includes("You've reached your limit") || text.includes('hit the subscription limit') || text.includes('try again after')) {
        notifyLimitReached();
      }
    } else if (detectedService === 'gemini') {
      // Gemini limits: "standard limit", "quota exceeded", "please try again later"
      if (text.includes('quota exceeded') || text.includes('reached your limit') || text.includes('try again later')) {
        notifyLimitReached();
      }
    }
  }

  // Helper: check if input field is indeed the main chat box
  function isMessageInput(el) {
    const placeholder = (el.placeholder || el.getAttribute('placeholder') || '').toLowerCase();
    const id = (el.id || '').toLowerCase();
    const className = (el.className || '').toLowerCase();
    
    return placeholder.includes('message') || 
           placeholder.includes('chat') || 
           placeholder.includes('pergunte') || 
           placeholder.includes('escreva') ||
           id.includes('prompt') || 
           className.includes('prompt') ||
           el.getAttribute('role') === 'textbox';
  }

  // Helper: check if button is indeed a send button
  function isSendButton(btn) {
    const label = (btn.getAttribute('aria-label') || btn.title || btn.innerText || '').toLowerCase();
    const className = (btn.className || '').toLowerCase();
    
    return label.includes('send') || 
           label.includes('enviar') || 
           label.includes('submit') ||
           className.includes('send') ||
           btn.querySelector('svg') !== null && (label.includes('message') || label.includes('arrow'));
  }

  // Notify background that a prompt was sent
  let lastSentTime = 0;
  function notifyMessageSent() {
    const now = Date.now();
    // Throttle triggers to avoid duplicates
    if (now - lastSentTime < 2000) return;
    lastSentTime = now;

    chrome.runtime.sendMessage({
      type: 'AUTO_TRIGGER_TIMER',
      service: detectedService,
      event: 'message_sent'
    });
  }

  // Notify background that a limit warning was shown
  let lastLimitTime = 0;
  function notifyLimitReached() {
    const now = Date.now();
    if (now - lastLimitTime < 5000) return;
    lastLimitTime = now;

    chrome.runtime.sendMessage({
      type: 'AUTO_TRIGGER_TIMER',
      service: detectedService,
      event: 'limit_reached'
    });
  }
})();
