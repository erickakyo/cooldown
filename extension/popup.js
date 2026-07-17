// Cooldown Popup Script - Liquid Glass Interface Logic

const TRANSLATIONS = {
  en: {
    updateAvailable: "Update available!",
    download: "Download",
    noTimers: "No timers configured yet.",
    addFirstTimer: "Add Your First Timer",
    settings: "Settings",
    language: "Language",
    appearance: "Appearance",
    themeSystem: "System",
    themeLight: "Light",
    themeDark: "Dark",
    sound: "Notification Sound",
    soundDefault: "Default",
    soundNone: "None",
    preAlert: "Pre-Alert Warning",
    preAlertNone: "None",
    preAlert5m: "5 minutes before",
    preAlert10m: "10 minutes before",
    preAlert15m: "15 minutes before",
    autoDetectLimits: "Auto-detect AI limit messages",
    autoDetectHelp: "Automatically triggers/resets Cooldown timers when you send messages or hit limits on Claude, ChatGPT or Gemini.",
    about: "About Cooldown",
    supportCoffee: "Buy me a coffee ☕",
    addTimer: "Add Timer",
    editTimer: "Edit Timer",
    servicePreset: "Service Preset",
    customPreset: "Custom",
    displayName: "Display Name",
    duration: "Duration",
    hoursShort: "h",
    minutesShort: "m",
    autoRepeat: "Auto-repeat cycles",
    autoRepeatHelp: "Starts a new cycle immediately after expiring (can drift from real AI window resets).",
    delete: "Delete",
    save: "Save",
    aboutDesc: "A lightweight timer that alerts you when your AI limits reset. No accounts, no data leaves your browser.",
    donateTitle: "Buy me a coffee ☕",
    donateIntro: "Cooldown is free and open source. If it saves you from staring at limit screen warnings, support the project!",
    pixCode: "Pix Copy & Paste Key:",
    copy: "Copy",
    copied: "Copied!",
    ready: "Ready!",
    idle: "Idle",
    running: "Running",
    startingNow: "Starting now — new cycle",
    adjust: "Adjust"
  },
  pt: {
    updateAvailable: "Atualização disponível!",
    download: "Baixar",
    noTimers: "Nenhum timer configurado ainda.",
    addFirstTimer: "Adicionar Meu Primeiro Timer",
    settings: "Ajustes",
    language: "Idioma",
    appearance: "Aparência",
    themeSystem: "Sistema",
    themeLight: "Claro",
    themeDark: "Escuro",
    sound: "Som de Notificação",
    soundDefault: "Padrão",
    soundNone: "Nenhum",
    preAlert: "Aviso de Pré-Alerta",
    preAlertNone: "Nenhum",
    preAlert5m: "5 minutos antes",
    preAlert10m: "10 minutos antes",
    preAlert15m: "15 minutos antes",
    autoDetectLimits: "Auto-detectar mensagens de limite de IA",
    autoDetectHelp: "Inicia/re-arma timers automaticamente ao enviar mensagens ou atingir limites no Claude, ChatGPT ou Gemini.",
    about: "Sobre o Cooldown",
    supportCoffee: "Buy me a coffee ☕",
    addTimer: "Adicionar Timer",
    editTimer: "Editar Timer",
    servicePreset: "Preset de Serviço",
    customPreset: "Personalizado",
    displayName: "Nome de Exibição",
    duration: "Duração",
    hoursShort: "h",
    minutesShort: "m",
    autoRepeat: "Auto-repetir ciclos",
    autoRepeatHelp: "Inicia um novo ciclo imediatamente após expirar (pode desalinhar do reset real da IA).",
    delete: "Excluir",
    save: "Salvar",
    aboutDesc: "Um timer leve que avisa quando os limites da sua IA resetam. Sem contas, nenhum dado sai do seu navegador.",
    donateTitle: "Buy me a coffee ☕",
    donateIntro: "O Cooldown é gratuito e de código aberto. Se ele te livra de ficar olhando para avisos de limite, apoie o projeto!",
    pixCode: "Chave Pix Copia e Cola:",
    copy: "Copiar",
    copied: "Copiado!",
    ready: "Liberado!",
    idle: "Inativo",
    running: "Executando",
    startingNow: "Comecei agora — novo ciclo",
    adjust: "Ajustar"
  }
};

