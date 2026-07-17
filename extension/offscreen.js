// Cooldown Offscreen Audio Player
// Uses Web Audio API to synthesize notification sounds dynamically.
// This avoids bundling binary audio files and works instantly in any Chrome environment.

chrome.runtime.onMessage.addListener((message) => {
  if (message.type === 'PLAY_AUDIO') {
    playSynthSound(message.sound);
  }
});

function playSynthSound(soundName) {
  const AudioContext = window.AudioContext || window.webkitAudioContext;
  if (!AudioContext) return;
  
  const ctx = new AudioContext();
  const dest = ctx.destination;
  
  if (soundName === 'glass') {
    // Elegant high-pitched glass chime
    const now = ctx.currentTime;
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    
    osc.type = 'sine';
    osc.frequency.setValueAtTime(1500, now);
    osc.frequency.exponentialRampToValueAtTime(800, now + 0.3);
    
    gain.gain.setValueAtTime(0.3, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.5);
    
    osc.connect(gain);
    gain.connect(dest);
    
    osc.start(now);
    osc.stop(now + 0.5);
  } else if (soundName === 'ping') {
    // Sharp retro alert ping
    const now = ctx.currentTime;
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    
    osc.type = 'triangle';
    osc.frequency.setValueAtTime(880, now);
    osc.frequency.exponentialRampToValueAtTime(1200, now + 0.15);
    
    gain.gain.setValueAtTime(0.25, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.2);
    
    osc.connect(gain);
    gain.connect(dest);
    
    osc.start(now);
    osc.stop(now + 0.2);
  } else if (soundName === 'bell') {
    // Multi-tone resonant bell
    const now = ctx.currentTime;
    const frequencies = [440, 554.37, 659.25, 880];
    
    frequencies.forEach((freq, index) => {
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();
      
      osc.type = 'sine';
      osc.frequency.setValueAtTime(freq, now);
      
      // Higher frequencies decay faster for natural bell acoustics
      const decay = 1.2 / (index + 1);
      
      gain.gain.setValueAtTime(0.15, now);
      gain.gain.exponentialRampToValueAtTime(0.001, now + decay);
      
      osc.connect(gain);
      gain.connect(dest);
      
      osc.start(now);
      osc.stop(now + decay);
    });
  } else {
    // Default sound: a double-chime synth
    const now = ctx.currentTime;
    
    // First chime
    const osc1 = ctx.createOscillator();
    const gain1 = ctx.createGain();
    osc1.type = 'sine';
    osc1.frequency.setValueAtTime(523.25, now); // C5
    gain1.gain.setValueAtTime(0.2, now);
    gain1.gain.exponentialRampToValueAtTime(0.001, now + 0.3);
    osc1.connect(gain1);
    gain1.connect(dest);
    osc1.start(now);
    osc1.stop(now + 0.3);
    
    // Second chime (slightly offset)
    const osc2 = ctx.createOscillator();
    const gain2 = ctx.createGain();
    osc2.type = 'sine';
    osc2.frequency.setValueAtTime(659.25, now + 0.12); // E5
    gain2.gain.setValueAtTime(0.2, now + 0.12);
    gain2.gain.exponentialRampToValueAtTime(0.001, now + 0.42);
    osc2.connect(gain2);
    gain2.connect(dest);
    osc2.start(now + 0.12);
    osc2.stop(now + 0.42);
  }
}
