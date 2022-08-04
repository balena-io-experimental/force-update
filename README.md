# force-update

Attempt to reproduce the environment where Supervisor 12.3.0 was observed to fail to force update with locks set.

## Usage
```bash
git clone git@github.com:balena-io-playground/force-update.git
cd force-update
# Assumes the presence of a force-update fleet for testing.
# We push twice so that the reproduction has 2 releases to switch between when pinning.
balena push force-update
balena push force-update
```

If the Supervisor is functioning normally, the device will move to the pinned release despite the presence of the update locks.

If the Supervisor is malfunctioning, the device will not be able to reach the pinned release.

Note: If for any reason, the update lock is present on the device when you don't want it to be, run the following to remove it:
```
balena exec $(balena ps -aq -f name=pin-release) bash -c ./reset.sh
```