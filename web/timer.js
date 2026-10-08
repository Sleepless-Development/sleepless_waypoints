let state = null;
let raf = 0;
let chartStyle = null;

const root = document.getElementById("timer");
const labelEl = root.querySelector(".tm-label");
const valueEl = root.querySelector(".tm-value");
const fillEl = root.querySelector(".tm-fill");
const segmentEls = [...root.querySelectorAll(".tm-segments span")];
const chart = document.getElementById("tm-chart");

const LEFT_STYLES = { pill: true, bar: true };

async function fetchNui(eventName, data) {
    const resp = await fetch(`https://sleepless_waypoints/${eventName}`, {
        method: "post",
        headers: { "Content-Type": "application/json; charset=UTF-8" },
        body: JSON.stringify(data),
    });

    return await resp.json();
}

function formatClock(ms) {
    const total = Math.max(0, Math.ceil(ms / 1000));
    const minutes = Math.floor(total / 60);
    const seconds = total % 60;
    return `${minutes}:${String(seconds).padStart(2, "0")}`;
}

function formatLeft(ms) {
    const total = Math.max(0, Math.ceil(ms / 1000));
    if (total >= 60) return formatClock(ms);
    return `${total}s left`;
}

function formatPercent(progress) {
    return `${Math.round(progress * 100)}%`;
}

function readout(progress, remaining) {
    if (state.mode === "script") return formatPercent(progress);
    if (LEFT_STYLES[state.style]) return formatLeft(remaining);
    return formatClock(remaining);
}

function ringSegment(cx, cy, inner, outer, a0, a1) {
    const point = (radius, angle) => [cx + radius * Math.cos(angle), cy + radius * Math.sin(angle)];
    const [x0, y0] = point(outer, a0);
    const [x1, y1] = point(outer, a1);
    const [x2, y2] = point(inner, a1);
    const [x3, y3] = point(inner, a0);
    const large = a1 - a0 > Math.PI ? 1 : 0;
    return `M ${x0.toFixed(2)} ${y0.toFixed(2)} A ${outer} ${outer} 0 ${large} 1 ${x1.toFixed(2)} ${y1.toFixed(2)} L ${x2.toFixed(2)} ${y2.toFixed(2)} A ${inner} ${inner} 0 ${large} 0 ${x3.toFixed(2)} ${y3.toFixed(2)} Z`;
}

function piePath(progress) {
    const amount = Math.min(1, Math.max(0, progress));
    if (amount <= 0) return "M 50 50";
    if (amount >= 0.999) {
        return "M 50 4 A 46 46 0 1 1 49.99 4 A 46 46 0 1 1 50 4 Z";
    }

    const angle = amount * Math.PI * 2 - Math.PI / 2;
    const x = 50 + 46 * Math.cos(angle);
    const y = 50 + 46 * Math.sin(angle);
    const large = amount > 0.5 ? 1 : 0;
    return `M 50 50 L 50 4 A 46 46 0 ${large} 1 ${x.toFixed(2)} ${y.toFixed(2)} Z`;
}

function arcPath(cx, cy, radius, a0, a1) {
    const x0 = cx + radius * Math.cos(a0);
    const y0 = cy + radius * Math.sin(a0);
    const x1 = cx + radius * Math.cos(a1);
    const y1 = cy + radius * Math.sin(a1);
    const large = a1 - a0 > Math.PI ? 1 : 0;
    return `M ${x0.toFixed(2)} ${y0.toFixed(2)} A ${radius} ${radius} 0 ${large} 1 ${x1.toFixed(2)} ${y1.toFixed(2)}`;
}

function svgEl(name, attrs) {
    const node = document.createElementNS("http://www.w3.org/2000/svg", name);
    for (const key in attrs) node.setAttribute(key, attrs[key]);
    return node;
}

