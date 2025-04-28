read -p "Enter files to add (leave empty to skip): " files_to_add
if [ -n "$files_to_add" ]; then
  git add $files_to_add
else
  echo "No files added."
fi

read -p "Enter commit message (leave empty to skip): " commit_message
if [ -n "$commit_message" ]; then
  git commit -m "$commit_message"
else
  echo "No commit made."
fi
nix flake update --flake ~/.config/nix-darwin/
git add flake.lock
git commit -m "Update flake.lock"
git push origin main
darwin-rebuild switch --flake ~/.config/nix-darwin/ --show-trace