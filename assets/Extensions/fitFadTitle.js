(function FitFadTitle() {
    let lastKey = "";
    let lastElement = null;

    setInterval(() => {
        const title = document.getElementById("fad-title");
        if (!title || !title.offsetWidth) {
            lastKey = "";
            lastElement = null;
            return;
        }

        const key = title.textContent + "|" + title.offsetWidth;
        if (title === lastElement && key === lastKey) return;

        title.style.fontSize = "";
        title.style.lineHeight = "1.15";
        title.style.whiteSpace = "normal";
        title.style.overflowWrap = "anywhere";
        title.style.display = "block";
        title.style.maxHeight = "none";
        title.style.overflow = "visible";

        let size = parseFloat(getComputedStyle(title).fontSize);
        while (size > 14 && title.scrollHeight > size * 1.15 * 2 + 2) {
            size -= 1;
            title.style.fontSize = size + "px";
        }

        title.style.display = "-webkit-box";
        title.style.webkitBoxOrient = "vertical";
        title.style.webkitLineClamp = "2";
        title.style.overflow = "hidden";

        lastElement = title;
        lastKey = title.textContent + "|" + title.offsetWidth;
    }, 500);
})();