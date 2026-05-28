#!/bin/bash

# ==========================================
#    Mllama Mobile - Termux AI Dashboard
#    Cyber WhiteHat AI Assistant
# ==========================================

DIR="$HOME/MllamaMobile"
MODEL_DIR="$DIR/model"
SESSION_DIR="$DIR/sessions"
WEB_DIR="$DIR/web"
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
    if [ -f "$MODEL_DIR/build/bin/llama-cli" ]; then
        bin_path="$MODEL_DIR/build/bin/llama-cli"
    elif [ -f "$MODEL_DIR/llama-cli" ]; then
        bin_path="$MODEL_DIR/llama-cli"
    elif [ -f "$MODEL_DIR/main" ]; then
        bin_path="$MODEL_DIR/main"
    elif [ -f "$TAR_FILE" ]; then
        echo -e "${YELLOW}[*] Mendeteksi file tar.gz... Mengekstrak binary...${NC}"
        tar -xzf "$TAR_FILE" -C "$MODEL_DIR" 2>/dev/null
        bin_path=$(find "$MODEL_DIR" -type f \( -name "llama-cli" -o -name "main" \) | head -n 1)
        if [ -n "$bin_path" ]; then
            chmod +x "$bin_path"
        fi
    fi
    echo "$bin_path"
}

LLAMA_BIN=$(find_llama_binary)

get_arch() {
    local arch=$(uname -m)
    if [[ "$arch" == *"aarch64"* ]] || [[ "$arch" == *"arm64"* ]]; then echo "ARM64-v8a"
    elif [[ "$arch" == *"armv7"* ]]; then echo "ARM32-v7a"
    else echo "$arch"; fi
}

get_total_ram() {
    if [ -f "/proc/meminfo" ]; then
        echo "$(awk '/MemTotal/ {printf "%.1f", $2/1024/1024}' /proc/meminfo) GB"
    else echo "Unknown"; fi
}

get_used_ram() {
    if [ -f "/proc/meminfo" ]; then
        local total=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
        local free=$(awk '/MemAvailable/ {print $2}' /proc/meminfo)
        echo "$(awk "BEGIN {printf \"%.1f\", ($total-$free)/1024/1024}") GB"
    else echo "Unknown"; fi
}

get_cpu_usage() {
    if [ -f "/proc/stat" ]; then
        read -r cpu user nice system idle iowait irq softirq steal guest guest_nice < <(sed -n 's/^cpu //p' /proc/stat)
        local idle_total=$((idle + iowait))
        local total=$((user + nice + system + idle_total + irq + softirq + steal + guest + guest_nice))
        echo "$((100 * (total - idle_total) / total))%"
    else echo "N/A"; fi
}

get_cpu_temp() {
    if [ -f "/sys/class/thermal/thermal_zone0/temp" ]; then
        local temp=$(cat /sys/class/thermal/thermal_zone0/temp)
        echo "$((temp / 1000))°C"
    else echo "N/A"; fi
}

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
# FUNGSI MANAJEMEN MODEL, SESSION & WEB
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

