(() => {
  "use strict";

  const OFFICES = [
    {
      id: "TW",
      code: "TW",
      name: "Taiwan",
      iana: "Asia/Taipei",
      pickerSub: "Taiwan",
    },
    {
      id: "GDL",
      code: "GDL",
      name: "Guadalajara",
      iana: "America/Mexico_City",
      pickerSub: "Guadalajara",
    },
    {
      id: "HOU",
      code: "HOU",
      name: "Houston",
      iana: "America/Chicago",
      pickerSub: "Houston",
    },
    {
      id: "SJLA",
      code: "SJ / LA",
      name: "San Jose / Los Angeles",
      iana: "America/Los_Angeles",
      pickerSub: "San Jose / LA",
      sameZone: true,
    },
  ];

  const WORLD_CITIES = [
    { name: "UTC", iana: "Etc/UTC" },
    { name: "London", iana: "Europe/London" },
    { name: "Paris", iana: "Europe/Paris" },
    { name: "Berlin", iana: "Europe/Berlin" },
    { name: "Dubai", iana: "Asia/Dubai" },
    { name: "Mumbai", iana: "Asia/Kolkata" },
    { name: "Singapore", iana: "Asia/Singapore" },
    { name: "Hong Kong", iana: "Asia/Hong_Kong" },
    { name: "Tokyo", iana: "Asia/Tokyo" },
    { name: "Seoul", iana: "Asia/Seoul" },
    { name: "Sydney", iana: "Australia/Sydney" },
    { name: "Auckland", iana: "Pacific/Auckland" },
    { name: "Sao Paulo", iana: "America/Sao_Paulo" },
    { name: "New York", iana: "America/New_York" },
    { name: "Chicago", iana: "America/Chicago" },
    { name: "Denver", iana: "America/Denver" },
    { name: "Vancouver", iana: "America/Vancouver" },
    { name: "Mexico City", iana: "America/Mexico_City" },
    { name: "Taipei", iana: "Asia/Taipei" },
    { name: "Los Angeles", iana: "America/Los_Angeles" },
  ];

  const els = {
    updateMeta: document.getElementById("updateMeta"),
    officePicker: document.getElementById("officePicker"),
    officeGrid: document.getElementById("officeGrid"),
    relativeBase: document.getElementById("relativeBase"),
    dPlusList: document.getElementById("dPlusList"),
    dMinusList: document.getElementById("dMinusList"),
    dawnList: document.getElementById("dawnList"),
  };

  let selectedOfficeId = detectDefaultOfficeId();

  function detectDefaultOfficeId() {
    try {
      const tz = Intl.DateTimeFormat().resolvedOptions().timeZone;
      const match = OFFICES.find((o) => o.iana === tz);
      if (match) return match.id;
    } catch (_) {
      /* ignore */
    }
    return "TW";
  }

  function getSelectedOffice() {
    return OFFICES.find((o) => o.id === selectedOfficeId) || OFFICES[0];
  }

  function partsFor(date, iana) {
    const fmt = new Intl.DateTimeFormat("en-US", {
      timeZone: iana,
      year: "numeric",
      month: "2-digit",
      day: "2-digit",
      weekday: "short",
      hour: "2-digit",
      minute: "2-digit",
      second: "2-digit",
      hourCycle: "h23",
    });
    const map = {};
    for (const p of fmt.formatToParts(date)) {
      if (p.type !== "literal") map[p.type] = p.value;
    }
    return map;
  }

  function formatDateTime(date, iana) {
    const p = partsFor(date, iana);
    const weekday = (p.weekday || "").replace(/\.$/, "");
    return `${p.year}-${p.month}-${p.day} (${weekday}) ${p.hour}:${p.minute}:${p.second}`;
  }

  function localYmd(date, iana) {
    const p = partsFor(date, iana);
    return `${p.year}-${p.month}-${p.day}`;
  }

  function localHour(date, iana) {
    return Number(partsFor(date, iana).hour);
  }

  function ymdToUtcNoonMs(ymd) {
    const [y, m, d] = ymd.split("-").map(Number);
    return Date.UTC(y, m - 1, d, 12, 0, 0);
  }

  function shiftYmd(ymd, dayDelta) {
    const ms = ymdToUtcNoonMs(ymd) + dayDelta * 86400000;
    const dt = new Date(ms);
    const y = dt.getUTCFullYear();
    const m = String(dt.getUTCMonth() + 1).padStart(2, "0");
    const d = String(dt.getUTCDate()).padStart(2, "0");
    return `${y}-${m}-${d}`;
  }

  function getOffsetMinutes(date, iana) {
    const dtf = new Intl.DateTimeFormat("en-US", {
      timeZone: iana,
      timeZoneName: "longOffset",
    });
    const tzName = dtf.formatToParts(date).find((p) => p.type === "timeZoneName")?.value || "";
    // GMT, GMT+8, GMT-07:00, UTC+5:30, etc.
    if (tzName === "GMT" || tzName === "UTC") return 0;
    const m = tzName.match(/(?:GMT|UTC)([+-])(\d{1,2})(?::?(\d{2}))?/);
    if (!m) {
      // Fallback: difference via locale string trick
      const asUtc = new Date(date.toLocaleString("en-US", { timeZone: "UTC" }));
      const asLocal = new Date(date.toLocaleString("en-US", { timeZone: iana }));
      return Math.round((asLocal - asUtc) / 60000);
    }
    const sign = m[1] === "-" ? -1 : 1;
    const hours = Number(m[2]);
    const mins = Number(m[3] || 0);
    return sign * (hours * 60 + mins);
  }

  function formatOffset(offsetMinutes) {
    const sign = offsetMinutes >= 0 ? "+" : "-";
    const abs = Math.abs(offsetMinutes);
    const h = Math.floor(abs / 60);
    const m = abs % 60;
    return m === 0 ? `UTC${sign}${h}` : `UTC${sign}${h}:${String(m).padStart(2, "0")}`;
  }

  function dstLabel(date, iana) {
    const year = Number(partsFor(date, iana).year);
    const jan = getOffsetMinutes(new Date(Date.UTC(year, 0, 15, 12)), iana);
    const jul = getOffsetMinutes(new Date(Date.UTC(year, 6, 15, 12)), iana);
    if (jan === jul) return "No DST";
    const dstSide = Math.max(jan, jul);
    const now = getOffsetMinutes(date, iana);
    return now === dstSide ? "DST" : "Standard";
  }

  function zoneInfo(date, iana) {
    const offset = getOffsetMinutes(date, iana);
    return {
      datetime: formatDateTime(date, iana),
      ymd: localYmd(date, iana),
      hour: localHour(date, iana),
      offsetLabel: formatOffset(offset),
      dst: dstLabel(date, iana),
    };
  }

  function escapeHtml(str) {
    return String(str)
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;");
  }

  function renderPicker() {
    els.officePicker.innerHTML = OFFICES.map((o) => {
      const checked = o.id === selectedOfficeId;
      return `<button type="button" class="picker-btn" role="radio" aria-checked="${checked}" data-id="${o.id}">
        ${escapeHtml(o.code)}
        <span class="sub">${escapeHtml(o.pickerSub)}</span>
      </button>`;
    }).join("");
  }

  function renderOffices(now) {
    els.officeGrid.innerHTML = OFFICES.map((o) => {
      const info = zoneInfo(now, o.iana);
      const isMe = o.id === selectedOfficeId;
      const dstClass = info.dst === "DST" ? "tag dst" : "tag";
      const same = o.sameZone ? `<span class="tag same-zone">Same zone</span>` : "";
      const badge = isMe ? `<span class="badge">You are here</span>` : "";
      return `<article class="office-card${isMe ? " is-me" : ""}">
        <div class="top">
          <span class="code">${escapeHtml(o.code)}</span>
          <span class="name">${escapeHtml(o.name)}</span>
          ${badge}
        </div>
        <div class="datetime">${escapeHtml(info.datetime)}</div>
        <div class="tags">
          <span class="tag">${escapeHtml(info.offsetLabel)}</span>
          <span class="${dstClass}">${escapeHtml(info.dst)}</span>
          ${same}
        </div>
      </article>`;
    }).join("");
  }

  function listHtml(items) {
    if (!items.length) {
      return `<li class="empty">None right now</li>`;
    }
    return items
      .map(
        (item) => `<li>
          <span class="city-name">${escapeHtml(item.name)}</span>
          <span class="city-time">${escapeHtml(item.datetime)}</span>
        </li>`
      )
      .join("");
  }

  function renderRelative(now) {
    const me = getSelectedOffice();
    const meInfo = zoneInfo(now, me.iana);
    els.relativeBase.textContent = `Base: ${me.code} · ${meInfo.datetime}`;

    const plusYmd = shiftYmd(meInfo.ymd, 1);
    const minusYmd = shiftYmd(meInfo.ymd, -1);

    const dPlus = [];
    const dMinus = [];
    const dawn = [];

    for (const city of WORLD_CITIES) {
      if (city.iana === me.iana) {
        // Still allow dawn list for same zone; skip D±1
        const info = zoneInfo(now, city.iana);
        if (info.hour >= 3 && info.hour < 4) {
          dawn.push({ name: city.name, datetime: info.datetime });
        }
        continue;
      }

      const info = zoneInfo(now, city.iana);
      if (info.ymd === plusYmd) dPlus.push({ name: city.name, datetime: info.datetime });
      if (info.ymd === minusYmd) dMinus.push({ name: city.name, datetime: info.datetime });
      if (info.hour >= 3 && info.hour < 4) dawn.push({ name: city.name, datetime: info.datetime });
    }

    els.dPlusList.innerHTML = listHtml(dPlus);
    els.dMinusList.innerHTML = listHtml(dMinus);
    els.dawnList.innerHTML = listHtml(dawn);
  }

  function tick() {
    const now = new Date();
    els.updateMeta.textContent = `Live · refreshes every second`;
    renderOffices(now);
    renderRelative(now);
  }

  els.officePicker.addEventListener("click", (e) => {
    const btn = e.target.closest("[data-id]");
    if (!btn) return;
    selectedOfficeId = btn.getAttribute("data-id");
    renderPicker();
    tick();
  });

  renderPicker();
  tick();
  setInterval(tick, 1000);
})();
