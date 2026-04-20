# macOS Screenshot Tool UI Redesign

## Overview

This document defines the approved UI redesign direction for the macOS screenshot tool. It extends the base product design with a production-oriented visual system, a clearer settings architecture, a more practical main window, and stronger screenshot-time visual contrast.

The redesign should preserve the existing product scope:

- screenshot utility first
- input method automation as a separate settings-driven feature
- background resident macOS app

This redesign does not change the core product boundaries. It changes presentation, structure, and interaction quality.

## Approved Direction

### High-Level Product Shape

- Main window uses a tool-home layout
- Settings window uses a professional settings-center layout
- Screenshot mode uses a high-contrast capture theme
- Full app theme supports `light`, `dark`, and `follow system`

### Design Reference Interpretation

The reference app style is interpreted as:

- left grouped sidebar navigation
- right-side card-based settings content
- stronger product feeling than a default form UI
- compact but readable information density

This style should influence the settings window directly. The main window should share the same visual language without becoming a settings console.

## Theme System

### Theme Options

The app must expose three user-selectable appearance modes:

- `浅色`
- `深色`
- `跟随系统`

These are global app-level settings and must apply consistently to:

- main window
- settings window
- full editor window
- pin window
- floating toolbar

When `跟随系统` is selected, the app should respond to macOS appearance changes without requiring restart.

### Liquid Glass

The app should adopt macOS 26 Liquid Glass where appropriate.

Implementation guidance:

- prefer native system controls and containers so they inherit system appearance naturally
- use glass-like treatment deliberately for structural surfaces such as sidebars, top bars, and floating chrome
- do not over-apply heavy blur everywhere
- keep content readability above visual novelty

This means:

- settings sidebar can use translucent glass treatment
- settings cards can use soft elevated surfaces over a darker or lighter material backdrop
- floating toolbar can use glass with a high-contrast outline
- main content panels should remain readable and stable

## Main Window

### Purpose

The main window is a practical tool homepage, not a dashboard or preferences console.

It should make the most common actions obvious:

- start capture
- open settings
- review recent captures
- inspect permission state

### Layout

Recommended structure:

1. Hero block
2. Primary actions row
3. Status cards
4. Recent captures section

### Hero Block

Contains:

- product title
- one-line description

The tone should be direct and utility-focused, not marketing-heavy.

### Primary Actions

At minimum:

- `开始截图`
- `打开设置`

`开始截图` must be the strongest action on the page.

### Status Cards

Display:

- Screen Recording permission state
- Accessibility permission state
- global shortcut summary or registration state
- input method automation state when available

These should be short-glance informational cards, not long forms.

### Recent Captures

Show:

- thumbnail or preview reference
- timestamp
- saved or copied status
- quick actions when feasible, such as copy/open/pin in later polish

Empty state should show helpful guidance rather than an empty list.

## Settings Window

### Overall Structure

The settings window should be rebuilt from top-tab navigation to a left grouped sidebar plus right content area.

This is the final approved structure.

### Sidebar Groups

Recommended groups:

- `基础`
  - `通用`
  - `外观`
- `截图`
  - `截图`
  - `标注`
- `输入法`
  - `输入法规则`
- `其他`
  - `权限与诊断`

### Sidebar Style

- grouped labels in smaller subdued text
- icon + text rows
- clear selected pill or glass-highlight state
- slightly darker material than content area for separation

### Content Area Style

Each page should contain:

- page title
- one concise descriptive line
- 1 to 3 cards with clear grouping

Do not create a single endlessly scrolling form if the page can be segmented into meaningful cards.

## Page Content Model

### 通用

Cards:

- `应用行为`
  - 开机启动
  - 关闭窗口后后台驻留
  - 菜单栏图标
- `运行状态`
  - 后台驻留状态
  - 快捷键注册状态

### 外观

Cards:

- `主题`
  - 浅色
  - 深色
  - 跟随系统
- `预览`
  - compact visual preview of theme effect on the app chrome
- `截图模式说明`
  - note that capture mode uses a dedicated high-contrast appearance strategy

### 截图

Cards:

