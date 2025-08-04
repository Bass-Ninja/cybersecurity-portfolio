#!/bin/bash
# Simple backup script: copies all .txt files from ~/documents to ~/backup

SOURCE_DIR="$HOME/documents"
BACKUP_DIR="$HOME/backup"

mkdir -p "$BACKUP_DIR"

cp "$SOURCE_DIR"/*.txt "$BACKUP_DIR"/

echo "Backup of .txt files completed."
