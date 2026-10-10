/* Preserve the original media URL and show a readable fallback if loading fails. */
document.addEventListener("DOMContentLoaded", () => {
    const chinese = document.documentElement.lang.startsWith("zh");
    const replaceFailedMedia = (media) => {
        if (media.dataset.unavailable) return;
        media.dataset.unavailable = "true";
        // Keep an image button's destination usable without nesting links.
        if (media.dataset.linkFallback && media.parentElement?.tagName === "A") {
            const label = document.createElement("span");
            label.textContent = media.alt;
            media.hidden = true;
            media.after(label);
            return;
        }
        const source = media.currentSrc || media.src || media.querySelector("source")?.src;
        if (!source) return;
        const message = document.createElement("div");
        message.className = "media-unavailable";
        message.setAttribute("role", "status");
        const link = document.createElement("a");
        link.href = source;
        link.textContent = chinese ? "媒体暂无法加载，查看原始资源" : "Media unavailable; view original resource";
        message.append(link);
        media.hidden = true;
        media.after(message);
    };
    document.querySelectorAll("article img, article video").forEach((media) => {
        // The task preview already switches failed video loads to its image fallback.
        if (media.closest("[data-environment-preview]")) return;
        media.addEventListener("error", () => replaceFailedMedia(media));
        media.querySelectorAll("source").forEach((source) => {
            source.addEventListener("error", () => replaceFailedMedia(media));
        });
        if ((media instanceof HTMLImageElement && media.complete && !media.naturalWidth)
            || (media instanceof HTMLVideoElement && media.error)) {
            replaceFailedMedia(media);
        }
    });
});