start_chat_terminal() {
    local session_name="$1"
    local session_file="$SESSION_DIR/$session_name.json"
    
    if [ ! -f "$session_file" ]; then
        echo '{"messages":[]}' > "$session_file"
    fi

    local SYS_PROMPT="Kamu adalah WhiteHat AI, asisten keamanan siber tingkat ahli. Tugasmu menjelaskan kerentanan, cara kerja serangan (untuk edukasi/pertahanan), memberikan solusi mitigasi, dan analisis kode. Jawaban harus akurat, terstruktur, dan fokus pada pertahanan (Blue Team). Jika ditanya di luar cyber security, arahkan kembali ke topik keamanan."

    echo -e "${GREEN}[*] Memulai sesi: $session_name${NC}"
    echo -e "${YELLOW}[*] Ketik '.exit' untuk kembali ke dashboard${NC}"
    echo -e "${YELLOW}[*] Ketik '.stats' untuk cek RAM HP saat AI berpikir${NC}"
    echo -e "------------------------------------------------"

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

    while true; do
        read -p "${WHITE}You: ${NC}" user_input

        if [ "$user_input" == ".exit" ]; then break; fi
        if [ "$user_input" == ".stats" ]; then show_system_stats; continue; fi
        if [ -z "$user_input" ]; then continue; fi

        jq --arg u "$user_input" '.messages += [{"role": "user", "content": $u}]' "$session_file" > tmp.json && mv tmp.json "$session_file"
        local CURRENT_CONTEXT="${CONTEXT}User: $user_input\nAI WhiteHat:"

        echo -ne "${YELLOW}${DIM}[*] AI sedang berpikir... (RAM: $(get_used_ram) Terpakai)      \r${NC}"

        local AI_RESPONSE=$("$LLAMA_BIN" -m "$MODEL_FILE" -c 4096 -ngl 99 -t 4 -b 512 --temp 0.7 --top-k 40 --top-p 0.9 --repeat-penalty 1.1 --system-prompt "$SYS_PROMPT" -p "$CURRENT_CONTEXT" -n 1024 --log-disable 2>/dev/null | sed 's/^AI WhiteHat://')

        echo -ne "\033[2K\r" 
        echo -e "${CYAN}AI WhiteHat:${NC} $AI_RESPONSE"
        echo ""

        AI_RESPONSE_CLEAN=$(echo "$AI_RESPONSE" | jq -Rs .)
        jq --argjson a "$AI_RESPONSE_CLEAN" '.messages += [{"role": "assistant", "content": $a}]' "$session_file" > tmp.json && mv tmp.json "$session_file"
        CONTEXT="${CURRENT_CONTEXT} ${AI_RESPONSE}\n"
    done
}

# ==========================================
# FUNGSI WEB UI BUILDER & RUNNER
# ==========================================

build_and_run_web() {
    if ! command -v node &> /dev/null; then
        echo -e "${YELLOW}[*] Menginstall Node.js untuk Web Server...${NC}"
        pkg install nodejs -y -q
    fi

    mkdir -p "$WEB_DIR"

    # Buat Backend server.js
    cat << 'EOFNODE' > "$WEB_DIR/server.js"
const http = require('http');
const fs = require('fs');
const path = require('path');
const { exec } = require('child_process');

const PORT = 8080;
const DIR = process.env.HOME + '/MllamaMobile';
const MODEL_FILE = DIR + '/model/cyber-model.gguf';

let LLAMA_BIN = '';
const modelDir = DIR + '/model';
if (fs.existsSync(modelDir + '/build/bin/llama-cli')) LLAMA_BIN = modelDir + '/build/bin/llama-cli';
else if (fs.existsSync(modelDir + '/llama-cli')) LLAMA_BIN = modelDir + '/llama-cli';
else if (fs.existsSync(modelDir + '/main')) LLAMA_BIN = modelDir + '/main';

const server = http.createServer((req, res) => {
    if (req.method === 'GET' && req.url === '/') {
        res.writeHead(200, { 'Content-Type': 'text/html' });
        fs.createReadStream(path.join(__dirname, 'index.html')).pipe(res);
    } 
    else if (req.method === 'POST' && req.url === '/chat') {
        let body = '';
        req.on('data', chunk => body += chunk);
        req.on('end', () => {
            const { message, history } = JSON.parse(body);
            const SYS_PROMPT = "Kamu adalah WhiteHat AI, asisten keamanan siber tingkat ahli. Tugasmu menjelaskan kerentanan, cara kerja serangan (untuk edukasi/pertahanan), memberikan solusi mitigasi, dan analisis kode. Jawaban harus akurat, terstruktur, dan fokus pada pertahanan (Blue Team). Jika ditanya di luar cyber security, arahkan kembali ke topik keamanan.";
            
            let CONTEXT = "";
            history.forEach(msg => {
                CONTEXT += (msg.role === 'user' ? "User: " : "AI WhiteHat: ") + msg.content + "\n";
            });
            CONTEXT += "User: " + message + "\nAI WhiteHat:";

            const cmd = `"${LLAMA_BIN}" -m "${MODEL_FILE}" -c 4096 -ngl 99 -t 4 -b 512 --temp 0.7 --top-k 40 --top-p 0.9 --repeat-penalty 1.1 --system-prompt "${SYS_PROMPT}" -p "${CONTEXT.replace(/"/g, '\\"').replace(/`/g, '\\`')}" -n 1024 --log-disable`;

            exec(cmd, { maxBuffer: 1024 * 1024 * 10 }, (error, stdout, stderr) => {
                if (error) {
                    res.writeHead(500, { 'Content-Type': 'application/json' });
                    res.end(JSON.stringify({ error: error.message }));
                    return;
                }
                let response = stdout.replace(/AI WhiteHat:/g, '').trim();
                res.writeHead(200, { 'Content-Type': 'application/json' });
                res.end(JSON.stringify({ response: response }));
            });
        });
    } else {
        res.writeHead(404);
        res.end('Not Found');
    }
});