const PRESETS = {
  claude: { name: 'Claude', hours: 5, minutes: 0 },
  chatgpt: { name: 'ChatGPT', hours: 3, minutes: 0 },
  gemini: { name: 'Gemini', hours: 24, minutes: 0 },
  antigravity: { name: 'Antigravity', hours: 5, minutes: 0 },
  codex: { name: 'Codex', hours: 5, minutes: 0 }
};

let currentLanguage = 'en';
let activeTimers = [];
let appSettings = {};
let countdownInterval = null;

// Initialize
document.addEventListener('DOMContentLoaded', async () => {
  await loadData();
  setupNavigation();
  setupSettingsHandlers();
  setupFormHandlers();
  setupDonationHandlers();
  applyLanguage(currentLanguage);
  applyTheme(appSettings.appearance);
  renderTimers();
  checkUpdates();

  // Ticks the UI every second to keep clocks accurate
  countdownInterval = setInterval(updateClocks, 1000);

  // Monitor changes from background script in real-time
  chrome.storage.onChanged.addListener((changes) => {
    if (changes.timers) {
      activeTimers = changes.timers.newValue || [];
      renderTimers();
    }
    if (changes.settings) {
      appSettings = changes.settings.newValue || {};
      currentLanguage = appSettings.language || 'en';
      applyLanguage(currentLanguage);
      applyTheme(appSettings.appearance);
    }
  });
});

async function loadData() {
  const data = await chrome.storage.local.get(['timers', 'settings']);
  activeTimers = data.timers || [];
  appSettings = data.settings || {};
  currentLanguage = appSettings.language || 'en';
}

// Navigation flow
function setupNavigation() {
  const showView = (viewId) => {
    document.querySelectorAll('.view').forEach(v => v.classList.remove('active'));
    document.getElementById(viewId).classList.add('active');
  };

  document.getElementById('btn-goto-settings').addEventListener('click', () => showView('view-settings'));
  document.getElementById('btn-settings-back').addEventListener('click', () => showView('view-main'));
  
  document.getElementById('btn-goto-add').addEventListener('click', () => {
    prepareTimerForm();
    showView('view-edit');
  });
  document.getElementById('btn-onboarding-add').addEventListener('click', () => {
    prepareTimerForm();
    showView('view-edit');
  });
  document.getElementById('btn-edit-back').addEventListener('click', () => showView('view-main'));

  document.getElementById('btn-goto-about').addEventListener('click', () => showView('view-about'));
  document.getElementById('btn-about-back').addEventListener('click', () => showView('view-settings'));

  document.getElementById('btn-goto-donate').addEventListener('click', () => showView('view-donate'));
  document.getElementById('btn-donate-back').addEventListener('click', () => showView('view-settings'));
}

// Settings changes handler
function setupSettingsHandlers() {
  const langSelect = document.getElementById('setting-language');
  const appSelect = document.getElementById('setting-appearance');
  const soundSelect = document.getElementById('setting-sound');
  const alertSelect = document.getElementById('setting-prealert');
  const detectCheck = document.getElementById('setting-autodetect');

  // Load values
  langSelect.value = appSettings.language || 'en';
  appSelect.value = appSettings.appearance || 'system';
  soundSelect.value = appSettings.sound || 'default';
  alertSelect.value = appSettings.prealert || '0';
  detectCheck.checked = appSettings.autodetect !== false;

  // Save on change
  const saveSettings = async () => {
    appSettings = {
      language: langSelect.value,
      appearance: appSelect.value,
      sound: soundSelect.value,
      prealert: alertSelect.value,
      autodetect: detectCheck.checked
    };
    await chrome.storage.local.set({ settings: appSettings });
  };

  langSelect.addEventListener('change', saveSettings);
  appSelect.addEventListener('change', saveSettings);
  soundSelect.addEventListener('change', saveSettings);
  alertSelect.addEventListener('change', saveSettings);
  detectCheck.addEventListener('change', saveSettings);

  // Play preview sound
  document.getElementById('btn-preview-sound').addEventListener('click', () => {
    chrome.runtime.sendMessage({
      type: 'PLAY_SOUND',
      sound: soundSelect.value
    });
  });
}

