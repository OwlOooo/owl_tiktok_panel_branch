#!/bin/sh

# 定义颜色变量
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m'
script_url="https://raw.githubusercontent.com/OwlOooo/owl_tiktok_panel_branch/main/owl.sh"



# 强制获取最新的脚本
if [ -f /usr/local/bin/owl ]; then
    printf  "${GREEN}旧的脚本存在，删除它...${NC}"
    sudo rm -f /usr/local/bin/owl
fi

# 添加时间戳参数
timestamp=$(date +%s)

printf  "${GREEN}下载最新的脚本...${NC}"
sudo curl -H "Cache-Control: no-cache, no-store, must-revalidate" -H "Pragma: no-cache" -H "Expires: 0" -o /usr/local/bin/owl -L "${script_url}?t=${timestamp}"

# 检查下载是否成功
if [ $? -ne 0 ]; then
    printf  "${RED}下载脚本失败，请检查URL是否正确。${NC}"
    exit 1
fi

# 设置权限
printf  "${GREEN}设置脚本权限...${NC}"
sudo chmod +x /usr/local/bin/owl

# 检查是否成功设置权限
if [ $? -ne 0 ]; then
    printf  "${RED}设置权限失败。${NC}"
    exit 1
fi

# 输出成功信息
printf  "${GREEN}已安装好脚本，输入owl命令即可使用脚本${NC}"
echo
