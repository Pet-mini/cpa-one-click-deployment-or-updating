#!/usr/bin/env bash

set -eEuo pipefail

SERVICE_NAME="${SERVICE_NAME:-cliproxyapi.service}"
INSTALLER_URL="${INSTALLER_URL:-https://raw.githubusercontent.com/brokechubb/cliproxyapi-installer/refs/heads/master/cliproxyapi-installer}"
USER_SERVICE_PATH="/root/.config/systemd/user/${SERVICE_NAME}"
SYSTEM_SERVICE_PATH="/etc/systemd/system/${SERVICE_NAME}"
CONFIG_FILE_PATH="/root/cliproxyapi/config.yaml"

info() {
  printf '[INFO] %s\n' "$*"
}

success() {
  printf '[OK] %s\n' "$*"
}

warn() {
  printf '[WARN] %s\n' "$*" >&2
}

error() {
  printf '[ERROR] %s\n' "$*" >&2
}

die() {
  error "$*"
  exit 1
}

on_error() {
  local line_no="$1"
  error "脚本执行失败，请检查上方输出（行号：${line_no}）"
}

trap 'on_error "$LINENO"' ERR

require_command() {
  local cmd="$1"
  command -v "$cmd" >/dev/null 2>&1 || die "缺少依赖命令：${cmd}"
}

detect_target_user() {
  if [[ -n "${SUDO_USER:-}" && "${SUDO_USER}" != "root" ]]; then
    TARGET_USER="${SUDO_USER}"
  else
    TARGET_USER="root"
  fi
}

load_target_user_info() {
  local passwd_entry

  passwd_entry="$(getent passwd "${TARGET_USER}" || true)"
  [[ -n "${passwd_entry}" ]] || die "无法获取用户 ${TARGET_USER} 的系统信息"

  TARGET_UID="$(printf '%s\n' "${passwd_entry}" | cut -d: -f3)"
  [[ -n "${TARGET_UID}" ]] || die "无法解析用户 ${TARGET_USER} 的 UID"
}

check_root() {
  if [[ "${EUID}" -ne 0 ]]; then
    die "请使用 root 或 sudo 运行：bash cpa.sh"
  fi
}

check_os() {
  [[ -r /etc/os-release ]] || die "无法读取 /etc/os-release"

  # shellcheck disable=SC1091
  source /etc/os-release

  [[ "${ID:-}" == "ubuntu" ]] || die "仅支持 Ubuntu 22.04 及以上系统"
  [[ -n "${VERSION_ID:-}" ]] || die "无法识别 Ubuntu 版本"

  local major_version="${VERSION_ID%%.*}"
  [[ "${major_version}" =~ ^[0-9]+$ ]] || die "无法解析 Ubuntu 版本号：${VERSION_ID}"
  (( major_version >= 22 )) || die "当前系统版本为 Ubuntu ${VERSION_ID}，需要 Ubuntu 22.04 及以上"
}

check_dependencies() {
  local cmd
  for cmd in curl bash systemctl cp getent sed; do
    require_command "${cmd}"
  done
}

run_user_command() {
  local runtime_dir="/run/user/${TARGET_UID}"

  if [[ "${TARGET_USER}" == "root" ]]; then
    XDG_RUNTIME_DIR="${runtime_dir}" "$@"
    return
  fi

  if command -v runuser >/dev/null 2>&1; then
    runuser -u "${TARGET_USER}" -- env XDG_RUNTIME_DIR="${runtime_dir}" "$@"
    return
  fi

  if command -v sudo >/dev/null 2>&1; then
    sudo -u "${TARGET_USER}" env XDG_RUNTIME_DIR="${runtime_dir}" "$@"
    return
  fi

  die "未找到 runuser 或 sudo，无法以用户 ${TARGET_USER} 执行命令"
}

stop_user_service_best_effort() {
  info "尝试停止用户服务：${SERVICE_NAME}（用户：${TARGET_USER}）"
  if run_user_command systemctl --user stop "${SERVICE_NAME}"; then
    success "用户服务已停止或已处于停止状态"
  else
    warn "停止用户服务失败或服务不存在，继续执行后续步骤"
  fi
}

stop_system_service_best_effort() {
  info "尝试停止系统服务：${SERVICE_NAME}"
  if systemctl stop "${SERVICE_NAME}"; then
    success "系统服务已停止或已处于停止状态"
  else
    warn "停止系统服务失败或服务不存在，继续执行后续步骤"
  fi
}

run_installer() {
  info "开始执行安装/更新脚本"
  info "安装源：${INSTALLER_URL}"
  curl -fsSL "${INSTALLER_URL}" | bash
  success "安装/更新脚本执行完成"
}

copy_service_file() {
  info "检查服务文件：${USER_SERVICE_PATH}"
  [[ -f "${USER_SERVICE_PATH}" ]] || die "安装完成后未找到服务文件：${USER_SERVICE_PATH}"

  info "复制服务文件到：${SYSTEM_SERVICE_PATH}"
  cp "${USER_SERVICE_PATH}" "${SYSTEM_SERVICE_PATH}"
  success "服务文件复制完成"
}

update_config_file() {
  info "检查配置文件：${CONFIG_FILE_PATH}"
  [[ -f "${CONFIG_FILE_PATH}" ]] || die "未找到配置文件：${CONFIG_FILE_PATH}"

  info "启动允许远程与更改管理面板密码"
  sed -Ei \
    -e 's/^([[:space:]]*allow-remote:[[:space:]]*)false([[:space:]]*(#.*)?)$/\1true\2/' \
    -e 's/^([[:space:]]*secret-key:[[:space:]]*)""([[:space:]]*(#.*)?)$/\1"admin"\2/' \
    "${CONFIG_FILE_PATH}"
  success "配置文件检查/更新完成"
}

reload_enable_start() {
  info "重新加载 systemd 配置"
  systemctl daemon-reload
  success "systemd 配置已重新加载"

  info "设置开机自启：${SERVICE_NAME}"
  systemctl enable "${SERVICE_NAME}"
  success "开机自启设置完成"

  info "启动服务：${SERVICE_NAME}"
  systemctl start "${SERVICE_NAME}"
  success "服务启动完成"
}

show_status() {
  info "查看服务状态：${SERVICE_NAME}"
  systemctl status "${SERVICE_NAME}" --no-pager
}

main() {
  check_root
  check_os
  check_dependencies
  detect_target_user
  load_target_user_info

  info "目标用户：${TARGET_USER}"
  info "用户服务文件路径：${USER_SERVICE_PATH}"
  info "配置文件路径：${CONFIG_FILE_PATH}"

  stop_user_service_best_effort
  stop_system_service_best_effort
  run_installer
  copy_service_file
  update_config_file
  reload_enable_start
  show_status

  success "cliproxyapi 安装/更新流程已完成"
}

main "$@"
