# VPI Dlang

VPI2をD言語で使うサンプルプロジェクト。Jetson Orin で動作確認しています。Jetson の `/opt/nvidia/vpi2/samples/01-convolve_2d` と同じようなことを行っています。

## Getting Started

LDCとDuBをインストールする。

```shell
# 2023/12/31時点では 1.35.0 が入る
curl -fsS https://dlang.org/install.sh | bash -s ldc
source ~/dlang/ldc-1.35.0/activate
```

実行。

```shell
dub -- pva <path/to/image_file>
```