- `捕获`
  - 快捷键
  - 默认动作
  - 图片格式
- `输出`
  - 默认保存目录
  - 是否复制到剪贴板
  - 是否进入编辑

### 标注

Cards:

- `默认样式`
  - 默认颜色
  - 默认线宽
  - 默认字体大小
- `编辑行为`
  - 记住上次工具
  - 贴图窗口置顶
  - blur or mosaic strength when implemented

### 输入法规则

Cards:

- `全局默认`
  - 功能开关
  - 全局默认输入法
- `应用规则`
  - rule list
  - inline enabled state
  - create new rule controls

### 权限与诊断

Cards:

- `系统权限`
  - 屏幕录制
  - 辅助功能
  - direct buttons to system settings
- `诊断`
  - recent input method switch outcome
  - screenshot pipeline state
  - failure hints

## Screenshot Mode

### Appearance Strategy

Screenshot mode must not simply follow the regular app theme.

It uses a dedicated high-contrast capture theme whose job is recognizability first.

### Rules

- overlay outside the selection remains dimmed
- selection border adapts for contrast against the underlying content
- resize handles and measurement labels must remain visible on both dark and light backgrounds
- floating toolbar may use a glass-like material, but only with a strong contrast edge

### Contrast Policy

Approved choice:

- selection outline and handles should use dynamic high-contrast behavior based on background rather than a fixed brand color

Recommended implementation:

- dual-outline treatment
  - inner stroke
  - outer contrast edge or shadow

This is preferred over using a single blue or single white border everywhere.

## Screenshot Workflow

### Capture Phase

- enter full-screen capture mode
- show crosshair
- drag to create selection
- allow drag adjustment and repositioning in later polish
- support `Esc` to cancel

### Floating Toolbar

Recommended default order:

- 矩形
- 箭头
- 画笔
- 文字
- 模糊
- separator
- 复制
- 保存
- 贴图
- 编辑

Toolbar placement:

- default below selection
- flip above when bottom space is insufficient

### Full Editor

The full editor should support richer interaction than the floating toolbar.

Its target layout:

- top tool row
- central canvas
- undo and clear controls
- direct tool switching

### Pin Window

The pin window should remain lightweight:

- floating
- draggable
- closable
- visually quieter than the editor

## Annotation Interaction

### Immediate Goal

Annotation must move from static rendering-only behavior to direct user interaction.

Expected interactive tools:

- rectangle drag
- arrow drag
- pen freehand path
- text insertion by click
- blur region by drag

### Editing State

An explicit editor interaction state object is recommended so UI input can be translated into annotation items cleanly.

Responsibilities:

- selected tool
- current stroke color
- line width
- font size
- text payload
- temporary preview item during drag

## Permissions and First-Use Flow

### General Principle

The app should guide, not overwhelm.

Do not front-load every permission prompt at first launch.

### First-Use Flow

- first launch shows clear main actions
- first screenshot attempt triggers Screen Recording guidance if needed
- first input method automation enablement triggers permission guidance if needed

### Visibility

Missing permissions should be visible in:

- main window status area
- permissions and diagnostics page

### Copy

Each permission explanation should clearly answer:

- why the permission is needed
- what breaks if it is missing
- how to fix it

## Chinese-First Copy

UI copy should be Chinese-first throughout the app.

English terminology is acceptable only where platform or technical labels are more understandable with it.

Tone should be:

- concise
- tool-oriented
- non-marketing

## Current Implementation Gaps to Close

These are the most important remaining UI/interaction gaps after the approved redesign:

- settings visual hierarchy still too sparse compared with the approved card-based layout
- editor interaction needs to be promoted from baseline to polished behavior
- screenshot overlay still needs more mature selection affordances
- some runtime system integrations still need hand verification on a real desktop

## Implementation Priority

1. Rebuild settings window structure and styling to the approved sidebar plus card model
2. Apply the theme system across the app and expose `浅色 / 深色 / 跟随系统`
3. Improve main window to the approved tool-home layout
4. Strengthen screenshot-mode high-contrast visuals
5. Polish annotation interaction and toolbar ergonomics
6. Refine first-use permission guidance and diagnostics
