# 適当アーキテクチャ
TekitouArchitecture -> TA  
TA-64 -> TekitouArchitecture - 64bit  

このアーキテクチャには、CPUの基本設計以外にも、各モジュールの基本設計や、プロトコルなども含まれています  

## TA-64
### CPUの基本設計  
1: 1命令は固定長の64bit  
2: レジスタ数は32個、r0は何しても0  
3: 命令の種類はネストしない、最初のOpCode(16bit)だけ  

記述言語: SystemVerilog  

### テスト方法
前提: Linux環境を用意してください。Debian/Ubuntu推奨  
0: `sudo apt install build-essential verilator libfl-dev`を実行してパッケージをインストール (初回のみ)  
1: `verilator --cc main.sv --exe sim_main.cpp --build --trace`でコンパイル  
2: `./obj_dir/Vmain`で実行  
これだけです  
あ、事前にリポジトリはクローンしといて