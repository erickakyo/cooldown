// Cooldown Background Service Worker - Manifest V3

const DEFAULT_SETTINGS = {
  language: 'en', // 'en' or 'pt'
  appearance: 'system',
  sound: 'default',
  prealert: '0', // seconds: '0', '300' (5m), '600' (10m), '900' (15m)
  autodetect: true
};

// Initialize extension defaults on install
chrome.runtime.onInstalled.addListener(async () => {
  const data = await chrome.storage.local.get(['timers', 'settings']);
  if (!data.settings) {
    await chrome.storage.local.set({ settings: DEFAULT_SETTINGS });
  }
  if (!data.timers) {
    await chrome.storage.local.set({ timers: [] });
  }

  // Create alarm to tick timers in the background every minute (failsafe)
  chrome.alarms.create('timer-tick', { periodInMinutes: 1 });
});

// Alarm handler
chrome.alarms.onAlarm.addListener(async (alarm) => {
  if (alarm.name === 'timer-tick') {
    await tickTimers();
  }
});

// Monitor changes in timers to update badge
chrome.storage.onChanged.addListener((changes) => {
  if (changes.timers) {
    updateBadge(changes.timers.newValue || []);
  }
});

// Listen for action clicks on notifications (e.g., Re-arm timer)
chrome.notifications.onButtonClicked.addListener(async (notificationId, buttonIndex) => {
  // Notification ID is formatted as "cooldown_[timerId]_[timestamp]"
  if (notificationId.startsWith('cooldown_')) {
    const parts = notificationId.split('_');
    const timerId = parts[1];
    
    // In our notification design, button 0 is "Start new cycle" / "Começar novo ciclo"
    if (buttonIndex === 0 && timerId) {
      await rearmTimer(timerId);
      chrome.notifications.clear(notificationId);
    }
  }
});

// Listen for messages from Popups and Content Scripts
chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  if (message.type === 'PLAY_SOUND') {
    playSound(message.sound || 'default');
  } else if (message.type === 'AUTO_TRIGGER_TIMER') {
    // Content script detected message/limit
    handleAutoTrigger(message.service, message.event);
  }
  return true;
});

// Update timers tick calculation
async function tickTimers() {
  const { timers, settings } = await chrome.storage.local.get(['timers', 'settings']);
  if (!timers || timers.length === 0) return;

  const now = Date.now();
  let changed = false;
  const currentSettings = settings || DEFAULT_SETTINGS;

  const updatedTimers = timers.map(timer => {
    if (timer.state !== 'running') return timer;

    const remainingSecs = Math.max(0, Math.ceil((timer.endTime - now) / 1000));
    
    // Pre-alert alert
    const prealertLimit = parseInt(currentSettings.prealert || '0', 10);
    if (prealertLimit > 0 && remainingSecs <= prealertLimit && !timer.prealertFired) {
      firePreAlert(timer, currentSettings.language);
      timer.prealertFired = true;
      changed = true;
    }

    if (remainingSecs <= 0) {
      // Cooldown finished!
      timer.state = 'ready';
      timer.endTime = null;
      timer.prealertFired = false;
      fireCooldownFinishedAlert(timer, currentSettings);
      
      // Auto-repeat logic
      if (timer.autoRepeat) {
        timer.state = 'running';
        timer.endTime = Date.now() + (timer.durationHours * 3600 + timer.durationMinutes * 60) * 1000;
      }
      changed = true;
    }

    return timer;
  });

  if (changed) {
    await chrome.storage.local.set({ timers: updatedTimers });
  } else {
    updateBadge(updatedTimers);
  }
}

// Rearm specific timer
async function rearmTimer(timerId) {
  const { timers } = await chrome.storage.local.get('timers');
  if (!timers) return;

  const updatedTimers = timers.map(timer => {
    if (timer.id === timerId) {
      const durationMs = (timer.durationHours * 3600 + timer.durationMinutes * 60) * 1000;
      timer.state = 'running';
      timer.endTime = Date.now() + durationMs;
      timer.prealertFired = false;
    }
    return timer;
  });

  await chrome.storage.local.set({ timers: updatedTimers });
}

