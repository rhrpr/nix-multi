read -p "Enter files to add (leave empty to skip): " files_to_add
if [ -n "$files_to_add" ]; then
  git add $files_to_add
else
  echo "No files added."
fi

read -p "Enter commit message: " commit_message
git commit -m "$commit_message"
nix flake update --flake ~/.config/nix-darwin/
darwin-rebuild switch --flake ~/.config/nix-darwin/ --show-trace
