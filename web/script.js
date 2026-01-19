let currentType = null;
let currentDistance = null;

function animateDistance(newValue, duration = 90) {
    const element = currentType === "checkpoint" ? document.getElementById("checkpoint-distance-value") : document.getElementById("small-distance-value");
    const start = parseFloat(currentDistance);
    const end = parseFloat(newValue);
    const startTime = performance.now();

    function animate(currentTime) {
        const elapsed = currentTime - startTime;
        const t = Math.min(elapsed / duration, 1);
        const easedT = t * t * (3 - 2 * t);
        const value = start + (end - start) * easedT;
        element.textContent = Math.round(value);
        if (t < 1) {
            requestAnimationFrame(animate);
        } else {
            currentDistance = newValue;
        }
    }

    requestAnimationFrame(animate);
}

export async function fetchNui(eventName, data) {
    const resp = await fetch(`https://sleepless_waypoints/${eventName}`, {
        method: "post",
        headers: {
            "Content-Type": "application/json; charset=UTF-8",
        },
        body: JSON.stringify(data),
    });

    return await resp.json();
}

function getFontAwesomeClass(icon) {
    if (!icon) return "";
    // If already has fa- prefix, use as-is
    if (icon.includes("fa-")) {
        return `fa-fw ${icon}`;
    }
    // Otherwise, assume solid style and add fa- prefix
    return `fa-fw fa-solid fa-${icon}`;
}

window.addEventListener("message", (event) => {
    const data = event.data;

    switch (data.action) {
        case "load":
            fetchNui("load", { id: data.id });
            break;

        case "setType":
            document.querySelectorAll(".marker-type").forEach((el) => (el.style.display = "none"));

            currentType = data.type;
            const marker = document.getElementById(`marker-${data.type}`);
            if (marker) {
                marker.style.display = "flex";
            }
            break;

        case "setColor":
            document.documentElement.style.setProperty("--marker-color", data.color);
            break;

        case "setIcon":
            if (currentType === "small") {
                const smallIcon = document.getElementById("small-icon");
                const iconContainer = document.querySelector(".small-icon-container");
                const imageContainer = document.querySelector(".small-image-container");

                if (data.icon) {
                    smallIcon.className = getFontAwesomeClass(data.icon);
                    if (data.iconColor) {
                        smallIcon.style.color = data.iconColor;
                    }
                    iconContainer.style.display = "flex";
                    imageContainer.style.display = "none";
                } else {
                    iconContainer.style.display = "none";
                }
            } else if (currentType === "checkpoint") {
                const checkpointIcon = document.getElementById("checkpoint-icon");
                const iconContainer = document.querySelector(".checkpoint-icon-container");
                const imageContainer = document.querySelector(".checkpoint-image-container");

                if (data.icon) {
                    checkpointIcon.className = getFontAwesomeClass(data.icon);
                    if (data.iconColor) {
                        checkpointIcon.style.color = data.iconColor;
                    }
                    iconContainer.style.display = "flex";
                    imageContainer.style.display = "none";
                } else {
                    iconContainer.style.display = "none";
                }
            }
            break;

        case "setImage":
            if (currentType === "small") {
                const smallImage = document.getElementById("small-image");
                const imageContainer = document.querySelector(".small-image-container");
                const iconContainer = document.querySelector(".small-icon-container");

                if (data.url) {
                    smallImage.src = data.url;
                    smallImage.style.display = "block";
                    imageContainer.style.display = "flex";
                    iconContainer.style.display = "none";
                } else {
                    smallImage.style.display = "none";
                    imageContainer.style.display = "none";
                }
            } else if (currentType === "checkpoint") {
                const checkpointImage = document.getElementById("checkpoint-image");
                const imageContainer = document.querySelector(".checkpoint-image-container");
                const iconContainer = document.querySelector(".checkpoint-icon-container");

                if (data.url) {
                    checkpointImage.src = data.url;
                    imageContainer.style.display = "flex";
                    iconContainer.style.display = "none";
                } else {
                    imageContainer.style.display = "none";
                }
            }
            break;

        case "setLabel":
            if (currentType === "checkpoint") {
                document.getElementById("checkpoint-label").textContent = data.text || "CHECKPOINT";
            }

            if (currentType === "small") {
                document.getElementById("small-label").textContent = data.text || "CHECKPOINT";
            }
            break;

        case "setDistance":
            const newDist = data.value || "0";
            const duration = data.duration - 10 || 100;
            if (!currentDistance || duration <= 50) {
                currentDistance = newDist;
                if (currentType === "checkpoint") {
                    document.getElementById("checkpoint-distance-value").textContent = newDist;
                } else {
                    document.getElementById("small-distance-value").textContent = newDist;
                }
            } else {
                animateDistance(newDist, data.duration - 10);
            }
            break;

        case "showDistance":
            if (currentType === "checkpoint") {
                document.getElementById("checkpoint-distance").style.display = data.show ? "flex" : "none";
            } else {
                document.getElementById("small-distance").style.display = data.show ? "flex" : "none";
            }
            break;

        case "hide":
            document.querySelectorAll(".marker-type").forEach((el) => (el.style.display = "none"));
            break;

        case "show":
            if (currentType) {
                document.getElementById(`marker-${currentType}`).style.display = "flex";
            }
            break;

        case "reset":
            // Reset all state for DUI pool reuse
            currentType = null;
            currentDistance = null;

            // Hide all markers
            document.querySelectorAll(".marker-type").forEach((el) => (el.style.display = "none"));

            // Reset color to default
            document.documentElement.style.setProperty("--marker-color", "#f5a623");

            // Reset checkpoint elements
            document.getElementById("checkpoint-label").textContent = "CHECKPOINT";
            document.getElementById("checkpoint-distance-value").textContent = "0";
            document.getElementById("checkpoint-icon").className = "";
            document.querySelector(".checkpoint-icon-container").style.display = "none";
            document.querySelector(".checkpoint-image-container").style.display = "none";
            document.getElementById("checkpoint-image").src = "";
            document.getElementById("checkpoint-distance").style.display = "flex";

            // Reset small marker elements
            document.getElementById("small-distance-value").textContent = "0";
            document.getElementById("small-icon").className = "";
            document.querySelector(".small-icon-container").style.display = "none";
            document.querySelector(".small-image-container").style.display = "none";
            document.getElementById("small-image").src = "";
            document.getElementById("small-distance").style.display = "flex";
            break;
    }
});
