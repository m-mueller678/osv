### steps to get this working
- First, run setup (`setup.py`)
- build with `./scripts/build -j8 image=vmcache [mode=debug]`
- run with `./scripts/run.py -e /vmcache`

### GDB
- use `./scripts/run.py -e /vmcache --wait [-d]` to run
- start gdb with `gdb build/debug/loader.elf` or `gdb build/release/loader.elf` 
- connect with `connect`
- use `osv sysms` to load symbols
  - must first continue to allow osv to initialize
- use `hbreak`, not `break`
- pass `--hypervisor qemu` to enable more breakpoints at the expense of slower execution
  - `break` seems to work fine if this is used

### EC2
- build with `./scripts/build -j16 image=ena`
- convert to raw with `scripts/convert raw`
  - this reads from `build/last`
- create AMI with `modules/ena/create_ami_from_image.sh build/release.x64/osv.raw 'unikernel-images-mueller' usr.raw`
  - from `https://github.com/wkozaczuk/osv-on-aws/tree/main`

driver_profile=aws somewehere


# CLI (does not work)
- build libssl `https://stackoverflow.com/a/73604364`
- build `LD_LIBRARY_PATH="/home/marcus/software/openssl-1.1.1o/:$LD_LIBRARY_PATH" ./scripts/build -j8`

# CLI (does not work)
- change `modules/openssl/Makefile` to use `libssl.so.3`
- `./scripts/build -j8`
- now `build/release.x64/libvdso.so` fails
