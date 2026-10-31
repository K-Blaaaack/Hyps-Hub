.pragma library

/*
 * Material Design 3 设计令牌（非颜色部分）。
 *
 * 颜色令牌由 C++ ThemeManager::colors() 提供（Theme.colors.*），因为主题需要
 * 跟随系统深浅色、并且要让 Qt 原生调色板（输入法候选、原生菜单）保持一致。
 * 这里只放与主题无关的几何/字号/动效/状态层令牌，全部按 MD3 规范取值。
 *
 * 用法：
 *     import "../theme/Md3.js" as Md3
 *     radius: Md3.shape.large
 *     font.pixelSize: Md3.type.titleMedium.size
 */

// --- Shape scale -----------------------------------------------------------
var shape = {
    none: 0,
    extraSmall: 4,
    small: 8,
    medium: 12,
    large: 16,
    extraLarge: 28,
    full: 9999
};

// --- Spacing scale（4dp 网格）---------------------------------------------
var space = {
    none: 0,
    xxs: 2,
    xs: 4,
    sm: 8,
    md: 12,
    lg: 16,
    xl: 24,
    xxl: 32,
    xxxl: 48
};

// --- Typescale -------------------------------------------------------------
// MD3 的 15 个角色。Qt 用 pixelSize + weight + letterSpacing 近似，
// lineHeight 用 Text.lineHeight（倍数）表达：lineHeight / size。
var type = {
    displayLarge:   { size: 57, weight: 400, tracking: -0.25, lineHeight: 64 },
    displayMedium:  { size: 45, weight: 400, tracking: 0.0,   lineHeight: 52 },
    displaySmall:   { size: 36, weight: 400, tracking: 0.0,   lineHeight: 44 },

    headlineLarge:  { size: 32, weight: 400, tracking: 0.0,   lineHeight: 40 },
    headlineMedium: { size: 28, weight: 400, tracking: 0.0,   lineHeight: 36 },
    headlineSmall:  { size: 24, weight: 400, tracking: 0.0,   lineHeight: 32 },

    titleLarge:     { size: 22, weight: 400, tracking: 0.0,   lineHeight: 28 },
    titleMedium:    { size: 16, weight: 500, tracking: 0.15,  lineHeight: 24 },
    titleSmall:     { size: 14, weight: 500, tracking: 0.1,   lineHeight: 20 },

    bodyLarge:      { size: 16, weight: 400, tracking: 0.5,   lineHeight: 24 },
    bodyMedium:     { size: 14, weight: 400, tracking: 0.25,  lineHeight: 20 },
    bodySmall:      { size: 12, weight: 400, tracking: 0.4,   lineHeight: 16 },

    labelLarge:     { size: 14, weight: 500, tracking: 0.1,   lineHeight: 20 },
    labelMedium:    { size: 12, weight: 500, tracking: 0.5,   lineHeight: 16 },
    labelSmall:     { size: 11, weight: 500, tracking: 0.5,   lineHeight: 16 }
};

// 等宽场景（日志、配置键、代码）沿用同一套尺寸，但字体族换成 App.monoFontFamily。
var mono = {
    large: { size: 14, tracking: 0.0, lineHeight: 20 },
    medium: { size: 12.5, tracking: 0.0, lineHeight: 18 },
    small: { size: 11.5, tracking: 0.0, lineHeight: 16 }
};

// --- State layer -----------------------------------------------------------
// MD3 状态层不透明度；叠加在容器色上，不要直接改内容的 alpha。
var state = {
    hover: 0.08,
    focus: 0.10,
    pressed: 0.10,
    dragged: 0.16,
    disabledContent: 0.38,
    disabledContainer: 0.12
};

// --- Motion ----------------------------------------------------------------
var motion = {
    short1: 50,
    short2: 100,
    short3: 150,
    short4: 200,
    medium1: 250,
    medium2: 300,
    medium3: 350,
    medium4: 400,
    long1: 450,
    long2: 500,
    long3: 550,
    long4: 600,
    extraLong1: 700
};

