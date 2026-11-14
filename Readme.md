# LAVYNRA VIDEO CUTTER

**A Simple, Fast & Powerful Video Splitting Tool for Termux**

Split your videos with ease, directly from your Android device.

[![Version](https://img.shields.io/badge/Version-1.2-00D7FF?style=for-the-badge)](https://github.com/LAVYNRA)
[![Platform](https://img.shields.io/badge/Platform-Termux-AD87FF?style=for-the-badge)](https://termux.dev/)
[![Language](https://img.shields.io/badge/Language-Bash-87FF5F?style=for-the-badge)](https://www.gnu.org/software/bash/)
[![License](https://img.shields.io/badge/License-MIT-yellow?style=for-the-badge)](LICENSE)

**Developed by [@LAVYNRA](https://github.com/lavynra-root)**

---

## About The Project | Tentang Project

### 🇬🇧 English

**LAVYNRA VIDEO CUTTER** is a lightweight and interactive command-line tool designed to split video files into multiple smaller segments directly on Android using Termux.

Powered by FFmpeg, this tool provides two cutting modes: **LOSSLESS** for fast video splitting without re-encoding, and **PRESISI** for more accurate segment durations through H.264 re-encoding.

With its clean terminal interface, automatic video scanning, video information analysis, and real-time progress display, managing video files becomes easier and more convenient.

### 🇮🇩 Indonesia

**LAVYNRA VIDEO CUTTER** adalah tools berbasis command-line yang ringan dan interaktif untuk memotong video menjadi beberapa bagian secara langsung melalui Android menggunakan Termux.

Didukung oleh FFmpeg, tools ini menyediakan dua mode pemotongan: **LOSSLESS** untuk memotong video dengan cepat tanpa encoding ulang, dan **PRESISI** untuk mendapatkan durasi potongan yang lebih akurat melalui proses encoding ulang H.264.

Dengan tampilan terminal yang rapi, pemindaian video otomatis, analisis informasi video, serta indikator progres secara real-time, proses pemotongan video menjadi lebih mudah dan praktis.

---

## Features | Fitur

| Feature | Description |
|:--|:--|
| Automatic Scanning | Automatically detects video files |
| Video Analysis | Displays codec, resolution, FPS, bitrate, and duration |
| LOSSLESS Mode | Splits videos without re-encoding |
| PRESISI Mode | Re-encodes videos for more accurate durations |
| Real-time Progress | Displays cutting progress in percentage |
| Multiple Formats | Supports various popular video formats |
| Pagination | Organizes video lists into multiple pages |
| Safe Output | Automatically creates separate output folders |
| Storage Access | Supports Android internal storage |

### Supported Video Formats

`MP4` · `MKV` · `MOV` · `AVI` · `WEBM` · `3GP` · `M4V` · `FLV` · `MPG` · `MPEG` · `WMV`

---

## Cutting Modes | Mode Pemotongan

### 1. LOSSLESS MODE

🇬🇧 Splits videos without re-encoding, preserving the original video and audio streams. This mode is fast and does not reduce quality.

🇮🇩 Memotong video tanpa encoding ulang sehingga kualitas asli video dan audio tetap terjaga. Prosesnya lebih cepat dan tidak memerlukan encoding ulang.

**Advantages | Kelebihan**
- Original quality preserved.
- Faster processing.
- No video re-encoding.

**Note | Catatan:** Cutting positions depend on keyframes, so segment durations may not always be exact.

### 2. PRESISI MODE

🇬🇧 Re-encodes videos using H.264 to achieve more accurate segment durations.

🇮🇩 Melakukan encoding ulang menggunakan H.264 untuk menghasilkan durasi potongan yang lebih akurat.

**Advantages | Kelebihan**
- More accurate cutting durations.
- Uses H.264 video encoding.
- Suitable when precise segment lengths are needed.

**Note | Catatan:** Processing takes longer and output quality or file size may differ from the original.

---

## Installation | Tutorial Instalasi

### Requirements | Persyaratan

- Android device.
- Termux.
- Internet connection for installation.
- Sufficient storage space.

### Step 1 — Install Termux

🇬🇧 Download and install Termux on your Android device.

🇮🇩 Unduh dan instal Termux terlebih dahulu.

Recommended source: [Termux on F-Droid](https://f-droid.org/packages/com.termux/)

### Step 2 — Update Packages

Open Termux and execute:

```bash
pkg update && pkg upgrade -y
```

### Step 3 — Install Dependencies

```bash
pkg install git ffmpeg -y
```

### Step 4 — Clone Repository

```bash
git clone https://github.com/USERNAME/REPOSITORY.git
```

> Replace `USERNAME/REPOSITORY` with your actual GitHub username and repository name.

### Step 5 — Enter Repository Directory

```bash
cd REPOSITORY
```

Replace `REPOSITORY` with the directory name created by the clone command.

### Step 6 — Give Execution Permission

```bash
chmod +x lavynra2.sh
```

### Step 7 — Run The Tool

```bash
bash lavynra2.sh
```

### Step 8 — Allow Storage Permission

When prompted, allow Termux to access your device storage.

You can also execute:

```bash
termux-setup-storage
```

---

## How To Use | Cara Penggunaan

1. Run the script.
2. Wait until the video scanning process finishes.
3. Select a video using its list number.
4. Wait for the video analysis.
5. Enter the desired cutting interval in seconds.
6. Select the cutting mode:
   - `1` — LOSSLESS
   - `2` — PRESISI
7. Review the cutting summary.
8. Confirm the process.
9. Wait until the cutting process finishes.

Your video segments will automatically be saved.

---

## Output Directory | Lokasi Hasil

All processed videos are stored in:

```text
Internal Storage/
└── LAVYNRA/
    └── LAVYNRA_Cutter/
        └── video_per30s/
            ├── video_part01.mp4
            ├── video_part02.mp4
            └── video_part03.mp4
```

Each video has its own output folder based on its filename and cutting interval.

---

## Usage Example | Contoh Penggunaan

Suppose you have a video with a duration of **95 seconds** and choose a cutting interval of **30 seconds**.

The expected result:

| Segment | Duration |
|:--|--:|
| Part 01 | 30 seconds |
| Part 02 | 30 seconds |
| Part 03 | 30 seconds |
| Part 04 | 5 seconds |

The final segment contains the remaining duration.

---

## Disclaimer | Catatan

🇬🇧 This tool is provided for personal and educational purposes. Processing time depends on video resolution, duration, device performance, and selected cutting mode.

🇮🇩 Tools ini dibuat untuk keperluan pribadi dan edukasi. Waktu pemrosesan bergantung pada resolusi video, durasi, performa perangkat, serta mode pemotongan yang digunakan.

---

## Credits

**Developed & Maintained by:** [LAVYNRA](https://github.com/lavynra-root)

**GitHub:** [https://github.com/lavynra-root](https://github.com/lavynra-root)

*Simple Tools. Better Experience.*

---

**THANK YOU FOR USING LAVYNRA VIDEO CUTTER**

⭐ If you find this project useful, consider giving it a star!
