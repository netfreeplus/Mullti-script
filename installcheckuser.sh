#!/bin/bash

get_arch() {
    case "$(uname -m)" in
        x86_64 | x64 | amd64 ) echo 'amd64' ;;
        armv8 | arm64 | aarch64 ) echo 'arm64' ;;
        * ) echo 'unsupported' ;;
    esac
}

check_ubuntu_version() {
    local version=$(lsb_release -rs)
    if [[ "$version" == "18."* ]]; then
        echo -e "\e[1;31mVersion de Ubuntu no soportada!\e[0m"
        exit 1
    fi
}

install_checkuser() {
    local latest_release=$(curl -s https://api.github.com//repos/DTunnel0/CheckUser-Go/releases/latest | grep "tag_name" | cut -d'"' -f4)
    local arch=$(get_arch)

    if [ "$arch" = "unsupported" ]; then
        echo -e "\e[1;31mArquitetura de CPU não suportada!\e[0m"
        exit 1
    fi

    local name="checkuser-linux-$arch"
    echo "Baixando $name..."
    wget -q "https://github.com/DTunnel0/CheckUser-Go/releases/download/$latest_release/$name" -O /usr/local/bin/checkuser
    chmod +x /usr/local/bin/checkuser

    port="2052"

    if [ -z "$port" ]; then
        echo -e "\e[1;31mPuerto no suministrado . Saliendo.\e[0m"
        exit 1
    fi

    if systemctl status checkuser &>/dev/null 2>&1; then
        echo "Parando el servicio Checkuser existente..."
        sudo systemctl stop checkuser
        sudo systemctl disable checkuser
        sudo rm /etc/systemd/system/checkuser.service
        sudo systemctl daemon-reload
        echo "El servicio checkuser existente se ha detenido y eliminado ."
    fi

    cat << EOF | sudo tee /etc/systemd/system/checkuser.service > /dev/null
[Unit]
Description=CheckUser Service
After=network.target nss-lookup.target

[Service]
User=root
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/checkuser --start --port $port
Restart=always

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload &>/dev/null
    sudo systemctl start checkuser &>/dev/null
    sudo systemctl enable checkuser &>/dev/null

    local addr=$(curl -s https://ipv4.icanhazip.com)
    local url=$(curl -s https://dns.dtunnel.com.br/api/v1/dns/create -X POST --data '{"content": "'"$addr"'"}' | grep -o '"domain": *"[^"]*"' | grep -o '"[^"]*"$' | tr -d '"')

    echo -e "\e[1;32mURL: \e[1;33mhttp://$addr:$port\e[0m"
    echo -e "\e[1;32mDOMAIN: \e[1;33mhttp://$url:$port\e[0m"
    echo -e "\e[1;32mO El servicio CheckUser se ha instalado e iniciado.\e[0m"
    read
}

reinstall_checkuser() {
    echo "Detener y eliminar el servicio Checkuser..."
    sudo systemctl stop checkuser &>/dev/null
    sudo systemctl disable checkuser &>/dev/null
    sudo rm /usr/local/bin/checkuser
    sudo rm /etc/systemd/system/checkuser.service
    sudo systemctl daemon-reload &>/dev/null
    echo "Servicio checkuser removido."

    install_checkuser
}

uninstall_checkuser() {
    sudo systemctl stop checkuser &>/dev/null
    sudo systemctl disable checkuser &>/dev/null
    sudo rm /usr/local/bin/checkuser
    sudo rm /etc/systemd/system/checkuser.service
    sudo systemctl daemon-reload &>/dev/null
    echo "Servicio checkuser removido."
    read
}

main() {
    clear

    echo '---------------------------------'
    echo -ne '     \e[1;33mCHECKUSER NETCOL-VIP\e[0m'
    if [[ -e /usr/local/bin/checkuser ]]; then
        echo -e ' \e[1;32mv'$(/usr/local/bin/checkuser --version | cut -d' ' -f2)'\e[0m'
    else
        echo -e ' \e[1;31m[DESINSTALADO]\e[0m'
    fi
    echo '---------------------------------'

    echo -e '\e[1;32m[01] - \e[1;31mINSTALAR CHECKUSER\e[0m'
    echo -e '\e[1;32m[02] - \e[1;31mREINSTALAR CHECKUSER\e[0m'
    echo -e '\e[1;32m[03] - \e[1;31mDESINSTALAR CHECKUSER\e[0m'
    echo -e '\e[1;32m[00] - \e[1;31mSAIR\e[0m'
    echo '---------------------------------'
    echo -ne '\e[1;32mEscoja una opción: \e[0m'; 
    read option

    case $option in
        1) install_checkuser; main ;;
        2) reinstall_checkuser; main ;;
        3) uninstall_checkuser; main ;;
        0) echo "Saindo.";;
        *) echo -e "\e[1;31mOpcion invalida intente nuevamente.\e[0m";read; main ;;
    esac
}

check_ubuntu_version
main
