#!/usr/bin/env bash
# build.sh — kernel-only build and flash for the OnePlus 9 (lemonade), 5.10.
#
#   ./build.sh build [-d device] [-t buildtype] [-g gms] [--sync] [--no-publish]
#       On the build server, from this kernel checkout inside the ROM tree
#       (<rom>/kernel/oneplus/sm8350-5.10). Builds only the images the kernel
#       lands in (boot, vendor_boot, dtbo, vendor_dlkm) with the ROM's own
#       targets, so the first-stage modules in vendor_boot and the modules in
#       vendor_dlkm always match the kernel. Packs them into
#       kernel-<version>-<date>.zip, and copies the zip plus vmlinux and
#       System.map (for RAM dump analysis) to /var/www/html/<user>/.
#
#   ./build.sh flash <kernel zip | URL | dir>
#       On the PC, phone connected (adb or fastboot). Flashes boot, vendor_boot
#       and dtbo from the bootloader, then vendor_dlkm from fastbootd, to the
#       active slot. The rest of the ROM must come from the same manifest.
#
# Flashing single images works because vbmeta is built with verification
# disabled unless WITH_AVB=true (device/oneplus/sm8350-common BoardConfigCommon.mk).

set -euo pipefail

KDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMAGES=(boot vendor_boot dtbo vendor_dlkm)

die() { echo "build.sh: $*" >&2; exit 1; }

build() {
    local device=lemonade type=userdebug gms=core sync=0 publish=1
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -d) device="$2"; shift 2 ;;
            -t) type="$2"; shift 2 ;;
            -g) gms="$2"; shift 2 ;;
            --sync) sync=1; shift ;;
            --no-publish) publish=0; shift ;;
            *) die "unknown build option '$1'" ;;
        esac
    done

    local rom
    rom="$(cd "$KDIR/../../.." && pwd)"
    [[ -f "$rom/build/envsetup.sh" ]] || die "no ROM tree at $rom (expected <rom>/kernel/oneplus/sm8350-5.10)"
    cd "$rom"

    if [[ $sync -eq 1 ]]; then
        repo sync -c --no-tags --force-sync \
            kernel/oneplus/sm8350-5.10 kernel/oneplus/sm8350-5.10-devicetrees \
            kernel/oneplus/sm8350-5.10-modules device/oneplus/sm8350-common
    fi

    # envsetup/lunch are not written for set -eu
    set +eu
    # shellcheck disable=SC1091
    source build/envsetup.sh
    axion "$device" "$type" "$gms" || die "lunch failed"
    local out="$ANDROID_PRODUCT_OUT"
    m -j"$(nproc)" bootimage vendorbootimage vendor_dlkmimage "${out#"$rom"/}/dtbo.img" || die "build failed"
    set -eu

    local kobj="$out/obj/KERNEL_OBJ" ver stage zip
    ver="$(cat "$kobj/include/config/kernel.release" 2>/dev/null || echo unknown)"
    zip="$out/kernel-$ver-$(date +%Y%m%d-%H%M).zip"
    stage="$(mktemp -d)"
    for i in "${IMAGES[@]}"; do cp "$out/$i.img" "$stage/"; done
    echo "$ver" > "$stage/kernel.release"
    (cd "$stage" && zip -q -1 "$zip" ./*)
    rm -rf "$stage"
    echo "kernel zip: $zip"

    if [[ $publish -eq 1 ]]; then
        local web="/var/www/html/$(id -un)"
        [[ -d "$web" && -w "$web" ]] || die "cannot write $web (use --no-publish)"
        cp "$zip" "$kobj/vmlinux" "$kobj/System.map" "$web/"
        echo "published to $web: $(basename "$zip"), vmlinux, System.map"
    fi
}

flash() {
    local src="${1:-}" dir
    [[ -n "$src" ]] || die "usage: build.sh flash <kernel zip | URL | dir>"
    command -v fastboot >/dev/null || die "fastboot not found"
    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT
    dir="$tmp"

    if [[ "$src" == http* ]]; then
        curl -fL -o "$tmp/kernel.zip" "$src"
        src="$tmp/kernel.zip"
    fi
    if [[ -f "$src" ]]; then
        unzip -q -o "$src" -d "$tmp"
    elif [[ -d "$src" ]]; then
        dir="$src"
    else
        die "no such file or directory: $src"
    fi
    for i in "${IMAGES[@]}"; do [[ -f "$dir/$i.img" ]] || die "missing $i.img in $src"; done
    [[ -f "$dir/kernel.release" ]] && echo "kernel: $(cat "$dir/kernel.release")"

    # fastboot waits for the device by itself
    fastboot devices | grep -q . || adb reboot bootloader

    # boot/vendor_boot/dtbo are physical partitions (bootloader); vendor_dlkm
    # is a logical partition in super, so it needs fastbootd.
    fastboot flash boot "$dir/boot.img"
    fastboot flash vendor_boot "$dir/vendor_boot.img"
    fastboot flash dtbo "$dir/dtbo.img"
    fastboot reboot fastboot
    fastboot flash vendor_dlkm "$dir/vendor_dlkm.img"
    fastboot reboot
}

case "${1:-}" in
    build) shift; build "$@" ;;
    flash) shift; flash "$@" ;;
    *) sed -n '2,20p' "$0"; exit 1 ;;
esac
