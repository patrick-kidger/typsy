#!/bin/sh
GITHUB_USERNAME=patrick-kidger

BRANCH=main
set -e
if output=$(git rev-parse --abbrev-ref HEAD) && [ "$output" != "$BRANCH" ]; then
  echo "Not on $BRANCH branch."
  exit 1
fi
if output1=$(git rev-parse "$BRANCH") && output2=$(git rev-parse origin/"$BRANCH") && [ "$output1" != "$output2" ]; then
  echo "Branch has not been pushed to remote."
  exit 1
fi
if output=$(git status --porcelain) && [ -z "$output" ]; then
  :
else 
  echo "Repo is not clean"
  exit 1
fi
./test.sh
PACKAGE_NAME=$(grep '^name' typst.toml | cut -d '"' -f 2)
VERSION=$(grep '^version' typst.toml | cut -d '"' -f 2)
if [ ! -d packages ]; then
  git clone --depth 1 --no-checkout --filter="tree:0" https://github.com/$GITHUB_USERNAME/packages
  cd packages
  git sparse-checkout init
  git sparse-checkout set packages/preview/$PACKAGE_NAME
  # This is the branch of the `packages` repository, not ours.
  git checkout main
  cd ..
else
  cd packages
  git checkout main
  cd ..
fi
if [ -d packages/packages/preview/$PACKAGE_NAME/$VERSION ]; then
  echo "$PACKAGE_NAME:$VERSION already exists"
  exit 1
fi
mkdir -p packages/packages/preview/$PACKAGE_NAME/$VERSION
if [ -d src/target ]; then
  rmdir src/target  # Spurious directory created by tinymist, don't need to copy that over.
fi
cp -r typst.toml README.md LICENSE src packages/packages/preview/$PACKAGE_NAME/$VERSION/
cd packages
BRANCH_NAME=$PACKAGE_NAME-$VERSION
git checkout -B $BRANCH_NAME
git add packages/preview/$PACKAGE_NAME/$VERSION
git commit -m "Releasing $PACKAGE_NAME:$VERSION"
git push -uf origin $BRANCH_NAME
open https://github.com/$GITHUB_USERNAME/packages/pull/new/$BRANCH_NAME
echo "Your browser has been opened with the pull request."