function buildChart(style) {
    if (chartStyle === style) return;
    chartStyle = style;
    chart.replaceChildren();

    if (style === "dial") {
        chart.setAttribute("viewBox", "0 0 100 100");
        const sweep = (Math.PI * 2) / 12;
        for (let i = 0; i < 12; i += 1) {
            const gap = 0.05;
            const a0 = -Math.PI / 2 + i * sweep + gap;
            const a1 = -Math.PI / 2 + (i + 1) * sweep - gap;
            chart.appendChild(svgEl("path", { d: ringSegment(50, 50, 32, 46, a0, a1), class: "tm-seg" }));
        }
        return;
    }

    if (style === "pie") {
        chart.setAttribute("viewBox", "0 0 100 100");
        chart.appendChild(svgEl("circle", { cx: "50", cy: "50", r: "46", class: "tm-pie-bg" }));
        chart.appendChild(svgEl("path", { d: "", class: "tm-wedge" }));
        return;
    }

    if (style === "donut") {
        chart.setAttribute("viewBox", "0 0 100 100");
        chart.appendChild(svgEl("circle", {
            cx: "50",
            cy: "50",
            r: "36",
            class: "tm-donut-track",
            pathLength: "100",
            transform: "rotate(-90 50 50)",
        }));
        chart.appendChild(svgEl("circle", {
            cx: "50",
            cy: "50",
            r: "36",
            class: "tm-donut-fill",
            pathLength: "100",
            "stroke-dasharray": "100",
            "stroke-dashoffset": "100",
            transform: "rotate(-90 50 50)",
        }));
        return;
    }

    if (style === "dots") {
        chart.setAttribute("viewBox", "0 0 300 44");
        for (let i = 0; i < 5; i += 1) {
            chart.appendChild(svgEl("circle", {
                cx: String(22 + i * 64),
                cy: "22",
                r: "22",
                class: "tm-dot",
            }));
        }
        return;
    }

    if (style === "signal") {
        chart.setAttribute("viewBox", "0 0 234 96");
        const heights = [32, 48, 64, 80, 96];
        for (let i = 0; i < heights.length; i += 1) {
            const height = heights[i];
            chart.appendChild(svgEl("rect", {
                x: String(i * 50),
                y: String(96 - height),
                width: "34",
                height: String(height),
                class: "tm-bar",
            }));
        }
        return;
    }

    if (style === "gauge") {
        chart.setAttribute("viewBox", "0 0 200 130");
        const d = arcPath(100, 82, 70, (150 * Math.PI) / 180, (390 * Math.PI) / 180);
        chart.appendChild(svgEl("path", { d, class: "tm-arc", pathLength: "100" }));
        chart.appendChild(svgEl("path", {
            d,
            class: "tm-arc-fill",
            pathLength: "100",
            "stroke-dasharray": "100",
            "stroke-dashoffset": "100",
        }));
        return;
    }

    if (style === "clock") {
        chart.setAttribute("viewBox", "0 0 100 100");
        for (let i = 0; i < 60; i += 1) {
            const angle = -Math.PI / 2 + (i / 60) * Math.PI * 2;
            const major = i % 5 === 0;
            const inner = major ? 34 : 40;
            chart.appendChild(svgEl("line", {
                x1: (50 + inner * Math.cos(angle)).toFixed(2),
                y1: (50 + inner * Math.sin(angle)).toFixed(2),
                x2: (50 + 46 * Math.cos(angle)).toFixed(2),
                y2: (50 + 46 * Math.sin(angle)).toFixed(2),
                class: major ? "tm-tick is-major" : "tm-tick",
            }));
        }
    }
}

function paintChart(progress) {
    if (chartStyle === "dial" || chartStyle === "clock" || chartStyle === "dots" || chartStyle === "signal") {
        const nodes = chart.children;
        const count = nodes.length;
        const filled = progress <= 0 ? 0 : progress >= 1 ? count : Math.max(1, Math.round(progress * count));
        for (let i = 0; i < count; i += 1) nodes[i].classList.toggle("is-on", i < filled);
        return;
    }

    if (chartStyle === "pie") {
        const wedge = chart.querySelector(".tm-wedge");
        if (wedge) wedge.setAttribute("d", piePath(progress));
        return;
    }

    if (chartStyle === "donut") {
        const ring = chart.querySelector(".tm-donut-fill");
        if (ring) ring.setAttribute("stroke-dashoffset", String(100 - progress * 100));
        return;
    }

    if (chartStyle === "gauge") {
        const arc = chart.querySelector(".tm-arc-fill");
        if (arc) arc.setAttribute("stroke-dashoffset", String(100 - progress * 100));
    }
}

const BLEND_SHARE = 0.32;

function hexChannel(hex, offset) {
    return Number.parseInt(hex.slice(offset, offset + 2), 16);
}

function mixHex(from, to, amount) {
    const channel = (offset) => Math.round(
        hexChannel(from, offset) + (hexChannel(to, offset) - hexChannel(from, offset)) * amount,
    ).toString(16).padStart(2, "0");
    return `#${channel(1)}${channel(3)}${channel(5)}`;
}

