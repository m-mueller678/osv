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
SF="${SF:-2}"
jemalloc_log=""

for arg in "$@"; do
    case "$arg" in
        del_va)
            rm -rf apps/spilly/module_bins/virtual_alloc
            ;;
        debug)
            release_debug=debug
            ;;
        jelog)
            jemalloc_log="--env=MALLOC_CONF=log:."
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

sed '/^[^;].*;;_DEBUG_MODE-/ s:^:;;DEBUG_MODE:' -i apps/spilly/spilly/compiler.lisp
sed '/;;_DEBUG_MODE-'$release_debug'/ s:;;DEBUG_MODE::g' -i apps/spilly/spilly/compiler.lisp

./scripts/build mode=$release_debug fs=virtiofs export=all image=spilly -j$(nproc) app_local_exec_tls_size=5000
mkdir build/export/disks/ -p
ln apps/spilly/disks/disk1 build/export/disks/disk1 -f
ln apps/spilly/disks/disk2 build/export/disks/disk2 -f
ln apps/spilly/db.bin build/export/db.bin -f

echo "gdb build/$release_debug/loader.elf -q -ex 'set pagination off' -ex 'connect' -ex 'hb run_main' -ex c -ex 'd 1' -ex 'osv syms -q' -ex 'hb rust_panic'"

./scripts/run.py -m "$MEM"G $cpus -e $threads' --power-off-on-abort '"$jemalloc_log"' --env=PERF_REPEAT='$REP' /spilly/'$ALLOC'/bench-oom:'$QUERY'.out /db.bin:tpch-'$SF --virtio-fs-tag=myfs --virtio-fs-dir=build/export $wait $dryrun