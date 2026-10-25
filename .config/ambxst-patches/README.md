# Ambxst patches

My changes to [Ambxst](https://github.com/Axenide/Ambxst), on top of upstream
1.3.14 (commit `83e8462`). The working copy lives in `~/.local/src/ambxst` on
branch `mumeyong`; only the patch series is tracked here.

## Restore on a new machine

```sh
git clone https://github.com/Axenide/Ambxst.git ~/.local/src/ambxst
cd ~/.local/src/ambxst
git switch -c mumeyong 83e8462
git am ~/.config/ambxst-patches/*.patch
```

## Refresh after new commits on the branch

```sh
rm ~/.config/ambxst-patches/*.patch
git -C ~/.local/src/ambxst format-patch -o ~/.config/ambxst-patches 83e8462..mumeyong
```