function smoothstep(amount) {
    const t = Math.min(1, Math.max(0, amount));
    return t * t * (3 - 2 * t);
}

function normalizeStops(stops) {
    if (!Array.isArray(stops)) return [];

    const clean = [];
    for (let i = 0; i < stops.length; i += 1) {
        const stop = stops[i];
        if (!stop || typeof stop.color !== "string" || !/^#[0-9a-fA-F]{6}$/.test(stop.color)) continue;
        const at = Number(stop.at);
        if (Number.isNaN(at)) continue;
        clean.push({ at: Math.min(1, Math.max(0, at)), color: stop.color.toLowerCase() });
    }

    clean.sort((a, b) => a.at - b.at);
    const out = [];
    for (let i = 0; i < clean.length; i += 1) {
        if (out.length > 0 && out[out.length - 1].at === clean[i].at) out[out.length - 1] = clean[i];
        else out.push(clean[i]);
    }
    return out;
}

function colorAt(progress, fallback, stops, blend) {
    if (!stops || stops.length === 0) return fallback;

    const p = Math.min(1, Math.max(0, progress));
    let index = 0;
    for (let i = 0; i < stops.length; i += 1) {
        if (stops[i].at <= p) index = i;
        else break;
    }

    const from = stops[index];
    const to = stops[index + 1];
    if (!to || !blend) return from.color;

    const span = to.at - from.at;
    if (span <= 0) return to.color;
    const start = to.at - span * BLEND_SHARE;
    if (p <= start) return from.color;
    return mixHex(from.color, to.color, smoothstep((p - start) / (to.at - start)));
}

function paint(now) {
    if (!state) return;

    let progress = 0;
    let remaining = 0;

    if (state.mode === "script") {
        progress = state.progress;
    } else {
        const elapsed = state.paused ? state.elapsed : state.elapsed + (now - state.anchor);
        remaining = Math.max(0, state.duration - elapsed);
        progress = state.duration > 0 ? Math.min(1, elapsed / state.duration) : 1;
    }

    valueEl.textContent = readout(progress, remaining);
    root.style.setProperty("--tm", colorAt(progress, state.color, state.stops, state.blend));
    fillEl.style.width = `${progress * 100}%`;

    const filled = progress <= 0 ? 0 : progress >= 1 ? segmentEls.length : Math.max(1, Math.round(progress * segmentEls.length));
    for (let i = 0; i < segmentEls.length; i += 1) segmentEls[i].classList.toggle("is-on", i < filled);

    paintChart(progress);

    if (state.mode === "timer" && !state.paused) {
        raf = requestAnimationFrame(paint);
    }
}

function applyTimer(data) {
    cancelAnimationFrame(raf);
    state = {
        style: data.style || "pill",
        mode: data.mode === "script" ? "script" : "timer",
        duration: data.duration || 0,
        elapsed: data.elapsed || 0,
        paused: Boolean(data.paused),
        progress: data.progress || 0,
        color: data.color || "#31a4fc",
        stops: normalizeStops(data.colors),
        blend: Boolean(data.blend),
        anchor: performance.now(),
    };

    root.dataset.style = state.style;
    root.classList.toggle("is-plain", data.background === false);
    root.classList.toggle("is-nolabel", data.showLabel === false || !data.label);
    root.classList.toggle("is-novalue", data.showValue === false);
    root.style.display = "block";
    labelEl.textContent = data.label || "";
    buildChart(state.style);
    paint(performance.now());
}

function resetTimer() {
    cancelAnimationFrame(raf);
    state = null;
    chartStyle = null;
    chart.replaceChildren();
    root.style.display = "none";
    root.classList.remove("is-plain", "is-nolabel", "is-novalue");
    delete root.dataset.style;
    labelEl.textContent = "";
    valueEl.textContent = "";
    fillEl.style.width = "0%";
    for (let i = 0; i < segmentEls.length; i += 1) segmentEls[i].classList.remove("is-on");
}

window.addEventListener("message", (event) => {
    const data = event.data;
    if (!data || !data.action) return;

    if (data.action === "load") {
        fetchNui("load", { id: data.id });
        return;
    }

    if (data.action === "setTimer") {
        applyTimer(data);
        return;
    }

    if (data.action === "reset") {
        resetTimer();
    }
});