// Timer Form and Presets logic
function prepareTimerForm(timerId = null) {
  const form = document.getElementById('timer-form');
  const title = document.getElementById('edit-view-title');
  const deleteBtn = document.getElementById('btn-delete-timer');
  
  form.reset();
  
  // Clear active preset classes
  document.querySelectorAll('.preset-btn').forEach(btn => btn.classList.remove('active'));

  if (timerId) {
    // Edit mode
    title.setAttribute('data-l10n', 'editTimer');
    deleteBtn.classList.remove('hidden');
    
    const timer = activeTimers.find(t => t.id === timerId);
    if (timer) {
      document.getElementById('timer-id').value = timer.id;
      document.getElementById('timer-name').value = timer.displayName;
      document.getElementById('timer-hours').value = timer.durationHours;
      document.getElementById('timer-minutes').value = timer.durationMinutes;
      document.getElementById('timer-autorepeat').checked = timer.autoRepeat;
      
      if (timer.preset) {
        const btn = document.querySelector(`.preset-btn[data-preset="${timer.preset}"]`);
        if (btn) btn.classList.add('active');
      } else {
        const btn = document.querySelector(`.preset-btn[data-preset="custom"]`);
        if (btn) btn.classList.add('active');
      }
    }
  } else {
    // Add mode
    title.setAttribute('data-l10n', 'addTimer');
    deleteBtn.classList.add('hidden');
    document.getElementById('timer-id').value = '';
    
    // Select Claude by default
    const claudeBtn = document.querySelector('.preset-btn[data-preset="claude"]');
    if (claudeBtn) {
      claudeBtn.click();
    }
  }
  applyLanguage(currentLanguage);
}

function setupFormHandlers() {
  // Preset buttons grid click
  document.querySelectorAll('.preset-btn').forEach(btn => {
    btn.addEventListener('click', () => {
      document.querySelectorAll('.preset-btn').forEach(b => b.classList.remove('active'));
      btn.classList.add('active');

      const presetKey = btn.getAttribute('data-preset');
      if (presetKey !== 'custom' && PRESETS[presetKey]) {
        const p = PRESETS[presetKey];
        document.getElementById('timer-name').value = p.name;
        document.getElementById('timer-hours').value = p.hours;
        document.getElementById('timer-minutes').value = p.minutes;
      }
    });
  });

  // Submit form
  document.getElementById('timer-form').addEventListener('submit', async (e) => {
    e.preventDefault();

    const id = document.getElementById('timer-id').value;
    const name = document.getElementById('timer-name').value;
    const hours = parseInt(document.getElementById('timer-hours').value, 10) || 0;
    const minutes = parseInt(document.getElementById('timer-minutes').value, 10) || 0;
    const autoRepeat = document.getElementById('timer-autorepeat').checked;
    
    const activePresetBtn = document.querySelector('.preset-btn.active');
    const preset = activePresetBtn ? activePresetBtn.getAttribute('data-preset') : 'custom';

    if (id) {
      // Update timer
      activeTimers = activeTimers.map(t => {
        if (t.id === id) {
          t.displayName = name;
          t.durationHours = hours;
          t.durationMinutes = minutes;
          t.autoRepeat = autoRepeat;
          t.preset = preset === 'custom' ? null : preset;
          
          // Re-calculate ends if it is running
          if (t.state === 'running') {
            const currentDurationMs = (hours * 3600 + minutes * 60) * 1000;
            t.endTime = Date.now() + currentDurationMs;
          }
        }
        return t;
      });
    } else {
      // Create new timer (State: 'ready' / 'liberado' by default)
      const newTimer = {
        id: crypto.randomUUID(),
        displayName: name,
        durationHours: hours,
        durationMinutes: minutes,
        autoRepeat: autoRepeat,
        preset: preset === 'custom' ? null : preset,
        state: 'ready', // ready, running, idle
        endTime: null,
        prealertFired: false
      };
      activeTimers.push(newTimer);
    }

    await chrome.storage.local.set({ timers: activeTimers });
    document.getElementById('btn-edit-back').click(); // Go back to main
  });

  // Delete timer
  document.getElementById('btn-delete-timer').addEventListener('click', async () => {
    const id = document.getElementById('timer-id').value;
    if (id) {
      activeTimers = activeTimers.filter(t => t.id !== id);
      await chrome.storage.local.set({ timers: activeTimers });
      document.getElementById('btn-edit-back').click();
    }
  });
}