server.listen(PORT, () => {
    console.log(`\n[🛡️ Mllama Web] Server berjalan di: http://localhost:${PORT}`);
    console.log(`[🛡️ Mllama Web] Buka browser HP kamu dan akses URL di atas.\n`);
    console.log(`[🛡️ Mllama Web] Tekan CTRL+C di Termux untuk menghentikan server.\n`);
});
EOFNODE

    # Buat Frontend index.html (3D Pro Dark Mode UI)
    cat << 'EOFHTML' > "$WEB_DIR/index.html"
<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Mllama Mobile - WhiteHat AI</title>
    <style>
        :root {
            --bg-dark: #050505;
            --bg-chat: #0a0a0a;
            --bg-input: #141414;
            --border: #1f1f1f;
            --text-main: #e0e0e0;
            --text-dim: #5a5a5a;
            --accent-green: #00ff9d;
            --accent-cyan: #00d9ff;
            --neon-glow: 0 0 10px rgba(0, 217, 255, 0.4), 0 0 20px rgba(0, 217, 255, 0.2);
        }
        * { box-sizing: border-box; margin: 0; padding: 0; font-family: 'Courier New', Courier, monospace; }
        body { background-color: var(--bg-dark); color: var(--text-main); height: 100vh; display: flex; flex-direction: column; overflow: hidden; position: relative; }

        /* Animasi Latar Belakang 3D Grid Pro */
        .bg-grid { position: absolute; top: 0; left: 0; width: 100%; height: 100%; z-index: -1; overflow: hidden; perspective: 500px; }
        .grid-floor { position: absolute; width: 200%; height: 200%; top: -50%; left: -50%; background-image: linear-gradient(rgba(0, 217, 255, 0.1) 1px, transparent 1px), linear-gradient(90deg, rgba(0, 217, 255, 0.1) 1px, transparent 1px); background-size: 40px 40px; transform: rotateX(60deg); animation: gridScroll 10s linear infinite; box-shadow: var(--neon-glow); }
        @keyframes gridScroll { 0% { transform: rotateX(60deg) translateY(0); } 100% { transform: rotateX(60deg) translateY(40px); } }

        header { padding: 15px 20px; border-bottom: 1px solid var(--border); background: rgba(5,5,5,0.8); backdrop-filter: blur(10px); display: flex; align-items: center; gap: 10px; z-index: 10; }
        header h1 { font-size: 1.1rem; text-transform: uppercase; letter-spacing: 2px; color: var(--accent-cyan); text-shadow: var(--neon-glow); }
        header span { font-size: 0.7rem; color: var(--accent-green); border: 1px solid var(--accent-green); padding: 2px 6px; border-radius: 2px; text-transform: uppercase; }

        #chat-container { flex: 1; overflow-y: auto; padding: 20px; display: flex; flex-direction: column; gap: 20px; scroll-behavior: smooth; }
        #chat-container::-webkit-scrollbar { width: 4px; }
        #chat-container::-webkit-scrollbar-thumb { background: var(--accent-cyan); border-radius: 4px; }
        
        .message { display: flex; gap: 15px; max-width: 850px; width: 100%; margin: 0 auto; animation: glitchIn 0.3s cubic-bezier(0.25, 0.46, 0.45, 0.94); }
        .message.user { align-self: flex-end; flex-direction: row-reverse; }
        
        .avatar { width: 35px; height: 35px; border-radius: 0; clip-path: polygon(50% 0%, 100% 25%, 100% 75%, 50% 100%, 0% 75%, 0% 25%); display: flex; align-items: center; justify-content: center; font-size: 1.2rem; flex-shrink: 0; background: var(--bg-input); }
        .message.ai .avatar { border: 1px solid var(--accent-cyan); box-shadow: var(--neon-glow); }
        .message.user .avatar { border: 1px solid var(--accent-green); box-shadow: 0 0 10px rgba(0, 255, 157, 0.4); }

        .bubble { padding: 12px 18px; border-radius: 0; line-height: 1.6; font-size: 0.9rem; white-space: pre-wrap; border-left: 3px solid transparent; }
        .message.user .bubble { background: var(--bg-input); border-left-color: var(--accent-green); color: #fff; }
        .message.ai .bubble { background: rgba(10,10,10,0.8); border-left-color: var(--accent-cyan); backdrop-filter: blur(5px); }

        /* Animasi 3D Thinking Kubus (Matrix Style) */
        .thinking-container { display: none; align-items: center; gap: 15px; max-width: 850px; margin: 0 auto; }
        .thinking-container.active { display: flex; }
        .cube-wrapper { width: 35px; height: 35px; perspective: 100px; }
        .cube { width: 100%; height: 100%; position: relative; transform-style: preserve-3d; animation: spinMatrix 2s infinite linear; }
        .face { position: absolute; width: 35px; height: 35px; border: 2px solid var(--accent-green); background: rgba(0, 255, 157, 0.1); box-shadow: 0 0 15px rgba(0, 255, 157, 0.4); }
        .face.front { transform: translateZ(17px); }
        .face.back { transform: rotateY(180deg) translateZ(17px); }
        .face.right { transform: rotateY(90deg) translateZ(17px); }
        .face.left { transform: rotateY(-90deg) translateZ(17px); }
        @keyframes spinMatrix { 0% { transform: rotateX(0deg) rotateY(0deg); } 100% { transform: rotateX(360deg) rotateY(360deg); } }
        @keyframes glitchIn { 0% { opacity: 0; transform: translateY(20px) skewX(-10deg); } 100% { opacity: 1; transform: translateY(0) skewX(0deg); } }
        .thinking-text { color: var(--accent-green); text-transform: uppercase; letter-spacing: 2px; font-size: 0.8rem; animation: pulse 1s infinite; }
        @keyframes pulse { 0%, 100% { opacity: 0.3; } 50% { opacity: 1; } }

        footer { padding: 15px 20px; border-top: 1px solid var(--border); background: rgba(5,5,5,0.9); backdrop-filter: blur(10px); z-index: 10; }
        .input-wrapper { max-width: 850px; margin: 0 auto; display: flex; gap: 10px; background: var(--bg-input); border: 1px solid var(--border); padding: 5px; clip-path: polygon(0 0, 100% 0, 100% 85%, 95% 100%, 0 100%); }
        #user-input { flex: 1; background: transparent; border: none; outline: none; color: #fff; padding: 10px; font-size: 0.9rem; resize: none; font-family: inherit; }
        #send-btn { background: transparent; border: 1px solid var(--accent-cyan); border-radius: 0; padding: 0 20px; cursor: pointer; font-weight: bold; color: var(--accent-cyan); text-transform: uppercase; transition: 0.2s; }
        #send-btn:hover { background: var(--accent-cyan); color: #000; box-shadow: var(--neon-glow); }
        #send-btn:disabled { border-color: #333; color: #333; cursor: not-allowed; box-shadow: none; }
    </style>
</head>
<body>

<div class="bg-grid">
    <div class="grid-floor"></div>
</div>

<header>
    <h1>Mllama Mobile</h1>
    <span>Cyber WhiteHat</span>
</header>

<div id="chat-container">
    <div class="message ai">
        <div class="avatar">🛡️</div>
        <div class="bubble">Koneksi tersambung ke terminal. Sistem keamanan aktif. Ketik pertanyaan kerentananmu...</div>
    </div>
</div>

<div class="thinking-container" id="thinking-indicator">
    <div class="cube-wrapper">
        <div class="cube">
            <div class="face front"></div>
            <div class="face back"></div>
            <div class="face right"></div>
            <div class="face left"></div>
        </div>
    </div>
    <div class="thinking-text">Decrypting Vulnerabilities...</div>
</div>

<footer>
    <div class="input-wrapper">
        <textarea id="user-input" rows="1" placeholder=">> Masukkan input..."></textarea>
        <button id="send-btn">KIRIM</button>
    </div>
</footer>

<script>
    const chatContainer = document.getElementById('chat-container');
    const userInput = document.getElementById('user-input');
    const sendBtn = document.getElementById('send-btn');
    const thinkingIndicator = document.getElementById('thinking-indicator');
    let chatHistory = [];

    function addMessage(role, text) {
        const msgDiv = document.createElement('div');
        msgDiv.classList.add('message', role);
        const avatar = document.createElement('div');
        avatar.classList.add('avatar');
        avatar.textContent = role === 'user' ? '💻' : '🛡️';
        const bubble = document.createElement('div');
        bubble.classList.add('bubble');
        bubble.textContent = text;
        msgDiv.appendChild(avatar);
        msgDiv.appendChild(bubble);
        chatContainer.appendChild(msgDiv);
        chatContainer.scrollTop = chatContainer.scrollHeight;
    }

    async function sendMessage() {
        const text = userInput.value.trim();
        if (!text) return;
        addMessage('user', text);
        chatHistory.push({ role: 'user', content: text });
        userInput.value = '';
        sendBtn.disabled = true;
        thinkingIndicator.classList.add('active');
        chatContainer.scrollTop = chatContainer.scrollHeight;

        try {
            const response = await fetch('/chat', {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ message: text, history: chatHistory })
            });
            const data = await response.json();
            thinkingIndicator.classList.remove('active');
            if (data.response) {
                addMessage('ai', data.response);
                chatHistory.push({ role: 'assistant', content: data.response });
            } else {
                addMessage('ai', '[ERROR] Eksekusi gagal. RAM mungkin penuh.');
            }
        } catch (error) {
            thinkingIndicator.classList.remove('active');
            addMessage('ai', '[ERROR] Koneksi terputus dari terminal.');
        }
        sendBtn.disabled = false;
        userInput.focus();
    }

    sendBtn.addEventListener('click', sendMessage);
    userInput.addEventListener('keydown', (e) => {
        if (e.key === 'Enter' && !e.shiftKey) { e.preventDefault(); sendMessage(); }
    });