// Automatically trigger/rearm based on content script detector
async function handleAutoTrigger(serviceName, event) {
  const { settings } = await chrome.storage.local.get('settings');
  const currentSettings = settings || DEFAULT_SETTINGS;
  if (!currentSettings.autodetect) return;

  const { timers } = await chrome.storage.local.get('timers');
  if (!timers) return;

  let changed = false;
  const updatedTimers = timers.map(timer => {
    // Find timer of matching preset
    if (timer.preset === serviceName) {
      if (event === 'message_sent') {
        // Rearm only if it's currently Idle or Ready
        if (timer.state === 'idle' || timer.state === 'ready') {
          const durationMs = (timer.durationHours * 3600 + timer.durationMinutes * 60) * 1000;
          timer.state = 'running';
          timer.endTime = Date.now() + durationMs;
          timer.prealertFired = false;
          changed = true;
        }
      } else if (event === 'limit_reached') {
        // Reset/re-arm timer instantly
        const durationMs = (timer.durationHours * 3600 + timer.durationMinutes * 60) * 1000;
        timer.state = 'running';
        timer.endTime = Date.now() + durationMs;
        timer.prealertFired = false;
        changed = true;
      }
    }
    return timer;
  });

  if (changed) {
    await chrome.storage.local.set({ timers: updatedTimers });
  }
}

// Notifications
function firePreAlert(timer, lang) {
  const title = lang === 'pt' ? 'Limite quase redefinido' : 'Limit almost reset';
  const minutes = Math.round((timer.endTime - Date.now()) / 60000);
  const message = lang === 'pt' 
    ? `O cooldown do ${timer.displayName} termina em aproximadamente ${minutes} minutos.` 
    : `Cooldown for ${timer.displayName} finishes in approximately ${minutes} minutes.`;

  chrome.notifications.create(`prealert_${timer.id}_${Date.now()}`, {
    type: 'basic',
    iconUrl: 'assets/icon128.png',
    title: title,
    message: message,
    priority: 1
  });
}

function fireCooldownFinishedAlert(timer, settings) {
  const lang = settings.language;
  const title = lang === 'pt' ? 'Limite liberado! 🎉' : 'Limit reset! 🎉';
  const message = lang === 'pt' 
    ? `O cooldown do ${timer.displayName} acabou. Pronto para o próximo ciclo.`
    : `Cooldown for ${timer.displayName} has ended. Ready for the next cycle.`;

  const btnTitle = lang === 'pt' ? 'Comecei agora — novo ciclo' : 'Starting now — new cycle';

  chrome.notifications.create(`cooldown_${timer.id}_${Date.now()}`, {
    type: 'basic',
    iconUrl: 'assets/icon128.png',
    title: title,
    message: message,
    buttons: [{ title: btnTitle }],
    requireInteraction: true,
    priority: 2
  });

  if (settings.sound && settings.sound !== 'none') {
    playSound(settings.sound);
  }
}

// Play notification sounds
async function playSound(soundName) {
  try {
    // In Manifest V3 we use the Offscreen API to play sounds.
    // First check if offscreen document is already created
    const contexts = await chrome.runtime.getContexts({
      contextTypes: ['OFFSCREEN_DOCUMENT']
    });

    if (contexts.length === 0) {
      await chrome.offscreen.createDocument({
        url: 'offscreen.html',
        reasons: ['AUDIO_PLAYBACK'],
        justification: 'Play notification sounds when timers complete'
      });
    }

    chrome.runtime.sendMessage({
      type: 'PLAY_AUDIO',
      sound: soundName
    });
  } catch (err) {
    console.error('Error playing sound in background:', err);
  }
}

// Update Extension Badge
function updateBadge(timers) {
  const activeTimers = timers.filter(t => t.state === 'running');
  if (activeTimers.length === 0) {
    const readyTimers = timers.filter(t => t.state === 'ready');
    if (readyTimers.length > 0) {
      chrome.action.setBadgeText({ text: 'OK' });
      chrome.action.setBadgeBackgroundColor({ color: '#10b981' }); // success-green
    } else {
      chrome.action.setBadgeText({ text: '' });
    }
    return;
  }

  // Find the timer with the closest expiration
  const now = Date.now();
  let minRemainingMs = Infinity;
  activeTimers.forEach(t => {
    const remaining = t.endTime - now;
    if (remaining < minRemainingMs) {
      minRemainingMs = remaining;
    }
  });

  if (minRemainingMs === Infinity || minRemainingMs <= 0) {
    chrome.action.setBadgeText({ text: 'OK' });
    chrome.action.setBadgeBackgroundColor({ color: '#10b981' });
    return;
  }

  const hours = Math.floor(minRemainingMs / 3600000);
  const minutes = Math.ceil((minRemainingMs % 3600000) / 60000);

  let badgeText = '';
  if (hours > 0) {
    badgeText = `${hours}h`;
  } else {
    badgeText = `${minutes}m`;
  }

  chrome.action.setBadgeText({ text: badgeText });
  chrome.action.setBadgeBackgroundColor({ color: '#3b82f6' }); // accent-blue
}
