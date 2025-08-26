#!/usr/bin/env sh
# Derived from: https://forums.linuxmint.com/viewtopic.php?t=318872

echo REMEMBER TO SUDO THIS!

MOUNT_POINT="/mnt/fish"
MINT_HOME=/run/media/fisherman/cd040d58-c27f-4875-8481-33cc93724802/home/.ecryptfs/fish
echo MINT_HOME $MINT_HOME

echo "Enter mint password"
MINT_PASSWORD=$(
  read -r x
  echo "$x"
)

# a079d69b6906934f429f9b60b258b73a
UNWRAPPED_PASSWORD="$(printf %s "$MINT_PASSWORD" | ecryptfs-unwrap-passphrase $MINT_HOME/.ecryptfs/wrapped-passphrase -)"
echo "UNWRAPPED_PASSWORD: $UNWRAPPED_PASSWORD"

printf %s "$UNWRAPPED_PASSWORD" | ecryptfs-add-passphrase --fnek -
echo USE THE SECOND ONE FOR THE FNEK SHIT\; TODO MAKE THIS AUTOMATIC

mount -t ecryptfs \
  "$MINT_HOME/.Private" "$MOUNT_POINT" \
  -o key=passphrase,ecryptfs_cipher=aes,ecryptfs_key_bytes=16,ecryptfs_enable_filename_crypto=yes,ecryptfs_passthrough=no,ecryptfs_unlink_sigs
