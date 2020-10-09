#!/usr/bin/env bash
echo "Cloning dependencies"
git clone --depth=1 https://github.com/KazuDante89/kernel_lavender -b caf-eas-wip folder
cd folder
git clone --depth=1 https://github.com/kdrag0n/proton-clang clang
git clone --depth=1 https://github.com/KazuDante89/AnyKernel3-EAS AnyKernel
echo "Done"
IMAGE=$(pwd)/out/arch/arm64/boot/Image.gz-dtb
TANGGAL=$(date +"%F-%S")
START=$(date +"%s")
export CONFIG_PATH=$PWD/arch/arm64/configs/lavender_defconfig
PATH="${PWD}/clang/bin:$PATH"
export LD="clang/bin/ld.lld"
export ARCH=arm64
export USE_CCACHE=1
export KBUILD_BUILD_HOST=circleci
export KBUILD_BUILD_USER="Kazu_Dante"
# Send info about the build to Telegram Channel/Group (Depending upon what chat_id you've specified in CircleCI Environment Variables)
function sendinfo() {
    curl -s -X POST "https://api.telegram.org/bot$token/sendMessage" \
        -d chat_id="$chat_id" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=html" \
        -d text="<b>[EAS-CAF] Shift Kernel </b>%0ABuild Status : SUCCESS%0ALast Commit Info - <code>$(git log --pretty=format:'"%h : %s"' -1)</code>"
}
# Push kernel to Telegram Channel/Group
function push() {
    cd AnyKernel
    ZIP=$(echo *.zip)
    curl -F document=@$ZIP "https://api.telegram.org/bot$token/sendDocument" \
        -F chat_id="$chat_id" \
        -F "disable_web_page_preview=true" \
        -F "parse_mode=html" \
        -F caption="Completed"
}
# Broke the process on Error countup check
function finerr() {
    curl -s -X POST "https://api.telegram.org/bot$token/sendMessage" \
        -d chat_id="$chat_id" \
        -d "disable_web_page_preview=true" \
        -d "parse_mode=markdown" \
          -d text="Fck Build throw error(s)"
    exit 1
}
# Compile plox
function compile() {
   make O=out ARCH=arm64 lavender_defconfig
       make -j$(nproc --all) O=out \
                             ARCH=arm64 \
                             CC=clang \
                             LD=ld.lld \
			                       CROSS_COMPILE=aarch64-linux-gnu- \
			                       CROSS_COMPILE_ARM32=arm-linux-gnueabi-
   cp out/arch/arm64/boot/Image.gz-dtb AnyKernel
}
# Zipping
function zipping() {
    cd AnyKernel || exit 1
    zip -r9 [EAS-CAF]-Shift-Kernel-CAF_v0.0.0.zip *
    cd ..
}
sendinfo
compile
zipping
END=$(date +"%s")
DIFF=$(($END - $START))
push