// Donation screen handlers
function setupDonationHandlers() {
  document.getElementById('btn-copy-pix').addEventListener('click', () => {
    const code = document.getElementById('pix-code').innerText;
    navigator.clipboard.writeText(code).then(() => {
      const toast = document.getElementById('copy-toast');
      toast.classList.remove('hidden');
      setTimeout(() => {
        toast.classList.add('hidden');
      }, 2000);
    });
  });
}

// Render dynamic timer cards
function renderTimers() {
  const container = document.getElementById('timers-container');
  const emptyState = document.getElementById('empty-state');
  
  container.innerHTML = '';
  
  if (activeTimers.length === 0) {
    emptyState.classList.remove('hidden');
    return;
  }
  
  emptyState.classList.add('hidden');
  const l = TRANSLATIONS[currentLanguage];

  activeTimers.forEach(timer => {
    const card = document.createElement('div');
    card.className = `timer-card state-${timer.state}`;
    card.setAttribute('data-id', timer.id);

    let stateBadge = '';
    let countdownText = '00:00:00';
    let actionButtons = '';

    if (timer.state === 'ready') {
      stateBadge = l.ready;
      countdownText = l.ready;
      actionButtons = `
        <button class="rearm-button btn-action-rearm">▶ ${l.startingNow}</button>
      `;
    } else if (timer.state === 'running') {
      stateBadge = l.running;
      countdownText = calculateRemainingStr(timer.endTime);
      actionButtons = `
        <button class="adjust-button btn-action-adjust">${l.adjust}</button>
      `;
    } else {
      stateBadge = l.idle;
      countdownText = formatDuration(timer.durationHours, timer.durationMinutes);
      actionButtons = `
        <button class="rearm-button btn-action-rearm">▶ ${l.startingNow}</button>
      `;
    }

    card.innerHTML = `
      <div class="timer-card-header">
        <div class="timer-info">
          <span class="timer-name">${escapeHtml(timer.displayName)}</span>
          <span class="timer-badge">${stateBadge}</span>
        </div>
        <button class="icon-button btn-card-edit">✏️</button>
      </div>
      <div class="timer-countdown" id="clock-${timer.id}">${countdownText}</div>
      <div class="timer-card-actions">
        ${actionButtons}
      </div>
    `;

    // Attach button events
    card.querySelector('.btn-card-edit').addEventListener('click', (e) => {
      e.stopPropagation();
      prepareTimerForm(timer.id);
      document.querySelectorAll('.view').forEach(v => v.classList.remove('active'));
      document.getElementById('view-edit').classList.add('active');
    });

    const rearmBtn = card.querySelector('.btn-action-rearm');
    if (rearmBtn) {
      rearmBtn.addEventListener('click', async () => {
        const durationMs = (timer.durationHours * 3600 + timer.durationMinutes * 60) * 1000;
        timer.state = 'running';
        timer.endTime = Date.now() + durationMs;
        timer.prealertFired = false;
        await chrome.storage.local.set({ timers: activeTimers });
      });
    }

    const adjustBtn = card.querySelector('.btn-action-adjust');
    if (adjustBtn) {
      adjustBtn.addEventListener('click', () => {
        // Quick adjust: add/subtract or input custom time
        const val = prompt(currentLanguage === 'pt' ? 'Informe o novo tempo (ex: 5h, 45m ou 2h30m):' : 'Enter new duration (e.g. 5h, 45m or 2h30m):');
        if (val) {
          const parsedMs = parseAdjustment(val);
          if (parsedMs !== null) {
            timer.endTime = Date.now() + parsedMs;
            chrome.storage.local.set({ timers: activeTimers });
          } else {
            alert(currentLanguage === 'pt' ? 'Formato inválido. Use algo como "2h" ou "30m".' : 'Invalid format. Use something like "2h" or "30m".');
          }
        }
      });
    }

    container.appendChild(card);
  });
}

