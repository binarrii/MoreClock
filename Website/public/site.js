const cities = {
  'Europe/London': { name: 'London', flag: '🇬🇧' },
  'Asia/Hong_Kong': { name: 'Hong Kong', flag: '🇭🇰' },
  'America/Los_Angeles': { name: 'San Francisco', flag: '🇺🇸' },
  'Asia/Tokyo': { name: 'Tokyo', flag: '🇯🇵' },
  'Europe/Berlin': { name: 'Berlin', flag: '🇩🇪' },
};
let previewZone = 'Asia/Hong_Kong';
const citySelect = document.querySelector('#city-select');
const prefix = document.querySelector('#prefix-input');
const dateSelect = document.querySelector('#date-select');
const bold = document.querySelector('#bold-check');
const formatTime = (date, zone) => new Intl.DateTimeFormat('en-GB', {
  timeZone: zone, hour: '2-digit', minute: '2-digit', hourCycle: 'h23',
}).format(date);

function renderPreview(now) {
  for (const time of document.querySelectorAll('[data-time-zone]')) {
    time.textContent = formatTime(now, time.dataset.timeZone);
  }
  const city = cities[previewZone];
  document.querySelector('#preview-city').textContent = city.name;
  document.querySelector('#preview-flag').textContent = city.flag;
  document.querySelector('#preview-time').textContent = formatTime(now, previewZone);
  document.querySelector('#preview-date').textContent = new Intl.DateTimeFormat('en-US', {
    timeZone: previewZone, weekday: 'long', month: 'long', day: 'numeric',
  }).format(now);
  const zoneLabel = new Intl.DateTimeFormat('en', {
    timeZone: previewZone, timeZoneName: 'shortOffset',
  }).formatToParts(now).find(part => part.type === 'timeZoneName')?.value ?? '';
  document.querySelector('#preview-offset').textContent = zoneLabel.replace('GMT', 'UTC');
}
function renderSettings(now = new Date()) {
  const zone = citySelect.value;
  const city = cities[zone];
  document.querySelector('#settings-city').textContent = city.name;
  document.querySelector('#settings-flag').textContent = city.flag;
  let date = '';
  if (dateSelect.value !== 'off') {
    const options = { timeZone: zone };
    if (dateSelect.value === 'both' || dateSelect.value === 'weekday') options.weekday = 'short';
    if (dateSelect.value === 'both' || dateSelect.value === 'date') {
      options.month = 'short'; options.day = 'numeric';
    }
    date = new Intl.DateTimeFormat('en-US', options).format(now);
  }
  const output = document.querySelector('#settings-output');
  output.textContent = [prefix.value, date, formatTime(now, zone)].filter(Boolean).join(' ');
  output.style.fontWeight = bold.checked ? '700' : '400';
}
for (const button of document.querySelectorAll('[data-clock]')) {
  button.addEventListener('click', () => {
    previewZone = button.dataset.clock;
    for (const item of document.querySelectorAll('[data-clock]')) {
      item.setAttribute('aria-pressed', String(item === button));
    }
    renderPreview(new Date());
  });
}
citySelect.addEventListener('change', () => {
  // Mirrors the app: fill an empty or previous automatically chosen flag.
  if (!prefix.value || Object.values(cities).some(city => city.flag === prefix.value)) {
    prefix.value = cities[citySelect.value].flag;
  }
  renderSettings();
});
for (const control of [prefix, dateSelect, bold]) control.addEventListener('input', () => renderSettings());

const tabs = [...document.querySelectorAll('.settings-tabs [role="tab"]')];
function selectTab(active) {
  for (const tab of tabs) {
    const selected = tab === active;
    tab.setAttribute('aria-selected', String(selected));
    tab.tabIndex = selected ? 0 : -1;
    document.getElementById(tab.getAttribute('aria-controls')).hidden = !selected;
  }
}
for (const tab of tabs) {
  tab.addEventListener('click', () => selectTab(tab));
  tab.addEventListener('keydown', event => {
    let index = tabs.indexOf(tab);
    if (event.key === 'ArrowRight') index = (index + 1) % tabs.length;
    else if (event.key === 'ArrowLeft') index = (index - 1 + tabs.length) % tabs.length;
    else if (event.key === 'Home') index = 0;
    else if (event.key === 'End') index = tabs.length - 1;
    else return;
    event.preventDefault(); selectTab(tabs[index]); tabs[index].focus();
  });
}
function tick() {
  const now = new Date();
  renderPreview(now); renderSettings(now);
  window.setTimeout(tick, 60000 - (Date.now() % 60000) + 50);
}
tick();
