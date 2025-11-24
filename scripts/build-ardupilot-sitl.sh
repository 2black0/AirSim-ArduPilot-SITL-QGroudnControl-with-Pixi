#!/usr/bin/env bash
set -euo pipefail

# Build ArduPilot SITL (ArduCopter) inside pixi environment.
# No external prereq script is executed.
# Requirements are provided by pixi: gcc/g++, make, python + waf deps, git.

AIRSIM_HOME=${AIRSIM_HOME:-"$(pwd)/.airsim_ardupilot"}
ARDUPILOT_REPO_URL=${ARDUPILOT_REPO_URL:-"https://github.com/ArduPilot/ardupilot.git"}
ARDUPILOT_DIR="${AIRSIM_HOME}/ardupilot"

usage() {
  cat <<USAGE
Usage: $0 [options]
  --clean        Remove previous build output (build/sitl)
  --force-clone  Delete existing repo folder then fresh clone
  --help         Show this help

Environment vars:
  AIRSIM_HOME            Base workspace (default: ./ .airsim_ardupilot)
  ARDUPILOT_REPO_URL     Override ArduPilot repo URL
USAGE
}

CLEAN=0
FORCE_CLONE=0
while [[ ${1:-} == --* ]]; do
  case "$1" in
    --clean) CLEAN=1; shift ;;
    --force-clone) FORCE_CLONE=1; shift ;;
    --help) usage; exit 0 ;;
    *) echo "[build-ardupilot] Unknown option: $1" >&2; exit 1 ;;
  esac
done

echo "[build-ardupilot] AIRSIM_HOME=${AIRSIM_HOME}"
mkdir -p "${AIRSIM_HOME}"

# Basic sanity: ensure gcc & python present from pixi env
command -v gcc >/dev/null || { echo "[build-ardupilot] gcc not found (activate pixi env with 'pixi shell')" >&2; exit 1; }
command -v python3 >/dev/null || { echo "[build-ardupilot] python3 not found (activate pixi env with 'pixi shell')" >&2; exit 1; }
command -v git >/dev/null || { echo "[build-ardupilot] git not found (activate pixi env with 'pixi shell')" >&2; exit 1; }

if [[ ${FORCE_CLONE} -eq 1 && -d "${ARDUPILOT_DIR}" ]]; then
  echo "[build-ardupilot] --force-clone: removing existing ${ARDUPILOT_DIR}"
  rm -rf "${ARDUPILOT_DIR}"
fi

if [[ ! -d "${ARDUPILOT_DIR}/.git" ]]; then
  echo "[build-ardupilot] Cloning ArduPilot repo"
  git clone --recurse-submodules "${ARDUPILOT_REPO_URL}" "${ARDUPILOT_DIR}"
else
  echo "[build-ardupilot] Repo exists; pulling latest"
  git -C "${ARDUPILOT_DIR}" pull --rebase --autostash || echo "[build-ardupilot] Pull failed; continuing"
fi

echo "[build-ardupilot] Updating submodules"
git -C "${ARDUPILOT_DIR}" submodule update --init --recursive

cd "${ARDUPILOT_DIR}"

if [[ ! -x ./waf ]]; then
  chmod +x ./waf || true
fi

if [[ ${CLEAN} -eq 1 ]]; then
  echo "[build-ardupilot] --clean: removing build/sitl"
  rm -rf build/sitl
fi

echo "[build-ardupilot] waf configure --board sitl"
./waf configure --board sitl

echo "[build-ardupilot] Building ArduCopter (this may take a while)"
./waf build --target bin/arducopter

BIN_PATH="${ARDUPILOT_DIR}/build/sitl/bin/arducopter"
if [[ -f "${BIN_PATH}" ]]; then
  echo "[build-ardupilot] Success: ${BIN_PATH}"
else
  echo "[build-ardupilot] Build finished but binary missing: ${BIN_PATH}" >&2
  exit 1
fi

echo "[build-ardupilot] Done. Run with:  ${BIN_PATH} -w" 