#!/usr/bin/env bash
set -euo pipefail

# Check if simulation components (AirSim, QGroundControl, ArduPilot SITL) are ready
# Returns exit code 0 if all components are present and valid

AIRSIM_HOME=${AIRSIM_HOME:-"$(pwd)/.airsim_ardupilot"}

# Color codes for output
if [[ -t 1 ]]; then
  GREEN='\033[0;32m'
  RED='\033[0;31m'
  YELLOW='\033[1;33m'
  BLUE='\033[0;34m'
  BOLD='\033[1m'
  RESET='\033[0m'
else
  GREEN=''
  RED=''
  YELLOW=''
  BLUE=''
  BOLD=''
  RESET=''
fi

CHECKS_PASSED=0
CHECKS_FAILED=0
CHECKS_WARNING=0

print_header() {
  echo -e "${BLUE}${BOLD}"
  echo "=============================================="
  echo "  Simulation Environment Check"
  echo "=============================================="
  echo -e "${RESET}"
  echo "AIRSIM_HOME: ${AIRSIM_HOME}"
  echo ""
}

check_airsim() {
  echo -e "${BOLD}[1/3] Checking AirSim Environment...${RESET}"
  
  local airsim_dir="${AIRSIM_HOME}/airsim/AirSimNH"
  local launcher="${airsim_dir}/LinuxNoEditor/AirSimNH.sh"
  
  if [[ ! -d "${airsim_dir}" ]]; then
    echo -e "${RED}✗ AirSim environment not found at: ${airsim_dir}${RESET}"
    echo "  Run: ./scripts/download-airsim.sh"
    ((CHECKS_FAILED++))
    return 1
  fi
  
  if [[ ! -f "${launcher}" ]]; then
    echo -e "${RED}✗ AirSim launcher not found: ${launcher}${RESET}"
    ((CHECKS_FAILED++))
    return 1
  fi
  
  if [[ ! -x "${launcher}" ]]; then
    echo -e "${YELLOW}⚠ AirSim launcher not executable: ${launcher}${RESET}"
    echo "  Fix: chmod +x ${launcher}"
    ((CHECKS_WARNING++))
  fi
  
  # Check for settings.json
  local settings_dir="${HOME}/Documents/AirSim"
  local settings_file="${settings_dir}/settings.json"
  
  if [[ ! -f "${settings_file}" ]]; then
    echo -e "${YELLOW}⚠ AirSim settings.json not found at: ${settings_file}${RESET}"
    echo "  This is optional but recommended for ArduPilot integration."
    ((CHECKS_WARNING++))
  else
    if grep -q '"VehicleType".*"ArduCopter"' "${settings_file}" 2>/dev/null; then
      echo -e "${GREEN}✓ AirSim settings configured for ArduCopter${RESET}"
    else
      echo -e "${YELLOW}⚠ AirSim settings.json exists but may not be configured for ArduCopter${RESET}"
      ((CHECKS_WARNING++))
    fi
  fi
  
  echo -e "${GREEN}✓ AirSim environment ready${RESET}"
  echo "  Location: ${airsim_dir}"
  echo "  Launcher: ${launcher}"
  ((CHECKS_PASSED++))
  echo ""
}

check_qgroundcontrol() {
  echo -e "${BOLD}[2/3] Checking QGroundControl...${RESET}"
  
  local qgc_path="${AIRSIM_HOME}/qgroundcontrol/QGroundControl-x86_64.AppImage"
  
  if [[ ! -f "${qgc_path}" ]]; then
    echo -e "${RED}✗ QGroundControl not found at: ${qgc_path}${RESET}"
    echo "  Run: ./scripts/download-qground.sh"
    ((CHECKS_FAILED++))
    return 1
  fi
  
  if [[ ! -x "${qgc_path}" ]]; then
    echo -e "${YELLOW}⚠ QGroundControl not executable: ${qgc_path}${RESET}"
    echo "  Fix: chmod +x ${qgc_path}"
    ((CHECKS_WARNING++))
  fi
  
  # Check file size (should be > 100MB for valid AppImage)
  local file_size
  file_size=$(stat -f%z "${qgc_path}" 2>/dev/null || stat -c%s "${qgc_path}" 2>/dev/null || echo "0")
  local min_size=$((100 * 1024 * 1024))  # 100 MB
  
  if [[ ${file_size} -lt ${min_size} ]]; then
    echo -e "${RED}✗ QGroundControl file seems too small (${file_size} bytes)${RESET}"
    echo "  The file may be corrupted. Try re-downloading."
    ((CHECKS_FAILED++))
    return 1
  fi
  
  echo -e "${GREEN}✓ QGroundControl ready${RESET}"
  echo "  Location: ${qgc_path}"
  echo "  Size: $(numfmt --to=iec-i --suffix=B ${file_size} 2>/dev/null || echo "${file_size} bytes")"
  ((CHECKS_PASSED++))
  echo ""
}

