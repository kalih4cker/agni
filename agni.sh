#!/bin/bash

#--------------------[ Banner for Agni ]--------------------#
cat << 'EOF'
======================================================
                       ⢱⣆⠀⠀⠀⠀⠀      
⠀⠀                  ⠀⠀⠈⣿⣷⡀⠀⠀⠀     
                   ⠀⠀⢸⣿⣿⣷⣧⠀⠀     
                   ⠀⡀⢠⣿⡟⣿⣿⣿⡇⠀     
                 ⠀⠀⣳⣼⣿⡏⢸⣿⣿⣿⢀     
                  ⣰⣿⣿⡿⠁⢸⣿⣿⡟⣼⡆    
              ⢰⢀⣾⣿⣿⠟⠀⠀⣾⢿⣿⣿⣿⣿     
              ⢸⣿⣿⣿⡏⠀⠀⠀⠃⠸⣿⣿⣿⡿    
               ⢳⣿⣿⣿⠀⠀⠀⠀⠀⠀⢹⣿⡿⡁   
                ⠹⣿⣿⡄⠀⠀⠀⠀⠀⢠⣿⡞⠁   
                  ⠈⠛⢿⣄⠀⠀⠀⣠⠞⠋⠀⠀   
                     ⠀⠉⠀⠀⠀⠀⠀⠀⠀    
      Subdomain Discovery Engine – Agni            
======================================================
        By: KaliyugH4cker-Ashwatthama  
EOF

#--------------------[ Input Domain ]--------------------#
if [ -z "$1" ]; then
    echo "Usage: $0 <domain>"
    exit 1
fi

domain=$1
result_dir="results/$domain"
mkdir -p "$result_dir"/{subfinder,assetfinder,amass,httpx,final}

#--------------------[ Check & Install Go ]--------------------#
if ! command -v go &>/dev/null; then
    echo "[!] Go not found. Installing..."
    wget https://go.dev/dl/go1.22.3.linux-amd64.tar.gz -O /tmp/go.tar.gz
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf /tmp/go.tar.gz
    echo 'export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin' >> ~/.bashrc
    export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin
    source ~/.bashrc
else
    echo "[✓] Go is already installed."
fi

#--------------------[ Function to Install Go Tools ]--------------------#
install_go_tool() {
    local name=$1
    local repo=$2
    if ! command -v "$name" &>/dev/null; then
        echo "[+] Installing $name..."
        go install "$repo"@latest
        sudo cp ~/go/bin/$name /usr/local/bin/
    else
        echo "[✓] $name already installed."
    fi
}

#--------------------[ Install Tools ]--------------------#
install_go_tool subfinder github.com/projectdiscovery/subfinder/v2/cmd/subfinder
install_go_tool assetfinder github.com/tomnomnom/assetfinder
install_go_tool amass github.com/owasp-amass/amass/v4/...
install_go_tool httpx github.com/projectdiscovery/httpx/cmd/httpx

#--------------------[ Subdomain Enumeration ]--------------------#
echo "[→] Running subfinder..."
subfinder -d "$domain" -silent > "$result_dir/subfinder/output.txt"

echo "[→] Running assetfinder..."
assetfinder --subs-only "$domain" > "$result_dir/assetfinder/output.txt"

echo "[→] Running amass (passive)..."
amass enum -passive -d "$domain" > "$result_dir/amass/output.txt"

#--------------------[ Merge & Deduplicate ]--------------------#
echo "[→] Merging and deduplicating subdomains..."
cat "$result_dir"/*/output.txt | sort -u > "$result_dir/final/unique_subdomains.txt"

#--------------------[ Probing Live Subdomains ]--------------------#
echo "[→] Probing with httpx..."
httpx -silent -l "$result_dir/final/unique_subdomains.txt" > "$result_dir/httpx/live_subdomains.txt"

#--------------------[ Done ]--------------------#
echo -e "\n[✓] All tasks complete."
echo "Live subdomains saved to: $result_dir/httpx/live_subdomains.txt"
