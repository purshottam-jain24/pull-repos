GITHUB_USERNAME="USERNAME"
GITHUB_TOKEN="ghp_TOKEN"
BACKUP_DIR="./github-projects"
PER_PAGE=200

mkdir -p "$BACKUP_DIR"
cd "$BACKUP_DIR" || exit 1

echo "Fetching all repositories for $GITHUB_USERNAME via SSH..."

page=1
repo_urls=()

while : ; do
    response=$(curl -s -H "Authorization: token $GITHUB_TOKEN" \
        "https://api.github.com/user/repos?per_page=$PER_PAGE&page=$page&affiliation=owner,collaborator,organization_member")

    urls=$(echo "$response" | grep -o '"ssh_url": "[^"]*' | awk -F'"' '{print $4}')

    if [ -z "$urls" ]; then
        break
    fi

    repo_urls+=($urls)
    ((page++))
done

echo "Total repositories found: ${#repo_urls[@]}"

for repo in "${repo_urls[@]}"; do
    repo_name=$(basename "$repo" .git)
    if [ -d "$repo_name" ]; then
        echo "Updating existing repo: $repo_name"
        cd "$repo_name" || continue

        git remote set-url origin "$repo"
        git fetch origin "+refs/heads/*:refs/remotes/origin/*"
        git fetch --tags
        default_branch=$(git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@')
        git pull origin "$default_branch"
        cd ..
    else
        echo "Cloning new repo: $repo_name"
        git clone "$repo"
        cd "$repo_name" || continue
        git fetch origin "+refs/heads/*:refs/remotes/origin/*"
        git fetch --tags
        cd ..
    fi
done

echo "All repositories are cloned/updated with SSH origin and all branches/tags."