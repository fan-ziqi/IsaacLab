#!/usr/bin/env bash
# Copyright (c) 2022-2026, The Isaac Lab Project Developers (https://github.com/isaac-sim/IsaacLab/blob/main/CONTRIBUTORS.md).
# All rights reserved.
#
# SPDX-License-Identifier: BSD-3-Clause

# Standalone Bash installer; Python is provided by the selected uv or Conda environment.
set -euo pipefail

repository_url="https://github.com/isaac-sim/IsaacLab.git"
isaaclab_version=""
manager=""
backend=""
install_dir=""
env_name=""
dry_run=false
bootstrap_tmp=""
conda_command="conda"

cleanup() {
    if [[ -n "$bootstrap_tmp" ]]; then
        rm -rf -- "$bootstrap_tmp"
    fi
}
trap cleanup EXIT
trap 'printf "安装停止（第 %s 行）。\n" "$LINENO" >&2' ERR

fail() {
    printf '安装停止：%s\n' "$*" >&2
    exit 1
}

usage() {
    cat <<'HELP'
Isaac Lab 一键安装脚本（Linux，非官方）

用法：bash install_isaaclab.sh [选项]
不带参数时，交互式选择安装选项。

  --version VERSION   3.0.0（release/3.0.0）、2.3.2 或 1.4.1
  --manager MANAGER   uv 或 conda
  --backend BACKEND   3.0.0 可选 isaacsim 或 newton
  --directory PATH    Isaac Lab 仓库的安装目录
  --env-name NAME     Conda 环境名，默认按版本命名
  --dry-run           只显示安装命令，不下载或修改文件
  -h, --help          显示帮助
HELP
}

parse_options() {
    local option value
    while (( $# )); do
        case "$1" in
            -h|--help) usage; exit 0 ;;
            --dry-run) dry_run=true; shift; continue ;;
            --version|--manager|--backend|--directory|--env-name)
                (( $# >= 2 )) || fail "$1 缺少参数。"
                option="$1"; value="$2"; shift 2 ;;
            --version=*|--manager=*|--backend=*|--directory=*|--env-name=*)
                option="${1%%=*}"; value="${1#*=}"; shift ;;
            *) fail "未知选项：$1。请使用 --help 查看用法。" ;;
        esac
        [[ -n "$value" ]] || fail "$option 不能为空。"
        case "$option" in
            --version) isaaclab_version="${value#v}" ;;
            --manager) manager="$value" ;;
            --backend) backend="$value" ;;
            --directory) install_dir="$value" ;;
            --env-name) env_name="$value" ;;
        esac
    done
}

