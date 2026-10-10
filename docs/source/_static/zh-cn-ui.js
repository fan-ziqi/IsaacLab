/* Chinese labels for the upstream interactive documentation browsers. */
(() => {
    "use strict";
    const translations = window.isaacLabDocsTranslations || {};
    const scopes = "[data-environment-browser], [data-environment-preview], "
        + "[data-environment-benchmarks], [data-environment-tasks], [data-demo-browser], [data-guide-browser]";
    const literals = "code, pre, kbd, script, style, [data-command-output]";
    const attributes = ["title", "alt", "placeholder", "aria-label"];

    const translate = (value) => {
        const trimmed = value.trim();
        if (Object.hasOwn(translations, trimmed)) {
            return value.replace(trimmed, translations[trimmed]);
        }
        return value
            .replace(/^(\d+) guides?$/, "$1 篇指南")
            .replace(/^(\d+) tasks?$/, "$1 项任务")
            .replace(/\b([\d,]+) envs\b/g, "$1 个环境")
            .replace(/\b([\d.]+)GB\b/g, "$1 GB")
            .replace(/ preview$/, " 预览")
            .replace(/Peak VRAM: /g, "峰值显存：")
            .replace(/Collection FPS/g, "采集 FPS")
            .replace(/Training FPS/g, "训练 FPS")
            .replace(/Collection: /g, "采集：")
            .replace(/Training: /g, "训练：")
            .replace(/collection throughput history in frames per second/g, "采集吞吐量历史（帧/秒）")
            .replace(/training throughput history in frames per second/g, "训练吞吐量历史（帧/秒）")
            .replace(/8,192-environment matching-profile run unavailable/g, "暂无对应配置的 8,192 环境运行结果")
            .replace(/Unspecified renderer/g, "未指定渲染器")
            .replace(/Presets not recorded/g, "未记录预设")
            .replace(/\b[Mm]easured /g, "测量日期：")
            .replace(/source record /g, "源记录：")
            .replace(/commit /g, "提交：");
    };

    const localize = (node) => {
        const element = node.nodeType === Node.ELEMENT_NODE ? node : node.parentElement;
        if (!element || !element.closest(scopes) || element.closest(literals)) {
            return;
        }
        if (node.nodeType === Node.TEXT_NODE) {
            const translated = translate(node.nodeValue);
            if (translated !== node.nodeValue) {
                node.nodeValue = translated;
            }
            return;
        }
        for (const attribute of attributes) {
            if (element.hasAttribute(attribute)) {
                const value = element.getAttribute(attribute);
                const translated = translate(value);
                if (translated !== value) {
                    element.setAttribute(attribute, translated);
                }
            }
        }
        for (const child of [...node.childNodes]) {
            localize(child);
        }
    };

    const initialize = () => {
        for (const root of document.querySelectorAll(scopes)) {
            localize(root);
            new MutationObserver((records) => {
                for (const record of records) {
                    if (record.type === "childList") {
                        for (const node of record.addedNodes) {
                            localize(node);
                        }
                    } else {
                        localize(record.target);
                    }
                }
            }).observe(root, {
                subtree: true, childList: true, characterData: true, attributes: true,
                attributeFilter: attributes,
            });
        }
    };
    if (document.readyState === "loading") {
        document.addEventListener("DOMContentLoaded", initialize, {once: true});
    } else {
        initialize();
    }
})();