</script>
</body>
</html>
EOFHTML

    # Jalankan server
    echo -e "${GREEN}[*] Memulai Server Web Mllama Mobile...${NC}"
    node "$WEB_DIR/server.js"
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
        echo -e "${WHITE} 1. ${GREEN}🚀 Mulai Percakapan Baru (Terminal)${NC}"
        echo -e "${WHITE} 2. ${GREEN}📂 Lanjutkan Percakapan Tersimpan${NC}"
        echo -e "${WHITE} 3. ${GREEN}🗑️  Hapus Riwayat Percakapan${NC}"
        echo -e "${WHITE} 4. ${GREEN}🔄 Ganti/Download Ulang Model${NC}"
        echo -e "${WHITE} 5. ${MAGENTA}🌐 Jalankan di Web UI (Localhost)${NC}"
        echo -e "${WHITE} 6. ${GREEN}❌ Keluar${NC}"
        echo -e "${GREEN}═══════════════════════════════════════════════════════${NC}"
        read -p "Pilih menu (1-6): " choice

        case $choice in
            1)
                read -p "Masukkan nama sesi baru (tanpa spasi): " new_session
                if [ -z "$new_session" ]; then
                    echo -e "${RED}[!] Nama sesi tidak boleh kosong!${NC}"
                    read -p "Tekan Enter..."
                    continue
                fi
                start_chat_terminal "$new_session"
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
                        start_chat_terminal "$load_session"
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
                build_and_run_web
                read -p "Tekan Enter untuk kembali ke menu..."
                ;;
            6)
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

if ! command -v jq &> /dev/null; then
    echo -e "${YELLOW}[*] Menginstall 'jq' untuk mengelola JSON...${NC}"
    pkg install jq -y -q
fi

mkdir -p "$DIR" "$MODEL_DIR" "$SESSION_DIR"

main_menu