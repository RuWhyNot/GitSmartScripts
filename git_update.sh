# Returns "*" if the current git state is dirty
function is_git_dirty {
	[[ $(git diff --shortstat 2> /dev/null | tail -n1) != "" ]] && echo "*"
}

# Returns "*" if the current branch have upstream branch in origin
function is_branch_tracked {
	BRANCH=$1

	[[ "$(git ls-remote --exit-code . origin/$BRANCH)" != "" ]] && echo "*"
}

function git_status {
	local LOCAL=$(git rev-parse @)

	local THIS_BRANCH="$(get_current_branch)"

	if [[ "$(is_branch_tracked $THIS_BRANCH)" ]]; then
		local REMOTE=$(git rev-parse @{u})
		local BASE=$(git merge-base @ @{u})

		if [[ $LOCAL == $REMOTE ]]; then
			echo "up-to-date"
		elif [[ $LOCAL == $BASE ]]; then
			echo "need-pull"
		elif [[ $REMOTE == $BASE ]]; then
			echo "need-push"
		else
			echo "diverged"
		fi
	else
		echo "untracked"
	fi
}

function set_color {
	MESSAGES_COLOR=$1 # global
}

function info_message {
	local MESSAGE=$1
	
	if [[ $MESSAGES_COLOR ]]; then
		# set console colot
		tput setaf $MESSAGES_COLOR
	fi

	echo $MESSAGE

	if [[ $MESSAGES_COLOR ]]; then
		# reset console color
		tput sgr0
	fi
}

function stash_save {
	info_message "Stashing uncommited changes"
	git stash save
}

function git_submodule_update {
	git submodule update -r
}

function stash_pop {
	info_message "Unstashing old changes"
	git stash pop
}

function rebase_to {
	local BRANCH=$1

	info_message "Rebasing on origin/$BRANCH"
	git rebase origin/$BRANCH
}

function push_changes {
	info_message "Pushing changes"
	git push
}

function get_current_branch {
	local test=$(git branch | grep "*")
	echo ${test:2}
}

function git_smart_update {
	local REBASE_BRANCH=$1

	local THIS_BRANCH="$(get_current_branch)"

	if [[ ! $REBASE_BRANCH ]]; then
		REBASE_BRANCH=$THIS_BRANCH
	fi

	git fetch

	local STATUS="$(git_status)"
	
	if [[ $STATUS == "need-pull" || $STATUS == "diverged" || $STATUS == "untracked" ]]; then
		if [[ "$(is_git_dirty)" ]]; then
			stash_save
			rebase_to $REBASE_BRANCH
			stash_pop
		else
			rebase_to $REBASE_BRANCH
		fi
	else
		info_message "Branch $THIS_BRANCH is up to date"
	fi
}


REPO=$1
COLOR=$2
ADVANCED_COMMAND=$3
PARAMETER=$4

set_color $COLOR

cd $REPO
info_message "Fetching $REPO"

if [[ $ADVANCED_COMMAND == "branch" && $PARAMETER ]]; then
	git_smart_update $PARAMETER
else
	git_smart_update
fi

git_submodule_update

if [[ $ADVANCED_COMMAND == "push" ]]; then
	push_changes
fi

info_message "Completed"

cd ..

