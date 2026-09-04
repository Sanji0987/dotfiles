/* Walker stylesheet — rendered in TWO stages.
 *
 *   this file
 *     |  stage 1 — omarchy-theme-set-templates, on every theme change:
 *     |            colour tokens, from the theme's colors.toml
 *     v
 *   ~/.local/state/omarchy/current/theme/walker.css   (still holds the ui_* tokens)
 *     |  stage 2 — ~/.local/bin/omarchy-walker-theme-sync:
 *     |            ui_* geometry tokens, from shell.toml + Hyprland
 *     v
 *   ~/.config/walker/themes/omarchy/style.css
 *
 * Edit THIS file, never either generated copy, then re-run a theme set (or
 * ~/omarchy_config_work/update.sh).
 *
 * WHY TWO STAGES: omarchy-theme-set-templates:383 builds its sed script purely
 * from THEME_COLORS, which :380 fills from colors.toml alone. It has no notion
 * of radii, font sizes or padding — those live in shell.toml's [font]/[spacing]
 * and in Hyprland's decoration:rounding. sed leaves tokens it has no rule for
 * untouched, so the ui_* names survive stage 1 and the sync script
 * resolves them against the exact formulas in Commons/Style.qml.
 *
 * The generated file is COPIED to walker's theme dir, never symlinked: walker
 * silently ignores a symlinked themes/<name>/style.css. Proven with invalid CSS
 * at that path — as a real file GTK prints "Theme parser error:
 * style.css:1:24-25"; as a symlink there is no parser output at all, the file is
 * never read.
 *
 * The copy is triggered by ~/.config/omarchy/hooks/theme-set.d/walker-css on
 * normal theme changes, and directly by update.sh on headless ones.
 *
 * MATCHING THE SHELL: colours come from the [menu] section of the generated
 * shell.toml (background, text, selected-background at 0.08 alpha, selected-text
 * = accent); geometry comes from the same [font]/[spacing] tokens and
 * decoration:rounding that Style.qml reads. Nothing here is eye-matched any
 * more — a base-size, [spacing] scale or rounding change moves both surfaces
 * together.
 *
 * KNOWN LIMIT: the card is 600x570 and the list 500px wide, from width-request
 * and min-content-width in /etc/xdg/walker/themes/default/layout.xml. Those are
 * GTK widget properties; CSS min-width can grow a widget but never shrink it
 * below width-request. Matching the shell's 300px card would mean copying
 * layout.xml into themes/omarchy/, which pins the layout against walker
 * upstream. Deliberately not done.
 */

@define-color window_bg_color {{ background }};
@define-color theme_fg_color  {{ foreground }};
@define-color accent_bg_color {{ accent }};
@define-color muted_fg_color  {{ muted }};
@define-color selection_color {{ selection }};
@define-color error_bg_color  {{ bright_red }};
@define-color error_fg_color  {{ background }};

* {
  all: unset;
}

/* ---------------------------------------------------------------- surface */

/* [menu] border is a Hyprland gradient; GTK cannot paint one, so the sync
 * script collapses it to its first stop. */
.box-wrapper {
  background: @window_bg_color;
  border: 1px solid {{ ui_menu_border }};
  border-radius: {{ ui_rounding }}px;
  padding: {{ ui_panel_padding }}px;
  box-shadow:
    0 19px 38px rgba(0, 0, 0, 0.35),
    0 15px 12px rgba(0, 0, 0, 0.22);
}

popover {
  background: {{ dark_background }};
  border: 1px solid {{ ui_menu_border }};
  border-radius: {{ ui_rounding }}px;
  padding: {{ ui_row_padding_x }}px;
}

/* ------------------------------------------------------------------ input */

/* The shell menu has no input *field* — Menu.qml:1196 draws a bare header row
 * at headerHeight, in Style.font.heading, sharing the rows' horizontal inset.
 * So: no background, no border, no focus ring. */

.search-container {
  border-radius: {{ ui_rounding }}px;
}

