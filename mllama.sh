#!/bin/bash

# ==========================================
#    Mllama Mobile - Termux AI Dashboard
#    Cyber WhiteHat AI Assistant
# ==========================================

DIR="$HOME/MllamaMobile"
MODEL_DIR="$DIR/model"
SESSION_DIR="$DIR/sessions"
TAR_FILE="$MODEL_DIR/llama-b9273-bin-android-arm64.tar.gz"
MODEL_FILE="$MODEL_DIR/cyber-model.gguf"
LOG_FILE="$DIR/ai_system.log"

# Warna Terminal
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
DIM='\033[2m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# ==========================================
# FUNGSI UTILITAS SISTEM
# ==========================================

# Cari binary llama.cpp
find_llama_binary() {
    local bin_path=""
    # Cek di build dir (spesifik untuk tar.gz llama.cpp)
    if [ -f "$MODEL_DIR/build/bin/llama-cli" ]; then
        bin_path="$MODEL_DIR/build/bin/llama-cli"
    elif [ -f "$MODEL_DIR/llama-cli" ]; then
        bin_path="$MODEL_DIR/llama-cli"
    elif [ -f "$MODEL_DIR/main" ]; then
        bin_path="$MODEL_DIR/main"
    elif [ -f "$TAR_FILE" ]; then
        echo -e "${YELLOW}[*] Mendeteksi file tar.gz... Mengekstrak binary...${NC}"
        tar -xzf "$TAR_FILE" -C "$MODEL_DIR" 2>/dev/null
        
        # Cari secara recursive setelah ekstrak
        bin_path=$(find "$MODEL_DIR" -type f -name "llama-cli" -o -name "main" | head -n 1)
        
        if [ -n "$bin_path" ]; then
            chmod +x "$bin_path"
        fi
    fi
    echo "$bin_path"
}

LLAMA_BIN=$(find_llama_binary)

# Deteksi Arsitektur & CPU
get_arch() {
    local arch=$(uname -m)
    if [[ "$arch" == *"aarch64"* ]] || [[ "$arch" == *"arm64"* ]]; then echo "ARM64-v8a"
    elif [[ "$arch" == *"armv7"* ]]; then echo "ARM32-v7a"
    else echo "$arch"; fi
}

# Cek Total RAM HP
get_total_ram() {
    if [ -f "/proc/meminfo" ]; then
        echo "$(awk '/MemTotal/ {printf "%.1f", $2/1024/1024}' /proc/meminfo) GB"
    else echo "Unknown"; fi
}

# Cek RAM Terpakai
get_used_ram() {
    if [ -f "/proc/meminfo" ]; then
        local total=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
        local free=$(awk '/MemAvailable/ {print $2}' /proc/meminfo)
        echo "$(awk "BEGIN {printf \"%.1f\", ($total-$free)/1024/1024}") GB"
    else echo "Unknown"; fi
}

# Cek CPU Usage (Instan)
get_cpu_usage() {
    if [ -f "/proc/stat" ]; then
        read -r cpu user nice system idle iowait irq softirq steal guest guest_nice < <(sed -n 's/^cpu //p' /proc/stat)
        local idle_total=$((idle + iowait))
        local total=$((user + nice + system + idle_total + irq + softirq + steal + guest + guest_nice))
        echo "$((100 * (total - idle_total) / total))%"
    else echo "N/A"; fi
}

# Cek Suhu CPU
get_cpu_temp() {
    if [ -f "/sys/class/thermal/thermal_zone0/temp" ]; then
        local temp=$(cat /sys/class/thermal/thermal_zone0/temp)
        echo "$((temp / 1000))°C"
    else echo "N/A"; fi
}

# Hitung Ukuran File/Dir
get_size() {
    du -sh "$1" 2>/dev/null | awk '{print $1}'
}

# ==========================================
# FUNGSI TAMPILAN UI
# ==========================================