choose() {
    local prompt="$1" response index
    shift
    local choices=("$@")
    while true; do
        printf '\n%s\n' "$prompt" >&2
        for index in "${!choices[@]}"; do
            printf '  %s) %s\n' "$((index + 1))" "${choices[index]}" >&2
        done
        read -r -p '请选择 [1]：' response || fail '输入已结束，请使用参数指定安装选项。'
        response="${response:-1}"
        if [[ "$response" =~ ^[1-9][0-9]*$ ]] && (( response <= ${#choices[@]} )); then
            printf '%s' "${choices[response - 1]}"
            return
        fi
        printf '请输入有效的选项编号。\n' >&2
    done
}

select_options() {
    [[ -n "$isaaclab_version" ]] || isaaclab_version="$(choose '选择 Isaac Lab 版本：' 3.0.0 2.3.2 1.4.1)"
    case "$isaaclab_version" in
        3.0.0) revision='release/3.0.0'; python_version='3.12'; glibc_min='2.35' ;;
        2.3.2)
            revision='v2.3.2'; python_version='3.11'; glibc_min='2.35'
            sim_version='5.1.0'; torch_version='2.7.0'; torchvision_version='0.22.0'; cuda_tag='cu128' ;;
        1.4.1)
            revision='v1.4.1'; python_version='3.10'; glibc_min='2.34'
            sim_version='4.2.0.2'; torch_version='2.4.0'; torchvision_version='0.19.0'; cuda_tag='cu118' ;;
        *) fail '支持的版本为 3.0.0、2.3.2 和 1.4.1。' ;;
    esac
    [[ -n "$manager" ]] || manager="$(choose '选择包管理器：' uv conda)"
    [[ "$manager" == uv || "$manager" == conda ]] || fail '包管理器必须为 uv 或 conda。'
    if [[ -z "$backend" ]]; then
        if [[ "$isaaclab_version" == 3.0.0 ]]; then
            backend="$(choose '选择安装后端（isaacsim 为完整工作流，newton 不安装 Isaac Sim）：' isaacsim newton)"
        else
            backend='isaacsim'
        fi
    fi
    [[ "$backend" == isaacsim || "$backend" == newton ]] || fail '后端必须为 isaacsim 或 newton。'
    [[ "$isaaclab_version" == 3.0.0 || "$backend" == isaacsim ]] || fail 'Newton 安装选项仅支持 Isaac Lab 3.0.0。'
    if [[ -z "$install_dir" ]]; then
        read -r -p "Isaac Lab 安装目录 [$PWD/IsaacLab-$isaaclab_version]：" install_dir || fail '输入已结束，请使用 --directory 指定目录。'
        install_dir="${install_dir:-$PWD/IsaacLab-$isaaclab_version}"
    fi
    install_dir="$(realpath -m -- "$install_dir")"
    env_name="${env_name:-isaaclab_${isaaclab_version//./_}}"
    [[ "$env_name" =~ ^[A-Za-z0-9_][A-Za-z0-9_-]*$ && "$env_name" != base ]] || fail '请选择有效的独立 Conda 环境名，不可使用 base。'
    printf '\nIsaac Lab %s · %s · Python %s · %s · %s\n项目目录：%s\n' \
        "$isaaclab_version" "$revision" "$python_version" "$manager" "$backend" "$install_dir"
}

run() {
    printf '$'; printf ' %q' "$@"; printf '\n'
    if ! "$dry_run"; then
        "$@"
    fi
}