check_ardupilot() {
  echo -e "${BOLD}[3/3] Checking ArduPilot SITL...${RESET}"
  
  local ardupilot_dir="${AIRSIM_HOME}/ardupilot"
  local binary="${ardupilot_dir}/build/sitl/bin/arducopter"
  
  if [[ ! -d "${ardupilot_dir}/.git" ]]; then
    echo -e "${RED}✗ ArduPilot repository not found at: ${ardupilot_dir}${RESET}"
    echo "  Run: ./scripts/build-ardupilot-sitl.sh"
    ((CHECKS_FAILED++))
    return 1
  fi
  
  if [[ ! -f "${binary}" ]]; then
    echo -e "${RED}✗ ArduCopter binary not found at: ${binary}${RESET}"
    echo "  Run: ./scripts/build-ardupilot-sitl.sh"
    ((CHECKS_FAILED++))
    return 1
  fi
  
  if [[ ! -x "${binary}" ]]; then
    echo -e "${YELLOW}⚠ ArduCopter binary not executable: ${binary}${RESET}"
    echo "  Fix: chmod +x ${binary}"
    ((CHECKS_WARNING++))
  fi
  
  # Get ArduPilot version
  local version="unknown"
  if command -v git >/dev/null 2>&1; then
    version=$(git -C "${ardupilot_dir}" describe --tags --always 2>/dev/null || echo "unknown")
  fi
  
  # Check binary size
  local binary_size
  binary_size=$(stat -f%z "${binary}" 2>/dev/null || stat -c%s "${binary}" 2>/dev/null || echo "0")
  
  if [[ ${binary_size} -lt 1000000 ]]; then
    echo -e "${RED}✗ ArduCopter binary seems too small (${binary_size} bytes)${RESET}"
    echo "  The build may have failed. Try rebuilding with --clean flag."
    ((CHECKS_FAILED++))
    return 1
  fi
  
  echo -e "${GREEN}✓ ArduPilot SITL ready${RESET}"
  echo "  Location: ${binary}"
  echo "  Version: ${version}"
  echo "  Size: $(numfmt --to=iec-i --suffix=B ${binary_size} 2>/dev/null || echo "${binary_size} bytes")"
  ((CHECKS_PASSED++))
  echo ""
}

check_pixi_env() {
  echo -e "${BOLD}[Extra] Checking Pixi Environment...${RESET}"
  
  if ! command -v pixi >/dev/null 2>&1; then
    echo -e "${YELLOW}⚠ pixi command not found in PATH${RESET}"
    echo "  Pixi is recommended for managing dependencies."
    ((CHECKS_WARNING++))
    echo ""
    return 0
  fi
  
  # Check if we're inside pixi environment
  if [[ -n "${PIXI_ENVIRONMENT_NAME:-}" ]]; then
    echo -e "${GREEN}✓ Running inside pixi environment: ${PIXI_ENVIRONMENT_NAME}${RESET}"
  else
    echo -e "${YELLOW}⚠ Not running inside pixi environment${RESET}"
    echo "  Activate with: pixi shell"
    ((CHECKS_WARNING++))
  fi
  
  echo ""
}

print_summary() {
  echo -e "${BLUE}${BOLD}=============================================="
  echo "  Summary"
  echo "==============================================RESET}"
  echo ""
  
  if [[ ${CHECKS_FAILED} -eq 0 && ${CHECKS_WARNING} -eq 0 ]]; then
    echo -e "${GREEN}${BOLD}✓ All checks passed! (${CHECKS_PASSED}/3)${RESET}"
    echo ""
    echo "Your simulation environment is ready to use."
    echo ""
    echo "Next steps:"
    echo "  1. Start AirSim:     ${AIRSIM_HOME}/airsim/AirSimNH/LinuxNoEditor/AirSimNH.sh"
    echo "  2. Start ArduPilot:  ${AIRSIM_HOME}/ardupilot/build/sitl/bin/arducopter -w"
    echo "  3. Start QGC:        ${AIRSIM_HOME}/qgroundcontrol/QGroundControl-x86_64.AppImage"
    return 0
  elif [[ ${CHECKS_FAILED} -eq 0 ]]; then
    echo -e "${YELLOW}${BOLD}⚠ Checks passed with ${CHECKS_WARNING} warning(s)${RESET}"
    echo ""
    echo "Your simulation environment should work, but consider fixing the warnings above."
    return 0
  else
    echo -e "${RED}${BOLD}✗ ${CHECKS_FAILED} check(s) failed, ${CHECKS_WARNING} warning(s)${RESET}"
    echo ""
    echo "Please fix the errors above before proceeding."
    return 1
  fi
}

main() {
  print_header
  check_airsim || true
  check_qgroundcontrol || true
  check_ardupilot || true
  check_pixi_env || true
  print_summary
}

main "$@"