show_ascii() {
    clear
    echo -e "${MAGENTA}${BOLD}"
    cat << "EOF"
  __  __       ___  ____     __  __  __ _ _    
 |  \/  |_   _|  _ \| ___ )  |  \/  |/ _| | |   
 | |\/| | | | | |  | ___ \  | |\/| | |_| | |   
 | |  | | |_| | |_| | ___) ) | |  | |  _| | |   
 |_|  |_|\__, |____/|____/  |_|  |_|_| |_|_|   
         |___/                                  
      ____  _               _             ____ 
     / ___|| |__   __ _  __| | _____  __ |__  /
     \___ \| '_ \ / _` |/ _` |/ _ \ \/ /   / / 
      ___) | | | | (_| | (_| |  __/>  <   / /_ 
     |____/|_| |_|\__,_|\__,_|\___/_/\_\ /____|
                      
EOF
    echo -e "${NC}"
    echo -e "${DIM}             [ Cyber WhiteHat AI Assistant ]${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
}

show_system_stats() {
    local arch=$(get_arch)
    local total_ram=$(get_total_ram)
    local used_ram=$(get_used_ram)
    local cpu_usage=$(get_cpu_usage)
    local cpu_temp=$(get_cpu_temp)
    local model_size=$(get_size "$MODEL_FILE" 2>/dev/null || echo "0")
    local binary_status="${RED}✗ Tidak Ditemukan${NC}"
    
    if [ -n "$LLAMA_BIN" ]; then
        binary_status="${GREEN}✓ Ready${NC}"
    fi

    echo -e "${CYAN}[ SYSTEM STATUS ]${NC}"
    echo -e "${WHITE} OS       : ${DIM}Android Termux ($(uname -o))${NC}"
    echo -e "${WHITE} Arch     : ${DIM}$arch${NC}"
    echo -e "${WHITE} CPU      : ${DIM}Usage: $cpu_usage | Temp: $cpu_temp${NC}"
    echo -e "${WHITE} RAM      : ${DIM}$used_ram / $total_ram${NC}"
    echo -e "${WHITE} Engine   : $binary_status ${DIM}$(basename "$LLAMA_BIN" 2>/dev/null)${NC}"
    echo -e "${WHITE} Model    : ${DIM}$(basename $MODEL_FILE) [$model_size]${NC}"
    echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
}

# ==========================================
# FUNGSI MANAJEMEN MODEL & SESSION
# ==========================================

check_model() {
    if [ ! -f "$MODEL_FILE" ]; then
        echo -e "${RED}[!] Model AI belum ada!${NC}"
        echo -e "${YELLOW}Untuk RAM 4-6GB, disarankan menggunakan model Qwen 2.5 3B (1.9GB).${NC}"
        read -p "Download model sekarang? (y/n): " dl_choice
        if [ "$dl_choice" == "y" ] || [ "$dl_choice" == "Y" ]; then
            echo -e "${CYAN}[*] Downloading Qwen2.5-3B-Instruct-Q4_K_M...${NC}"
            wget -O "$MODEL_FILE" "https://huggingface.co/Qwen/Qwen2.5-3B-Instruct-GGUF/resolve/main/qwen2.5-3b-instruct-q4_k_m.gguf"
            if [ $? -eq 0 ]; then
                echo -e "${GREEN}[+] Download selesai!${NC}"
            else
                echo -e "${RED}[!] Download gagal. Cek koneksi internet.${NC}"
                exit 1
            fi
        else
            echo -e "${RED}[!] Model wajib didownload untuk menjalankan AI.${NC}"
            exit 1
        fi
    fi
}

start_chat() {
    local session_name="$1"
    local session_file="$SESSION_DIR/$session_name.json"
    
    # Inisialisasi file JSON jika belum ada
    if [ ! -f "$session_file" ]; then
        echo '{"messages":[]}' > "$session_file"
    fi

    # System Prompt Khusus Whitehat
    local SYS_PROMPT="Kamu adalah WhiteHat AI, asisten keamanan siber tingkat ahli. Tugasmu menjelaskan kerentanan, cara kerja serangan (untuk edukasi/pertahanan), memberikan solusi mitigasi, dan analisis kode. Jawaban harus akurat, terstruktur, dan fokus pada pertahanan (Blue Team). Jika ditanya di luar cyber security, arahkan kembali ke topik keamanan. Jangan pernah memberikan script deface atau merusak, fokus pada pentesting."

    echo -e "${GREEN}[*] Memulai sesi: $session_name${NC}"
    echo -e "${YELLOW}[*] Ketik '.exit' untuk kembali ke dashboard${NC}"
    echo -e "${YELLOW}[*] Ketik '.stats' untuk cek RAM HP saat AI berpikir${NC}"
    echo -e "------------------------------------------------"

    # Load riwayat ke string untuk context llama.cpp
    local CONTEXT=""
    while IFS= read -r line; do
        local role=$(echo "$line" | jq -r '.role')
        local content=$(echo "$line" | jq -r '.content')
        if [ "$role" == "user" ]; then
            CONTEXT+="User: $content\n"
        elif [ "$role" == "assistant" ]; then
            CONTEXT+="AI WhiteHat: $content\n"
        fi
    done < <(jq -c '.messages[]' "$session_file" 2>/dev/null)

    # Loop Chat
    while true; do
        read -p "${WHITE}You: ${NC}" user_input

        if [ "$user_input" == ".exit" ]; then
            break
        fi

        if [ "$user_input" == ".stats" ]; then
            show_system_stats
            continue
        fi

        if [ -z "$user_input" ]; then
            continue
        fi

        # Simpan input user ke JSON
        jq --arg u "$user_input" '.messages += [{"role": "user", "content": $u}]' "$session_file" > tmp.json && mv tmp.json "$session_file"

        # Tambahkan input ke context sementara
        local CURRENT_CONTEXT="${CONTEXT}User: $user_input\nAI WhiteHat:"

        # Tampilkan indikator berpikir
        echo -ne "${YELLOW}${DIM}[*] AI sedang berpikir... (RAM: $(get_used_ram) Terpakai)      \r${NC}"

        # Jalankan Llama.cpp
        local AI_RESPONSE=$("$LLAMA_BIN" \
            -m "$MODEL_FILE" \
            -c 4096 \
            -ngl 99 \
            -t 4 \
            -b 512 \
            --temp 0.7 \
            --top-k 40 \
            --top-p 0.9 \
            --repeat-penalty 1.1 \
            --system-prompt "$SYS_PROMPT" \
            -p "$CURRENT_CONTEXT" \
            -n 1024 \
            --log-disable 2>/dev/null | sed 's/^AI WhiteHat://') # Bersihkan prefix

        # Hapus indikator berpikir dan tampilkan hasil
        echo -ne "\033[2K\r" 
        echo -e "${CYAN}AI WhiteHat:${NC} $AI_RESPONSE"
        echo ""

        # Simpan respon AI ke JSON
        AI_RESPONSE_CLEAN=$(echo "$AI_RESPONSE" | jq -Rs .)
        jq --argjson a "$AI_RESPONSE_CLEAN" '.messages += [{"role": "assistant", "content": $a}]' "$session_file" > tmp.json && mv tmp.json "$session_file"
        
        # Update context loop
        CONTEXT="${CURRENT_CONTEXT} ${AI_RESPONSE}\n"
    done
}

# ==========================================
# MENU UTAMA DASHBOARD
# ==========================================

main_menu() {
    check_model
    
    if [ -z "$LLAMA_BIN" ]; then
        echo -e "${RED}[!] Binary llama.cpp tidak ditemukan! Pastikan file tar.gz ada di folder model/.${NC}"
        exit 1
    fi

    while true; do
        show_ascii
        show_system_stats
        
        echo -e "${CYAN}[ MAIN MENU ]${NC}"
        echo -e "${WHITE} 1. ${GREEN}🚀 Mulai Percakapan Baru${NC}"
        echo -e "${WHITE} 2. ${GREEN}📂 Lanjutkan Percakapan Tersimpan${NC}"
        echo -e "${WHITE} 3. ${GREEN}🗑️  Hapus Riwayat Percakapan${NC}"
        echo -e "${WHITE} 4. ${GREEN}🔄 Ganti/Download Ulang Model${NC}"
        echo -e "${WHITE} 5. ${GREEN}❌ Keluar${NC}"
        echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
        read -p "Pilih menu (1-5): " choice

        case $choice in
            1)
                read -p "Masukkan nama sesi baru (tanpa spasi): " new_session
                if [ -z "$new_session" ]; then
                    echo -e "${RED}[!] Nama sesi tidak boleh kosong!${NC}"
                    read -p "Tekan Enter..."
                    continue
                fi
                start_chat "$new_session"
                ;;
            2)
                echo -e "${YELLOW}[*] Daftar Sesi Tersimpan:${NC}"
                local files=$(ls -1 "$SESSION_DIR" 2>/dev/null | sed 's/\.json$//')
                if [ -z "$files" ]; then
                    echo -e "${RED}Belum ada sesi tersimpan.${NC}"
                else
                    echo "$files"
                    read -p "Pilih nama sesi: " load_session
                    if [ -f "$SESSION_DIR/$load_session.json" ]; then
                        start_chat "$load_session"
                    else
                        echo -e "${RED}[!] Sesi tidak ditemukan!${NC}"
                    fi
                fi
                read -p "Tekan Enter untuk melanjutkan..."
                ;;
            3)
                echo -e "${YELLOW}[*] Daftar Sesi:${NC}"
                ls -1 "$SESSION_DIR" 2>/dev/null | sed 's/\.json$//'
                read -p "Masukkan nama sesi yang ingin dihapus: " del_session
                if [ -f "$SESSION_DIR/$del_session.json" ]; then
                    rm "$SESSION_DIR/$del_session.json"
                    echo -e "${GREEN}[+] Sesi $del_session berhasil dihapus.${NC}"
                else
                    echo -e "${RED}[!] Sesi tidak ditemukan.${NC}"
                fi
                read -p "Tekan Enter untuk melanjutkan..."
                ;;
            4)
                echo -e "${YELLOW}[*] Model saat ini: $(get_size $MODEL_FILE)${NC}"
                read -p "Hapus model lama dan download ulang? (y/n): " redl
                if [ "$redl" == "y" ] || [ "$redl" == "Y" ]; then
                    rm -f "$MODEL_FILE"
                    check_model
                fi
                ;;
            5)
                show_ascii
                echo -e "${GREEN}Sampai jumpa, Hacker! Tetap etis dan amankan dunia digital.${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Pilihan tidak valid!${NC}"
                read -p "Tekan Enter untuk melanjutkan..."
                ;;
        esac
    done
}

# ==========================================
# INISIALISASI AWAL
# ==========================================

# Install jq jika belum ada (untuk baca/tulis JSON)
if ! command -v jq &> /dev/null; then
    echo -e "${YELLOW}[*] Menginstall 'jq' untuk mengelola JSON...${NC}"
    pkg install jq -y -q
fi

# Buat folder jika belum ada
mkdir -p "$DIR" "$MODEL_DIR" "$SESSION_DIR"

# Jalankan Menu
main_menu