version_at_least() {
    local actual="$1" required="$2" index left right
    local actual_parts required_parts
    [[ "$actual" =~ ^[0-9]+(\.[0-9]+)*$ ]] || return 1
    IFS=. read -r -a actual_parts <<< "$actual"
    IFS=. read -r -a required_parts <<< "$required"
    for ((index = 0; index < ${#required_parts[@]} || index < ${#actual_parts[@]}; index++)); do
        left=$((10#${actual_parts[index]:-0}))
        right=$((10#${required_parts[index]:-0}))
        if (( left > right )); then return 0; fi
        if (( left < right )); then return 1; fi
    done
    return 0
}

check_system() {
    if "$dry_run"; then
        printf '实际安装前将检查 Linux、GLIBC 和 NVIDIA 驱动，并准备包管理器。\n'
        return
    fi
    [[ "$(uname -s)" == Linux ]] || fail '此脚本仅支持 Linux。'
    machine="$(uname -m)"
    [[ "$machine" == x86_64 || "$machine" == aarch64 ]] || fail '支持的架构为 x86_64 和 aarch64。'
    [[ "$isaaclab_version" == 3.0.0 || "$machine" == x86_64 ]] || fail '旧版安装仅支持 x86_64。'
    local glibc_version driver_output driver
    glibc_version="$(getconf GNU_LIBC_VERSION)" || fail '需要使用 GLIBC 的受支持 Linux 系统。'
    version_at_least "${glibc_version##* }" "$glibc_min" || fail "需要 GLIBC >= $glibc_min；脚本不会升级系统 GLIBC。"
    command -v git >/dev/null || fail '请先安装 git。'
    command -v nvidia-smi >/dev/null || fail '未找到 nvidia-smi，请先安装 NVIDIA GPU 驱动。'
    driver_output="$(nvidia-smi --query-gpu=driver_version --format=csv,noheader)" || fail '无法读取 NVIDIA 驱动版本。'
    [[ -n "$driver_output" ]] || fail '未检测到 NVIDIA GPU。'
    if [[ "$isaaclab_version" == 3.0.0 ]]; then
        while IFS= read -r driver; do
            version_at_least "$driver" '580.65.06' || fail 'CUDA 13.0 需要 NVIDIA 驱动 >= 580.65.06。'
        done <<< "$driver_output"
    fi
    printf '系统检查通过，无需提前安装 CUDA Toolkit 或 nvcc。\n'
}

prepare_manager() {
    if "$dry_run"; then return; fi
    if [[ "$manager" == uv ]]; then
        if ! command -v uv >/dev/null; then
            command -v curl >/dev/null || fail '安装 uv 需要 curl。'
            bootstrap_tmp="$(mktemp -d)"
            run curl -fLsS https://astral.sh/uv/install.sh -o "$bootstrap_tmp/install-uv.sh"
            run sh "$bootstrap_tmp/install-uv.sh"
            export PATH="${HOME}/.local/bin:${PATH}"
            command -v uv >/dev/null || fail 'uv 安装后仍未找到命令，请检查 PATH。'
        fi
    elif ! command -v conda >/dev/null; then
        local conda_install_dir="${HOME}/miniforge3"
        if [[ ! -x "$conda_install_dir/bin/conda" ]]; then
            [[ ! -e "$conda_install_dir" ]] || fail "$conda_install_dir 已存在且不可用，请先配置 Conda。"
            command -v curl >/dev/null || fail '安装 Miniforge 需要 curl。'
            bootstrap_tmp="$(mktemp -d)"
            run curl -fLsS "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-${machine}.sh" \
                -o "$bootstrap_tmp/install-miniforge.sh"
            run bash "$bootstrap_tmp/install-miniforge.sh" -b -p "$conda_install_dir"
        fi
        conda_command="$conda_install_dir/bin/conda"
        [[ -x "$conda_command" ]] || fail '未找到 Conda 命令。'
    fi
}

clone_repository() {
    if [[ -e "$install_dir" ]]; then
        if ! "$dry_run"; then
            [[ -d "$install_dir" ]] || fail '安装目录不是目录，请选择新的位置。'
            local root status
            root="$(git -C "$install_dir" rev-parse --show-toplevel)" || fail '安装目录不是 Git 仓库，请选择新的位置。'
            [[ "$root" == "$install_dir" ]] || fail '安装目录不是独立的 Git 仓库，请选择新的位置。'
            status="$(git -C "$install_dir" status --porcelain)"
            [[ -z "$status" ]] || fail '安装目录有未提交的修改，请先保存修改或选择新的位置。'
        fi
        run git -C "$install_dir" fetch --depth 1 "$repository_url" "$revision"
        run git -C "$install_dir" checkout --detach FETCH_HEAD
    else
        run git clone --branch "$revision" --depth 1 "$repository_url" "$install_dir"
    fi
}

run_in_environment() {
    if [[ "$manager" == conda ]]; then
        run "$conda_command" run --no-capture-output -n "$env_name" "$@"
    else
        run "$@"
    fi
}

create_environment() {
    local version_output
    if [[ "$manager" == conda ]]; then
        local environments=""
        if ! "$dry_run"; then environments="$("$conda_command" env list)"; fi
        if ! awk -v name="$env_name" '$1 == name {found = 1} END {exit !found}' <<< "$environments"; then
            run "$conda_command" create -n "$env_name" "python=$python_version" pip -y
        fi
        if ! "$dry_run"; then
            version_output="$("$conda_command" run --no-capture-output -n "$env_name" python --version)"
        fi
    else
        if [[ "$isaaclab_version" == 3.0.0 ]]; then env_dir="$install_dir/.venv"; else env_dir="$install_dir/env_isaaclab"; fi
        if [[ ! -e "$env_dir" ]]; then
            if [[ "$isaaclab_version" == 3.0.0 ]]; then return; fi
            run uv venv --python "$python_version" --python-preference only-managed --seed "$env_dir"
        fi
        if ! "$dry_run"; then
            [[ -x "$env_dir/bin/python" ]] || fail '已有环境不含可用的 Python，请选择新的安装目录。'
            version_output="$("$env_dir/bin/python" --version)"
        fi
    fi
    if ! "$dry_run"; then
        [[ "$version_output" == "Python $python_version."* ]] || fail "已有环境的 Python 版本不是 $python_version，请选择新环境名或新目录。"
    fi
}

install_dependencies() {
    if [[ "$isaaclab_version" == 3.0.0 ]]; then
        if [[ "$manager" == uv ]]; then
            local sync_args=(uv sync --python 3.12 --python-preference only-managed)
            if [[ "$backend" == isaacsim ]]; then sync_args+=(--extra isaacsim); fi
            run "${sync_args[@]}"
        else
            local targets='newton,rl[rsl-rl],visualizer[newton]'
            if [[ "$backend" == isaacsim ]]; then targets+=',isaacsim'; fi
            run_in_environment bash ./isaaclab.sh --install "$targets"
        fi
        return
    fi
    local pip_args
    if [[ "$manager" == uv ]]; then
        pip_args=(uv pip install --python "$env_dir/bin/python")
    else
        pip_args=(python -m pip install)
    fi
    run_in_environment "${pip_args[@]}" "torch==$torch_version" "torchvision==$torchvision_version" \
        --index-url "https://download.pytorch.org/whl/$cuda_tag"
    local sim_packages
    if [[ "$isaaclab_version" == 1.4.1 ]]; then
        sim_packages=("isaacsim==$sim_version" "isaacsim-extscache-physics==$sim_version" \
            "isaacsim-extscache-kit==$sim_version" "isaacsim-extscache-kit-sdk==$sim_version")
    else
        sim_packages=("isaacsim[all,extscache]==$sim_version")
    fi
    run_in_environment "${pip_args[@]}" "${sim_packages[@]}" --extra-index-url https://pypi.nvidia.com
    if [[ "$manager" == uv ]]; then
        VIRTUAL_ENV="$env_dir" run bash ./isaaclab.sh --install rsl_rl
    else
        run_in_environment bash ./isaaclab.sh --install rsl_rl
    fi
}

verify_installation() {
    if [[ "$isaaclab_version" == 3.0.0 ]]; then
        if [[ "$manager" == uv ]]; then
            local verify_args=(uv run)
            if [[ "$backend" == isaacsim ]]; then verify_args+=(--extra isaacsim); fi
            run "${verify_args[@]}" isaaclab --help
        else
            run_in_environment isaaclab --help
        fi
    else
        local script='scripts/tutorials/00_sim/create_empty.py'
        if ! "$dry_run" && [[ ! -f "$script" ]]; then script='source/standalone/tutorials/00_sim/create_empty.py'; fi
        if [[ "$manager" == uv ]]; then
            VIRTUAL_ENV="$env_dir" run bash ./isaaclab.sh --python "$script" --help
        else
            run_in_environment bash ./isaaclab.sh --python "$script" --help
        fi
    fi
}

main() {
    parse_options "$@"
    select_options
    # Keep an activated environment from redirecting the chosen installation.
    unset VIRTUAL_ENV CONDA_PREFIX CONDA_DEFAULT_ENV PYTHONPATH UV_PROJECT_ENVIRONMENT UV_PYTHON
    check_system
    prepare_manager
    clone_repository
    if "$dry_run"; then printf '$ cd %q\n' "$install_dir"; else cd -- "$install_dir"; fi
    create_environment
    install_dependencies
    verify_installation
    if "$dry_run"; then printf '\n安装预览结束，未执行命令。\n'; else printf '\n安装和命令行入口检查完成。\n'; fi
    printf '项目目录：%s\n' "$install_dir"
    if [[ "$manager" == conda ]]; then
        printf '使用环境：conda activate %s\n' "$env_name"
    elif [[ "$isaaclab_version" == 3.0.0 ]]; then
        if [[ "$backend" == isaacsim ]]; then printf '后续在项目目录中使用：uv run --extra isaacsim isaaclab ...\n';
        else printf '后续在项目目录中使用：uv run isaaclab ...\n'; fi
    else
        printf '使用环境：source %q\n' "$env_dir/bin/activate"
    fi
    if [[ "$backend" == isaacsim ]]; then printf '首次启动 Isaac Sim 时，请阅读并自行确认 NVIDIA 的许可协议。\n'; fi
}

main "$@"
