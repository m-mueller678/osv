#!/usr/bin/env bash

set -e

release_debug=release
wait=""
dryrun=""
QUERY="${QUERY:-1}"
REP="${REP:-1}"
threads=""
cpus=""
MEM="${MEM:-4}"
ALLOC="${ALLOC:-virtual_alloc}"

for arg in "$@"; do
    case "$arg" in
        del_va)
            rm -rf apps/spilly/module_bins/virtual_alloc
            ;;
        debug)
            release_debug=debug
            ;;
        wait)
            wait='--wait'
            ;;
        dry)
            dryrun='--dry-run'
            ;;
        t1)
            threads='--env=THREAD=1'
            cpus='-c 1'
            ;;
        *)
            echo "Error: Unknown command '$arg'"
            exit 1
            ;;
    esac
done

./scripts/build mode=$release_debug fs=virtiofs export=all image=spilly -j$(nproc) app_local_exec_tls_size=5000
mkdir build/export/disks/ -p
ln ../spilly/disks/disk1 build/export/disks/disk1 -f
ln ../spilly/disks/disk2 build/export/disks/disk2 -f
ln ../spilly/db.bin build/export/db.bin -f

echo "gdb build/$release_debug/loader.elf -q -ex 'set pagination off' -ex 'connect' -ex 'hb run_main' -ex c -ex 'd 1' -ex 'osv syms -q' -ex 'hb rust_panic'"

./scripts/run.py -m "$MEM"G $cpus -e $threads' --power-off-on-abort --env=PERF_REPEAT='$REP' /spilly/'$ALLOC'/bench-oom:'$QUERY'.out /db.bin:tpch-2' --virtio-fs-tag=myfs --virtio-fs-dir=build/export $wait $dryrun