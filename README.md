# GlassFrame

**GlassFrame** is an elegant, minimal, and highly interactive photo frame skin for [Rainmeter](https://www.rainmeter.net/). It allows you to showcase up to 4 of your favorite images on your Windows desktop in various geometric layouts, complete with real-time scaling and a stylized configuration panel.

---

## 🚀 Features

- **5 Layout Modes:**
  - **Mode 1 (Single):** Displays a single image filling the entire widget.
  - **Mode 2 (Dual vertical split):** Displays two images side-by-side (50% width each).
  - **Mode 3 (Triple vertical split):** Displays three images side-by-side (33.3% width each).
  - **Mode 4 (Grid 2x2):** Displays four images arranged in a clean grid.
  - **Mode 5 (Circle):** An elegant circular crop focused on the first image, ideal for portraits or avatars.
- **Dynamic Scroll Scaling:** Instantly scale the entire skin on-the-fly (from `0.4x` to `3.0x`) by simply scrolling your mouse wheel (`Scroll Up` / `Scroll Down`) over the widget's background.
- **Instant Control Panel:** A slide-in-place control panel appears instantly when you hover your mouse over the widget, letting you switch layouts or launch settings.
- **Dedicated Settings GUI:** A stylized native Windows Forms interface powered by PowerShell that lets you:
  - Select images for all 4 slots using a file picker.
  - Choose a custom **Background Color** via a standard Windows color palette.
  - Adjust background opacity (transparency level) using a slider.
  - Apply changes in real-time or close the settings window using separate, dedicated buttons.
- **Premium Aesthetics:** Featuring soft rounded corners, modern semi-transparent panels, and glassmorphism elements that match Windows 11 design guidelines.

---

## 📁 File Structure

The project has a modular, lightweight structure:

- **[GlassFrame.ini](./GlassFrame.ini):** The primary Rainmeter skin file. Declares visual elements (meters), shape container clipping masks, and scaling math.
- **[Variables.inc](./Variables.inc):** Stores persistent user configurations, including chosen image file paths, background colors, and transparency values.
- **[Settings.ps1](./Settings.ps1):** A PowerShell WinForms script that renders the graphical settings GUI.
- **[SelectImage.ps1](./SelectImage.ps1):** A helper PowerShell utility to open the file selection dialog asynchronously.
- **[Layout.lua](./Layout.lua):** A Lua script reserved for advanced dynamic layout management and future expansions.

---

## 🛠️ Requirements

- Windows 10 or Windows 11
- [Rainmeter](https://www.rainmeter.net/) (v4.5 or newer recommended)
- PowerShell 5.1 or newer (pre-installed with Windows)

---

## ⚙️ Installation & Usage

1. Copy the `GlassFrame` folder into your Rainmeter skins directory:
   ```txt
   C:\Users\<YourUsername>\Documents\Rainmeter\Skins\GlassFrame
   ```
2. Open the Rainmeter Manager and click **"Refresh all"** in the bottom left corner.
3. Locate `GlassFrame` in the list, select `GlassFrame.ini`, and click **"Load"**.
4. **Accessing Controls:** Hover over the loaded widget and click the hamburger menu button (☰) in the top-right corner to reveal the control panel.
5. **Configuring:** Click the **"Configurar"** button on the control panel to open the settings window to load your own pictures and choose custom colors.
6. **Resizing:** Hover over the background of the skin and use your mouse scroll wheel to zoom the widget in or out.

---

## 💡 Troubleshooting

### The Settings GUI doesn't open
By default, Windows may restrict running PowerShell scripts. Although the skin executes the settings script bypassing local policies for safety (`-ExecutionPolicy Bypass`), antivirus software or system-wide domain policies may still block it.

To resolve this:
1. Open PowerShell as Administrator.
2. Run the following command:
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```
3. Type `Y` (or `S` in Portuguese) and press `Enter` to confirm.

---

## 📄 License

This project is open-source and available under the [MIT License](https://opensource.org/licenses/MIT). Feel free to modify, customize, and redistribute!
