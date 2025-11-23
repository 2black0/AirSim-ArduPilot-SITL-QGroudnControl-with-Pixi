#!/usr/bin/env bash
set -euo pipefail

# Simple AirSim environment downloader (AirSimNH only)
# Uses: wget, unzip (provided by pixi simulation env)
# Destination base can be overridden via AIRSIM_HOME

AIRSIM_HOME=${AIRSIM_HOME:-"$(pwd)/.airsim_ardupilot"}
RELEASE_TAG=${AIRSIM_ENV_RELEASE:-v1.8.1}
ZIP_NAME="AirSimNH.zip"
BASE_URL="https://github.com/microsoft/AirSim/releases/download/${RELEASE_TAG}"
ZIP_URL="${BASE_URL}/${ZIP_NAME}"
TARGET_DIR="${AIRSIM_HOME}/airsim"
ZIP_PATH="${TARGET_DIR}/${ZIP_NAME}"
ENV_DIR="${TARGET_DIR}/AirSimNH"

echo "[download-airsim] AIRSIM_HOME=${AIRSIM_HOME}"
mkdir -p "${TARGET_DIR}"

if [[ -d "${ENV_DIR}" ]]; then
  echo "[download-airsim] Environment already exists: ${ENV_DIR}"
  echo "[download-airsim] Skipping download."
else
  if [[ ! -f "${ZIP_PATH}" ]]; then
    echo "[download-airsim] Downloading ${ZIP_URL}"
    wget --progress=dot:giga -O "${ZIP_PATH}" "${ZIP_URL}"
  else
    echo "[download-airsim] Zip already present: ${ZIP_PATH}"
  fi
  echo "[download-airsim] Extracting ${ZIP_NAME}"
  unzip -q "${ZIP_PATH}" -d "${TARGET_DIR}"
  echo "[download-airsim] Removing ${ZIP_PATH}"
  rm -f "${ZIP_PATH}"
fi

# Setup settings.json
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
PROJECT_ROOT=$(cd "${SCRIPT_DIR}/.." && pwd)
SETTINGS_TEMPLATE="${PROJECT_ROOT}/config/airsim/settings.json"
SETTINGS_TARGET="${TARGET_DIR}/settings.json"
DOCUMENTS_DIR="${HOME}/Documents/AirSim"
DOCUMENTS_SETTINGS="${DOCUMENTS_DIR}/settings.json"

if [[ -f "${SETTINGS_TEMPLATE}" ]]; then
  if [[ ! -f "${SETTINGS_TARGET}" ]]; then
    echo "[download-airsim] Copying settings.json template"
    cp "${SETTINGS_TEMPLATE}" "${SETTINGS_TARGET}"
  fi
  
  mkdir -p "${DOCUMENTS_DIR}"
  
  if [[ -L "${DOCUMENTS_SETTINGS}" ]]; then
    rm -f "${DOCUMENTS_SETTINGS}"
  elif [[ -e "${DOCUMENTS_SETTINGS}" ]]; then
    echo "[download-airsim] Backing up existing settings.json"
    mv "${DOCUMENTS_SETTINGS}" "${DOCUMENTS_SETTINGS}.bak.$(date +%Y%m%d%H%M%S)"
  fi
  
  echo "[download-airsim] Creating symlink to settings.json"
  ln -s "${SETTINGS_TARGET}" "${DOCUMENTS_SETTINGS}"
else
  echo "[download-airsim] Warning: settings.json template not found at ${SETTINGS_TEMPLATE}"
fi

echo "[download-airsim] Done. AirSimNH at ${ENV_DIR}"