#!/usr/bin/env bash
set -euo pipefail

# Simple QGroundControl downloader (latest AppImage)
# Uses: wget (pixi simulation env)

AIRSIM_HOME=${AIRSIM_HOME:-"$(pwd)/.airsim_ardupilot"}
QGC_FILE="QGroundControl-x86_64.AppImage"
QGC_URL=${QGC_URL:-"https://github.com/mavlink/qgroundcontrol/releases/latest/download/${QGC_FILE}"}
QGC_DIR="${AIRSIM_HOME}/qgroundcontrol"
QGC_PATH="${QGC_DIR}/${QGC_FILE}"

echo "[download-qground] AIRSIM_HOME=${AIRSIM_HOME}"
mkdir -p "${QGC_DIR}"

if [[ -f "${QGC_PATH}" ]]; then
  echo "[download-qground] AppImage already exists: ${QGC_PATH}"
  echo "[download-qground] Skipping download."
else
  echo "[download-qground] Downloading ${QGC_URL}"
  wget --progress=dot:giga -O "${QGC_PATH}" "${QGC_URL}"
  chmod +x "${QGC_PATH}" || echo "[download-qground] Warning: chmod failed"
fi

echo "[download-qground] Done. QGroundControl at ${QGC_PATH}"