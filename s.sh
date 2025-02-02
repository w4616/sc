#!/usr/bin/env bash

RED="\033[31m"
GREEN="\033[32m"
YELLOW="\033[33m"
PLAIN='\033[0m'

red() {
    echo -e "\033[31m\033[01m$1\033[0m"
}

green() {
    echo -e "\033[32m\033[01m$1\033[0m"
}

yellow() {
    echo -e "\033[33m\033[01m$1\033[0m"
}

REGEX=("debian" "ubuntu" "centos|red hat|kernel|oracle linux|alma|rocky" "'amazon linux'")
RELEASE=("Debian" "Ubuntu" "CentOS" "CentOS")
PACKAGE_UPDATE=("apt-get -y update" "apt-get -y update" "yum -y update" "yum -y update")
PACKAGE_INSTALL=("apt -y install" "apt -y install" "yum -y install" "yum -y install")
PACKAGE_UNINSTALL=("apt -y autoremove" "apt -y autoremove" "yum -y autoremove" "yum -y autoremove")

[[ $EUID -ne 0 ]] && red "请在root用户下运行脚本" && exit 1

CMD=("$(grep -i pretty_name /etc/os-release 2>/dev/null | cut -d \" -f2)" "$(hostnamectl 2>/dev/null | grep -i system | cut -d : -f2)" "$(lsb_release -sd 2>/dev/null)" "$(grep -i description /etc/lsb-release 2>/dev/null | cut -d \" -f2)" "$(grep . /etc/redhat-release 2>/dev/null)" "$(grep . /etc/issue 2>/dev/null | cut -d \\ -f1 | sed '/^[ ]*$/d')")

for i in "${CMD[@]}"; do
    SYS="$i" && [[ -n $SYS ]] && break
done

for ((int = 0; int < ${#REGEX[@]}; int++)); do
    [[ $(echo "$SYS" | tr '[:upper:]' '[:lower:]') =~ ${REGEX[int]} ]] && SYSTEM="${RELEASE[int]}" && [[ -n $SYSTEM ]] && break
done

[[ -z $SYSTEM ]] && red "不支持当前VPS系统，请使用主流的操作系统" && exit 1

if [[ -z $(type -P screen) ]]; then
    if [[ ! $SYSTEM == "CentOS" ]]; then
        ${PACKAGE_UPDATE[int]}
    fi
    ${PACKAGE_INSTALL[int]} screen
fi

back2menu() {
    echo ""
    green "所选操作执行完成"
    read -rp "请输入“y”退出，或按任意键回到主菜单：" back2menuInput
    case "$back2menuInput" in
        y) exit 1 ;;
        *) menu ;;
    esac
}

createScreen(){
    read -rp "设置screen后台会话名称：" screenName
    if [[ -z $screenName ]]; then
        red "未设置screen后台会话名称，退出操作"
        back2menu
    fi
    screen -U -S $screenName
    back2menu
}

enterScreen(){
    screenNames=`screen -ls | grep '(Detached)' | awk '{print $1}' | awk -F "." '{print $2}'`
    if [[ -n $screenNames ]]; then
        yellow "当前运行的Screen后台会话如下所示："
        green "$screenNames"
    fi
    read -rp "输入进入的screen后台会话名称：" screenName
    screen -U -r $screenName || red "没有找到 $screenName 会话"
    back2menu
}

deleteScreen(){
    screenNames=`screen -ls | grep '(Detached)' | awk '{print $1}' | awk -F "." '{print $2}'`
    if [[ -n $screenNames ]]; then
        yellow "当前运行的Screen后台会话如下所示："
        green "$screenNames"
    fi
    read -rp "输入删除的screen后台会话名称：" screenName
    screen -S $screenName -X quit || red "没有找到 $screenName 会话"
    back2menu
}

killAllScreen(){
    screenNames=`screen -ls | grep '(Detached)' | awk '{print $1}' | awk -F "." '{print $2}'`
    screen -wipe
    [[ -n $screenNames ]] && screen -ls | grep '(Detached)' | cut -d. -f1 | awk '{print $1}' | xargs kill
    green "所有screen后台会话已清除完毕" || red "没有任何screen后台会话"
    back2menu
}

menu(){
    clear
    echo "#############################################################"
    echo -e "#                   ${RED} Screen  后台管理脚本${PLAIN}                   #"
    echo -e "# ${GREEN}作者${PLAIN}: Misaka No                                           #"
    echo -e "# ${GREEN}博客${PLAIN}: https://owo.misaka.rest                             #"
    echo -e "# ${GREEN}论坛${PLAIN}: https://vpsgo.co                                    #"
    echo -e "# ${GREEN}TG群${PLAIN}: https://t.me/misakanetcn                            #"
    echo -e "# ${GREEN}GitHub${PLAIN}: https://github.com/Misaka-blog                    #"
    echo -e "# ${GREEN}Bitbucket${PLAIN}: https://bitbucket.org/misakano7545             #"
    echo -e "# ${GREEN}GitLab${PLAIN}: https://gitlab.com/misaka-blog                    #"
    echo "#############################################################"
    echo ""
    echo -e " ${GREEN}1.${PLAIN} 创建screen后台会话并设置会话名称"
    echo " -------------"
    echo -e " ${GREEN}2.${PLAIN} 查看并进入指定screen后台会话"
    echo -e " ${GREEN}3.${PLAIN} 查看并删除指定screen后台会话"
    echo " -------------"
    echo -e " ${GREEN}4.${PLAIN} 清除所有screen后台会话"
    echo " -------------"
    echo -e " ${GREEN}0.${PLAIN} 退出脚本"
    echo ""
    yellow "使用脚本的一些小提示："
    yellow "1. 退出Screen后台会话时，请按Ctrl+A+D快捷键退出"
    yellow "2. 请谨慎使用4选项"
    echo ""
    read -rp "请输入选项 [0-4]:" menuNumberInput
    case "$menuNumberInput" in 
        1 ) createScreen ;;
        2 ) enterScreen ;;
        3 ) deleteScreen ;;
        4 ) killAllScreen ;;
        * ) exit 1 ;;
    esac
}

if [ $# > 0 ]; then
    menu
else
    menu
fi
