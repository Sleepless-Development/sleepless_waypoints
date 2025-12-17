let currentType = null;

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
    case "setType":
      document
        .querySelectorAll(".marker-type")
        .forEach((el) => (el.style.display = "none"));

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
        const iconContainer = document.querySelector(
          ".checkpoint-icon-container"
        );
        const imageContainer = document.querySelector(
          ".checkpoint-image-container"
        );

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
        const imageContainer = document.querySelector(
          ".checkpoint-image-container"
        );
        const iconContainer = document.querySelector(
          ".checkpoint-icon-container"
        );

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
        document.getElementById("checkpoint-label").textContent =
          data.text || "CHECKPOINT";
      }
      break;

    case "setDistance":
      if (currentType === "checkpoint") {
        document.getElementById("checkpoint-distance-value").textContent =
          data.value || "0";
      } else {
        document.getElementById("small-distance-value").textContent =
          data.value || "0";
      }
      break;

    case "showDistance":
      if (currentType === "checkpoint") {
        document.getElementById("checkpoint-distance").style.display = data.show
          ? "flex"
          : "none";
      } else {
        document.getElementById("small-distance").style.display = data.show
          ? "flex"
          : "none";
      }
      break;

    case "hide":
      document
        .querySelectorAll(".marker-type")
        .forEach((el) => (el.style.display = "none"));
      break;

    case "show":
      if (currentType) {
        document.getElementById(`marker-${currentType}`).style.display = "flex";
      }
      break;
  }
});
