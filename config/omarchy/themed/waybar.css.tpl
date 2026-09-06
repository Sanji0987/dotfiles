/* Waybar colour palette — rendered in ONE stage, unlike walker.css.tpl.
 *
 *   this file
 *     |  omarchy-theme-set-templates, on every theme change: colour tokens
 *     |  substituted from the theme's colors.toml
 *     v
 *   ~/.local/state/omarchy/current/theme/waybar.css
 *
 * ~/dotfiles/config/waybar/style.css @imports that generated file directly
 * for its @define-color rules. Everything else — padding, radii, spacing,
 * font choice — is fixed by hand in style.css, so there is no second stage
 * to resolve geometry tokens against shell.toml/Hyprland the way walker's
 * sync script does. Waybar is a fallback bar, not a pixel match for the
 * Quickshell one: hand-picked constants are good enough, and skipping the
 * second stage means one less moving part to keep working. If that stops
 * being true (say, radius should track Hyprland's decoration:rounding),
 * revisit rather than reinventing the walker two-stage machinery here.
 *
 * Edit THIS file, never the generated copy, then re-run a theme change (or
 * `omarchy-shell-update`).
 */

@define-color background {{ background }};
@define-color foreground {{ foreground }};
@define-color dark_background {{ dark_background }};
@define-color accent {{ accent }};
@define-color selection {{ selection }};
@define-color muted {{ muted }};
@define-color red {{ red }};
@define-color bright_red {{ bright_red }};
@define-color green {{ green }};
@define-color yellow {{ yellow }};