.input {
  background: transparent;
  color: @theme_fg_color;
  caret-color: @accent_bg_color;
  border: none;
  border-radius: {{ ui_rounding }}px;
  padding: 0 {{ ui_row_padding_x }}px;
  min-height: {{ ui_header_height }}px;
  font-size: {{ ui_heading }}px;
}

.input placeholder {
  color: @muted_fg_color;
}

.input selection {
  background: @selection_color;
  color: @theme_fg_color;
}

/* ------------------------------------------------------------------- list */

.list {
  color: @theme_fg_color;
}

/* GtkGridView row spacing is a widget property, not CSS, so the gap between
 * rows (Menu.qml:107, Style.spacing.xs) is applied as a row margin instead. */
.item-box {
  border-radius: {{ ui_rounding }}px;
  padding: 0 {{ ui_row_padding_x }}px;
  min-height: {{ ui_row_height }}px;
  margin-bottom: {{ ui_row_gap }}px;
}

/* Mirrors [menu] selected-background = text @ 0.08, selected-text = accent. */
child:selected .item-box,
row:selected .item-box {
  background: alpha(@theme_fg_color, 0.08);
  border: 1px solid alpha(@accent_bg_color, 0.25);
}

child:selected .item-text,
row:selected .item-text {
  color: @accent_bg_color;
}

.item-text {
  font-size: {{ ui_heading }}px;
}

.item-subtext {
  font-size: {{ ui_body_small }}px;
  color: @muted_fg_color;
}

.providerlist .item-subtext {
  font-size: unset;
  color: @muted_fg_color;
}

/* Inert while hide_quick_activation / hide_action_hints are set in
 * config.toml; kept so unhiding is a one-line revert. */
.item-quick-activation {
  background: alpha(@accent_bg_color, 0.25);
  border-radius: {{ ui_rounding }}px;
  padding: {{ ui_row_padding_x }}px;
}

.item-image-text {
  font-size: {{ ui_icon_large }}px;
}

.normal-icons { -gtk-icon-size: 16px; }
.large-icons  { -gtk-icon-size: {{ ui_icon_large }}px; }
.preview .large-icons { -gtk-icon-size: 64px; }

scrollbar {
  opacity: 0;
}

/* --------------------------------------------------------------- provider */

.calc .item-text     { font-size: {{ ui_display }}px; }
.symbols .item-image { font-size: {{ ui_display }}px; }

.todo.done .item-text-box { opacity: 0.25; }
.todo.urgent              { font-size: {{ ui_display }}px; }
.todo.active              { font-weight: bold; }

.bluetooth.disconnected { opacity: 0.5; }

.preview-content.archlinuxpkgs,
.preview-content.dnfpackages,
.preview-content.aptpackages {
  font-family: monospace;
}

.preview {
  border: 1px solid alpha(@accent_bg_color, 0.25);
  border-radius: {{ ui_rounding }}px;
  color: @theme_fg_color;
}

.preview-box,
.elephant-hint,
.placeholder {
  color: @muted_fg_color;
}

/* --------------------------------------------------------------- keybinds */

.keybinds {
  padding-top: {{ ui_row_padding_x }}px;
  border-top: 1px solid alpha(@theme_fg_color, 0.10);
  font-size: {{ ui_body_small }}px;
  color: @muted_fg_color;
}

.keybind-button         { opacity: 0.6; }
.keybind-button:hover   { opacity: 0.9; }
.keybind-bind           { text-transform: lowercase; color: @muted_fg_color; }

.keybind-label {
  padding: 2px 4px;
  border-radius: {{ ui_rounding }}px;
  border: 1px solid alpha(@theme_fg_color, 0.35);
}

/* ------------------------------------------------------------------ error */

.error {
  padding: {{ ui_row_padding_x }}px;
  border-radius: {{ ui_rounding }}px;
  background: @error_bg_color;
  color: @error_fg_color;
}

:not(.calc).current {
  font-style: italic;
}