// --- 组件尺寸（MD3 规范值）-------------------------------------------------
var size = {
    button: 40,
    buttonLarge: 56,
    iconButton: 40,
    iconButtonLarge: 48,
    fabSmall: 40,
    fab: 56,
    fabLarge: 96,
    chip: 32,
    textField: 56,
    listItem: 56,
    listItemTwoLine: 72,
    listItemThreeLine: 88,
    navRail: 80,
    navRailExpanded: 256,
    navRailIndicatorWidth: 56,
    navRailIndicatorHeight: 32,
    topAppBarSmall: 64,
    topAppBarMedium: 112,
    topAppBarLarge: 152,
    switchTrackWidth: 52,
    switchTrackHeight: 32,
    switchThumb: 24,
    switchThumbSelected: 24,
    switchThumbPressed: 28,
    dialogMinWidth: 280,
    dialogMaxWidth: 560,
    snackbarMinWidth: 344,
    snackbarMaxWidth: 672,
    icon: 24,
    iconSmall: 20,
    iconLarge: 32,
    scrollbar: 8,
    divider: 1
};

// --- Elevation -------------------------------------------------------------
// MD3 的 elevation 由「表面色阶 + 阴影」共同表达。软件渲染下不用 MultiEffect，
// 用 MdElevation 画 2–3 层半透明圆角矩形近似；tint 表示该层应使用的表面角色。
var elevation = {
    level0: { tint: "surface",            shadow: 0.00, offset: 0, blur: 0 },
    level1: { tint: "surfaceContainerLow",  shadow: 0.10, offset: 1, blur: 2 },
    level2: { tint: "surfaceContainer",     shadow: 0.12, offset: 2, blur: 4 },
    level3: { tint: "surfaceContainerHigh", shadow: 0.14, offset: 3, blur: 8 },
    level4: { tint: "surfaceContainerHigh", shadow: 0.16, offset: 4, blur: 10 },
    level5: { tint: "surfaceContainerHighest", shadow: 0.18, offset: 5, blur: 12 }
};

// --- 辅助函数 --------------------------------------------------------------
function clamp01(value) {
    var v = Number(value);
    if (isNaN(v)) {
        return 0;
    }
    return v < 0 ? 0 : (v > 1 ? 1 : v);
}

// Theme.colors 是 QVariantMap，取出来是 "#rrggbb" 字符串而不是 QColor，
// 所以不能直接读 .r/.g/.b（那是 undefined，Qt.rgba 会得到黑色）。
function channels(color) {
    if (typeof color === "string") {
        let hex = color.trim();
        if (hex.charAt(0) === "#") {
            hex = hex.slice(1);
        }
        if (hex.length === 3) {
            hex = hex[0] + hex[0] + hex[1] + hex[1] + hex[2] + hex[2];
        }
        if (hex.length === 8) {
            hex = hex.slice(2);
        }
        if (hex.length === 6) {
            return {
                r: parseInt(hex.slice(0, 2), 16) / 255,
                g: parseInt(hex.slice(2, 4), 16) / 255,
                b: parseInt(hex.slice(4, 6), 16) / 255
            };
        }
        return { r: 1, g: 1, b: 1 };
    }
    return { r: color.r, g: color.g, b: color.b };
}

function alpha(color, opacity) {
    if (!color) {
        return "transparent";
    }
    const c = channels(color);
    return Qt.rgba(c.r, c.g, c.b, clamp01(opacity));
}

function hover(color) {
    return alpha(color, state.hover);
}

function pressed(color) {
    return alpha(color, state.pressed);
}

function focus(color) {
    return alpha(color, state.focus);
}

/* 内容不可用：MD3 用 onSurface 的 38% 叠加在表面色上，这里直接返回近似实色。 */
function disabledContent(color) {
    return alpha(color, state.disabledContent);
}

function disabledContainer(color) {
    return alpha(color, state.disabledContainer);
}

/* Text.lineHeight 是倍数而不是像素。 */
function lineHeight(role) {
    return role.lineHeight / role.size;
}

/* 圆形/胶囊半径：MD3 shape.full 的实际用法是按高度取半。 */
function pill(height) {
    return Math.max(0, height) / 2;
}

function px(value) {
    return Math.round(Number(value) * 100) / 100;
}
