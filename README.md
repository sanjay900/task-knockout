# Task Knockout

Command line workflow tool coordinating other command line tools.
The aim here is to drive together git, hub, github and [jira-cli](https://github.com/formigarafa/jira-integration).

## Usage:
```
ko <command> [options] [arguments]

Commands:
  ko branch <issue_id> [branch name] [--branch-from=develop]  # create branch for issue
  ko branches <issue_id>                                      # list existing branches for issue
  ko help [COMMAND]                                           # Describe available commands or one specific command
  ko pull_request <issue_id> [branch_name]                    # [NYI] create pull request for issue

## Prerequisites:
* jira-cli
* git
* hub

## Installation:

clone repository
bundle install
edit config/environments.yml
add it to your PATH.

## Notes:

Still in development: You will get surprises (the good kind, though).

## TODO:
- [ ] implement command start <task>
- [ ] implement command finish <task>
- [ ] implement command pause <task>
- [ ] add timesheet app int the workflow
- [ ] implement some contextualization from env where the command is run to avoid the need to aways pass the task id to the command.
