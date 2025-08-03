#!/usr/bin/env sh

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <project_name> <project_path>"
  exit 1
fi

PROJECT_NAME="$1"
PROJECT_PATH="$(realpath "$2")"

mkdir -p ./contexts/$PROJECT_NAME/.local/share/opencode
cp -r ./contexts/opencode-docker/.local/state ./contexts/$PROJECT_NAME/.local/state
cp ./contexts/opencode-docker/.local/share/opencode/auth.json ./contexts/$PROJECT_NAME/.local/share/opencode/
cp ./run-opencode-docker.sh ./run-$PROJECT_NAME.sh
sed -i "0,/PROJECT_NAME/s/opencode-docker/$PROJECT_NAME/" ./run-$PROJECT_NAME.sh
sed -i "/PROJECT_PATH/s#=.*#=$PROJECT_PATH#" ./run-$PROJECT_NAME.sh
chmod 700 ./run-$PROJECT_NAME.sh

echo "'./run-$PROJECT_NAME.sh' is ready to use!"