// Timer clock ticker
function updateClocks() {
  activeTimers.forEach(timer => {
    if (timer.state !== 'running') return;
    const clockEl = document.getElementById(`clock-${timer.id}`);
    if (clockEl) {
      clockEl.innerText = calculateRemainingStr(timer.endTime);
    }
  });
}

// Helpers
function calculateRemainingStr(endTime) {
  const diff = endTime - Date.now();
  if (diff <= 0) return '00:00:00';

  const secs = Math.floor(diff / 1000);
  const h = Math.floor(secs / 3600);
  const m = Math.floor((secs % 3600) / 60);
  const s = secs % 60;

  return [h, m, s].map(v => String(v).padStart(2, '0')).join(':');
}

function formatDuration(hours, minutes) {
  return `${String(hours).padStart(2, '0')}:${String(minutes).padStart(2, '0')}:00`;
}

function parseAdjustment(str) {
  const regex = /^(?:(\d+)h)?\s*(?:(\d+)m)?$/i;
  const match = str.trim().match(regex);
  if (!match) return null;

  const h = parseInt(match[1], 10) || 0;
  const m = parseInt(match[2], 10) || 0;
  if (h === 0 && m === 0) return null;

  return (h * 3600 + m * 60) * 1000;
}

// Apply localization strings
function applyLanguage(lang) {
  currentLanguage = lang;
  const catalog = TRANSLATIONS[lang];
  
  document.querySelectorAll('[data-l10n]').forEach(el => {
    const key = el.getAttribute('data-l10n');
    if (catalog[key]) {
      if (el.tagName === 'INPUT' && el.type === 'submit') {
        el.value = catalog[key];
      } else {
        el.innerText = catalog[key];
      }
    }
  });
  
  // Form placeholders
  const nameInput = document.getElementById('timer-name');
  if (nameInput) {
    nameInput.placeholder = lang === 'pt' ? 'Ex: Claude — Trabalho' : 'e.g. Claude — Work';
  }
}

// Apply Theme
function applyTheme(theme) {
  const body = document.body;
  body.classList.remove('theme-light', 'theme-dark');
  
  if (theme === 'system') {
    const systemIsDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
    body.classList.add(systemIsDark ? 'theme-dark' : 'theme-light');
  } else if (theme === 'light') {
    body.classList.add('theme-light');
  } else {
    body.classList.add('theme-dark');
  }
}

function checkUpdates() {
  // Simple check mock - real checks pull from releases API
  fetch('https://api.github.com/repos/erickakyo/cooldown/releases/latest')
    .then(r => r.json())
    .then(data => {
      // If extension version is older, show banner (comparing simple semver)
      const currentVer = '1.0.0';
      if (data.tag_name && data.tag_name.replace('v', '') > currentVer) {
        document.getElementById('update-banner').classList.remove('hidden');
      }
    })
    .catch(() => {});
}

function escapeHtml(unsafe) {
  return unsafe
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&#039;");
}
