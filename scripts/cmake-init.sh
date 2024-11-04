cmake-init --overwrite .
# bash "$PIXI_PROJECT_ROOT/scripts/init-presets.sh"
python scripts/modify-presets.py
rm "$PIXI_PROJECT_ROOT/.clangd"
