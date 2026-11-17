# 🎭 PERSONA 5 // PHANTOM THIEVES VIDEO HEIST
### Descargador de Videos Ultrarrápido para Windows con Estilo Persona 5 y Consola CMD

<p align="center">
  <img src="icon.png" width="160" alt="Persona 5 Icon" />
</p>

<p align="center">
  <strong>«A todos los servidores de la red: Hemos venido a liberar tu contenido a máxima velocidad.»</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Persona_5-Take_Your_Heart-e60012?style=for-the-badge" alt="Persona 5" />
  <img src="https://img.shields.io/badge/Motor-yt--dlp_Turbo-ffe600?style=for-the-badge&logoColor=black" alt="yt-dlp" />
  <img src="https://img.shields.io/badge/Plataforma-Windows_10_/_11-0078d7?style=for-the-badge&logo=windows" alt="Windows" />
  <img src="https://img.shields.io/badge/Dependencias-Cero_(Auto--instalable)-2eff8b?style=for-the-badge" alt="Zero Dependencies" />
</p>

---

## ⚡ ¿Qué es esto?

**Persona 5 Video Heist** es una aplicación y página web local diseñada con la estética audaz de **Persona 5** (rojo carmesí, negro cómic, blanco y amarillo relámpago). Te permite descargar videos y música de casi cualquier plataforma web (YouTube, TikTok, Twitter/X, Instagram, Facebook, Reddit, Twitch, etc.) a velocidades extremas utilizando comandos **CMD** y el motor **yt-dlp** con aceleración multihilo.

---

## 🚀 Características Principales

- ⚔️ **All-Out Attack (Máxima Calidad)**: Descarga videos en 1080p, 2K, 4K y 60 FPS combinando el mejor video y audio disponible.
- ⚡ **Swift Strike (Descarga Instantánea)**: Descarga ultrarrápida en MP4 directo (sin esperas de codificación).
- 🎵 **Persona Beat (Extracción de Audio)**: Convierte automáticamente a MP3 a 320 kbps con carátula e información.
- 🛡️ **Shadow Vault (Archival MKV)**: Conserva todos los subtítulos y pistas de audio originales.
- 🚀 **Turbo CMD Multi-Stream (-N 16)**: Divide la descarga en 16 fragmentos concurrentes para saturar tu conexión y descargar en segundos.
- 💻 **Consola CMD en Tiempo Real (Futaba HUD)**: Mira el registro del comando CMD en vivo con indicador de velocidad (MB/s), porcentaje y ETA con barras de peligro diagonales estilo P5.
- 🪟 **Modo Ventana CMD Nativa**: Botón dedicado para abrir una consola real de Windows (`cmd.exe`) si prefieres ver la ejecución en tu terminal.
- 🔊 **Efectos de Sonido P5 Sintetizados**: Sonidos de selección, corte de espada y fanfarria de victoria al completar la descarga (100% offline).
- 📌 **Acceso Directo con Icono en el Escritorio**: Se genera automáticamente en tu escritorio con el logo oficial de los Phantom Thieves.
- 🌐 **Compatibilidad Universal (Cero Requisitos)**: Funciona en cualquier PC con Windows. Si tienes **Node.js** lo usará; si no tienes Node.js ni Python, arrancará automáticamente con el servidor nativo de **PowerShell**.

---

## 📥 Cómo Usarlo en Cualquier Computadora (Instrucciones de 1 Clic)

Cualquier persona puede usarlo siguiendo estos sencillos pasos:

### Paso 1: Descargar el Proyecto
Puedes clonarlo con Git:
```bash
git clone https://github.com/wertonywool/descargador.git
```
*O haz clic en el botón verde **Code** > **Download ZIP** arriba en GitHub y descomprímelo en tu computadora.*

### Paso 2: Iniciar
Entra a la carpeta descargada y haz doble clic en:
👉 **`iniciar.bat`**

¡Listo! El script hará todo automáticamente:
1. Verificará e instalará `yt-dlp.exe` automáticamente si no está presente.
2. Creará el acceso directo **«Persona 5 - Descargador de Videos»** con su icono personalizado en tu Escritorio.
3. Iniciará el servidor local y abrirá la interfaz en tu navegador predeterminado (`http://127.0.0.1:5050`).

---

## 🖥️ ¿Dónde se guardan los videos descargados?

Todos los videos y canciones se guardan automáticamente en tu carpeta de Descargas de Windows:
```
C:\Usuarios\<TuUsuario>\Downloads\Persona5_Descargas
```
Puedes abrir la carpeta al instante haciendo clic en el botón **«📂 ABRIR CARPETA DE DESCARGAS»** dentro de la aplicación.

---

## 🛠️ Estructura del Proyecto

```
descargador/
├── bin/                        # Binarios locales de descarga (yt-dlp, ffmpeg)
├── public/
│   ├── index.html              # Interfaz web estilizada estilo Persona 5
│   ├── icon.png                # Icono Phantom Thieves (PNG alta resolución)
│   └── icon.ico                # Icono para Windows (.ico)
├── iniciar.bat                 # Lanzador principal de 1 clic (Auto-setup)
├── crear-acceso-directo.bat    # Regenera el acceso directo en el Escritorio
├── crear-acceso-directo.ps1    # Script PowerShell para ubicar el escritorio real
├── server.js                   # Servidor ultrarrápido para entornos con Node.js
├── server.ps1                  # Servidor de respaldo nativo sin dependencias
└── README.md                   # Documentación oficial
```

---

## 📋 Atajos y Opciones CMD

Dentro de la aplicación encontrarás:
- **¡ROBAR VIDEO AHORA!**: Ejecuta la descarga en segundo plano y transmite el progreso al HUD de la página.
- **ABRIR EN VENTANA CMD**: Despacha una ventana de consola real de Windows ejecutando el comando exacto.
- **COPIAR COMANDO**: Copia al portapapeles la línea de comando `yt-dlp` completa para que puedas pegarla manualmente en cualquier terminal si lo deseas.

---

## 👑 Créditos

Inspirado en la dirección de arte y menús de **Persona 5** (Atlus / SEGA).  
Desarrollado con ❤️ para máxima velocidad y facilidad de uso.
