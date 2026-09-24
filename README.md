# dotfiles

My dotfiles. Public because I would rather not log in to pull them.

There is nothing on this branch on purpose — every setup is a branch of its
own, and they have no history in common.

| branch | machine | desktop |
|---|---|---|
| [`desktop`](../../tree/desktop) | CachyOS | Hyprland, waybar, mako, rofi |
| [`swift`](../../tree/swift) | Fedora 44 | Sway, waybar, rofi |
| [`gnome`](../../tree/gnome) | Fedora 44 | GNOME 50.5 Wayland, WhiteSur |

Each branch is self-contained: its own README, its own `install.sh`, its own
package list. They are orphan branches with no shared ancestor and no files in
common, so nothing is meant to be merged, rebased or cherry-picked between them
and `git diff desktop gnome` is meaningless by design.

```sh
git clone -b desktop https://github.com/Sanji0987/dotfiles ~/dotfiles
cd ~/dotfiles && ./install.sh
```
