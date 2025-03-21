#!/bin/bash

# 设置安装目录
BASE_DIR="/root/t3rn"
INSTALL_DIR="$BASE_DIR/executor/executor/bin"
ENV_FILE="$INSTALL_DIR/.env"
START_SCRIPT="$INSTALL_DIR/start_executor.sh"

# 创建根目录和目标目录
mkdir -p "$INSTALL_DIR"

# 交互式输入要下载的版本号
read -p "Enter the version of executor you want to download (e.g., v0.29.0): " EXECUTOR_VERSION
EXECUTOR_URL="https://github.com/t3rn/executor-release/releases/download/$EXECUTOR_VERSION/executor-linux-$EXECUTOR_VERSION.tar.gz"

# 下载 executor 程序
if [ ! -f "$INSTALL_DIR/executor" ]; then
  echo "Downloading Executor binary version $EXECUTOR_VERSION..."
  wget -q -O "$BASE_DIR/executor.tar.gz" "$EXECUTOR_URL"
  echo "Extracting Executor binary..."
  tar -xzf "$BASE_DIR/executor.tar.gz" -C "$BASE_DIR"
  rm "$BASE_DIR/executor.tar.gz"
  chmod +x "$INSTALL_DIR/executor"
else
  echo "Executor binary already exists. Skipping download."
fi

# 创建 .env 文件
if [ ! -f "$ENV_FILE" ]; then
  echo "Creating .env file..."

  # 交互式输入 Private Key 和 Alchemy ID
  read -p "Enter your Private Key: " PRIVATE_KEY
  read -p "Enter your Alchemy ID: " ALCHEMY_ID

  # 写入 .env 文件
  cat <<EOL > "$ENV_FILE"
NODE_ENV=testnet
LOG_LEVEL=debug
LOG_PRETTY=false
EXECUTOR_PROCESS_ORDERS=true
EXECUTOR_PROCESS_CLAIMS=true
PRIVATE_KEY_LOCAL=$PRIVATE_KEY
RPC_ENDPOINTS_ARBT='https://arb-sepolia.g.alchemy.com/v2/$ALCHEMY_ID'
RPC_ENDPOINTS_BSSP='https://base-sepolia.g.alchemy.com/v2/$ALCHEMY_ID'
RPC_ENDPOINTS_BLSS='https://blast-sepolia.g.alchemy.com/v2/$ALCHEMY_ID'
RPC_ENDPOINTS_OPSP='https://opt-sepolia.g.alchemy.com/v2/$ALCHEMY_ID'
RPC_ENDPOINTS_L1RN='https://brn.rpc.caldera.xyz/'
ENABLED_NETWORKS='arbitrum-sepolia,base-sepolia,blast-sepolia,optimism-sepolia,l1rn'
EXECUTOR_PROCESS_PENDING_ORDERS_FROM_API=false
EXECUTOR_MAX_L3_GAS_PRICE=420
EOL

  echo ".env file created successfully."
else
  echo ".env file already exists. Skipping creation."
fi

# 创建启动脚本
if [ ! -f "$START_SCRIPT" ]; then
  echo "Creating start script..."
  cat <<EOL > "$START_SCRIPT"
#!/bin/bash
cd $INSTALL_DIR
export \$(grep -v '^#' .env | xargs)
./executor
EOL
  chmod +x "$START_SCRIPT"
  echo "Start script created successfully."
else
  echo "Start script already exists. Skipping creation."
fi

# 检查是否安装 screen
if ! command -v screen &> /dev/null; then
  echo "screen is not installed. Installing screen..."
  sudo apt update
  sudo apt install -y screen
else
  echo "screen is already installed. Skipping installation."
fi

# 使用 screen 启动程序
echo "Starting executor in a new screen session..."
screen -dmS t3rn_executor bash -c "$START_SCRIPT"

# 输出完成信息
echo "Installation complete!"
echo "Use 'screen -r t3rn_executor' to reattach the session."
