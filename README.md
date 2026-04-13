# cpa-one-click-deployment-or-updating

用于 Ubuntu 22.04+ 的 cliproxyapi 一键部署/更新脚本。  
One-click deployment/update script for cliproxyapi on Ubuntu 22.04+.

## 中文说明

### 这是什么

这是一个面向 Ubuntu 22.04 及以上系统的 Bash 脚本，用于快速执行 cliproxyapi 的安装或更新流程，并通过 systemd 管理服务。

### 适用环境

- Ubuntu 22.04+
- 需要 `root` 或 `sudo`
- 需要系统中可用的 `curl`、`bash`、`systemctl`、`cp`、`getent`、`sed`

### 如何使用

#### 方法一：下载后执行

```bash
curl -O https://raw.githubusercontent.com/Pet-mini/cpa-one-click-deployment-or-updating/main/cpa.sh
sudo bash cpa.sh
```

#### 方法二：直接执行

```bash
curl -fsSL https://raw.githubusercontent.com/Pet-mini/cpa-one-click-deployment-or-updating/main/cpa.sh | sudo bash
```

### 脚本大致会做什么

1. 检查是否以 `root` / `sudo` 执行
2. 检查系统是否为 Ubuntu 22.04 及以上
3. 检查必要命令是否存在
4. 尝试停止旧的用户服务和系统服务
5. 拉取并执行上游安装器
6. 复制服务文件到 systemd 系统目录
7. 修改配置文件
8. 重载、启用并启动 systemd 服务
9. 输出服务状态

默认会在配置文件中执行以下修改：

- 将 `allow-remote` 设置为 `true`
- 将管理面板 `secret-key` 设置为 `admin`

### 注意事项

- 请在你自己的服务器或测试环境中使用
- 执行前建议先阅读脚本内容，确认符合你的需求
- 如果系统环境与脚本预期不一致，可能需要你自行调整
- 使用前请确认默认开启远程访问及默认 `secret-key: admin` 符合你的使用需求

### 免责声明

本项目按当前状态提供，不承诺适用于所有环境。请在自有环境中自行验证后使用，使用后果由使用者自行承担。

## English

### What is this

This is a Bash script for Ubuntu 22.04+ that performs a quick cliproxyapi installation or update workflow and manages the service with systemd.

### Requirements

- Ubuntu 22.04+
- `root` or `sudo`
- `curl`, `bash`, `systemctl`, `cp`, `getent`, and `sed`

### Usage

#### Option 1: Download and run

```bash
curl -O https://raw.githubusercontent.com/Pet-mini/cpa-one-click-deployment-or-updating/main/cpa.sh
sudo bash cpa.sh
```

#### Option 2: Run directly

```bash
curl -fsSL https://raw.githubusercontent.com/Pet-mini/cpa-one-click-deployment-or-updating/main/cpa.sh | sudo bash
```

### What the script does

1. Verifies `root` / `sudo`
2. Verifies Ubuntu 22.04 or newer
3. Checks required commands
4. Tries to stop existing user/system services
5. Downloads and runs the upstream installer
6. Copies the service file into the systemd system directory
7. Updates the config file
8. Reloads, enables, and starts the service
9. Shows the final service status

By default, the script writes the following values into the config file:

- Sets `allow-remote` to `true`
- Sets the admin panel `secret-key` to `admin`

### Notes

- Use it in your own server or test environment
- Review the script before running it
- You may need to adjust it for environments that differ from the expected setup
- Make sure the default remote access setting and default `secret-key: admin` fit your needs before use

### Disclaimer

This project is provided as-is without warranty. Please validate it in your own environment before use.
