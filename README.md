# MyPrefs

Moje Linux postavke, spremne za prelazak sa Fedore 43 na bilo koju drugu distribuciju
(Fedora, Arch, Debian/Ubuntu).

## Struktura

```
MyPrefs/
├── packages/   # liste paketa + skripta koja ih instalira automatski
├── dotfiles/   # bashrc, gitconfig, vimrc
├── assets/     # fontovi i pozadine
└── vscode/     # settings.json + extensions.txt
```

## packages

Skripta `install.sh` sama prepozna package manager (`dnf`, `apt` ili `pacman`) i
instalira odgovarajucu listu:

| Fajl | Za koga |
|---|---|
| `dnf-packages.txt` | Fedora |
| `apt-packages.txt` | Debian / Ubuntu |
| `arch-packages.txt` | Arch (pacman) |
| `aur-packages.txt` | Arch (yay, AUR) |

```bash
cd packages
./install.sh --dry-run   # samo ispise sta bi radio
./install.sh             # instalira
```

Skripta po potrebi dodaje i vanjske repoe (VS Code, cloudflared, RPM Fusion na Fedori).

## dotfiles

Konfiguracija gita (default editor je vim), vima i basha (aliasi, prompt, .NET).
Kopiraj ili linkaj u home:

```bash
ln -sf ~/MyPrefs/dotfiles/bashrc    ~/.bashrc
ln -sf ~/MyPrefs/dotfiles/gitconfig ~/.gitconfig
ln -sf ~/MyPrefs/dotfiles/vimrc     ~/.vimrc
```

U `bashrc`-u treba dopuniti alias `esesha`.

## assets

- `fonts/` - fontovi (JetBrains Mono, licenca OFL)
- `backgrounds/` - pozadine

Nema skripte za instalaciju. Fontove je dovoljno kopirati u `~/.local/share/fonts/`
pa pokrenuti `fc-cache -f`.

## vscode

`settings.json` (font, boje, C++/clangd, Live Server) i `extensions.txt`
(clangd, C#/.NET, SQL Server, Python, Live Server, PlatformIO za ESP32).

```bash
cp vscode/settings.json ~/.config/Code/User/settings.json
xargs -n1 code --install-extension < vscode/extensions.txt
```

Napomene:
- C++ koristi clangd, pa treba paket `clangd` (nalazi se u listama paketa).
- ESP32 preko USB-a: dodaj korisnika u grupu `dialout` (Fedora/Debian) ili `uucp` (Arch)
  i odjavi se/prijavi.
